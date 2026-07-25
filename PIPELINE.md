# PIPELINE.md — hyperbuild architecture

hyperbuild is a two-stage, 19-step Claude Code pipeline (steps 1–12 plus half-steps 3.5,
4.5 and 8.5 = Stage A PLAN; steps 13–16 = Stage B BUILD) with exactly ONE human checkpoint between the
stages. This document is the architecture reference: the principles, every step's
contract, the state layout, both gates, the subagent spawn contract, and the lineage back
to hyperresearch — the deep-research harness this design is copied from.

The entry skill `hyperbuild` is a thin router; each step is its own skill under
`.claude/skills/hyperbuild-N-<name>/` (19 step skills + the router + the three gate-time
command skills `hyperbuild-choose`, `hyperbuild-revise`, `hyperbuild-redesign`
= 23 skill directories); the 22 subagents live in `.claude/agents/hb-*.md`.

---

## The 11 architecture principles

1. **Router + step skills.** The entry skill `hyperbuild` is a thin ROUTER: bootstrap,
   sequence, recover. It never does step work. Each pipeline step is its own skill,
   invoked via `Skill(skill: "hyperbuild-N-name")`, loaded fresh into context at the
   moment it's needed. This is hyperresearch's V8 lesson: one 1200-line skill gets
   compacted away mid-run; per-step skills survive context rot. Skills never chain to
   each other — every step bounces control back through the router, which re-reads state
   and loads the next skill fresh.

2. **Canonical idea is gospel.** The verbatim user idea is persisted once to
   `runs/<run_tag>/idea.md` and re-read by every step and every subagent. Never
   paraphrased. Every spawn prompt block-quotes it; every subagent judges its own work
   against it and rejects work that doesn't serve it.

3. **Durable state on disk.** Every step writes canonical artifacts to known paths.
   `runs/<run_tag>/manifest.json` records step transitions. A crashed run resumes at the
   exact step where it died via artifact scan + manifest. No step trusts the
   orchestrator's memory; each step re-derives its inputs from disk.

4. **Subagent spawn contract.** Every Task prompt includes: (1) the verbatim idea,
   block-quoted; (2) a pipeline-position statement ("You are step N... step N-1 produced
   X... step N+1 will consume Y"); (3) the subagent's specific inputs and exact output
   path; (4) the list of context files it must read first. See [The spawn
   contract](#the-spawn-contract).

5. **Parallel within a step, sequential across steps.** Steps never overlap (the ONLY
   exceptions: the two named concurrent pairs, 2 ∥ 3 and 8 ∥ 9 — see the router's
   "Concurrent step pairs" section); inside a
   step, spawning subagents in parallel is MANDATORY when there are multiple — all Task
   calls in ONE message, non-overlapping assignments, zero duplicated work.

6. **Adversarial by construction.** Drafts, plans, and code are attacked by critics
   (`hb-code-critic`, `hb-spec-critic`, `hb-ux-critic`) that emit findings JSON and NEVER
   edit. Fixes are applied as surgical edits by a tool-locked patcher (`hb-patcher`,
   Read+Edit only) — patch, never regenerate. The lock is physical: the patcher has no
   Write tool, so it cannot create files or rewrite wholesale.

7. **Hard gates.** A stage is complete only when its gate's checklist passes. Gate
   failures are fixed by changing the artifacts, never by re-interpreting the checks.
   Max 3 fix rounds, then the run stays blocked and says so honestly. Gate errors are
   facts about the artifacts, not opinions to assess.

8. **Never emit bare text while subagent tasks are in flight.** In headless mode a
   text-only response triggers `end_turn` and kills the pipeline. While waiting, append
   thoughts to `runs/<run_tag>/temp/orchestrator-notes.md` — productive thinking time
   AND keeps the turn alive.

9. **Git is the safety net.** The generated app lives in a git repo from the moment
   step 13 scaffolds it (git init + platform .gitignore + initial commit once the empty
   app builds). Step 14 commits after EVERY wave (message: `wave <N>: <task ids> — <one
   line>`) and after each epic's critic+patcher pass; step 15 commits after its patch
   pass. Rollback is `git revert`, the epic critics review real diffs, and the audit
   trail runs task → commit. The ship gate requires a clean working tree.

10. **Design craft is gated.** `docs/DESIGN-CRAFT.md` is BINDING on the design steps —
    6 (design research), 7 (design systems), 8 (mockups), 8.5 (visual QA). Every design
    spawn prompt cites it by path; every `hb-design-researcher`,
    `hb-design-system-author`, `hb-mockup-smith`, and `hb-design-critic` reads it before
    producing anything. Violations are DEFECTS, not taste disagreements: a banned
    AI-design tell, a missing signature element, one system font doing every job, clipped
    text, a FAB parked on a list row — each is re-spawned or patched like any other
    failed check. The load-bearing half of the principle is the second one: **a rendered
    screen nobody looked at is not a finished design.** Craft rules that no step ever
    checks against pixels are decoration, which is why step 8.5 exists.

11. **Every load-bearing claim is adversarially verified.** `docs/RESEARCH-ARCHIVE.md`
    is BINDING on every research step — 2, 3, 3.5, 5, 6, 9 — and on step 12's
    reusability guide. Each writes ONE research AREA, and every area runs the same four
    phases in order: `research/` (one agent per dimension, breadth, UNVERIFIED by
    construction) → `verify/` (one agent per load-bearing CLAIM, told to REFUTE it
    against primary sources) → `critique/` (critics reading the WHOLE area corpus for
    contradictions BETWEEN dimensions) → `author/` (the synthesis, and the only file
    downstream steps must read). The mechanism is the asymmetry: a researcher surveying
    a dimension optimizes for coverage and will repeat a 2023 blog post, a package
    archived last year, and an API name that never existed; a fact-checker handed ONE
    claim and told to kill it checks the registry, the official reference, and the
    actual repo. One agent handed five claims confirms all five — it has no budget to
    lose an argument with itself — so it is ONE VERIFIER PER CLAIM, all spawned in
    parallel in one message. Claims are registered per area in
    `runs/<run_tag>/temp/claims-0N.json`; 3–5 per research file at `standard`, 6–10 at
    `premier`. Verdicts come from a closed vocabulary — CONFIRMED / PARTIALLY_TRUE /
    REFUTED / UNVERIFIABLE — and **a REFUTED claim may never survive into a synthesis
    doc**, nor into the PRD, a feature spec, an epic, a task, or a code comment;
    PARTIALLY_TRUE carries its correction everywhere it appears; UNVERIFIABLE is never
    the sole support for a `must`. Refuted claims are RECORDED, never silently deleted:
    the `verify/` file stays and the `research/` file is left standing as the honest
    record of what one surveying agent believed — rewriting it would destroy the
    evidence that verification works. And every file in all four phases ends with the
    prompt that produced it (the PROVENANCE RULE, RESEARCH-ARCHIVE §4), because a
    finding says what an agent concluded while the prompt says what it was asked and
    what it was never asked to consider. The second half of the principle is economic:
    **research is spent once.** A checkout is one app; the user builds many, and almost
    nothing about which state library is current or what the store's privacy rules say
    is specific to the app that paid for it. Area names are therefore FIXED and never
    platform-specific, so the next checkout copies an area in with zero path edits.

---

## Stage A — PLAN (`/hyperbuild <idea>`)

### Step 1 — Intake (`hyperbuild-1-intake`)

Persists the verbatim idea, mints the run identity, resolves the platform, and seeds all
run state. Run tag = idea slug + 6 random hex chars (e.g. `habit-coach-3f9a2c`).
Platform resolution: stated in the idea wins; otherwise inferred, with the rationale
recorded. Gear resolution: `premier` in the idea prompt opts in; default `standard`.
Seeds TodoWrite with every step (1–16, including the half-steps 3.5, 4.5 and 8.5) plus
the checkpoint todo — 20 todos. Spawns: none.

**Artifacts:** `runs/<run_tag>/idea.md` (gospel), `runs/<run_tag>/manifest.json`,
`runs/<run_tag>/scaffold.md` (orchestrator's private planning doc, never ships),
`runs/<run_tag>/decisions/platform.md`.

### Step 2 — Market recon (`hyperbuild-2-market-recon`)

Competitor discovery, then deep per-competitor analysis: latest versions, feature sets,
changelogs, pricing, positioning, store ratings. Spawns 1 `hb-competitor-scout`, then
one `hb-competitor-analyst` per competitor in ONE message — 6–8 competitors at
`standard`, 12–15 at `premier`; 5–8 sources per dossier standard, 10–15 premier.
Step 2 owns the `research/` phase of area 01 and the first half of its `verify/` phase
(principle 11): every dossier writes its findings as COMPLETE ASSERTIONS (`Alpha's free
tier already ships the entire proposed MVP on both platforms`, never `Competitor
pricing`), the step registers the load-bearing ones — every price, tier, version, and
"they already ship this" — into `runs/<run_tag>/temp/claims-01.json`, and spawns ONE
`hb-claim-verifier` PER CLAIM in parallel, each using the RESEARCH-ARCHIVE §6 prompt
verbatim. 3–5 claims per dossier at `standard`, 6–10 at `premier`. This is the pass that
catches a competitor already shipping the MVP at a tenth of the assumed price — before
step 4 builds a PRD around a gap that does not exist.
BINDING: `docs/RESEARCH-ARCHIVE.md`, cited by path in every spawn prompt; every file
ends with the prompt that produced it.

**Artifacts:** `research/01-product-and-market/research/competitors/<slug>.md` (one
dossier per competitor), `research/01-product-and-market/verify/<competitor-slug>--<claim-slug>.md`
(one per registered claim; `<dimension>--<claim-slug>` is the universal shape), `research/01-product-and-market/author/competitor-landscape.md`
(feature matrix + positioning map, carrying every verify/ correction),
`runs/<run_tag>/temp/claims-01.json`.

### Step 3 — Social mining (`hyperbuild-3-social-mining`)

What real users say: Reddit, HN + forums, app-store reviews, LinkedIn/X. Verbatim quotes
with URLs; pain points, wish lists, and praised features ranked by frequency ×
intensity. Spawns 4 `hb-sentiment-miner` in parallel (one per platform group); 25–40
posts per platform at `standard`, 60–100 at `premier`. Steps 2 and 3 share no inputs
and run as a concurrent pair (2 ∥ 3 — one of the two permitted exceptions to
sequential steps); step 3.5 starts only when BOTH are done.
Step 3 writes the sentiment half of area 01's `research/` phase under the same contract
(principle 11): each miner's H3s are complete assertions about what users want or hate,
the step registers the load-bearing ones into the shared
`runs/<run_tag>/temp/claims-01.json` (3–5 per platform file at `standard`, 6–10 at
`premier`), and one `hb-claim-verifier` per claim is spawned in parallel to refute it —
is the "top complaint" a real pattern, or one viral thread reposted five times and a
vendor blog quoting itself? Only what survives reaches `author/sentiment-synthesis.md`,
which is the file step 4 turns into user demand in the PRD.
BINDING: `docs/RESEARCH-ARCHIVE.md`; every file carries its own prompt.

**Artifacts:** `research/01-product-and-market/research/sentiment/{reddit,hn-forums,appstore-reviews,linkedin-x}.md`,
`research/01-product-and-market/verify/<platform>--<claim-slug>.md`,
`research/01-product-and-market/author/sentiment-synthesis.md` (ranked pain points +
wish lists, corrections applied).

### Step 3.5 — Research audit (`hyperbuild-3-5-research-audit`)

The ADVERSARIAL RESEARCH AUDIT — runs only after steps 2 AND 3 are both complete. It is
area 01's `critique/` phase plus its index, the last two phases of principle 11's
sequence, and it runs AFTER every `verify/` file from steps 2 and 3 has landed.

The area gets 2 critic seats at `standard` (3 at `premier`), spawned in ONE message, each
under a DISTINCT lens: in area 01 one seat is always `hb-research-critic` (the skeptic
lens it has always owned — see below) and the rest are `hb-corpus-critic`. Each reads
the WHOLE area corpus — every competitor dossier, every sentiment file, and every
`verify/` verdict — hunting the defect class no single-claim fact-check can see:
contradictions BETWEEN dimensions (two dossiers describing incompatible pricing for one
product; a pain point the competitive set says is already solved), coverage holes, and
claims whose support collapses once the corpus is read as a whole. Each critic separates
what it actually ran or read (`[VERIFIED]`) from what it merely reasoned about
(`[OPEN]`), and NEVER edits another agent's file. The `hb-research-critic` seat runs the
corpus-level refutation pass it has always owned: the top pain points and wish-list items
attacked directly, and syndicated/derivative copies clustered so a story reposted five
times argues with the weight of ONE source.

The orchestrator then resolves the whole area: every CONFIRMED critic finding and every
`verify/` correction is applied to the `author/` docs — REFUTED claims removed from the
synthesis (and never re-derived downstream), PARTIALLY_TRUE claims rewritten to their
corrected form, UNVERIFIABLE claims labelled and barred from carrying a `must` alone.
Claims are downgraded or annotated, NEVER silently deleted, and the `research/` files
are not rewritten. Finally the step writes `_INDEX.md`: every agent in the area grouped
by phase, with file sizes (the cheap signal that an agent returned a stub) and each
verify/ file's verdict, plus the standing note that `research/` is unverified and
`verify/` overrides it. Step 4 then builds the PRD on evidence that survived both a
per-claim refutation attempt and a whole-corpus read.

**Artifacts:** `research/01-product-and-market/critique/<critic-name>.md` (one per critic
seat, including `research-audit.md` from `hb-research-critic`),
`research/01-product-and-market/_INDEX.md`, and the corrected
`research/01-product-and-market/author/{competitor-landscape,sentiment-synthesis}.md`.

### Step 4 — Product spec (`hyperbuild-4-product-spec`)

Merges steps 2+3 (as audited by step 3.5) into the PRD: personas, feature list under MoSCoW (must/should/could/
won't for v1), differentiators, every feature traced to competitor evidence or user
demand, and the FULL screen inventory — the canonical list of app screens with names.
Steps 8, 11, and 14 all key off that list. Each screen is additionally classified
`mockup_feasibility: full | partial | none` — `full` = standard UI, fully mockable in
HTML; `partial` = engine/camera/map/canvas content with mockable chrome (HUD, overlays,
menus) around a placeholder viewport, with a one-line note of what IS mockable; `none` =
pure engine-rendered, not mockable. Steps 8, 12, and 15 key off this classification.
Spawns 1 `hb-spec-critic` to attack the
draft; the orchestrator patches the PRD from its findings.
Its inputs are area 01's `author/` docs — NOT the raw `research/` files — because those
are the only ones carrying the verify/ corrections: principle 11's synthesis rule reaches
this far, so a REFUTED claim may not appear as fact in the PRD, a PARTIALLY_TRUE claim
appears only in its corrected form, and no UNVERIFIABLE claim alone justifies a `must`.

**Artifacts:** `research/product-spec.md` (at the vault ROOT — the product contract, not
a research finding).

### Step 4.5 — Feature specs (`hyperbuild-4-5-feature-specs`)

Expands every must/should PRD feature into its own deep spec file (could features only
if the cap allows): cap 15 files at `standard`, 25 at `premier`. Each file carries
frontmatter (`id: F-NN`, name, moscow, `status: specced`, screens) and the eight
required body sections (Overview, User stories, UX flow, States & edge cases, Data
touchpoints, Acceptance criteria, Evidence, Open questions). Spawns 3–5
`hb-feature-author` in parallel (the roster split into batches). Downstream: steps 6–8 read feature specs for real
content and flows; step 11 tasks cite feature ids; step 8 flips status to `designed`,
step 14 to `implemented`. Full contract: `features/README.md`.

**Artifacts:** `features/NN-<slug>.md` (one per feature), `features/00-index.md`.

### Step 5 — Stack research (`hyperbuild-5-stack-research`)

Deep research of best practices for the chosen platform/language, and the area that pays
for itself twice: almost none of it is specific to this app. The step DECOMPOSES the
platform into DIMENSIONS — 6–8 at `standard`, 10–14 at `premier` — instead of four fixed
topics: official architecture guidance, project structure, the state library's current
API, error handling and language idioms, the testing corpus (unit/widget/golden/a11y as
the platform allows), data/persistence, lints and tooling, CI and release, performance
and startup. HARVEST-FIRST: each researcher searches GitHub for official style guides
and high-star best-practices repos, vets and shallow-clones keepers into
`research/harvest/` (logged in `harvest-log.md` with licenses), then gap-fills with web
research; 8–12 sources per dimension at `standard`, 15–25 at `premier`. Spawns ONE
`hb-stack-researcher` per dimension, all in ONE message.

Then principle 11's engine runs over the area. Every H3 is a complete assertion
(`Automatic retry is ON by default in Riverpod 3 and is actively harmful here`, never
`Provider lifecycle`); the step registers 3–5 load-bearing claims per dimension file at
`standard` (6–10 at `premier`) into `runs/<run_tag>/temp/claims-02.json` — versions,
package maintenance status, licences, API and parameter names first — and spawns ONE
`hb-claim-verifier` PER CLAIM in parallel with the RESEARCH-ARCHIVE §6 prompt verbatim.
This is where a package archived last year stops being presented as alive and a
plausible-sounding method name that does not exist gets caught, BEFORE step 10 writes it
into a generated skill and step 14 compiles against it. THE PREMISE TRAP applies here
above all (RESEARCH-ARCHIVE §6): the installed SDK version is stated as a QUESTION for
the researchers to verify, never asserted in the brief, because a fact handed to an
agent is the one claim nobody checks. Then 3 `hb-corpus-critic` (5 at `premier` — area 02
runs the larger panel by design; every other area runs 2 / 3) read
the whole area for cross-dimension contradictions — three dimensions each shipping a
different, internally consistent API for one service is the signature defect — and only
then is the stack-guide authored, applying every correction. Every dimension doc ends in
committed "we will do X" decisions, not surveys; the stack-guide additionally names the
project's code taxonomy that steps 11 and 14 categorize tasks against.
BINDING: `docs/RESEARCH-ARCHIVE.md`; every file in all four phases ends with its prompt.

**Artifacts:** `research/02-engineering/research/<dimension>.md` (one per dimension),
`research/02-engineering/verify/<dimension>--<claim-slug>.md`,
`research/02-engineering/critique/<critic-name>.md`,
`research/02-engineering/_INDEX.md`, `research/02-engineering/author/stack-guide.md`
(the merged, committed guide Stage B builds against),
`runs/<run_tag>/temp/claims-02.json`. The area name is FIXED — never
`02-flutter-engineering` — so every downstream consumer hardcodes
`research/02-engineering/author/stack-guide.md` and is right on every platform.

### Step 6 — Design research (`hyperbuild-6-design-research`)

Proposes exactly 3 NAMED design directions suited to this app and audience (e.g. "Soft
Focus", "Swiss Utility", "Neon Playful"), then deep-researches each: reference design
systems, typography, color theory, motion, component patterns, accessibility —
HARVEST-FIRST (public design-system repos and open token sets cloned into
`research/harvest/`, then gap-fill). Spawns 3 `hb-design-researcher` in parallel (one
per direction); 6–10 sources per direction at `standard`, 12–18 at `premier`.
BINDING: `docs/DESIGN-CRAFT.md` — cited by path in every spawn prompt, read before any
research is written. The three directions must be three different products, not three
palettes on one layout (principle 10).

Area 03 runs the same four phases as every other research area (principle 11). Design
research looks like the least factual area and is not: the claims that decide a design
are the platform design system's ACTUAL current status and version, which components
really exist under the names cited, what the framework can genuinely render, and — the
expensive one — font LICENCES. So the step registers 3–5 load-bearing claims per
direction file at `standard` (6–10 at `premier`) into `runs/<run_tag>/temp/claims-03.json`
and spawns ONE `hb-claim-verifier` per claim; 2 `hb-corpus-critic` (3 at `premier`) then
read all three directions together, which is also where "these are three palettes on one
layout" gets named in prose before step 8.5 has to find it in pixels. The `author/`
synthesis, `design-directions.md`, is the corrected brief step 7 builds the three systems
from.
BINDING: `docs/RESEARCH-ARCHIVE.md` alongside DESIGN-CRAFT; every file ends with its prompt.

**Artifacts:** `research/03-design-system/research/<direction-slug>.md` (one per
direction), `research/03-design-system/verify/<direction-slug>--<claim-slug>.md`,
`research/03-design-system/critique/<critic-name>.md`,
`research/03-design-system/_INDEX.md`,
`research/03-design-system/author/design-directions.md`,
`runs/<run_tag>/temp/claims-03.json`.

### Step 7 — Design systems (`hyperbuild-7-design-systems`)

Builds the 3 full design systems from their research docs: type scale, color palette
(light + dark), spacing, radii, elevation, and component specs (buttons, cards, inputs,
nav, lists, empty states). Spawns 3 `hb-design-system-author` in parallel.
BINDING: `docs/DESIGN-CRAFT.md` — every system must commit, in real sections with real
values, to the eight craft commitments (signature element, display+body type pairing with
a stated scale, ONE named depth model, a radius rhythm plus a distinctive shape move,
hue-biased neutrals with separate status tokens, CSS-drawn empty-state art, data
personality, motion notes). Hand-wavy commitments become step 8.5 defects.

**Artifacts:** `runs/<run_tag>/designs/{a,b,c}/design-system.md`,
`runs/<run_tag>/designs/{a,b,c}/tokens.css` (CSS custom properties).

### Step 8 — Mockups (`hyperbuild-8-mockups`)

For every `full`/`partial` screen in the PRD's screen inventory × each of the 3 designs:
a self-contained HTML mockup — inline CSS derived from that design's tokens, REAL content
from the PRD and feature specs (never lorem ipsum), phone-frame wrapper for mobile
platforms. `partial` screens get their real HUD/chrome/overlays over a clearly-marked
placeholder viewport; `none` screens get no mockup — instead an art-direction card in
that design's `design-system.md`. After the mockups land, the orchestrator renders
`screenshots/<screen>.png` for every mockup via headless Chrome
(`chrome --headless=new --screenshot=<out> --window-size=458,912 --hide-scrollbars
file://<mockup>` — the phone-frame page's full outer size, bezel included;
desktop apps use a desktop viewport); if Chrome is missing, it logs a warning in the
manifest and continues — missing screenshots become a design-gate warning, not a hard
fail. Plus the gallery: side-by-side iframes per screen, design names, jump nav. Spawns 3–6
`hb-mockup-smith` (screens split per design). Screen count: every mockable PRD screen,
cap 12 at `standard`, cap 20 at `premier`. Flips feature `status: specced → designed`.
BINDING: `docs/DESIGN-CRAFT.md` — its §4 layout-integrity rules and its §5 self-check are
the smith's definition of done, and its §2 banned tells are checked by name before a
mockup is reported complete.

**Artifacts:** `runs/<run_tag>/designs/{a,b,c}/mockups/<screen>.html`,
`runs/<run_tag>/designs/{a,b,c}/screenshots/<screen>.png`,
`runs/<run_tag>/designs/index.html`.

### Step 8.5 — Visual QA (`hyperbuild-8-5-visual-qa`)

The design pipeline's adversarial pass — the only step in the harness that LOOKS at what
was drawn. Runs after step 8's exit criteria pass (it consumes step 8's renders and
nothing else, so it is invoked once both members of the 8 ∥ 9 pair have returned; it is
never a third concurrent member). Spawns 3 `hb-design-critic` in parallel, one per
direction, each with Read access to that direction's `screenshots/*.png`, its
`mockups/*.html`, its `design-system.md`, and `docs/DESIGN-CRAFT.md`. Each critic OPENS
every screenshot and judges three things:

1. **Craft** (DESIGN-CRAFT §2, §3) — does the direction trip any of the 12 banned
   AI-design tells; is the signature element present on ≥3 screens; do display and body
   resolve to different families; is the declared depth model actually applied; are there
   ≥3 distinct radii and the named shape move; are neutrals hue-biased and the accent
   scarce; do empty states carry real CSS-drawn art; do ≥2 data-personality forms appear.
2. **Layout integrity** (DESIGN-CRAFT §4) — the mechanical, checkable facts, every one of
   them a bug the first real run shipped: nothing clipped at any edge; no FAB or sheet
   covering a list row, a nav label, or a CTA; truncation deliberate (clamped lines or a
   real ellipsis — never a half-word like `12d lef`); no horizontal page scroll; tap
   targets ≥44×44; body text ≥15px at ≥4.5:1; spacing from the scale; real PRD content
   everywhere; status-bar and home-indicator safe areas drawn; dark mode holds.
   Cross-screen consistency within a direction counts here too: ONE nav component, one
   destination set, one icon set, one status-bar treatment — and no app tab bar on
   onboarding, modal, or full-screen-camera routes.
3. **Conformance and distinctness** — every binding rule the direction's own
   `design-system.md` states (nav destinations, FAB placement, list sort order, component
   anatomy) verified against the renders; then the cross-direction test judged on PIXELS:
   name three STRUCTURAL differences between a, b, and c without referring to color. If
   only the palette differs, the three directions are one layout in three skins and the
   check fails.

Findings land as `runs/<run_tag>/gates/visual-qa-{a,b,c}.json` — per-screen, per-rule,
each with the screenshot path and the named rule it violates. Critics NEVER edit
(principle 6). Every defect re-spawns the `hb-mockup-smith` that drew the offending
screen with the screenshot path and the defect named verbatim; the orchestrator
re-renders and re-critiques. MAX 2 critic rounds = exactly ONE patch round (deliberately
stricter than the ≤3 gate-fix-round budget: what survives here is written down, not looped
on), then unresolved defects are carried into the
step 12 report as explicit warnings so the human sees them at the gate instead of
discovering them in the pixels.

**Why this step exists:** the first real hyperbuild run produced three competent design
SYSTEMS and 30 rendered screens that nobody ever opened. The systems specified empty-state
illustrations, motion, dark palettes, and a load-bearing shape channel; the screens showed
flat cards, clipped rows, and a floating action button parked on top of a list — including,
on three separate screens, on top of the primary CTA. Every one of those defects was
visible in a PNG the pipeline had already rendered. The gap was not judgment, it was that
no step in the pipeline had eyes.

**Artifacts:** `runs/<run_tag>/gates/visual-qa-{a,b,c}.json`; re-rendered
`screenshots/<screen>.png` and patched `mockups/<screen>.html` for every fixed defect.

### Step 9 — Skill research (`hyperbuild-9-skill-research`)

Deep research on Claude Code skill authoring: SKILL.md format, frontmatter fields,
progressive disclosure, when to split reference files, what a genuinely rich skill looks
like — HARVEST-FIRST (shallow-clones `zakariaf/Flutter-Skills`, the canonical anatomy
exemplar, plus `anthropics/skills` and vetted community collections into
`research/harvest/skills/`) and mining this harness itself as an exemplar. The guide
ends with binding rules plus a shortlist of harvested skills step 10 can adapt (with
licenses). Spawns ONE `hb-stack-researcher` per dimension (SKILL.md format and
frontmatter, progressive disclosure, reference/example/script anatomy, trigger-rich
descriptions, richness norms, the harvested-skill shortlist). Steps 8 and 9 share no
inputs and run as a concurrent pair (8 ∥ 9 — the other permitted exception to sequential
steps); step 8.5 needs only 8, step 10 needs only 9, and 11 needs 8's gallery only at
gate time.

Area 04 runs the full four-phase contract (principle 11), and the stakes are unusually
mechanical: step 10 BUILDS five skills against whatever this guide says. A frontmatter
field that does not exist, a tool name spelled wrong, or a format rule remembered from an
older SKILL.md spec ships five broken skills whose script gates then fail in steps 14 and
16. So 3–5 load-bearing claims per dimension file at `standard` (6–10 at `premier`) are
registered into `runs/<run_tag>/temp/claims-04.json` and verified one agent per claim
against the primary source — the official Claude Code documentation and real skill
repositories, never recollection — followed by 2 `hb-corpus-critic` (3 at `premier`) over
the whole area.
BINDING: `docs/RESEARCH-ARCHIVE.md`; every file ends with its prompt.

**Artifacts:** `research/04-claude-skills/research/<dimension>.md`,
`research/04-claude-skills/verify/<dimension>--<claim-slug>.md`,
`research/04-claude-skills/critique/<critic-name>.md`,
`research/04-claude-skills/_INDEX.md`,
`research/04-claude-skills/author/skill-authoring-guide.md`,
`runs/<run_tag>/temp/claims-04.json`.

### Step 10 — Skill forge (`hyperbuild-10-skill-forge`)

Generates PROJECT-SPECIFIC skills into `.claude/skills/` from the stack-guide + PRD:
`app-code-style`, `app-architecture`, `app-testing`, `app-components` (wired to the
chosen design tokens later, in step 13), `app-review-checklist`. Each uses the RICH
four-part anatomy (lean SKILL.md core + `references/` deep dives + `examples/` in the
target language + `scripts/*.sh` PASS/FAIL gates), adapting harvested skills from step
9's shortlist where they fit (license-checked, attributed; for Flutter,
`zakariaf/Flutter-Skills` is the primary source) and writing from zero only for gaps.
Spawns 5 `hb-skill-smith` in ONE message (one per skill). These skills are what
`hb-implementer` and the critics enforce during Stage B — and the script gates are run
mechanically by steps 14 and 16.

**Artifacts:** `.claude/skills/app-{code-style,architecture,testing,components,review-checklist}/`
— each a four-part skill directory (`SKILL.md`, `references/`, `examples/`, `scripts/`).

### Step 11 — Epics (`hyperbuild-11-epics`)

The full backlog. `epics/00-overview.md` (epic list, dependency order, PRD coverage
matrix), one directory per epic with `epic.md` (goal, scope, out-of-scope, depends_on,
acceptance criteria) and one `task-NN-<slug>.md` per task (frontmatter: id, epic,
`status: todo`, depends_on, size, category — a `## Code taxonomy` category from the
stack-guide — features, and `files` — the non-empty list of planned repo-relative
paths, step 14's wave-disjointness key; body: context, spec, files to touch, testing
requirements, definition of done). Every must/should PRD feature maps to ≥1 task. Scale:
4–8 epics at `standard` (6–12 premier), 3–8 tasks per epic (4–10 premier). Spawns 1
`hb-epic-planner` (breakdown), then 3–6 `hb-task-author` in parallel (one per epic
batch), then `hb-spec-critic` for the coverage audit. Full contract: `epics/README.md`.

**Artifacts:** `epics/00-overview.md`, `epics/NN-<slug>/epic.md`,
`epics/NN-<slug>/task-NN-<slug>.md`.

### Step 12 — Design gate (`hyperbuild-12-design-gate`)

Runs the [design gate checklist](#gate-1--design-gate-step-12) via 1 `hb-gate-verifier`,
writes the report, then STOPS — the ONE permitted stop in the whole pipeline. It also
writes `research/README.md`, the vault's front door: the areas index table (area, run,
agent count, reusable-elsewhere verdict) plus the REUSABILITY GUIDE required by
`docs/RESEARCH-ARCHIVE.md` §8 — every area classified BY NAME as portable to any app,
portable to any app on this platform, or specific to this app; the copy mechanics for the
next checkout; the capture date and the 90-day re-verify rule; and the known bad premises
and unresolved critic findings stated plainly, because an honest gap beats a clean-looking
index. Mockup
coverage is judged against the feasibility-classified screen inventory (`full`/`partial`
screens only); missing `screenshots/<screen>.png` renders (e.g. headless Chrome
unavailable) surface as warnings in the report, never hard failures. The final
message to the user summarizes the run (competitor count, top pain points, platform
decision, epic/task counts), says how to open `runs/<run_tag>/designs/index.html`, and
asks for `/hyperbuild-choose a|b|c` — plus one line each for `/hyperbuild-revise` and
`/hyperbuild-redesign`, so "none of these yet" is an answer the user can give at the stop.
Unresolved step 8.5 defects appear in the report as named warnings, never omissions.
Manifest: `blocked_on: "design-choice"`.

**Artifacts:** `runs/<run_tag>/gates/design-gate-report.md`, `research/README.md`.

---

## The checkpoint — `/hyperbuild-choose <a|b|c>`

A thin skill, not a step. It:

1. Validates a run exists and is parked at the design gate.
2. Writes `runs/<run_tag>/decisions/design-choice.md`.
3. Copies the chosen design's `tokens.css` + `design-system.md` to `app/design/`
   (paths recorded in the decision file).
4. Updates the manifest: `design_choice`, `stage: "BUILD"`, clears `blocked_on`.
5. Optional second argument overrides the platform — then steps 5, 10, and 11 re-run
   before building (stack research, generated skills, and the backlog are all
   platform-shaped; the research vault and designs survive).
6. Invokes `Skill(skill: "hyperbuild")` — the router's resume logic takes over and
   drives Stage B.

### Reworking the designs at the same stop

Two sibling command skills share the checkpoint's preconditions (`stage: "PLAN"`,
`steps["12"] == "done"`, `blocked_on: "design-choice"`) and refuse in every other state:

- **`/hyperbuild-revise <plain-English change>`** — takes the request as free text and
  CLASSIFIES it into one of four scopes, then applies only that scope's blast radius:
  **idea** (a dated `## Revisions` entry appended to `idea.md`, then the PRD, feature
  specs, and everything downstream that depends on them) · **feature** (surgical edits to
  `features/NN-*.md` + `00-index.md` + the PRD rows that state the same fact, then the
  affected epics) · **design** (a tweak to ONE direction that stays itself — step 7 for
  that letter, its smiths, its screenshots, step 8.5 scoped to it; the other two are
  untouched, so the user's mental comparison survives) · **epics** (step 11 re-run under
  a stated constraint). A request for new or replacement DIRECTIONS is handed off to
  `/hyperbuild-redesign`.
- **`/hyperbuild-redesign [notes]`** — regenerates the design directions from free-form
  notes, parsing KEEP/REPLACE (`keep c, replace a and b`): every slot by default, or only
  the letters not kept. Kept letters survive untouched; replaced slots are archived under
  `designs/archive/round-<N>/`, then 6 → 7 → 8 → 8.5 → 12 re-run for the new letters
  only. Research, feature specs, epics, and generated skills all survive; only `designs/`
  is rebuilt.

Both mark the steps they invalidate `"redo"` in the manifest, record the steer in the
shared ledger `runs/<run_tag>/decisions/revisions.md` (appended, one entry per
invocation), and both END by re-parking the run at the design gate with a fresh report.
`idea.md`'s frontmatter and verbatim body stay gospel (principle 2) — never reworded,
never reordered; `/hyperbuild-revise` at IDEA scope may only APPEND a dated
`## Revisions` section below them, which is precisely how the change propagates (every
spawn block-quotes the idea body). The ONE-stop rule is preserved exactly: taste iterates
at the stop that already exists, and only `/hyperbuild-choose` releases Stage B.

---

## Stage B — BUILD (autonomous)

### Step 13 — Scaffold (`hyperbuild-13-scaffold`)

Initializes the real project in `app/` per the stack-guide: the platform's own scaffold
command (`flutter create` / Xcode project / npm scaffold...), lint + formatter + test
harness + CI config wired, commit-ready structure. `git init` in `app/` + the platform
.gitignore + the INITIAL COMMIT once the empty app builds and its smoke test passes —
principle 9's safety net starts here. Implements the chosen design tokens
in the target framework (e.g. `theme.dart` / `Theme.swift` generated from `tokens.css`)
and updates the `app-components` skill with concrete theme references so implementers
cite real symbols, not CSS. Orchestrator + 1 `hb-implementer`.

**Artifacts:** `app/` (scaffolded project, now its own git repo with the initial
commit), framework theme file(s) under `app/`,
updated `.claude/skills/app-components/SKILL.md`.

### Step 14 — Implement (`hyperbuild-14-implement`)

WAVE-BASED PARALLEL implementation over the task DAG — not epic-sequential. The wave
loop:

1. **Ready set** — every task across ALL epics whose `depends_on` tasks are done and
   whose epic's `depends_on` epics are done.
2. **Wave** — a subset of the ready set with PAIRWISE-DISJOINT `files:` lists
   (conflicting tasks defer to a later wave), capped at the parallel-implementers knob:
   3–5 at `standard`, 6–10 at `premier`.
3. Spawn the whole wave's implementer + test-engineer pairs IN PARALLEL, one message.
4. **Sync point** — full test suite + every generated skill's `scripts/*.sh` gate green
   before the next wave; NEVER start a wave on red. Then COMMIT the wave
   (`wave <N>: <task ids> — <summary>`). The wave's plan line — `wave <N>: [<task ids>]`
   — was already appended to `runs/<run_tag>/temp/wave-log.md` BEFORE the wave spawned:
   that log-before-spawn ordering IS the crash-resume mechanism (a logged wave with no
   matching `wave <N>:` commit is a dead wave).
5. **Epic completion** — when an epic's last task finishes: spawn `hb-code-critic` on
   the epic's REAL git diff; findings go to `hb-patcher` (tool-locked Read+Edit);
   verify the epic's acceptance criteria and check them off with evidence; commit the
   patch pass. Assembly tasks come late automatically — they depend on their parts.

Per-task mechanics inside a wave:

1. Mark the task `in-progress` (frontmatter edit).
2. Spawn `hb-implementer` — reads the idea, the PRD section, the feature file(s) the
   task cites, the task file, the generated `app-*` skills, and the chosen design's
   mockup HTML + `screenshots/<screen>.png` for its screens.
3. Spawn `hb-test-engineer` — writes/extends tests for the task, runs them, fixes
   failures until green. For UI tasks it ALSO writes visual/golden-snapshot tests per
   the stack-guide where the platform supports them (Flutter golden tests, iOS snapshot
   tests, RN/web screenshot tests), with the chosen design's mockup + screenshot as the
   visual spec.
4. Mark the task `done` (frontmatter edit). Flip covered features to
   `status: implemented`.

The honesty guardrails are non-negotiable: disjoint `files:` within a wave, a
full-suite + skill-gates sync point between waves, epic-completion critic passes, and
contracts/foundation tasks first via the DAG. Parallel within a wave, honest gates
between waves.

**Artifacts:** code + tests under `app/`; task frontmatter status flips in `epics/`;
`runs/<run_tag>/temp/wave-log.md`; the wave/epic git commit history in `app/`.

### Step 15 — Adversarial review (`hyperbuild-15-adversarial-review`)

Whole-app adversarial pass. Spawns 3 critics in parallel, ONE message:

- `hb-code-critic` — quality, security, idioms vs stack-guide + generated skills.
- `hb-spec-critic` — every must/should feature actually present and wired end-to-end.
- `hb-ux-critic` — SCREENSHOT COMPARISON: captures the implemented app's screens via
  platform tooling (golden-test outputs, simulator/emulator screenshots, or running the
  app) and judges them side by side against the chosen design's
  `screenshots/<screen>.png` — layout, tokens, spacing, typography, and states fidelity,
  NOT pixel-identity (rendering engines differ). Only `full`/`partial` screens are
  judged, and `partial` only on their mocked chrome/HUD.

Findings JSONs are merged and ranked; `hb-patcher` applies surgical fixes, and the
patch pass ends in a commit in `app/` (principle 9). Structural
findings (anything a small Edit hunk can't fix) become NEW TASKS and loop back through
step 14 — max 1 loop, then remaining structural findings go in the ship report as known
gaps.

**Artifacts:** critic findings JSONs at
`runs/<run_tag>/gates/review-findings-{code,spec,ux}.json` (plus `review-merged.json`
and `review-patch-log.json` in the same directory), patched + committed code in `app/`,
any new task files in `epics/`.

### Step 16 — Ship gate (`hyperbuild-16-ship-gate`)

Runs the [ship gate checklist](#gate-2--ship-gate-step-16) via 1 `hb-gate-verifier` —
including the mechanical TRACEABILITY CHAIN walk (feature → spec file → done tasks →
files in `app/` → passing tests) and the git checks (clean working tree, wave/epic
commit history present).
Failures: fix the artifacts, re-run the gate — max 3 rounds, else the run stays blocked
with an honest report. The final message: what was built, how to run it, test count,
known gaps.

**Artifacts:** `runs/<run_tag>/gates/ship-report.md`.

---

## State layout

Repo root — pipeline outputs (one checkout = one app):

```
research/                          # the vault (steps 2–9) — markdown is truth
├── README.md                      # areas index + REUSABILITY GUIDE (step 12)
├── product-spec.md                # the PRD, incl. canonical screen inventory (step 4)
├── harvest/                       # shallow-cloned GitHub repos + harvest-log.md
│                                  #   (disposable cache; the distilled artifacts
│                                  #   are truth, this is provenance)
├── 01-product-and-market/         # steps 2, 3, 3.5
├── 02-engineering/                # step 5
├── 03-design-system/              # step 6
└── 04-claude-skills/              # step 9
                                   #   each area: _INDEX.md + research/ + verify/
                                   #   + critique/ + author/ (see The research
                                   #   archive below)
features/                          # step 4.5 — NN-<slug>.md + 00-index.md
epics/                             # step 11 — 00-overview.md + NN-<slug>/ dirs
app/                               # steps 13–16 — the application (+ app/design/ tokens)
```

Every research file's frontmatter carries `run_tag` + `created` so provenance survives
multi-run vaults; later runs reuse the vault before re-fetching.

Run workspace — `runs/<run_tag>/` (full contract in `runs/README.md`):

```
runs/<run_tag>/
├── idea.md                    # GOSPEL: verbatim user idea + frontmatter
├── manifest.json              # step transitions; THE resume point
├── scaffold.md                # orchestrator's private planning doc (never ships)
├── temp/orchestrator-notes.md # anti-idle thinking log
├── temp/claims-0N.json        # per-area claim register (steps 2/3 → 01, 5 → 02, 6 → 03, 9 → 04):
│                              #   every extracted claim, whether it was selected, and its verdict
├── temp/wave-log.md           # step 14's wave ledger: `wave <N>: [<task ids>]`, logged pre-spawn
├── designs/
│   ├── index.html             # gallery comparing all three (step 8)
│   └── {a,b,c}/
│       ├── design-system.md
│       ├── tokens.css
│       ├── mockups/<screen>.html
│       └── screenshots/<screen>.png   # headless-Chrome renders (step 8)
├── decisions/
│   ├── platform.md            # chosen stack + rationale (step 1)
│   ├── design-choice.md       # written by /hyperbuild-choose
│   └── revisions.md    # appended by /hyperbuild-revise + /hyperbuild-redesign
└── gates/
    ├── design-gate-report.md  # step 12
    ├── visual-qa-{a,b,c}.json # step 8.5 — per-direction visual QA findings
    └── ship-report.md         # step 16
```

Manifest schema:

```json
{
  "run_tag": "habit-coach-3f9a2c",
  "stage": "PLAN",
  "platform": "flutter",
  "gear": "standard",
  "steps": {"1": "done", "2": "done", "3": "done", "3.5": "done", "4": "done", "4.5": "done"},
  "design_choice": null,
  "blocked_on": null
}
```

Resume ladder (the router owns it): manifest first, TodoWrite second, artifact scan
third — the router carries the full step→canonical-artifact table. If `design_choice`
is set and `stage` is `BUILD`, continue at the first unfinished build step.

---

## The research archive — area layout

The binding format contract is `docs/RESEARCH-ARCHIVE.md`; this section states the
architecture it enforces. One AREA per research step-group, four phases per area, the
same shape every time:

```
research/
├── README.md                    # areas index + REUSABILITY GUIDE (written at step 12)
├── product-spec.md              # the PRD (step 4) — stays at root: product contract, not research
├── harvest/                     # shallow clones + harvest-log.md (unchanged)
├── 01-product-and-market/       # steps 2, 3, 3.5
│   ├── _INDEX.md
│   ├── research/competitors/<slug>.md, research/sentiment/<platform>.md
│   ├── verify/<dimension>--<claim-slug>.md
│   ├── critique/<critic-name>.md
│   └── author/competitor-landscape.md, author/sentiment-synthesis.md
├── 02-engineering/              # step 5
│   ├── _INDEX.md
│   ├── research/<dimension>.md
│   ├── verify/, critique/
│   └── author/stack-guide.md
├── 03-design-system/            # step 6
│   ├── _INDEX.md
│   ├── research/<direction-slug>.md
│   ├── verify/, critique/
│   └── author/design-directions.md
└── 04-claude-skills/            # step 9
    ├── _INDEX.md
    ├── research/<dimension>.md
    ├── verify/, critique/
    └── author/skill-authoring-guide.md
```

**The four phases, and why each exists.**

- **`research/`** — one file per dimension, ONE agent each, independent web research.
  Breadth. UNVERIFIED BY CONSTRUCTION, and the `_INDEX.md` says so out loud.
- **`verify/`** — one file per load-bearing claim, each written by an agent told to
  REFUTE that one claim against primary sources. Depth. The most valuable and least
  obvious directory in the vault.
- **`critique/`** — critics reading the WHOLE area corpus, hunting contradictions
  BETWEEN dimensions: the defect class no single-claim fact-check can see, because each
  dimension is internally consistent and they disagree only with each other.
- **`author/`** — the synthesis, and the ONLY research files downstream steps must read.
  It carries every correction and synthesizes; it never introduces a fact absent from
  its inputs.
- **`_INDEX.md`** — every agent in the area grouped by phase, with file sizes (the cheap
  signal that an agent returned a stub) and each verify/ file's verdict.

**Area names are FIXED and never platform-specific.** Not `02-flutter-engineering`, not
`03-material-design-system`. The platform is chosen BY the research inside area 02, so a
platform in the path would make every downstream path conditional on a decision that had
not been made when the path was written. Fixed names let every step, skill, and gate
hardcode `research/02-engineering/author/stack-guide.md` and be right on every run, on
every platform, forever. The platform goes in frontmatter and prose, NEVER in paths —
and that is also what makes an area copy-pastable into the next checkout with zero edits.

**Ordering inside an area is strict:** all of `research/` lands, then claims are
registered into `runs/<run_tag>/temp/claims-0N.json` and ALL verifiers spawn in one
parallel message, then the corpus critics read everything, then the author writes. An
`author/` file produced before its area's `verify/` files exist is a process violation,
not a scheduling optimization — it is a synthesis that rests on unchecked claims
(principle 11).

**Two files that do NOT move:** `research/product-spec.md` (the PRD is the product
contract, not a research finding — steps 4.5, 6, 8, 11 and the gates all key off it at
the vault root) and `research/harvest/` (the shallow-clone cache, shared by every
harvest-first step).

---

## The spawn contract

Every Task spawn, in every step, follows the same 4-piece contract. No exceptions —
a subagent that doesn't know the verbatim idea and its exact position in the pipeline
will overreach, duplicate work, or optimize for the wrong thing.

1. **The verbatim idea, block-quoted** — plus the path to `idea.md` so the subagent can
   re-read it. GOSPEL: work that doesn't serve the idea gets rejected, no matter how
   interesting.
2. **Pipeline position** — "You are step N (<name>) of the hyperbuild pipeline. Step
   N-1 produced X. After you return, step N+1 will consume Y." This scopes the
   subagent: it knows it is not the whole pipeline and must not overreach.
3. **Specific inputs + exact output path** — a flat key: value list. The subagent never
   chooses where to write.
4. **Context files to read first** — an explicit, curated reading list. Expensive
   subagents are handed their inputs, not sent browsing.

Template (rendered by the orchestrator at spawn time; `<...>` = values it substitutes,
`{{...}}` = file contents it inlines):

```
subagent_type: hb-<agent-name>
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step <N> (<step name>) of the hyperbuild
  pipeline. Step <N-1> produced <input artifact(s)>. After you return,
  <what the orchestrator does next / which step consumes your output>.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - gear: <standard|premier>
  - <param>: <value>
  - output_path: <exact file this subagent must write>

  READ FIRST:
  - runs/<run_tag>/idea.md
  - <every context file, exact repo-relative paths>
```

Tool-locked subagents get the lock restated inside PIPELINE POSITION ("You are
TOOL-LOCKED to [Read, Edit] — you cannot Write"), and the orchestrator pre-stubs any
file an Edit-only agent must populate, because Edit cannot create files.

**The fifth piece, on RESEARCH-PHASE spawns only — the PROVENANCE RULE.** Every subagent
writing into a research area (`research/`, `verify/`, `critique/`, `author/` under
`research/0N-<area>/`) is told, inside the prompt itself, to END ITS FILE with that same
prompt reproduced VERBATIM in a collapsible `<details><summary>The prompt that produced
this</summary>` block — no summary, no paraphrase, no "the prompt asked me to…" (a
four-backtick outer fence when the prompt body contains a triple backtick). Every research
prompt therefore carries its own reproduction instruction, and `docs/RESEARCH-ARCHIVE.md`
is listed BY PATH in the same spawn's READ FIRST block. A research file without its
provenance block is INCOMPLETE and the agent is re-spawned, exactly like any other failed
check. Format and rationale: RESEARCH-ARCHIVE §4.

---

## Gate 1 — design gate (step 12)

Every check is a disk-verifiable fact, executed mechanically by `hb-gate-verifier` and
recorded with per-check evidence in `runs/<run_tag>/gates/design-gate-report.md`.
Failures are fixed by changing the artifacts (max 3 rounds), NEVER by re-reading a check
charitably.

- [ ] `runs/<run_tag>/idea.md` exists with frontmatter (`run_tag`, `created`, `platform`)
- [ ] `runs/<run_tag>/decisions/platform.md` exists with a stated rationale
- [ ] `research/01-product-and-market/author/competitor-landscape.md` exists; competitor
      dossier count in `.../research/competitors/` within gear range (6–8 standard /
      12–15 premier)
- [ ] All 4 `research/01-product-and-market/research/sentiment/*.md` files +
      `research/01-product-and-market/author/sentiment-synthesis.md` exist
- [ ] Area 01's `critique/` holds ≥2 critic files (≥3 at `premier`) and
      `research/01-product-and-market/_INDEX.md` exists, listing every agent under its
      phase with file sizes; every CONFIRMED critic finding shows a resolution
      (downgrade/annotation) in the `author/` docs
- [ ] `research/product-spec.md` exists at the vault ROOT with MoSCoW feature list AND a
      named screen inventory
- [ ] All 4 research areas exist and are COMPLETE per `docs/RESEARCH-ARCHIVE.md`: each of
      `research/{01-product-and-market,02-engineering,03-design-system,04-claude-skills}/`
      has a non-empty `research/`, `verify/`, `critique/`, `author/` and an `_INDEX.md`
- [ ] EVERY file under all four areas ends with its provenance block (the collapsible
      "The prompt that produced this" — RESEARCH-ARCHIVE §4). A file without one is
      INCOMPLETE, not a style miss
- [ ] Claim coverage: ≥3 `verify/` files per AREA (≥6 at `premier`), and every
      `research/` file with at least one `"selected": true` claim in its area's registry
      has ≥1 `verify/` file — each with a frontmatter `verdict` from the closed
      vocabulary CONFIRMED / PARTIALLY_TRUE / REFUTED / UNVERIFIABLE. (Per-AREA, not
      per-FILE: the areas bind a hard `VERIFY_BUDGET` of ≤25 standard / ≤60 premier, so
      "≥3 verify files per research file" would demand 30–36 in area 01 at standard and
      84 in area 02 at premier — unsatisfiable by construction. This wording is the one
      `hyperbuild-12-design-gate`'s check 22 executes; the two must not drift.)
- [ ] NO REFUTED claim survives in any `author/` doc, in `research/product-spec.md`, in
      `features/*.md`, or in `epics/**` — every REFUTED verdict is traced to its
      correction or its removal; every PARTIALLY_TRUE claim appears only in its corrected
      form; no UNVERIFIABLE claim is the sole support for a `must` feature
- [ ] `research/02-engineering/research/<dimension>.md` count within gear range (6–8
      standard / 10–14 premier) + `research/02-engineering/author/stack-guide.md` exists
      and contains committed "we will do X" decisions
- [ ] 3 `research/03-design-system/research/<direction-slug>.md` docs +
      `research/03-design-system/author/design-directions.md` exist
- [ ] `research/04-claude-skills/author/skill-authoring-guide.md` exists
- [ ] `research/README.md` exists: the areas index table plus the REUSABILITY GUIDE
      (RESEARCH-ARCHIVE §8) — every area classified portable-to-any-app /
      portable-to-this-platform / this-app-only, with capture dates, the re-verify rule,
      and the known bad premises and unresolved critic findings named explicitly
- [ ] `features/00-index.md` exists; every must/should PRD feature has a
      `features/NN-<slug>.md` file with all 8 required body sections
- [ ] All 5 generated skills exist under `.claude/skills/app-*/SKILL.md` with valid
      frontmatter
- [ ] For EACH of designs a, b, c: `design-system.md` + `tokens.css` + one
      `mockups/<screen>.html` per `full`/`partial` screen in the PRD screen inventory
      (cap 12 standard / 20 premier); NO `.html` for `none` screens
- [ ] Every `none` screen in the PRD inventory has a `## Art direction — <Screen>` card
      in EACH of the 3 designs' `design-system.md` (vacuous pass when the inventory has
      no `none` screens)
- [ ] One non-empty `screenshots/<screen>.png` per mockup in each design — when the
      manifest has `screenshots_skipped: true`, missing screenshots are a WARNING
      (`warn`), never a hard fail
- [ ] `runs/<run_tag>/gates/visual-qa-{a,b,c}.json` exists — one per direction, each
      accounting for EVERY rendered screenshot: a `.png` named in neither
      `screens_reviewed` nor `screens_not_viewed` FAILS (a rendered screen nobody looked
      at is not a finished design, principle 10). A screen listed in
      `screens_not_viewed` WITH a reason is a `warn` and is named in the report, not a
      hard fail — step 8.5 is required to say "I could not open this" rather than judge
      it from HTML. With `screenshots_skipped: true` there are no pixels to view: the
      files must still exist, recording the source-level review step 8.5 fell back to,
      and the report carries the degraded-QA warning
- [ ] ZERO step 8.5 `critical` findings are still `open`: each is either fixed (the
      re-rendered screenshot passes) or `accepted-known-issue` after both critic rounds
      were spent, with a reason — and every accepted one is printed in this report's
      `### Known visual issues` table AND in the user-facing stop message. Unresolved
      `major`/`minor` findings stay recorded in the visual-QA JSONs; the gate does not
      block on them
- [ ] The cross-direction distinctness check ran on PIXELS (step 8.5's own 8.5.8 pass,
      recorded in `temp/orchestrator-notes.md`). It is enforced INSIDE step 8.5: three
      structural, non-color differences named, or a DESIGN-CRAFT §2.12 finding filed
      against every direction that reads as a palette swap. The gate reads the resulting
      findings, not a separate verdict
- [ ] `runs/<run_tag>/designs/index.html` exists and references all three designs
- [ ] `epics/00-overview.md` exists; every epic dir has `epic.md` + ≥1 task file; every
      task has valid frontmatter with `status: todo`
- [ ] Coverage complete BOTH directions: every must/should feature id appears in ≥1
      task's `features:` list, and every task's cited features exist
- [ ] Manifest: steps 1–11 (incl. 3.5, 4.5 and 8.5) all `done`

On pass: write the report, set `blocked_on: "design-choice"`, STOP, and message the user
(summary + gallery path + `/hyperbuild-choose a|b|c`). This is the ONE permitted stop.

## Gate 2 — ship gate (step 16)

Same mechanics: `hb-gate-verifier`, per-check evidence, artifacts-only fixes, max 3
rounds, then `blocked_on` set + an honest report in
`runs/<run_tag>/gates/ship-report.md`.

- [ ] Full test suite passes (exit 0); test count recorded
- [ ] Lint/analyzer clean (zero errors; warnings enumerated in the report)
- [ ] Every generated-skill `scripts/*.sh` gate passes (exit 0), script list recorded
- [ ] App builds with the platform-appropriate build command; launch verified where the
      platform allows it
- [ ] Every task file in `epics/**/task-*.md` has `status: done`
- [ ] Every epic's acceptance criteria checked off, with evidence (file/test reference)
- [ ] PRD coverage matrix complete: every must/should feature `status: implemented` and
      wired end-to-end
- [ ] TRACEABILITY CHAIN walked mechanically: every must/should feature F-NN → its
      `features/NN-<slug>.md` exists → ≥1 task with `features: [F-NN]`, all
      `status: done` → every file in those tasks' `files:` lists exists in `app/` →
      the tests those tasks added pass. A break ANYWHERE in the chain blocks the ship
- [ ] `app/` git working tree is clean, with the wave/epic commit history present
- [ ] Step 15 critic findings resolved or explicitly listed as known gaps
- [ ] `gates/ship-report.md` written: what was built, how to run it, test count, known
      gaps

Final message to the user mirrors the report: what was built, how to run it, test count,
known gaps. If blocked after 3 rounds: say exactly what is red and why. Honesty over
optimism.

---

## Scale gears

Default `standard`; the user opts into `premier` by saying "premier" in the idea prompt.
Step 1 records `gear` in the manifest; every step reads it and cites its own numbers.
When the gear scales up, EVERY knob widens together — raising only research volume would
strand evidence that no epic ever consumes.

The verification knobs are the expensive ones and it is worth being blunt about it: with
one fact-checker per load-bearing claim, a `standard` research area costs its dimension
researchers PLUS 3–5 verifiers per research file PLUS 2 corpus critics PLUS an author,
and there are four areas. Research now runs several times the agents and several times
the wall clock it did before this contract, and it dominates a run's token bill. The
trade is deliberate and is stated in principle 11: it is the only reason a version,
price, licence, or store policy in this vault is still worth reading in six months, and
the archive is reusable by every later app (`research/README.md`), so the cost is paid
once across many builds. A run that needs to be cheaper runs `standard` — never a
hand-trimmed `standard` with the verifiers quietly dropped, which converts a checked
archive back into a confident survey.

| Knob | standard | premier |
|------|----------|---------|
| Competitors analyzed | 6–8 | 12–15 |
| Sources per competitor dossier | 5–8 | 10–15 |
| Sentiment posts mined per platform | 25–40 | 60–100 |
| Stack research sources per topic | 8–12 | 15–25 |
| Engineering research dimensions | 6–8 | 10–14 |
| Design research sources per direction | 6–10 | 12–18 |
| Claims verified per research file | 3–5 | 6–10 |
| Verify agents per area (hard ceiling) | ≤25 | ≤60 |
| Corpus critics per area *(the area binds the count: 01/03/04 = 2 / 3 · 02 = 3 / 5)* | 2–3 | 3–5 |
| Mockup screens | every PRD screen (cap 12) | every PRD screen (cap 20) |
| Feature spec files | every must/should (cap 15) | every must/should (cap 25) |
| Epics | 4–8 | 6–12 |
| Tasks per epic | 3–8 | 4–10 |
| Parallel implementers per wave (step 14) | 3–5 | 6–10 |
| Critic fix rounds (gates) | ≤3 | ≤3 |

---

## LINEAGE — what hyperbuild copied from hyperresearch

hyperbuild is not "inspired by" hyperresearch in the loose sense; each mechanism below
is a deliberate port of a mechanism that hyperresearch proved under fire.

| hyperbuild mechanism | Hyperresearch ancestor | What carried over |
|---|---|---|
| `hyperbuild` router + `hyperbuild-N-*` step skills, each loaded fresh via `Skill()` | `hyperresearch` entry skill + 16 step skills (the V8 fix) | One giant skill gets compacted away mid-run and steps silently vanish; per-step skills load at the moment of need and survive context rot. Steps bounce control back through the router; they never chain directly. |
| `runs/<run_tag>/idea.md` — verbatim, block-quoted into every spawn | `research/runs/<vault_tag>/query.md` — "RESEARCH QUERY (verbatim, gospel)" | The user's exact words are the supreme arbiter for every subagent. Paraphrase drifts; gospel doesn't. |
| `manifest.json` + resume ladder (manifest → TodoWrite → artifact scan) | run manifest + `run resume` + per-skill "Recover state" sections | Disk is truth, context is cache. A crashed run resumes at the exact dead step; no step trusts the orchestrator's memory. |
| Critics emit findings JSON, `hb-patcher` is tool-locked `[Read, Edit]`, orchestrator pre-stubs its log files | 4 parallel critics + `hyperresearch-patcher` `[Read, Edit]` lock + pre-stubbed `patch-log.json` | Capability = contract. Reviewers locate problems and cite evidence; exactly one downstream role owns the wording; the tool lock makes wholesale regeneration physically impossible. |
| Step 12 design gate + step 16 ship gate, run by `hb-gate-verifier`, ≤3 fix rounds, honest blocked state | `run verify` ship gate + lint battery ("Gate errors are facts about the report, not opinions") | Gates are mechanical checklists with per-check evidence. Failures change artifacts, never interpretations. Blocked runs say so instead of shipping quietly broken. |
| `standard`/`premier` gears; step 1 records `gear`, steps cite their numbers | `full`/`premier` gear profiles rendered into skills | All scale knobs live in one table and widen together — scaling is a gear change, not sixteen prompt edits. |
| The 4-piece spawn contract | The "standard 3-piece contract" (gospel query, pipeline position, YOUR INPUTS + run directives) | Every subagent knows the user's intent, its exact position, its exact inputs, and its exact output path — so it cannot overreach or free-write. |
| Root-level `research/` vault, plain markdown, frontmatter provenance | `research/notes/` vault — "Markdown is truth, SQLite is cache" | Research is a first-class, human-readable deliverable that outlives the run; later runs reuse it before re-fetching. |
| `temp/orchestrator-notes.md` anti-idle protocol | "CRITICAL: never emit bare text while waiting" + orchestrator-notes | Headless-mode survival: a text-only response ends the turn; writing evolving thoughts to disk keeps the turn alive and is productive. |
| Adversarial searches required in every research artifact ("X criticism", "why I stopped using X") | Step 2's mandatory adversarial search pass | A corpus of praise produces a naive plan; hostile sources are fetched on purpose. |
| Step 3.5 research audit — `hb-research-critic` + the area's `hb-corpus-critic`s refute the corpus, cluster syndicated copies | hyperresearch's corpus critic / source-independence audit | Research is attacked BEFORE it is consumed: derivative copies count as ONE source, and every headline claim survives a refutation attempt or gets downgraded — never silently deleted. |
| The `verify/` engine — one `hb-claim-verifier` per LOAD-BEARING claim, told to REFUTE it against primary sources, verdicts from a closed vocabulary, corrections applied in `author/` (`docs/RESEARCH-ARCHIVE.md` §5–§7) | hyperresearch's cite-checker pass + its source-independence audit, fused and pushed down to the claim | hyperresearch never lets a citation into the report without a checker fetching the source, and never lets five syndicated copies of one story count as five. hyperbuild applies both at claim granularity: the cite-checker becomes one agent per claim, handed the claim ALONE and told to kill it (an agent handed five claims confirms all five — it has no budget to lose an argument with itself); the independence audit becomes the corpus critics, who see what no single-claim check can, i.e. dimensions that are each internally consistent and disagree only with each other. The verdict vocabulary is closed (CONFIRMED / PARTIALLY_TRUE / REFUTED / UNVERIFIABLE) for the same reason hyperresearch's gate errors are facts, not opinions — "mostly true" is not a result you can act on. Divergence: hyperresearch checks citations in a report it is about to ship; hyperbuild checks claims a whole APP will be built on, so REFUTED is barred from every downstream artifact, not just the prose. |
| Every research file ends with the verbatim prompt that produced it (the PROVENANCE RULE) + `research/README.md`'s reusability guide | The root-level vault's "markdown is truth" provenance frontmatter, extended | hyperresearch keeps sources and dates so a finding can be re-checked. hyperbuild keeps the PROMPT too, because the reusable asset is the brief and the fan-out, not the conclusion: the finding says what one agent decided, the prompt says what it was asked and what it was never asked to consider. That is what lets the NEXT checkout copy an area in and re-run it with a different brief instead of re-buying it at full price. |
| Step 8.5 visual QA — `hb-design-critic` opens every rendered screenshot and grades it against `docs/DESIGN-CRAFT.md`, defects re-spawn the smith that drew the screen | The same adversarial-critic mechanism, pointed at PIXELS instead of prose | hyperresearch attacks the artifact it is about to ship in the medium the reader will consume it in. Design's medium is the render, so the critic must LOOK: a craft rule checked only against the design system's own prose is self-certification (the first run's directions self-scored "three different products" while rendering one layout in three palettes). Findings JSON, no edits, ≤3 fix rounds — a design gate with the same mechanics as every other gate. |
| Step 14 wave loop — disjoint-`files:` tasks from any epic run in parallel between sync points | Parallel-within-a-step discipline (all Task calls in ONE message, non-overlapping assignments) | Parallelism lives inside one unit of work with disjoint assignments and a hard gate at its edge; the wave is step 14's unit, the full-suite sync point its gate. |
| Per-wave/per-epic git commits in `app/` (`wave <N>: <task ids> — ...`) + clean-tree ship gate | Pre-stubbed `patch-log.json` provenance ledger | Every change is attributable after the fact: task → commit is the audit trail, epic critics review real diffs, and rollback is `git revert`, not archaeology. |
| Small, categorized parts: the stack-guide's code taxonomy (step 5), one-kind small tasks (step 11), each piece's tests green BEFORE composition (step 14) | Atomic work items + the patcher's small surgical Edit hunks (per-hunk cap) | Small pieces are easier to test, review, and implement with focus; screens compose from already-tested subcomponents instead of being built in one shot. |
| ONE human stop — the design gate | (deliberate divergence) hyperresearch has zero mid-run checkpoints | Taste is the one thing the pipeline shouldn't decide. hyperbuild stops exactly once, for exactly one question — a\|b\|c — and nowhere else. `/hyperbuild-revise` and `/hyperbuild-redesign` iterate the designs AT that stop and re-park there; they never open a second one. |

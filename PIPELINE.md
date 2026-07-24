# PIPELINE.md — hyperbuild architecture

hyperbuild is a two-stage, 18-step Claude Code pipeline (steps 1–12 plus half-steps 3.5
and 4.5 = Stage A PLAN; steps 13–16 = Stage B BUILD) with exactly ONE human checkpoint between the
stages. This document is the architecture reference: the principles, every step's
contract, the state layout, both gates, the subagent spawn contract, and the lineage back
to hyperresearch — the deep-research harness this design is copied from.

The entry skill `hyperbuild` is a thin router; each step is its own skill under
`.claude/skills/hyperbuild-N-<name>/` (18 step skills + the router + `hyperbuild-choose`
= 20 skill directories); the 19 subagents live in `.claude/agents/hb-*.md`.

---

## The 9 architecture principles

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

---

## Stage A — PLAN (`/hyperbuild <idea>`)

### Step 1 — Intake (`hyperbuild-1-intake`)

Persists the verbatim idea, mints the run identity, resolves the platform, and seeds all
run state. Run tag = idea slug + 6 random hex chars (e.g. `habit-coach-3f9a2c`).
Platform resolution: stated in the idea wins; otherwise inferred, with the rationale
recorded. Gear resolution: `premier` in the idea prompt opts in; default `standard`.
Seeds TodoWrite with every step (1–16, including 3.5 and 4.5) plus the checkpoint todo —
19 todos. Spawns: none.

**Artifacts:** `runs/<run_tag>/idea.md` (gospel), `runs/<run_tag>/manifest.json`,
`runs/<run_tag>/scaffold.md` (orchestrator's private planning doc, never ships),
`runs/<run_tag>/decisions/platform.md`.

### Step 2 — Market recon (`hyperbuild-2-market-recon`)

Competitor discovery, then deep per-competitor analysis: latest versions, feature sets,
changelogs, pricing, positioning, store ratings. Spawns 1 `hb-competitor-scout`, then
one `hb-competitor-analyst` per competitor in ONE message — 6–8 competitors at
`standard`, 12–15 at `premier`; 5–8 sources per dossier standard, 10–15 premier.

**Artifacts:** `research/competitors/<slug>.md` (one dossier per competitor),
`research/competitor-landscape.md` (feature matrix + positioning map).

### Step 3 — Social mining (`hyperbuild-3-social-mining`)

What real users say: Reddit, HN + forums, app-store reviews, LinkedIn/X. Verbatim quotes
with URLs; pain points, wish lists, and praised features ranked by frequency ×
intensity. Spawns 4 `hb-sentiment-miner` in parallel (one per platform group); 25–40
posts per platform at `standard`, 60–100 at `premier`. Steps 2 and 3 share no inputs
and run as a concurrent pair (2 ∥ 3 — one of the two permitted exceptions to
sequential steps); step 3.5 starts only when BOTH are done.

**Artifacts:** `research/sentiment/reddit.md`, `research/sentiment/hn-forums.md`,
`research/sentiment/appstore-reviews.md`, `research/sentiment/linkedin-x.md`,
`research/sentiment-synthesis.md` (ranked pain points + wish lists).

### Step 3.5 — Research audit (`hyperbuild-3-5-research-audit`)

The ADVERSARIAL RESEARCH AUDIT — runs only after steps 2 AND 3 are both complete.
Spawns 1 `hb-research-critic` to attack `research/competitor-landscape.md` +
`research/sentiment-synthesis.md`: it tries to REFUTE the top pain points and wish-list
items (cherry-picked? one viral thread reposted five times? syndication is not
consensus — derivative copies are clustered and argue with the weight of ONE source),
spot-checks version/feature claims against live sources, and flags anything
unsupported. The critic NEVER edits the synthesis docs itself; the orchestrator patches
them per the CONFIRMED findings — claims are downgraded or annotated, never silently
deleted. Step 4 then builds the PRD on evidence that has survived a refutation attempt.

**Artifacts:** `research/research-audit.md` (findings + resolutions).

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

**Artifacts:** `research/product-spec.md`.

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

Deep research of best practices for the chosen platform/language: app architecture,
project structure + state management, testing strategy, tooling/CI/lint. HARVEST-FIRST:
each researcher searches GitHub for official style guides and high-star best-practices
repos, vets and shallow-clones keepers into `research/harvest/` (logged in
`harvest-log.md` with licenses), then gap-fills with web research. Spawns 4
`hb-stack-researcher` in ONE message (one per topic); 8–12 sources per topic at
`standard`, 15–25 at `premier`. Every topic doc ends in committed "we will do X"
decisions — not surveys.

**Artifacts:** `research/stack/architecture.md`, `research/stack/structure.md`,
`research/stack/testing.md`, `research/stack/tooling-ci.md`, `research/stack-guide.md`
(the merged, committed guide Stage B builds against).

### Step 6 — Design research (`hyperbuild-6-design-research`)

Proposes exactly 3 NAMED design directions suited to this app and audience (e.g. "Soft
Focus", "Swiss Utility", "Neon Playful"), then deep-researches each: reference design
systems, typography, color theory, motion, component patterns, accessibility —
HARVEST-FIRST (public design-system repos and open token sets cloned into
`research/harvest/`, then gap-fill). Spawns 3 `hb-design-researcher` in parallel (one
per direction); 6–10 sources per direction at `standard`, 12–18 at `premier`.

**Artifacts:** `research/design/<direction-slug>.md` (one per direction).

### Step 7 — Design systems (`hyperbuild-7-design-systems`)

Builds the 3 full design systems from their research docs: type scale, color palette
(light + dark), spacing, radii, elevation, and component specs (buttons, cards, inputs,
nav, lists, empty states). Spawns 3 `hb-design-system-author` in parallel.

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

**Artifacts:** `runs/<run_tag>/designs/{a,b,c}/mockups/<screen>.html`,
`runs/<run_tag>/designs/{a,b,c}/screenshots/<screen>.png`,
`runs/<run_tag>/designs/index.html`.

### Step 9 — Skill research (`hyperbuild-9-skill-research`)

Deep research on Claude Code skill authoring: SKILL.md format, frontmatter fields,
progressive disclosure, when to split reference files, what a genuinely rich skill looks
like — HARVEST-FIRST (shallow-clones `zakariaf/Flutter-Skills`, the canonical anatomy
exemplar, plus `anthropics/skills` and vetted community collections into
`research/harvest/skills/`) and mining this harness itself as an exemplar. The guide
ends with binding rules plus a shortlist of harvested skills step 10 can adapt (with
licenses). Spawns 1–2 `hb-stack-researcher`. Steps 8 and 9 share no inputs and run as
a concurrent pair (8 ∥ 9 — the other permitted exception to sequential steps); step 10
needs only 9, and 11 needs 8's gallery only at gate time.

**Artifacts:** `research/skill-authoring-guide.md`.

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
writes the report, then STOPS — the ONE permitted stop in the whole pipeline. Mockup
coverage is judged against the feasibility-classified screen inventory (`full`/`partial`
screens only); missing `screenshots/<screen>.png` renders (e.g. headless Chrome
unavailable) surface as warnings in the report, never hard failures. The final
message to the user summarizes the run (competitor count, top pain points, platform
decision, epic/task counts), says how to open `runs/<run_tag>/designs/index.html`, and
asks for `/hyperbuild-choose a|b|c`. Manifest: `blocked_on: "design-choice"`.

**Artifacts:** `runs/<run_tag>/gates/design-gate-report.md`.

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
├── competitors/<slug>.md          # one dossier per competitor
├── competitor-landscape.md        # feature matrix + positioning map
├── sentiment/<platform>.md        # reddit, hn-forums, appstore-reviews, linkedin-x
├── sentiment-synthesis.md         # ranked pain points + wish lists
├── research-audit.md              # step 3.5's adversarial audit: findings + resolutions
├── product-spec.md                # the PRD, incl. canonical screen inventory
├── stack/<topic>.md               # architecture, structure, testing, tooling-ci
├── stack-guide.md                 # merged committed best-practices guide
├── design/<direction-slug>.md     # one research doc per design direction
├── skill-authoring-guide.md       # Claude Code skill-authoring research
└── harvest/                       # shallow-cloned GitHub repos + harvest-log.md
                                   #   (disposable cache; the distilled artifacts
                                   #   above are truth, this is provenance)
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
│   └── design-choice.md       # written by /hyperbuild-choose
└── gates/
    ├── design-gate-report.md  # step 12
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

---

## Gate 1 — design gate (step 12)

Every check is a disk-verifiable fact, executed mechanically by `hb-gate-verifier` and
recorded with per-check evidence in `runs/<run_tag>/gates/design-gate-report.md`.
Failures are fixed by changing the artifacts (max 3 rounds), NEVER by re-reading a check
charitably.

- [ ] `runs/<run_tag>/idea.md` exists with frontmatter (`run_tag`, `created`, `platform`)
- [ ] `runs/<run_tag>/decisions/platform.md` exists with a stated rationale
- [ ] `research/competitor-landscape.md` exists; competitor dossier count within gear
      range (6–8 standard / 12–15 premier)
- [ ] All 4 `research/sentiment/*.md` files + `research/sentiment-synthesis.md` exist
- [ ] `research/research-audit.md` exists; every CONFIRMED finding shows a resolution
      (downgrade/annotation) in the synthesis docs
- [ ] `research/product-spec.md` exists with MoSCoW feature list AND a named screen
      inventory
- [ ] All 4 `research/stack/*.md` topic docs + `research/stack-guide.md` exist;
      stack-guide contains committed "we will do X" decisions
- [ ] 3 `research/design/<direction-slug>.md` docs exist
- [ ] `research/skill-authoring-guide.md` exists
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
- [ ] `runs/<run_tag>/designs/index.html` exists and references all three designs
- [ ] `epics/00-overview.md` exists; every epic dir has `epic.md` + ≥1 task file; every
      task has valid frontmatter with `status: todo`
- [ ] Coverage complete BOTH directions: every must/should feature id appears in ≥1
      task's `features:` list, and every task's cited features exist
- [ ] Manifest: steps 1–11 (incl. 3.5 and 4.5) all `done`

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

| Knob | standard | premier |
|------|----------|---------|
| Competitors analyzed | 6–8 | 12–15 |
| Sources per competitor dossier | 5–8 | 10–15 |
| Sentiment posts mined per platform | 25–40 | 60–100 |
| Stack research sources per topic | 8–12 | 15–25 |
| Design research sources per direction | 6–10 | 12–18 |
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
| Step 3.5 research audit — `hb-research-critic` refutes the corpus, clusters syndicated copies | hyperresearch's corpus critic / source-independence audit | Research is attacked BEFORE it is consumed: derivative copies count as ONE source, and every headline claim survives a refutation attempt or gets downgraded — never silently deleted. |
| Step 14 wave loop — disjoint-`files:` tasks from any epic run in parallel between sync points | Parallel-within-a-step discipline (all Task calls in ONE message, non-overlapping assignments) | Parallelism lives inside one unit of work with disjoint assignments and a hard gate at its edge; the wave is step 14's unit, the full-suite sync point its gate. |
| Per-wave/per-epic git commits in `app/` (`wave <N>: <task ids> — ...`) + clean-tree ship gate | Pre-stubbed `patch-log.json` provenance ledger | Every change is attributable after the fact: task → commit is the audit trail, epic critics review real diffs, and rollback is `git revert`, not archaeology. |
| Small, categorized parts: the stack-guide's code taxonomy (step 5), one-kind small tasks (step 11), each piece's tests green BEFORE composition (step 14) | Atomic work items + the patcher's small surgical Edit hunks (per-hunk cap) | Small pieces are easier to test, review, and implement with focus; screens compose from already-tested subcomponents instead of being built in one shot. |
| ONE human stop — the design gate | (deliberate divergence) hyperresearch has zero mid-run checkpoints | Taste is the one thing the pipeline shouldn't decide. hyperbuild stops exactly once, for exactly one question — a|b|c — and nowhere else. |

---
name: hyperbuild-6-design-research
description: >
  Step 6 of the hyperbuild pipeline — research area 03-design-system. The
  orchestrator names EXACTLY 3 design directions that are three genuinely
  DIFFERENT VISUAL WORLDS (each committing to its own answer on type
  personality, depth model, shape language, color strategy, density, and
  data/status form), then spawns ONE wave: 3 hb-design-researcher subagents
  (one per direction) plus 2 (standard) / 3 (premier) hb-stack-researcher
  subagents on the SHARED dimensions the platform forces on all three
  directions — what the target framework can actually render, font
  availability and licensing, platform design-language conventions,
  accessibility/contrast constraints. All six-ish docs land in
  research/03-design-system/research/ in the docs/RESEARCH-ARCHIVE.md format
  (claims as H3 assertions + Sources + provenance block). The orchestrator
  registers the area's claims in runs/<run_tag>/temp/claims-03.json, drafts
  author/design-directions.md, then RUNS THE VERIFICATION ENGINE (step 3.5,
  phases V1-V6: one hb-claim-verifier per FACTUAL claim — taste is exempt —
  then a 2/3-seat hb-corpus-critic panel, the author patch, and _INDEX.md),
  and finishes with the correction table that overrides the never-rewritten
  research docs for step 7.
  docs/DESIGN-CRAFT.md is BINDING here: its anti-pattern ban list applies at
  direction level. Step 7 (hb-design-system-author) consumes the direction
  docs one-for-one. Invoked by the hyperbuild router via Skill(); not run
  directly by users.
---

# Step 6 — Design research (area `03-design-system`)

You are executing step 6 (design-research) of the hyperbuild pipeline. Step 5 (stack research) just committed the technical stack; step 7 will turn each of the three direction docs you produce here into a complete design system, and the user will eventually pick exactly ONE of the three — so all three must be shippable.

**Goal:** name EXACTLY 3 design directions, fill research area `research/03-design-system/` with all four phases (`research/`, `verify/`, `critique/`, `author/` + `_INDEX.md`), and leave the run-local letter↔direction mapping at `runs/<run_tag>/designs/directions.md`.

**⚠ CRITICAL: THREE directions, not one, not two, and NO strawmen.** The design gate (step 12) verifies all three designs have all screens. A run with one "real" direction and two throwaways forces the user's hand and defeats the ONE human checkpoint. All three directions must be designs you would defend shipping.

**⚠ CRITICAL: three VISUAL WORLDS, not three palettes.** This step is where the design either becomes distinctive or is doomed. A previous real run named three directions that differed on accent colour and ±8px of corner radius, and every downstream step faithfully built three versions of the same flat list app. Steps 7 and 8 can only express what you commit to here — they cannot rescue a mood board.

**TWO BINDING CONTRACTS.**

- **`docs/DESIGN-CRAFT.md` — the craft bar. Read it before you name anything.** Its §2 anti-pattern list applies AT DIRECTION LEVEL (a banned tell may not be a direction's thesis), and §3.1 (signature element), §3.3 (depth model), §3.4 (shape language), §3.5 (colour with a chosen neutral) and §3.7 (data personality) define the axes you must commit each direction to. Every researcher you spawn reads it too, and step 7's authors are held to it.
- **`docs/RESEARCH-ARCHIVE.md` — the research output contract.** Area `03-design-system` obeys it exactly: the four-phase layout (§2), the file formats (§3), the universal provenance rule (§4), the claim→verify mechanism (§5), the canonical verifier prompt (§6), and the synthesis rule (§7). Violations are DEFECTS: the file is rejected and the agent re-spawned. Cite this file by path in EVERY spawn prompt.

**THE TASTE EXEMPTION — state it, honour it, do not let it swallow the step.** Design carries two kinds of statement and only one is verifiable:

- **FACTUAL** — what a framework can render, what a font licence permits, whether a face is actually obtainable, what a platform guideline or store policy requires, what a WCAG ratio is, which version ships which API, what a named real product actually does on screen. These ARE claims. They enter the claim register, they get an adversarial verifier, and a refuted one may not survive into the synthesis.
- **TASTE** — "this pairing reads editorial", "the direction suits night-shift nurses", "an oversized numeral carries the hierarchy here". These are EXEMPT from verification: no fact-checker settles them, and spawning one wastes a subagent on an argument it cannot win. Taste is disciplined by `docs/DESIGN-CRAFT.md` and by the critics in `critique/`, NOT by `verify/`.

Taste being exempt from verification does NOT exempt it from mechanism: DESIGN-CRAFT's rule stands — every adjective is followed by the move that produces it. An unverifiable claim that is also unbuildable is a defect, just not a `verify/` defect.

## Inputs

Active run: `<run_tag>` from router context. If lost, recover it: the `runs/*/manifest.json` whose `stage` is PLAN and `steps.5` is `done`.

Read these before anything else:
- `docs/DESIGN-CRAFT.md` — the BINDING craft bar. Read it FIRST and in full; §2's ban list constrains which directions you may name at all.
- `docs/RESEARCH-ARCHIVE.md` — the BINDING archive format. Read §2–§7 before you spawn anything.
- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL. Never paraphrase it.
- `runs/<run_tag>/manifest.json` — `gear` (standard | premier), `platform`
- `runs/<run_tag>/decisions/platform.md` — chosen platform + rationale (mobile vs web vs desktop changes which reference systems matter)
- `research/02-engineering/author/stack-guide.md` — the committed stack: the framework whose rendering ceiling the shared dimensions must establish, and the toolchain version that binds it
- `research/product-spec.md` — the PRD: personas, MoSCoW feature list, differentiators, screen inventory
- `research/01-product-and-market/author/sentiment-synthesis.md` — ranked pain points and wish lists (what users hate and love about competitor UX)
- `research/01-product-and-market/author/competitor-landscape.md` — feature matrix + positioning map (which visual territories competitors already occupy) AND the named real products you will draw reference points from
- `research/harvest/harvest-log.md` — if it exists, anything already harvested that a direction can cite as a reference point
- `features/00-index.md` — feature ids, names, screens (skim; the researchers read the full specs)

Create the area skeleton before spawning anything:

```bash
mkdir -p research/03-design-system/{research,verify,critique,author} runs/<run_tag>/temp
```

All four phase dirs, up front — an area with missing phase dirs reads as an area that SKIPPED verification, and design-gate check 22 then reports "missing verify/" instead of the honest "empty verify/", pointing the remedy at the wrong diagnosis. `_INDEX.md` is written last, by engine phase V6.

## Procedure

### Step 6.1 — Name EXACTLY 3 design directions (orchestrator work — do NOT delegate)

This naming decision is yours. The researchers deep-research a direction; they do not invent one.

Derive the directions from the evidence, not from taste:
- **Personas + audience** (PRD): who is this for, and what register do they expect? A tool for nurses on night shift wants different energy than a tool for teenage sneaker resellers.
- **Sentiment pain points**: if users call competitors "cluttered" or "childish", at least one direction must directly answer that complaint.
- **Competitor positioning**: read the positioning map and claim visual territory competitors have left open. Do not produce a fourth clone of the category leader's look.
- **Platform**: the direction must be plausible on the chosen platform's conventions (iOS/Material/web).

**Naming convention — MANDATORY.** Each direction gets a two-word evocative name in the style "Soft Focus", "Swiss Utility", "Neon Playful", "Quiet Ledger", "Warm Terminal". The name is a compressed design thesis, not decoration. BANNED names: anything generic that could describe any app — "Modern Clean", "Minimalist", "Simple UI", "Material Design". If the name would fit a banking app and a game equally well, rename it.

**AXES OF VISUAL LANGUAGE — MANDATORY.** A mood is not a direction. Each direction must commit, in writing, to its own answer on ALL SIX axes below. These six are the mechanics that produce three visual WORLDS instead of three palettes on one layout, and they are what steps 7 and 8 actually build from.

| Axis | The question the direction must answer | Example answers (illustrative — do not reuse verbatim) |
|------|----------------------------------------|--------------------------------------------------------|
| Type personality | Which display + body pairing, and what does the pairing SAY? (DESIGN-CRAFT §3.2) | editorial serif display + humanist body / condensed caps display + rounded body / oversized numerals in a data face + geometric sans |
| Depth model | How does elevation read — pick ONE (DESIGN-CRAFT §3.3) | layered tinted shadow / borderless tinted surfaces / crisp offset with solid border |
| Shape language | The radius rhythm + the ONE distinctive move (DESIGN-CRAFT §3.4) | asymmetric-corner containers / clip-path notch / capsule + masked arc / hard 2px edges with a diagonal cut |
| Color strategy | Where does colour come from, and what is it FOR? (DESIGN-CRAFT §3.5) | duotone on a hue-biased neutral / single-hue tonal ramp carrying hierarchy / high-chroma semantic field / colour as temperature over time |
| Density | Rows on screen, gutter width, how much air, where hierarchy breaks the grid | 4 tall rows under a hero numeral / 9 compact ledger rows / medium rows in grouped bands with a wide gutter |
| Data & status form | How quantity, progress and status are DRAWN (DESIGN-CRAFT §3.7) | radial ring + segmented bar / column strip + shape-coded pill / timeline rail + dot cluster / fill-level metaphor |

Rules:
- Every direction answers all SIX. Write the answers down: they go into `directions.md`, into every researcher's spawn prompt, and step 7 authors are bound by them.
- Across the three, **no two directions may share an answer on more than ONE axis** — at least 5 of 6 must be pairwise different. Two directions with the same depth model AND the same data form is a failed selection, whatever their palettes do.
- "Status is a coloured pill or coloured text" may be the data & status answer for AT MOST one direction, and traffic-light colour alone is never an answer (DESIGN-CRAFT §2.10). A countdown app whose only quantitative form is a number in text has failed this axis.

**THE REDO RULE — read your own briefs back as a stranger.** If all three could honestly be described as "a clean minimal list app", or if the only difference a user would PERCEIVE is the accent colour, the selection FAILED: REDO step 6.1 before spawning anyone. Ambition is the point — at least one of the three must make a move a cautious designer would call risky (an oversized numeral, a full-bleed field of colour, type that dominates the screen, a container that is not a rounded rectangle, a status channel that is shape rather than colour).

**NO DIRECTION MAY *BE* AN AI-DESIGN CLICHÉ.** `docs/DESIGN-CRAFT.md` §2 binds at direction level: a banned tell cannot be a direction's thesis. The first real run produced exactly three of these, so name and refuse them explicitly:
1. **Cream + serif display + terracotta accent** ("warm / artisanal / homely") — paper background, Georgia-ish headline, clay accent. BANNED as a direction.
2. **Mono or near-greyscale + one accent, utility register** ("quiet / restrained / ledger") — greyscale, 2–4px radii, no elevation, a low type ceiling. Restraint IS legitimate; this execution of it is banned. A restrained direction must pay for its refusal of depth somewhere visible — scale, tone, texture, or a signature device — and must say WHERE in its brief.
3. **Traffic-light status as the whole colour story** ("signal / urgency / alert") — red/amber/green chips on grey rows. Status colour is allowed; it is never the palette and never the design idea.

Also banned at direction level (DESIGN-CRAFT §2): purple→blue gradient hero, near-black + one acid pop, Inter/Space Grotesk as the reflexive face, one uniform border-radius, and flat-white-card-plus-1px-hairline as the container vocabulary.

**Per-direction brief — write these four blocks, in this order:**

1. **Thesis** — 2–3 sentences: what it is, who it serves best, what it deliberately sacrifices.
2. **Axis commitments** — the six answers, one line each. Concrete, not adjectival.
3. **Signature element candidate** — DESIGN-CRAFT §3.1: ONE named, memorable recurring device that belongs to THIS app and no other ("the tide bar", "the notch card", "the shelf-life rail"), traced to the app's subject in one sentence. A CANDIDATE, not a spec — the researcher validates it and the step 7 author specs it. A logo is not one; an accent colour is not one; "rounded corners" is not one.
4. **Reference points (≥2)** — REAL, NAMED products or design systems, each with what SPECIFICALLY is borrowed: a shape treatment, a colour behaviour, a type pairing, a data form, a density decision. "Modern fintech apps" and "clean iOS apps" are not reference points. Draw them from `research/01-product-and-market/author/competitor-landscape.md`, anything already in `research/harvest/harvest-log.md`, and your own knowledge of shipped products — the researcher VERIFIES each one this run and replaces any it cannot fetch, so name real things.

Slug = kebab-case of the name (e.g. "Soft Focus" → `soft-focus`).

### Step 6.2 — Write the run-local direction mapping

Write `runs/<run_tag>/designs/directions.md` (create `runs/<run_tag>/designs/` if needed). This file is the RUN-LOCAL letter↔direction mapping — letters, names, slugs, research-doc paths, the axis grid and the briefs. Steps 7, 8, 12, and `/hyperbuild-choose` all key off it, because letters are a property of THIS run, not of the portable archive. The researched rationale lives elsewhere: `research/03-design-system/author/design-directions.md` (steps 6.7–6.9), which is the archive's synthesis and carries the verification corrections. Do not duplicate corrections here.

The axis grid and briefs below are pasted verbatim into the step 6.3 spawn prompts and read again by step 7's design-system authors — write them as instructions, not as marketing. Format:

```markdown
# Design directions — <run_tag>

| Letter | Name | Slug | Research doc |
|--------|------|------|--------------|
| a | Soft Focus | soft-focus | research/03-design-system/research/soft-focus.md |
| b | Swiss Utility | swiss-utility | research/03-design-system/research/swiss-utility.md |
| c | Neon Playful | neon-playful | research/03-design-system/research/neon-playful.md |

Area synthesis (corrections binding on step 7): research/03-design-system/author/design-directions.md
Area index: research/03-design-system/_INDEX.md

## Axis grid

| Axis | a — <Name> | b — <Name> | c — <Name> |
|------|------------|------------|------------|
| Type personality | <answer> | <answer> | <answer> |
| Depth model | <answer> | <answer> | <answer> |
| Shape language | <answer> | <answer> | <answer> |
| Color strategy | <answer> | <answer> | <answer> |
| Density | <answer> | <answer> | <answer> |
| Data & status form | <answer> | <answer> | <answer> |

Pairwise distinctness: a↔b differ on <n>/6, a↔c on <n>/6, b↔c on <n>/6 — all must be ≥5.
Redo rule: <one line stating why these three could NOT all be called "a clean minimal list app">.

## Briefs

### a — Soft Focus
**Thesis.** <2–3 sentences: what it is, who it serves best, what it deliberately sacrifices.>
**Signature element candidate.** <Named device> — <one sentence tracing it to this app's subject.>
**Reference points.** <Real product or system> — <what specifically is borrowed>. <Real product or system> — <what specifically is borrowed>.
**Rejects.** <The DESIGN-CRAFT §2 cliché(s) this direction is nearest to and how it stays clear, plus the competitor look it refuses.>

### b — Swiss Utility
<same four blocks>

### c — <Name>
<same four blocks>
```

### Step 6.3 — Pick the SHARED dimensions, then spawn the whole wave in ONE message

**6.3a — Pick the shared dimensions (orchestrator work).** The three direction researchers each see one world; nobody sees the constraints the PLATFORM imposes on all three. Those constraints are where design research fabricates: a blur the framework cannot draw, a foundry face nobody may embed, a guideline that does not say what everyone repeats. So the wave also carries **2 shared dimension docs (standard) / 3 (premier)**, chosen IN ORDER from this fixed menu (fixed slugs — `_INDEX.md` and every later reader depend on them):

| # | Dimension slug | What it must settle | Gear |
|---|---|---|---|
| 1 | `framework-render-capability` | What the committed framework/renderer can ACTUALLY draw at the version the toolchain will install: gradients, blur/backdrop effects, clip-paths and non-rectangular containers, the shadow/elevation model, masks, custom paint, variable fonts, per-platform gaps, and the cost of each. Which of the three directions' shape and depth commitments are buildable, and which need a substitute. | ALWAYS |
| 2 | `type-availability-and-licensing` | Which faces are actually obtainable and on what terms: system stacks per platform, OFL/Google-Fonts availability, foundry licence classes (desktop vs app-embedding vs webfont), what embedding in a shipped binary requires, file weight, variable-font support, and numeral features (tabular/oldstyle) the data forms depend on. | ALWAYS |
| 3 | `platform-design-conventions` | What the platform's own design language REQUIRES vs merely suggests: HIG/Material/web conventions, navigation and hierarchy patterns, safe areas, dynamic type, and what review actually rejects — quoted from the guideline text, not from a blog summary of it. | premier default |
| 4 | `accessibility-and-contrast-constraints` | WCAG 2.2 AA/AAA numbers that bind these palettes, contrast maths for the specific colour strategies in play (tonal ramps and low-contrast neutrals are the hazard), platform accessibility APIs, tap-target minimums, reduced-motion and reduced-transparency behaviour. | premier alternative to #3 |

Selection rule: dimensions 1 and 2 ALWAYS run. `standard` stops there. `premier` adds ONE more — **#4** when the PRD's personas or the sentiment synthesis make accessibility load-bearing, or when any direction's colour strategy leans on low contrast or a tonal ramp; otherwise **#3**. Record the choice and the reason in `runs/<run_tag>/temp/orchestrator-notes.md`.

**THE PREMISE TRAP (RESEARCH-ARCHIVE §6).** Do NOT state the framework version, the renderer, or a font's licence as fact in any spawn prompt — a fact stated in the prompt is the one claim nobody checks. Hand the framework dimension the QUESTION: "verify the installed/pinned framework version from `research/02-engineering/author/stack-guide.md` and the toolchain FIRST, then research what THAT version renders." Same for fonts: the licence is a research output, never a prompt premise.

**6.3b — Spawn all researchers in ONE message — true parallel execution.** 3 `hb-design-researcher` (one per direction, zero overlap — a researcher researches ONLY its assigned direction) + 2–3 `hb-stack-researcher` (one per shared dimension). Source targets from the router's scale-profile table: **directions 6–10 sources standard / 12–18 premier; shared dimensions 8–12 standard / 15–25 premier** — substitute the resolved range into each prompt.

*(A `/hyperbuild-redesign` round re-enters the step here and spawns ONLY the replacement direction researchers. The shared dimension docs, and the `verify/` files behind them, are platform facts and stay as they are unless the platform itself changed — re-verify any older than 90 days per RESEARCH-ARCHIVE §8 instead of re-researching them.)*

**Direction spawn template (fill one per direction):**

```
subagent_type: hb-design-researcher
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 6 (design research) of the hyperbuild
  pipeline, producing one `research/` file of research area
  03-design-system. Steps 2-4 produced competitor research,
  user-sentiment research, and the PRD; the orchestrator has just named
  3 design directions and you own exactly ONE of them. Sibling agents
  are researching the other two directions and the SHARED platform
  dimensions (what the framework can render, font availability and
  licensing) in parallel — do not cover their ground. After you return,
  the orchestrator extracts your FACTUAL claims and spawns one
  adversarial fact-checker per claim, then writes
  research/03-design-system/author/design-directions.md; step 7 spawns
  an hb-design-system-author that reads YOUR doc plus that synthesis to
  author this direction's full design system (design-system.md +
  tokens.css), and step 8 builds HTML mockups from it. You research and
  commit; you do NOT write the design system, do NOT write CSS tokens,
  and do NOT research the other two directions.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - area: 03-design-system
  - direction_letter: <a|b|c>
  - direction_name: "<Name>"
  - direction_slug: <slug>
  - direction_brief: "<the thesis block from directions.md, verbatim>"
  - direction_axes: <the six axis commitments from the axis grid, verbatim,
    one line each: type personality / depth model / shape language /
    color strategy / density / data & status form>
  - signature_candidate: "<the named signature-element candidate + its
    one-sentence trace to the app's subject, verbatim>"
  - reference_points: <the >=2 named real products/systems from the brief,
    each with what specifically is borrowed>
  - direction_rejects: "<the Rejects line from the brief, verbatim>"
  - source_target: <6-10 | 12-18> curated sources (gear: <standard|premier>)
  - output_path: research/03-design-system/research/<direction-slug>.md

  READ FIRST (context files, in this order):
  - docs/DESIGN-CRAFT.md — the BINDING craft bar. Read it in full before
    you research anything. Its §2 ban list applies to THIS DIRECTION as a
    whole, not only to individual mockups.
  - docs/RESEARCH-ARCHIVE.md — the BINDING output format: §3.1 (the file
    format, claims as H3 assertions), §4 (the provenance rule), §5 (what
    makes a claim load-bearing).
  - runs/<run_tag>/idea.md
  - research/product-spec.md — personas, differentiators, screen inventory
  - research/01-product-and-market/author/sentiment-synthesis.md — UX pain
    points your direction must answer
  - research/01-product-and-market/author/competitor-landscape.md — visual
    territory already occupied
  - runs/<run_tag>/decisions/platform.md — platform conventions that bind you
  - research/02-engineering/author/stack-guide.md — the committed stack.
    Do NOT assume what it renders; a sibling dimension establishes that.
  - features/00-index.md — the features your components must eventually serve

  FORMAT (BINDING — docs/RESEARCH-ARCHIVE.md):
  - Frontmatter: run_tag, created: <YYYY-MM-DD>, area: 03-design-system,
    dimension: <direction-slug>, phase: research, direction: "<Name>",
    slug: <direction-slug>, letter: <a|b|c>.
  - Then the provenance line: `> Phase: **research** · Agent <your agent
    id> · Run <run_tag>`.
  - Then `## Summary`: one dense paragraph, followed by your FACTUAL
    claims as H3 headings. EVERY H3 UNDER `## Summary` IS A COMPLETE
    ASSERTION — subject, verb, something that can be proven wrong — with
    `*Confidence: high|medium|low[, **LOAD-BEARING**]*`, the evidence
    (versions, dates, exact names, numbers), and its source URLs. A topic
    label ("Typography", "Colour") is a DEFECT. At least 3 (standard) /
    5 (premier) such claims.
  - THE TASTE EXEMPTION: only FACTUAL statements belong under `## Summary`
    as claims — the font exists and its licence permits app embedding,
    the framework renders this effect at this version, this guideline
    requires this number, this named product actually does this on
    screen. Aesthetic judgement ("this pairing reads editorial", "this
    suits the audience") is EXEMPT from the claim register and stays in
    the craft sections below, where it must still name its MECHANISM.
    Do not dress taste as a claim to pad the register, and do not hide a
    checkable fact in a craft section to dodge verification.
  - Then the craft sections, in the order your agent definition's output
    contract gives: ## Direction thesis, ## Visual language,
    ## Signature element, ## Reference points,
    ## What this direction rejects, ## Reference design systems,
    ## Typography, ## Color, ## Motion, ## Component patterns,
    ## Accessibility, ## Known failure modes, ## Commitments, ## Sources.
  - END THE FILE with the provenance block (RESEARCH-ARCHIVE §4): a
    <details><summary>The prompt that produced this</summary> block
    containing THIS ENTIRE PROMPT, verbatim, inside a fenced code block.
    No summary, no paraphrase. A file without its prompt block is
    INCOMPLETE and gets re-spawned.

  RESEARCH REQUIREMENTS:
  - HARVEST-FIRST: before blank-page web research, search GitHub for
    public design-system repos and open token sets that embody this
    direction (Material, HIG resources, published open-source systems).
    Vet candidates (meaningful stars, commits within ~12-18 months,
    authoritative origin); log every candidate — kept or rejected, with
    reason — in research/harvest/harvest-log.md (repo URL, stars,
    last-commit date, license, verdict); shallow-clone keepers via Bash:
    git clone --depth 1 <url> research/harvest/design/<repo>/. License
    rule: MIT/Apache/BSD/CC — adapt with attribution; GPL/AGPL/
    unlicensed — learn and cite, never copy. Then gap-fill with web
    research.
  - NAMED SOURCE (pre-vetted; DISCOVER still looks for more):
    https://github.com/nextlevelbuilder/ui-ux-pro-max-skill (MIT) —
    enter it in the harvest-log with verdict CHERRY-PICK: its
    three-layer token architecture (primitive → semantic → component
    CSS variables — step 7's tokens.css follows this structure unless
    your ## Commitments argue otherwise) and its token-validator script
    pattern are valuable; its slides/banner/brand skills are out of
    scope; overall quality is mixed — vet each piece before borrowing.
  - VERIFY THE REFERENCE POINTS you were handed: fetch each one this run.
    Any you cannot verify, REPLACE with a real one you did fetch and say
    so in the doc. Then ADD more, so the doc names at least 4 (standard)
    / 6 (premier) reference points total.
  - Cover ALL of: reference design systems (2-4 named systems or apps that
    embody this direction, with what to borrow from each), typography
    (a display face and a body face from DIFFERENT families, both meeting
    DESIGN-CRAFT §3.2's availability rule, plus the scale ratio, weights
    and tracking), color theory
    (palette strategy, light AND dark viability, WCAG AA contrast),
    motion (posture, durations, what animates and what never does),
    component patterns (buttons, cards, inputs, nav, lists, empty states).
  - Font, licence, framework-capability and guideline statements are
    FACTUAL: each needs a primary source (the foundry's or Google Fonts'
    licence page, the framework's own API docs, the guideline text
    itself) and each belongs under `## Summary` as an H3 claim, because
    a fact-checker will be spawned against it.
  - At least ONE adversarial search for this direction's known failure
    modes (e.g. "<style> accessibility problems", "why designers abandoned
    <style>", "<reference system> criticism"). Record what you found and
    how the direction avoids it.
  - Prioritize sources from the last 18 months; any version or feature
    claim must cite a dated source.
  - `## Commitments`: 5-10 "we will do X" decisions specific enough that
    the step 7 author never has to guess.
  - `## Sources`: every source as URL + access date + one-line takeaway.

  FOUR SECTIONS THAT CARRY THIS DIRECTION'S IDENTITY (all required, all
  binding on step 7 — see your agent definition's output contract for the
  full ordering):
  - ## Visual language — the SIX axis decisions above, each researched,
    sharpened and made concrete: type personality (named display + body
    faces and what the pairing says), depth model (ONE of DESIGN-CRAFT
    §3.3's three, applied everywhere), shape language (radius rhythm +
    the ONE distinctive move), color strategy (where colour comes from,
    the hue-biased neutral recipe, what the accent is FOR and how scarce
    it is), density (rows on screen, gutter, where hierarchy breaks the
    grid), data & status form (which drawn forms from DESIGN-CRAFT §3.7).
    You may sharpen an axis answer; you may NOT swap it for a different
    one or converge it toward the other two directions. If research shows
    an axis answer is unworkable, say so explicitly and propose the
    nearest workable alternative that keeps the direction distinct.
  - ## Signature element — take the candidate you were handed and make it
    specifiable: name it, trace it to the app's subject, describe the
    construction (geometry, gradient/clip-path/mask approach, how it
    scales hero -> compact), and name AT LEAST 3 screens from the PRD's
    screen inventory where it appears plus where it must NEVER appear. If
    the candidate does not survive research, replace it with a better one
    and justify the swap in one sentence.
  - ## Reference points — the verified real products/systems, each with
    what SPECIFICALLY is borrowed (a shape treatment, a colour behaviour,
    a type pairing, a data form, a density decision) and one line on
    "what would date this look" so step 7 steers clear of it.
  - ## What this direction rejects — the DESIGN-CRAFT §2 clichés this
    direction sits nearest to and the mechanism that keeps it clear, the
    competitor look it refuses, and what it deliberately sacrifices.

  PROHIBITIONS: Do NOT write design tokens or CSS. Do NOT survey all three
  directions — yours is assigned. Do NOT pad the source list with undated
  listicles. Do NOT propose, and do NOT let your direction drift into, any
  DESIGN-CRAFT §2 banned tell — especially the three this pipeline has
  already shipped: cream + serif display + terracotta accent; near-
  greyscale + one accent "quiet utility"; traffic-light red/amber/green as
  the colour story. Do NOT hand back vague adjectives: "warm and friendly",
  "clean and modern", "bold and confident" are NOT design decisions. Every
  adjective must be followed by the MECHANISM that produces it — the named
  face, the depth model, the shape move, the colour recipe.
```

**Shared-dimension spawn template (fill one per selected dimension):**

```
subagent_type: hb-stack-researcher
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 6 (design research) of the hyperbuild
  pipeline, producing one SHARED dimension of research area
  03-design-system. Three sibling agents are each deep-researching ONE
  named design direction (a visual world) in parallel; you research the
  constraint the PLATFORM imposes on ALL THREE, so none of them commits
  to something that cannot be built, licensed, or shipped. After you
  return, the orchestrator extracts your claims and spawns one
  adversarial fact-checker per load-bearing claim; step 7 authors three
  design systems inside the ceiling you establish. You do NOT design, do
  NOT pick a direction, and do NOT write tokens or CSS.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - area: 03-design-system
  - researcher_id: <framework-render-capability |
    type-availability-and-licensing | platform-design-conventions |
    accessibility-and-contrast-constraints>
  - topic: <the "What it must settle" cell from the shared-dimension
    table, verbatim>
  - the_three_directions: <for each letter: name + the two axis answers
    this dimension bears on — e.g. for framework-render-capability, the
    shape language and depth model of all three; for
    type-availability-and-licensing, the type personality of all three.
    They are what your findings must adjudicate; you research the
    platform, not the taste.>
  - source_target: <8-12 | 15-25> sources (gear: <standard|premier>)
  - output_path: research/03-design-system/research/<researcher_id>.md

  READ FIRST (context files, in this order):
  - docs/RESEARCH-ARCHIVE.md — the BINDING output format: §3.1, §4, §5.
  - docs/DESIGN-CRAFT.md — §3.2 (the font availability rule), §3.3
    (depth models), §3.4 (shape language), §3.7 (data forms) — the
    vocabulary your findings must speak.
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/decisions/platform.md
  - research/02-engineering/author/stack-guide.md
  - research/product-spec.md — personas and the screen inventory
  - runs/<run_tag>/designs/directions.md — the axis grid you are
    adjudicating

  VERIFY THE ENVIRONMENT FIRST (do not take it from this prompt): the
  framework and its version are a QUESTION, not a premise. Establish
  which version the toolchain will actually install — from the
  stack-guide, the lockfile/pin it names, and the vendor's own release
  channel — and research what THAT version does. A capability that
  landed in a version this project will not install is a REFUTED
  capability. State the version you established, with its source, as
  your first claim.

  FORMAT (BINDING — docs/RESEARCH-ARCHIVE.md §3.1): frontmatter
  (run_tag, created, area: 03-design-system, dimension: <researcher_id>,
  phase: research), the `> Phase: **research** · Agent <id> · Run
  <run_tag>` line, `## Summary` (one dense paragraph, then your claims
  as H3 COMPLETE ASSERTIONS — each with *Confidence: …*, evidence with
  exact versions/names/numbers/dates, and source URLs; a topic label is
  a DEFECT), `## Recommendations` ("we will do X" / "never do Y", each
  tied to THIS app's constraints), `## Sources` (URL + access date +
  one-line takeaway). At least 4 claims (standard) / 6 (premier), and
  mark `**LOAD-BEARING**` every claim a design decision would rest on.
  END THE FILE with the provenance block
  (RESEARCH-ARCHIVE §4) containing THIS ENTIRE PROMPT verbatim inside a
  fenced code block.

  RESEARCH REQUIREMENTS:
  - PRIMARY SOURCES ONLY for the load-bearing facts: the framework's own
    API reference and release notes; the foundry's or Google Fonts'
    actual licence text (SIL OFL, the EULA page) — not a summary of it;
    the platform's own human-interface / material guideline page; the
    W3C WCAG text itself. A blog post explaining a guideline is not the
    guideline.
  - HARVEST-FIRST where it applies: log any repo you clone in
    research/harvest/harvest-log.md (URL, stars, last-commit, license,
    verdict) and shallow-clone keepers with
    `git clone --depth 1 <url> research/harvest/design/<repo>/`.
  - ADJUDICATE, do not survey: for EACH of the three directions, say
    plainly which of its commitments this dimension permits, which it
    permits only at a named cost, and which it forbids — and for
    anything forbidden, name the nearest buildable substitute that keeps
    that direction distinct from its siblings.
  - Run at least one adversarial search against the received wisdom in
    your topic (e.g. "<effect> performance problems <framework>",
    "<font licence> app embedding not allowed", "<guideline> myth").
  - Prioritize sources from the last 18 months; every version, licence,
    price or policy claim cites a dated source.

  PROHIBITIONS: Do NOT rank or choose among the three directions — that
  is the user's call at the design gate. Do NOT write design tokens,
  CSS, or a design system. Do NOT restate the axis grid back as
  findings. Do NOT assert a version, licence, or guideline requirement
  you did not fetch this run.
```

### Step 6.4 — Wait discipline

**CRITICAL: never emit bare text while the wave is running** — a text-only response ends the turn and kills the pipeline. While waiting, append thoughts to `runs/<run_tag>/temp/orchestrator-notes.md`: which direction you predict the user picks, what the step 7 authors will need emphasized, screens likely to stress each direction, which axis commitments you expect the framework dimension to forbid, and the axis-by-axis distinctness re-check you will run in 6.5 (which pairs are closest, which axis you expect to converge). One progress check per minute max.

### Step 6.5 — Validate returns

When all researchers return:
1. Confirm all files exist: 3 × `research/03-design-system/research/<direction-slug>.md` and 2–3 × `research/03-design-system/research/<dimension>.md`.
2. **Archive-format check on EVERY file** (RESEARCH-ARCHIVE §3.1, §4): frontmatter present with `area: 03-design-system`, `dimension`, `phase: research`; a `## Summary` whose H3s are COMPLETE ASSERTIONS, not topic labels; `## Sources` with URL + access date + takeaway; and the closing provenance block containing the full prompt verbatim. **A file missing its provenance block is INCOMPLETE — re-spawn that agent.** A `## Summary` of topic labels is a DEFECT — re-spawn with two of the offending headings quoted and one rewritten as an assertion to show the shape.
3. Source counts meet the gear target (directions 6 minimum standard / 12 premier; shared dimensions 8 / 15).
4. Each direction doc has a non-empty `## Commitments` section and covers all five required craft areas plus the adversarial findings.
5. **Identity sections present and substantive** — each direction doc has `## Visual language` (all six axes answered concretely), `## Signature element` (named + constructed + ≥3 named screens), `## Reference points` (≥4 standard / ≥6 premier, each with what is borrowed), and `## What this direction rejects`. A section that restates the brief without adding a mechanism counts as missing.
6. **Cross-direction distinctness — read the three `## Visual language` sections side by side.** Re-check the pairwise rule: no two directions share an answer on more than ONE axis. If a researcher sharpened an axis into convergence with a sibling, re-spawn THAT researcher with the sibling's conflicting answer quoted and its own axis commitment restated as binding.
7. **Cliché sweep** — read the three docs against `docs/DESIGN-CRAFT.md` §2 by name. If any direction has become cream+serif+terracotta, near-greyscale+one-accent utility, or traffic-light-status-as-palette, re-spawn that researcher with the ban quoted. Do not patch a cliché from the orchestrator seat — the direction has to be re-argued.
8. **Claim yield** — each direction doc carries ≥3 factual H3 claims (≥5 premier); each shared dimension doc ≥4 (≥6 premier). A doc below the floor either hid its facts in prose or has nothing checkable: re-spawn it ONCE naming the floor.
9. If a researcher failed or its doc is missing a required section, re-spawn that ONE researcher ONCE with the gap named explicitly. If it fails twice, log the gap in `runs/<run_tag>/temp/orchestrator-notes.md` and proceed — step 7's author will be told which section is thin, and `_INDEX.md` records the gap. Never proceed with fewer than 3 direction docs on disk.
### Step 6.6 — Register the claims (`runs/<run_tag>/temp/claims-03.json`)

RESEARCH-ARCHIVE §5 steps 1–2, applied to area 03, in the registry schema the engine reads (`hyperbuild-3-5-research-audit` phase V1). Read EVERY H3 under `## Summary` in every `research/03-design-system/research/*.md` file — each is one candidate claim — and append it to the registry.

**THE AREA-03 FILTER — apply the TASTE EXEMPTION as you register:**
- **Registered (FACTUAL):** anything with a version, price, licence, policy, guideline requirement, WCAG number, API/effect/property name, font availability or foundry term, or a statement about what a named real product does. Claims marked `**LOAD-BEARING**` go first.
- **NOT registered (TASTE):** aesthetic judgement, audience fit, the direction thesis, "what the pairing says", density feel, which form is more elegant. No primary source settles these, and a verifier handed one produces a confident non-answer that then looks like evidence. Taste is disciplined by `docs/DESIGN-CRAFT.md` and by the critique panel — never by a fact-checker. Register such a claim with `"kind": "taste"` and `"selected": false` so `_INDEX.md` can state honestly that it was deliberately not checked, and never spawn a verifier for it.
- Borderline test: **could a primary source settle it?** If the answer names a document — an API reference, a licence file, a guideline page, a store policy, a product's live UI — it is factual. If the answer is "a designer would say", it is taste.
- **Premise sweep (ARCHIVE §6):** register every environment fact any spawn prompt asserted — the framework version, the renderer, a "stable is X" — with `"dimension": "premise"` and `"load_bearing": true`. They lead the verify surface.

Registry entries use the engine's schema (`id`, `dimension`, `source_file`, `claim`, `claim_slug`, `detail`, `sources`, `confidence`, `load_bearing`, `selected`, `verdict`, `correction`) plus the area-03 field `"kind": "factual" | "taste"`:

```json
{
  "run_tag": "<run_tag>", "area": "03-design-system",
  "gear": "standard", "created": "<YYYY-MM-DD>",
  "claims": [{
    "id": "C-01",
    "dimension": "framework-render-capability",
    "source_file": "research/03-design-system/research/framework-render-capability.md",
    "claim": "<the H3 heading under ## Summary, verbatim>",
    "claim_slug": "<computed, never eyeballed — see the engine's V2>",
    "detail": "<the claim's body, verbatim>",
    "sources": ["https://…"],
    "confidence": "high",
    "load_bearing": true,
    "kind": "factual",
    "selected": true,
    "verdict": null,
    "correction": null
  }]
}
```

Ranking for the verify surface (the engine's V2 keeps 3–5 per dimension standard / 6–10 premier): (1) premises, (2) framework capabilities a direction's shape or depth commitment rests on, (3) font availability and licence terms, (4) guideline / store / WCAG requirements stated as binding, (5) claims about what a named reference product does, (6) any dated version or price.

### Step 6.7 — Draft `author/design-directions.md` BEFORE verification

The engine PATCHES author docs (phase V5); it does not write them. So the synthesis must exist first, as an honest pre-verification draft — the engine then corrects it in place, which is what makes the corrections visible rather than invisible. Write `research/03-design-system/author/design-directions.md`:

```markdown
---
run_tag: <run_tag>
created: <YYYY-MM-DD>
area: 03-design-system
phase: author
---
# Design directions — the researched brief

> Phase: **author** · Orchestrator (step 6, Skill `hyperbuild-6-design-research`) · Run `<run_tag>`

## How to read this
The three `research/<direction-slug>.md` docs are UNVERIFIED by construction and are NEVER
rewritten when a fact-check refutes them. THIS FILE CARRIES THE CORRECTIONS AND OVERRIDES
THEM. Step 7's design-system authors read their own direction doc for the craft and this
file for what survived. Letters (a|b|c) are run-local: see runs/<run_tag>/designs/directions.md.
TASTE WAS DELIBERATELY NOT FACT-CHECKED (see _INDEX.md) — it is disciplined by
docs/DESIGN-CRAFT.md and by critique/, not by verify/.

## The three directions
<Per direction: name, slug, thesis, the six axis answers as researched, the signature
element as specified, the verified reference points, what it rejects. Two to four tight
paragraphs each — the researched rationale, not a re-paste of the brief.>

## Platform ceiling (from the shared dimensions)
<What the framework renders and at what cost; which faces are obtainable and under which
licence; the guideline / accessibility numbers that bind all three directions.>

## Binding on step 7
<The decisions the design-system authors may not relitigate: the axis grid, the signature
elements, the surviving font choices, the platform ceiling.>
```

Close it with the provenance block (§4). The orchestrator wrote this file, so the block carries the authoring brief it followed: quote this `### Step 6.7` section verbatim inside the fenced block (FOUR-backtick outer fence — it contains code fences) and add the line `Authored by the step 6 orchestrator (Skill hyperbuild-6-design-research), not a subagent.`

### Step 6.8 — Run the VERIFICATION ENGINE over area 03

**Do NOT re-derive the procedure.** Read `.claude/skills/hyperbuild-3-5-research-audit/SKILL.md`, section **THE VERIFICATION ENGINE**, bind the parameter block below, and run phases **V1 → V6 unchanged** — including the canonical `hb-claim-verifier` spawn prompt (ARCHIVE §6, used verbatim), the batching rule (≤15 Task calls per message), the verdict fold-back into `CLAIMS`, the V5 patch semantics, and V6's `_INDEX.md`.

| Engine parameter | Area 03 binding |
|---|---|
| `AREA` | `03-design-system` |
| `AREA_TITLE` | `Design system — three directions + the platform ceiling` |
| `CLAIMS` | `runs/<run_tag>/temp/claims-03.json` |
| `RESEARCH_DIR` | `research/03-design-system/research/` (`<direction-slug>.md` × 3, `<shared-dimension>.md` × 2–3) |
| `VERIFY_DIR` | `research/03-design-system/verify/` |
| `CRITIQUE_DIR` | `research/03-design-system/critique/` |
| `AUTHOR_DOCS` | `research/03-design-system/author/design-directions.md` |
| `INDEX` | `research/03-design-system/_INDEX.md` |
| `PANEL` | completeness → `hb-corpus-critic` → `critique/completeness-critic.md` · skeptic → `hb-corpus-critic` → `critique/distinctness-and-buildability-critic.md` · premier only: domain → `hb-corpus-critic` → `critique/domain-accessibility-critic.md` |
| `VERIFY_BUDGET` | ≤25 standard / ≤60 premier |
| `CONSUMER` | step 7 (the three `hb-design-system-author` spawns) |

**Area-03 additions to the engine — three, and only three:**

1. **The verify surface is FACTUAL claims only.** Never select a `"kind": "taste"` entry, whatever its `load_bearing` flag says. Add ONE line to each filled §6 verifier prompt, after the failure-mode list: `This claim was selected as FACTUAL. If you conclude it is not checkable against any primary source — that it is an aesthetic judgement rather than a fact — return UNVERIFIABLE and say so in one line; do not manufacture agreement.`
2. **Design-specific primary sources** to name in each verifier's source list: the framework's own API reference and release notes for the exact version; the foundry's or Google Fonts' licence text (the SIL OFL file, the EULA page) rather than a summary of it; the platform's own HIG / Material / WAI-ARIA page; the W3C WCAG success-criterion text; and the reference product's live UI or its own published design-system site.
3. **Area-03 lens briefs for the V4 panel** (the panel table's brief column, replaced — the seats, agent and file count are the engine's):
   - `completeness-critic.md` — which axis, screen, or platform question did NOBODY research? What did every direction assume without checking? Where is the corpus silent on something step 7 must decide (a token value, an empty state, a dark-mode behaviour)?
   - `distinctness-and-buildability-critic.md` — do the three still describe three WORLDS after research, or did two converge on an axis (name the exact sentences)? Did any direction drift onto a `docs/DESIGN-CRAFT.md` §2 banned tell? Read the shared dimension docs against the three directions: which committed shape, depth, motion or type decision does the framework / licence / guideline research forbid or tax, and does the direction doc acknowledge it? Where has taste been dressed as a fact, or a checkable fact buried in prose to dodge the register? Where is an adjective unaccompanied by its mechanism?
   - `domain-accessibility-critic.md` *(premier)* — take the three palettes, type scales, densities and data forms at face value and make them FAIL an accessibility review: contrast on the actual proposed pairs, tap targets at the claimed density, status carried by colour alone, motion with no reduced-motion path, dynamic-type overflow.

**If V4's distinctness critic finds a direction has converged with a sibling or landed on a banned tell**, re-spawn THAT direction's researcher (the 6.3 template, the finding quoted) before finishing V5 — a cliché is re-argued by its researcher, never patched from the orchestrator seat. Everything else is patched per V5.

**Never emit bare text while the verifier or critic waves run** — append to `runs/<run_tag>/temp/orchestrator-notes.md` instead (which claim you expect to fall, which direction it would wound).

### Step 6.9 — Fill the step-7 correction table

V5 has patched the author doc (`## Refuted by verification`, inline `[corrected by verification: …]`, `## Open critique findings`). One area-03 extra remains, because the direction docs are NOT rewritten and step 7's authors read them directly: add a `## Corrections that override the research docs` table to `author/design-directions.md`, one row per non-CONFIRMED verdict, generated mechanically from `claims-03.json`:

```markdown
## Corrections that override the research docs
| Direction/dimension | Claim (short) | Verdict | What ships instead |
|---|---|---|---|
| soft-focus | "<claim>" | REFUTED | <the replacement, named — e.g. the substitute face and why> |
| type-availability-and-licensing | "<claim>" | PARTIALLY_TRUE | <the exact right version/licence/number> |
| framework-render-capability | "<claim>" | UNVERIFIABLE | <usable only labelled unverified; never the sole support for a must> |
```

**Every font, effect, or guideline number that reaches step 7 must trace to a claim that was CONFIRMED, corrected here, or explicitly labelled unverified.** If a direction's display face was refuted (licence forbids embedding, face does not exist), THIS TABLE NAMES THE REPLACEMENT — do not send step 7 to pick one, and do not leave the refuted face standing in the direction doc as the only instruction an author will read.

## Artifacts

- `runs/<run_tag>/designs/directions.md` — the RUN-LOCAL letter↔direction mapping (format in 6.2).
- `research/03-design-system/research/<direction-slug>.md` × 3 — one per direction. Frontmatter:

```markdown
---
run_tag: <run_tag>
created: <YYYY-MM-DD>
area: 03-design-system
dimension: <direction-slug>
phase: research
direction: <Name>
slug: <direction-slug>
letter: <a|b|c>
---
```

  Body: `## Summary` (dense paragraph + the FACTUAL claims as H3 assertions), then, in this order, `## Direction thesis`, `## Visual language` (the six axis decisions), `## Signature element`, `## Reference points`, `## What this direction rejects`, `## Reference design systems`, `## Typography`, `## Color`, `## Motion`, `## Component patterns`, `## Accessibility`, `## Known failure modes` (the adversarial findings), `## Commitments`, `## Sources`, then the provenance block.

  The four identity sections — `## Visual language`, `## Signature element`, `## Reference points`, `## What this direction rejects` — are BINDING on step 7's `hb-design-system-author` exactly like `## Commitments` is.

- `research/03-design-system/research/<dimension>.md` × 2 (standard) / 3 (premier) — the shared platform dimensions, RESEARCH-ARCHIVE §3.1 format (`## Summary` with H3 claims, `## Recommendations`, `## Sources`, provenance block).
- `research/03-design-system/verify/<dimension>--<claim-slug>.md` — one per SELECTED claim, §3.2 format, closed verdict vocabulary, provenance block (engine V3).
- `research/03-design-system/critique/completeness-critic.md`, `critique/distinctness-and-buildability-critic.md`, and (premier) `critique/domain-accessibility-critic.md` — §3.3 format, `[VERIFIED]` vs `[OPEN]` separated, `## Recommended patches`, provenance block (engine V4).
- `research/03-design-system/author/design-directions.md` — the synthesis (6.7), patched by engine V5 and carrying the 6.9 correction table that overrides the research docs.
- `research/03-design-system/_INDEX.md` — all four phases, every agent, every file size, verdict tally, `## Unverified` (engine V6). Takes NO provenance block.
- `runs/<run_tag>/temp/claims-03.json` — the claim registry, with `selected`, `verdict` and `correction` folded back in (kept, not shipped).

## Exit criteria

- `runs/<run_tag>/designs/directions.md` exists with exactly 3 rows pointing at `research/03-design-system/research/<slug>.md`, names passing the naming convention, the full `## Axis grid` with all six axes answered for all three letters, and per-direction briefs carrying thesis + axis commitments + signature-element candidate + ≥2 named reference points + rejects
- The axis grid's pairwise distinctness is ≥5/6 for all three pairs, and the redo-rule line is answered
- No direction is itself a `docs/DESIGN-CRAFT.md` §2 banned tell
- All 3 direction docs and all 2–3 shared dimension docs exist under `research/03-design-system/research/` with valid archive frontmatter (`area`, `dimension`, `phase`; direction docs also `direction`, `slug`, `letter`)
- **Every file in the area ends with its provenance block** containing the full prompt verbatim (RESEARCH-ARCHIVE §4) — research, verify, critique and author alike
- Every `## Summary` H3 is a complete assertion, not a topic label; each direction doc carries ≥3 factual claims (≥5 premier), each shared dimension doc ≥4 (≥6 premier)
- Each direction doc has ≥6 sources (standard) / ≥12 (premier); each shared dimension doc ≥8 / ≥15 — each source with URL + access date + one-line takeaway
- Each direction doc has a non-empty `## Commitments` and `## Known failure modes` section, and substantive `## Visual language` (six axes), `## Signature element` (named, constructed, ≥3 named screens), `## Reference points` (≥4 standard / ≥6 premier, each with what is borrowed) and `## What this direction rejects` sections (step 6.5 checks 5–7 passed)
- `runs/<run_tag>/temp/claims-03.json` exists with one entry per H3 claim in the area, each carrying `kind`, `selected` and — for every `"selected": true` entry — a `verdict`; NO `"kind": "taste"` entry was selected for verification
- Every claim on the selected verify surface has a `verify/` file with a verdict from the closed vocabulary `CONFIRMED | PARTIALLY_TRUE | REFUTED | UNVERIFIABLE`; claims that never got one are listed under `_INDEX.md` `## Unverified` with a reason
- The critique panel ran at the gear's seat count (2 standard / 3 premier) with DISTINCT lenses, one file each, every finding naming files
- ZERO UNPATCHED REFUTED CLAIMS: no REFUTED claim survives as fact in `author/design-directions.md`, and every one is findable under `## Refuted by verification` — nothing silently deleted; every PARTIALLY_TRUE claim carries its correction inline; every UNVERIFIABLE claim is labelled and is nowhere the sole support of a `must`-level decision
- `author/design-directions.md` carries the `## Corrections that override the research docs` table with a row for every non-CONFIRMED verdict, and every refuted font/effect/number names its replacement
- `research/03-design-system/_INDEX.md` lists all four phases with per-file sizes, the verdict tally and `## Unverified`, and states that `verify/` overrides `research/` and that taste was deliberately exempt
- No `research/` file was rewritten to hide a refutation
- Then update manifest: `steps.6 = "done"`, mark the step-6 todo complete, return to the router.

## Next step

Return to the router (`hyperbuild`). Invoke:

```
Skill(skill: "hyperbuild-7-design-systems")
```

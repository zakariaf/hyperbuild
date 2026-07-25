---
name: hyperbuild-6-design-research
description: >
  Step 6 of the hyperbuild pipeline — the orchestrator names EXACTLY 3
  design directions that are three genuinely DIFFERENT VISUAL WORLDS
  (each committing to its own answer on type personality, depth model,
  shape language, color strategy, density, and data/status form), then
  spawns 3 hb-design-researcher subagents in parallel (one per direction,
  6–10 sources each standard / 12–18 premier) to deep-research reference
  design systems, typography, color theory, motion, and component patterns
  into research/design/<direction-slug>.md. docs/DESIGN-CRAFT.md is BINDING
  here: its anti-pattern ban list applies at direction level. Step 7
  (hb-design-system-author) consumes these docs one-for-one. Invoked by the
  hyperbuild router via Skill(); not run directly by users.
---

# Step 6 — Design research (parallel, 3 directions)

You are executing step 6 (design-research) of the hyperbuild pipeline. Step 5 (stack research) just committed the technical stack; step 7 will turn each of the three research docs you produce here into a complete design system, and the user will eventually pick exactly ONE of the three — so all three must be shippable.

**Goal:** name EXACTLY 3 design directions and produce one deep research doc per direction at `research/design/<direction-slug>.md`, plus the letter↔direction mapping at `runs/<run_tag>/designs/directions.md`.

**⚠ CRITICAL: THREE directions, not one, not two, and NO strawmen.** The design gate (step 12) verifies all three designs have all screens. A run with one "real" direction and two throwaways forces the user's hand and defeats the ONE human checkpoint. All three directions must be designs you would defend shipping.

**⚠ CRITICAL: three VISUAL WORLDS, not three palettes.** This step is where the design either becomes distinctive or is doomed. A previous real run named three directions that differed on accent colour and ±8px of corner radius, and every downstream step faithfully built three versions of the same flat list app. Steps 7 and 8 can only express what you commit to here — they cannot rescue a mood board.

**BINDING craft bar: read `docs/DESIGN-CRAFT.md` before you name anything.** Its §2 anti-pattern list applies AT DIRECTION LEVEL (a banned tell may not be a direction's thesis), and §3.1 (signature element), §3.3 (depth model), §3.4 (shape language), §3.5 (colour with a chosen neutral) and §3.7 (data personality) define the axes you must commit each direction to. Every researcher you spawn reads it too, and step 7's authors are held to it.

## Inputs

Active run: `<run_tag>` from router context. If lost, recover it: the `runs/*/manifest.json` whose `stage` is PLAN and `steps.5` is `done`.

Read these before anything else:
- `docs/DESIGN-CRAFT.md` — the BINDING craft bar. Read it FIRST and in full; §2's ban list constrains which directions you may name at all.
- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL. Never paraphrase it.
- `runs/<run_tag>/manifest.json` — `gear` (standard | premier), `platform`
- `runs/<run_tag>/decisions/platform.md` — chosen platform + rationale (mobile vs web vs desktop changes which reference systems matter)
- `research/product-spec.md` — the PRD: personas, MoSCoW feature list, differentiators, screen inventory
- `research/sentiment-synthesis.md` — ranked pain points and wish lists (what users hate and love about competitor UX)
- `research/competitor-landscape.md` — feature matrix + positioning map (which visual territories competitors already occupy) AND the named real products you will draw reference points from
- `research/harvest/harvest-log.md` — if it exists, anything already harvested that a direction can cite as a reference point
- `features/00-index.md` — feature ids, names, screens (skim; the researchers read the full specs)

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
4. **Reference points (≥2)** — REAL, NAMED products or design systems, each with what SPECIFICALLY is borrowed: a shape treatment, a colour behaviour, a type pairing, a data form, a density decision. "Modern fintech apps" and "clean iOS apps" are not reference points. Draw them from `research/competitor-landscape.md`, anything already in `research/harvest/harvest-log.md`, and your own knowledge of shipped products — the researcher VERIFIES each one this run and replaces any it cannot fetch, so name real things.

Slug = kebab-case of the name (e.g. "Soft Focus" → `soft-focus`).

### Step 6.2 — Write the direction mapping

Write `runs/<run_tag>/designs/directions.md` (create `runs/<run_tag>/designs/` if needed). This file is the canonical letter↔direction mapping; steps 7, 8, 12, and `/hyperbuild-choose` all key off it. The axis grid and briefs below are pasted verbatim into the step 6.3 spawn prompts and read again by step 7's design-system authors — write them as instructions, not as marketing. Format:

```markdown
# Design directions — <run_tag>

| Letter | Name | Slug | Research doc |
|--------|------|------|--------------|
| a | Soft Focus | soft-focus | research/design/soft-focus.md |
| b | Swiss Utility | swiss-utility | research/design/swiss-utility.md |
| c | Neon Playful | neon-playful | research/design/neon-playful.md |

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

### Step 6.3 — Spawn 3 hb-design-researcher subagents in ONE message

**Spawn all 3 in ONE message — true parallel execution.** One researcher per direction. Each gets a different `direction_*` block and output path. Zero overlap: a researcher researches ONLY its assigned direction.

Source target per direction: **6–10 sources if `gear` is standard, 12–18 if premier** (from the router's scale-profile table — substitute the resolved range into the spawn prompt).

**Spawn template (fill one per direction):**

```
subagent_type: hb-design-researcher
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 6 (design research) of the hyperbuild
  pipeline. Steps 2-4 produced competitor research, user-sentiment
  research, and the PRD; the orchestrator has just named 3 design
  directions and you own exactly ONE of them. After you return, step 7
  spawns an hb-design-system-author that reads ONLY your research doc to
  author this direction's full design system (design-system.md +
  tokens.css), and step 8 builds HTML mockups from it. You research and
  commit; you do NOT write the design system, do NOT write CSS tokens,
  and do NOT research the other two directions.

  YOUR INPUTS:
  - run_tag: <run_tag>
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
  - output_path: research/design/<direction-slug>.md

  READ FIRST (context files, in this order):
  - docs/DESIGN-CRAFT.md — the BINDING craft bar. Read it in full before
    you research anything. Its §2 ban list applies to THIS DIRECTION as a
    whole, not only to individual mockups.
  - runs/<run_tag>/idea.md
  - research/product-spec.md — personas, differentiators, screen inventory
  - research/sentiment-synthesis.md — UX pain points your direction must answer
  - research/competitor-landscape.md — visual territory already occupied
  - runs/<run_tag>/decisions/platform.md — platform conventions that bind you
  - features/00-index.md — the features your components must eventually serve

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
  - At least ONE adversarial search for this direction's known failure
    modes (e.g. "<style> accessibility problems", "why designers abandoned
    <style>", "<reference system> criticism"). Record what you found and
    how the direction avoids it.
  - Prioritize sources from the last 18 months; any version or feature
    claim must cite a dated source.
  - End the doc with a "## Commitments" section: 5-10 "we will do X"
    decisions specific enough that the step 7 author never has to guess.
  - End with a "## Sources" section: every source as URL + access date +
    one-line takeaway.

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

### Step 6.4 — Wait discipline

**CRITICAL: never emit bare text while the 3 researchers are running** — a text-only response ends the turn and kills the pipeline. While waiting, append thoughts to `runs/<run_tag>/temp/orchestrator-notes.md`: which direction you predict the user picks, what the step 7 authors will need emphasized, screens likely to stress each direction, and the axis-by-axis distinctness re-check you will run in 6.5 (which pairs are closest, which axis you expect to converge). One progress check per minute max.

### Step 6.5 — Validate returns

When all 3 return:
1. Confirm all 3 files exist at `research/design/<direction-slug>.md`.
2. Read each doc's `## Sources` section — count meets the gear target (6 minimum standard, 12 minimum premier); each entry has URL + access date + takeaway.
3. Confirm each doc has a non-empty `## Commitments` section and covers all five required areas plus the adversarial findings.
4. **Identity sections present and substantive** — each doc has `## Visual language` (all six axes answered concretely), `## Signature element` (named + constructed + ≥3 named screens), `## Reference points` (≥4 standard / ≥6 premier, each with what is borrowed), and `## What this direction rejects`. A section that restates the brief without adding a mechanism counts as missing.
5. **Cross-direction distinctness — read the three `## Visual language` sections side by side.** Re-check the pairwise rule: no two directions share an answer on more than ONE axis. If a researcher sharpened an axis into convergence with a sibling, re-spawn THAT researcher with the sibling's conflicting answer quoted and its own axis commitment restated as binding.
6. **Cliché sweep** — read the three docs against `docs/DESIGN-CRAFT.md` §2 by name. If any direction has become cream+serif+terracotta, near-greyscale+one-accent utility, or traffic-light-status-as-palette, re-spawn that researcher with the ban quoted. Do not patch a cliché from the orchestrator seat — the direction has to be re-argued.
7. If a researcher failed or its doc is missing a required section, re-spawn that ONE researcher ONCE with the gap named explicitly. If it fails twice, log the gap in `runs/<run_tag>/temp/orchestrator-notes.md` and proceed — step 7's author will be told which section is thin. Never proceed with fewer than 3 docs on disk.

## Artifacts

- `runs/<run_tag>/designs/directions.md` — the letter↔direction mapping (format above).
- `research/design/<direction-slug>.md` × 3 — one per direction. Frontmatter:

```markdown
---
run_tag: <run_tag>
created: <YYYY-MM-DD>
direction: <Name>
slug: <direction-slug>
letter: <a|b|c>
---
```

Required body sections, in this order: `## Direction thesis`, `## Visual language` (the six axis decisions), `## Signature element`, `## Reference points`, `## What this direction rejects`, `## Reference design systems`, `## Typography`, `## Color`, `## Motion`, `## Component patterns`, `## Accessibility`, `## Known failure modes` (the adversarial findings), `## Commitments`, `## Sources`.

The four identity sections — `## Visual language`, `## Signature element`, `## Reference points`, `## What this direction rejects` — are BINDING on step 7's `hb-design-system-author` exactly like `## Commitments` is.

## Exit criteria

- `runs/<run_tag>/designs/directions.md` exists with exactly 3 rows, names passing the naming convention, the full `## Axis grid` with all six axes answered for all three letters, and per-direction briefs carrying thesis + axis commitments + signature-element candidate + ≥2 named reference points + rejects
- The axis grid's pairwise distinctness is ≥5/6 for all three pairs, and the redo-rule line is answered
- No direction is itself a `docs/DESIGN-CRAFT.md` §2 banned tell
- All 3 `research/design/<direction-slug>.md` files exist with valid frontmatter (`run_tag`, `created`, `direction`, `slug`, `letter`)
- Each doc has ≥6 sources (standard) / ≥12 (premier), each with URL + access date + one-line takeaway
- Each doc has a non-empty `## Commitments` and `## Known failure modes` section
- Each doc has substantive `## Visual language` (six axes), `## Signature element` (named, constructed, ≥3 named screens), `## Reference points` (≥4 standard / ≥6 premier, each with what is borrowed) and `## What this direction rejects` sections (step 6.5 checks 4–6 passed)
- Then update manifest: `steps.6 = "done"`, mark the step-6 todo complete, return to the router.

## Next step

Return to the router (`hyperbuild`). Invoke:

```
Skill(skill: "hyperbuild-7-design-systems")
```

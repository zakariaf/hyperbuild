---
name: hyperbuild-6-design-research
description: >
  Step 6 of the hyperbuild pipeline — the orchestrator names EXACTLY 3
  distinct design directions fitted to this app and its audience, then
  spawns 3 hb-design-researcher subagents in parallel (one per direction,
  6–10 sources each standard / 12–18 premier) to deep-research reference
  design systems, typography, color theory, motion, and component patterns
  into research/design/<direction-slug>.md. Step 7 (hb-design-system-author)
  consumes these docs one-for-one. Invoked by the hyperbuild router via
  Skill(); not run directly by users.
---

# Step 6 — Design research (parallel, 3 directions)

You are executing step 6 (design-research) of the hyperbuild pipeline. Step 5 (stack research) just committed the technical stack; step 7 will turn each of the three research docs you produce here into a complete design system, and the user will eventually pick exactly ONE of the three — so all three must be shippable.

**Goal:** name EXACTLY 3 design directions and produce one deep research doc per direction at `research/design/<direction-slug>.md`, plus the letter↔direction mapping at `runs/<run_tag>/designs/directions.md`.

**⚠ CRITICAL: THREE directions, not one, not two, and NO strawmen.** The design gate (step 12) verifies all three designs have all screens. A run with one "real" direction and two throwaways forces the user's hand and defeats the ONE human checkpoint. All three directions must be designs you would defend shipping.

## Inputs

Active run: `<run_tag>` from router context. If lost, recover it: the `runs/*/manifest.json` whose `stage` is PLAN and `steps.5` is `done`.

Read these before anything else:
- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL. Never paraphrase it.
- `runs/<run_tag>/manifest.json` — `gear` (standard | premier), `platform`
- `runs/<run_tag>/decisions/platform.md` — chosen platform + rationale (mobile vs web vs desktop changes which reference systems matter)
- `research/product-spec.md` — the PRD: personas, MoSCoW feature list, differentiators, screen inventory
- `research/sentiment-synthesis.md` — ranked pain points and wish lists (what users hate and love about competitor UX)
- `research/competitor-landscape.md` — feature matrix + positioning map (which visual territories competitors already occupy)
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

**Distinctness test — MANDATORY.** The three directions must differ on at least THREE of these five axes: information density, color energy, typographic voice, shape language (radii/geometry), motion posture. Three palette swaps of the same layout is a failed step. Write one sentence per direction stating which axes it stakes out.

For each direction write a 2–3 sentence brief: the thesis, who it serves best, and what it deliberately sacrifices. Slug = kebab-case of the name (e.g. "Soft Focus" → `soft-focus`).

### Step 6.2 — Write the direction mapping

Write `runs/<run_tag>/designs/directions.md` (create `runs/<run_tag>/designs/` if needed). This file is the canonical letter↔direction mapping; steps 7, 8, 12, and `/hyperbuild-choose` all key off it. Format:

```markdown
# Design directions — <run_tag>

| Letter | Name | Slug | Research doc |
|--------|------|------|--------------|
| a | Soft Focus | soft-focus | research/design/soft-focus.md |
| b | Swiss Utility | swiss-utility | research/design/swiss-utility.md |
| c | Neon Playful | neon-playful | research/design/neon-playful.md |

## Briefs

### a — Soft Focus
<2–3 sentence brief. Axes staked: density (low), color energy (muted), motion (gentle).>

### b — Swiss Utility
<brief + axes>

### c — <Name>
<brief + axes>
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
  - direction_brief: "<the 2-3 sentence brief from directions.md, verbatim>"
  - source_target: <6-10 | 12-18> curated sources (gear: <standard|premier>)
  - output_path: research/design/<direction-slug>.md

  READ FIRST (context files, in this order):
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
  - Cover ALL of: reference design systems (2-4 named systems or apps that
    embody this direction, with what to borrow from each), typography
    (families, scale philosophy, platform availability), color theory
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

  Do NOT write design tokens or CSS. Do NOT survey all three directions —
  yours is assigned. Do NOT pad the source list with undated listicles.
```

### Step 6.4 — Wait discipline

**CRITICAL: never emit bare text while the 3 researchers are running** — a text-only response ends the turn and kills the pipeline. While waiting, append thoughts to `runs/<run_tag>/temp/orchestrator-notes.md`: which direction you predict the user picks, what the step 7 authors will need emphasized, screens likely to stress each direction. One progress check per minute max.

### Step 6.5 — Validate returns

When all 3 return:
1. Confirm all 3 files exist at `research/design/<direction-slug>.md`.
2. Read each doc's `## Sources` section — count meets the gear target (6 minimum standard, 12 minimum premier); each entry has URL + access date + takeaway.
3. Confirm each doc has a non-empty `## Commitments` section and covers all five required areas plus the adversarial findings.
4. If a researcher failed or its doc is missing a required section, re-spawn that ONE researcher ONCE with the gap named explicitly. If it fails twice, log the gap in `runs/<run_tag>/temp/orchestrator-notes.md` and proceed — step 7's author will be told which section is thin. Never proceed with fewer than 3 docs on disk.

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

Required body sections: `## Direction thesis`, `## Reference design systems`, `## Typography`, `## Color`, `## Motion`, `## Component patterns`, `## Accessibility`, `## Known failure modes` (the adversarial findings), `## Commitments`, `## Sources`.

## Exit criteria

- `runs/<run_tag>/designs/directions.md` exists with exactly 3 rows, names passing the naming convention, and per-direction briefs with staked axes
- All 3 `research/design/<direction-slug>.md` files exist with valid frontmatter (`run_tag`, `created`, `direction`, `slug`, `letter`)
- Each doc has ≥6 sources (standard) / ≥12 (premier), each with URL + access date + one-line takeaway
- Each doc has a non-empty `## Commitments` and `## Known failure modes` section
- Then update manifest: `steps.6 = "done"`, mark the step-6 todo complete, return to the router.

## Next step

Return to the router (`hyperbuild`). Invoke:

```
Skill(skill: "hyperbuild-7-design-systems")
```

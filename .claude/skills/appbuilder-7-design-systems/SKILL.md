---
name: appbuilder-7-design-systems
description: >
  Step 7 of the appbuilder pipeline — spawns 3 ab-design-system-author
  subagents in parallel (one per design direction from step 6). Each
  author reads its direction's research doc and writes a complete design
  system: runs/<run_tag>/designs/<a|b|c>/design-system.md + tokens.css —
  type scale, light+dark color palettes, spacing, radii, elevation, and
  component specs (buttons, cards, inputs, nav, lists, empty states).
  tokens.css follows the three-layer token structure (primitive →
  semantic → component) unless the direction's research argues otherwise.
  Step 8's mockup smiths inline these tokens verbatim; /appbuilder-choose
  copies the winning tokens.css to app/design/ and step 13 implements it
  in the target framework. Invoked by the appbuilder router via Skill();
  not run directly by users.
---

# Step 7 — Design systems (parallel, 3 authors)

You are executing step 7 (design-systems) of the appbuilder pipeline. Step 6 produced one research doc per design direction plus the letter↔direction mapping; step 8 will build HTML mockups of every PRD screen directly from the tokens and component specs you produce here.

**Goal:** three complete, independently authored design systems on disk — `runs/<run_tag>/designs/<a|b|c>/design-system.md` + `tokens.css` — one per direction.

**⚠ CRITICAL: do NOT author the design systems yourself.** Each system is written by an `ab-design-system-author` subagent (opus, tool-locked to Read + Write) with a fresh context holding exactly one direction's research. If you find yourself about to write `design-system.md` or `tokens.css` directly, STOP and spawn the authors. Three systems written by one saturated orchestrator context converge on each other — the exact failure the three-direction architecture exists to prevent.

## Inputs

Active run: `<run_tag>` from router context. If lost, recover it: the `runs/*/manifest.json` whose `stage` is PLAN and `steps.6` is `done`.

Read these before anything else:
- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL.
- `runs/<run_tag>/manifest.json` — `gear`, `platform`
- `runs/<run_tag>/designs/directions.md` — letter↔name↔slug↔research-doc mapping (step 6)
- `research/design/<direction-slug>.md` × 3 — skim each doc's `## Commitments` section so you can validate the authors honored them
- `runs/<run_tag>/decisions/platform.md` — platform conventions (nav pattern, type availability)
- `research/product-spec.md` — screen inventory (the components must serve these screens)

## Procedure

### Step 7.1 — Fix the canonical token contract

All three `tokens.css` files MUST define the SAME custom-property NAMES with different VALUES. This is load-bearing twice over: step 8's mockup smiths write component CSS against these names regardless of design, and step 13 translates the winning `tokens.css` into the target framework's theme without caring which letter won. An author inventing its own token names breaks both consumers.

The canonical token names (paste this list into every spawn prompt):

```
--font-family-display, --font-family-body, --font-family-mono
--font-size-xs, --font-size-sm, --font-size-base, --font-size-lg,
--font-size-xl, --font-size-2xl, --font-size-3xl
--font-weight-regular, --font-weight-medium, --font-weight-bold
--line-height-tight, --line-height-base
--color-bg, --color-surface, --color-surface-raised, --color-border,
--color-text, --color-text-muted, --color-primary, --color-on-primary,
--color-accent, --color-success, --color-warning, --color-danger,
--color-focus-ring
--space-1 through --space-8
--radius-sm, --radius-md, --radius-lg, --radius-full
--shadow-1, --shadow-2, --shadow-3
--motion-fast, --motion-base, --motion-slow, --easing-standard
```

Authors may ADD direction-specific tokens beyond this set; they may never rename or omit one of these.

These canonical names are the SEMANTIC layer of the three-layer token structure (harvested from nextlevelbuilder/ui-ux-pro-max-skill, MIT) that every tokens.css MUST follow — primitive (raw values) → semantic (purpose aliases) → component (component-scoped vars), all as CSS custom properties — unless the direction's research doc argues otherwise. The spawn template spells out the layers; step 7.4 checks them.

### Step 7.2 — Spawn 3 ab-design-system-author subagents in ONE message

**Spawn all 3 in ONE message — true parallel execution.** One author per direction. Zero overlap: an author reads ONLY its own direction's research doc and never looks at the other two systems.

**Spawn template (fill one per direction):**

```
subagent_type: ab-design-system-author
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 7 (design systems) of the appbuilder
  pipeline. Step 6's ab-design-researcher produced the research doc for
  your direction, ending in a "## Commitments" section that is BINDING on
  you. After you return, step 8's ab-mockup-smith subagents inline your
  tokens.css verbatim into every screen mockup, and if the user picks
  your direction, step 13 implements your tokens as the app's real theme.
  You are tool-locked to [Read, Write] — you cannot fetch new sources;
  everything you need is in your research doc. You author ONE design
  system; the other two directions have their own authors.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - direction_letter: <a|b|c>
  - direction_name: "<Name>"
  - research_doc: research/design/<direction-slug>.md
  - output_dir: runs/<run_tag>/designs/<letter>/
  - outputs: design-system.md AND tokens.css in that directory

  READ FIRST (context files, in this order):
  - runs/<run_tag>/idea.md
  - research/design/<direction-slug>.md — your entire brief; honor every
    line of "## Commitments"
  - runs/<run_tag>/decisions/platform.md — platform conventions
  - research/product-spec.md — the screen inventory your components serve
  - runs/<run_tag>/designs/directions.md — your direction's staked axes

  CANONICAL TOKEN CONTRACT — tokens.css MUST define exactly these
  custom-property names (add more if the direction needs them; never
  rename or omit one):
  <paste the full token-name list from step 7.1>

  tokens.css structure — THREE LAYERS, in this order (binding unless
  your research doc's "## Commitments" argues otherwise; if it does,
  say so in a comment at the top of the file):
  1. PRIMITIVE — raw values only (e.g. --blue-500: #2563eb), under a
     /* primitive */ comment header
  2. SEMANTIC — purpose aliases onto primitives via var(); the
     canonical contract names above live here (e.g. --color-primary:
     var(--blue-500)), under a /* semantic */ comment header
  3. COMPONENT — component-scoped vars onto semantic tokens (e.g.
     --button-bg: var(--color-primary)), under a /* component */
     comment header
  Layout: a :root block with the full LIGHT palette and all non-color
  tokens, then a [data-theme="dark"] block AND a
  @media (prefers-color-scheme: dark) block that both override the
  color tokens for dark mode — override primitives/semantic aliases,
  never fork component tokens per theme. Real CSS values at the
  primitive layer; no var() chains to undefined names, no placeholder
  values.

  design-system.md REQUIRED sections, all substantive:
  - ## Principles — 3-5 named principles derived from the direction thesis
  - ## Type scale — families, the full size/weight/line-height scale as a
    table mapped to the --font-* tokens, usage rules per level
  - ## Color — light AND dark palettes as tables (token, value, usage);
    state WCAG AA contrast for text-on-bg, text-muted-on-bg, and
    on-primary-on-primary pairs in BOTH modes
  - ## Spacing — the --space-* scale values and the layout grid rhythm
  - ## Radii & shape — the shape language, mapped to --radius-*
  - ## Elevation — the --shadow-* levels and when each is used
  - ## Motion — durations/easing mapped to --motion-*, what animates,
    what never animates
  - ## Components — a spec for EACH of: buttons (primary, secondary,
    ghost, disabled), cards, inputs (field + label + error state), nav
    (matching the platform: tab bar / top bar / side nav), lists (row
    anatomy, leading/trailing elements), empty states (copy tone,
    illustration posture, CTA). Each spec: anatomy, sizing in tokens,
    states, one do/don't pair.

  Every component spec MUST be expressible with your tokens alone — if a
  spec needs a value no token provides, add the token. Do NOT copy the
  research doc's prose wholesale; the design system is decisions, not
  survey. Do NOT emit lorem ipsum or TBD anywhere.
```

### Step 7.3 — Wait discipline

**CRITICAL: never emit bare text while the 3 authors are running.** Append thoughts to `runs/<run_tag>/temp/orchestrator-notes.md` instead: which screens will stress each system, what step 8's smiths should double-check, likely dark-mode trouble spots. One progress check per minute max.

### Step 7.4 — Validate mechanically

When all 3 return, run these checks per letter (a, b, c):

1. Both files exist: `runs/<run_tag>/designs/<letter>/design-system.md` and `runs/<run_tag>/designs/<letter>/tokens.css`.
2. Token contract: for every name in the step 7.1 list, `grep -c -- "<token-name>" runs/<run_tag>/designs/<letter>/tokens.css` ≥ 1. Every miss is a defect.
3. Dark palette: `grep -c 'data-theme="dark"' tokens.css` ≥ 1 AND `grep -c 'prefers-color-scheme' tokens.css` ≥ 1.
4. Three-layer structure: `grep -ci 'primitive' tokens.css` ≥ 1 AND `grep -ci 'semantic' tokens.css` ≥ 1 AND `grep -ci 'component' tokens.css` ≥ 1 (the layer comment headers), plus at least one canonical token resolving via `var()` to a primitive — UNLESS the file's top comment cites the research doc's contrary commitment.
5. design-system.md contains all eight required `##` sections and the `## Components` section covers all six component families.
6. Distinctness spot-check: compare the three `--color-primary` values and `--radius-md` values across letters. If two systems are near-identical on both, the author drifted off its direction — re-spawn that author with its `## Commitments` section quoted back.

Failures: re-spawn the offending author ONCE with the exact failed checks named. If it fails twice, fix the mechanical gaps yourself via Edit (token renames, missing dark block) and log what you patched in `runs/<run_tag>/temp/orchestrator-notes.md` — but never rewrite a system's design decisions from the orchestrator seat.

## Artifacts

- `runs/<run_tag>/designs/a/design-system.md` + `runs/<run_tag>/designs/a/tokens.css`
- `runs/<run_tag>/designs/b/design-system.md` + `runs/<run_tag>/designs/b/tokens.css`
- `runs/<run_tag>/designs/c/design-system.md` + `runs/<run_tag>/designs/c/tokens.css`

design-system.md frontmatter:

```markdown
---
run_tag: <run_tag>
created: <YYYY-MM-DD>
direction: <Name>
letter: <a|b|c>
---
```

## Exit criteria

- All 6 files exist (3 × design-system.md, 3 × tokens.css)
- Every tokens.css defines every canonical token name, with a light `:root` palette and dark overrides via both `[data-theme="dark"]` and `prefers-color-scheme`
- Every tokens.css shows the three-layer structure — primitive (raw values) → semantic (purpose aliases) → component (component-scoped vars) — or carries a top-of-file comment citing the research doc's contrary commitment (step 7.4 check 4 passed)
- Every design-system.md has all eight required sections; `## Components` covers buttons, cards, inputs, nav, lists, empty states
- Each design-system.md states WCAG AA contrast for the required pairs in both modes
- The three systems are visibly distinct (step 7.4 check 6 passed)
- Then update manifest: `steps.7 = "done"`, mark the step-7 todo complete, return to the router.

## Next step

Return to the router (`appbuilder`). Invoke:

```
Skill(skill: "appbuilder-8-mockups")
```

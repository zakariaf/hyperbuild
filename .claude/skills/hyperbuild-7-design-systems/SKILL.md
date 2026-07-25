---
name: hyperbuild-7-design-systems
description: >
  Step 7 of the hyperbuild pipeline — spawns 3 hb-design-system-author
  subagents in parallel (one per design direction from step 6). Each
  author reads its direction's research doc and writes a complete design
  system: runs/<run_tag>/designs/<a|b|c>/design-system.md + tokens.css —
  a named signature element, a display+body type pairing, light+dark
  color palettes, spacing, a shape language, a named depth model,
  motion, illustration/empty-state art direction, data personality, and
  component specs (buttons, cards, inputs, nav, lists, empty states).
  docs/DESIGN-CRAFT.md is BINDING on this step. tokens.css follows the
  three-layer token structure (primitive → semantic → component) unless
  the direction's research argues otherwise, and must carry real layered
  elevation, a radius rhythm, both type faces, and motion tokens.
  Step 8's mockup smiths inline these tokens verbatim; /hyperbuild-choose
  copies the winning tokens.css to app/design/ and step 13 implements it
  in the target framework. Invoked by the hyperbuild router via Skill();
  not run directly by users.
---

# Step 7 — Design systems (parallel, 3 authors)

You are executing step 7 (design-systems) of the hyperbuild pipeline. Step 6 produced one research doc per design direction plus the letter↔direction mapping; step 8 will build HTML mockups of every PRD screen directly from the tokens and component specs you produce here.

**Goal:** three complete, independently authored design systems on disk — `runs/<run_tag>/designs/<a|b|c>/design-system.md` + `tokens.css` — one per direction, each meeting the craft bar in `docs/DESIGN-CRAFT.md`.

**The craft bar is binding.** `docs/DESIGN-CRAFT.md` §3 lists eight commitments every design system must make; this step's required sections ARE those commitments. The failure this exists to prevent: the first real run's systems documented Motion, Elevation, and Empty states beautifully and shipped token sets that produced flat, dated screens — because the documents described craft the tokens never provided and no check compared the two. A design system that reads well and tokenizes nothing is a FAILED design system here.

**⚠ CRITICAL: do NOT author the design systems yourself.** Each system is written by an `hb-design-system-author` subagent (opus, tool-locked to Read + Write) with a fresh context holding exactly one direction's research. If you find yourself about to write `design-system.md` or `tokens.css` directly, STOP and spawn the authors. Three systems written by one saturated orchestrator context converge on each other — the exact failure the three-direction architecture exists to prevent.

## Inputs

Active run: `<run_tag>` from router context. If lost, recover it: the `runs/*/manifest.json` whose `stage` is PLAN and `steps.6` is `done`.

Read these before anything else:
- `docs/DESIGN-CRAFT.md` — THE CRAFT BAR. Binding on this step. §2 is the banned-cliché list, §3 is the section contract you validate against in 7.4, §3.2 is the self-contained font palette authors must pick from.
- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL.
- `runs/<run_tag>/manifest.json` — `gear`, `platform`
- `runs/<run_tag>/designs/directions.md` — letter↔name↔slug↔research-doc mapping (step 6)
- `research/design/<direction-slug>.md` × 3 — skim each doc's `## Commitments` section AND its four IDENTITY sections (`## Visual language` — the six axis answers; `## Signature element`; `## Reference points`; `## What this direction rejects`) so you can validate the authors honored them. Step 6 declares all five BINDING on this step's authors; they are what make the three systems three different products, and 7.4 check 8 verifies they landed
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
--tracking-tight, --tracking-caps
--space-1 through --space-8
--radius-sm, --radius-md, --radius-lg, --radius-full
--shadow-1, --shadow-2, --shadow-3
--motion-fast, --motion-base, --motion-slow, --easing-standard,
--easing-emphasized
--signature-* (at least one token named for the direction's signature
  element, carrying its values — e.g. --signature-clip,
  --signature-radius, --signature-gradient, --signature-size)
```

Authors may ADD direction-specific tokens beyond this set; they may never rename or omit one of these.

**Craft token requirements — the VALUES, not just the names.** The first run passed the name contract and still produced flat screens, because the values were `--shadow-1: none`, one radius reused four times, one system font stack in both family slots, and a 20px type ceiling. Paste this block into every spawn prompt alongside the name list:

```
- TYPE, BOTH FACES: --font-family-display and --font-family-body resolve
  to DIFFERENT families, each picked from docs/DESIGN-CRAFT.md §3.2's
  self-contained face table, each ending in a generic fallback
  (serif / sans-serif / monospace). -apple-system or system-ui in BOTH
  slots is a FAILURE. --font-size-3xl >= 30px unless the design system
  argues the exception and names what carries hierarchy instead.
  --tracking-tight is negative (-0.02em…-0.04em, display); --tracking-caps
  is +0.06em…+0.12em (all-caps micro-labels).
- SHAPE, A RHYTHM: --radius-sm / --radius-md / --radius-lg are three
  DIFFERENT values (--radius-full is the capsule). One value repeated is
  a FAILURE. At least one --signature-* token carries the direction's
  distinctive shape move (clip-path polygon, asymmetric corner set,
  gradient stops, arc mask) so step 8 can apply it by name.
- ELEVATION, REAL DEPTH: --shadow-2 and --shadow-3 are MULTI-LAYER
  (2-3 comma-separated shadows) in a PALETTE HUE at low saturation — a
  tight contact shadow plus a wide soft one. Single-layer
  rgba(0,0,0,0.1) is a FAILURE. If the direction's depth model is
  "borderless tinted surfaces" (shadows deliberately absent), then
  --color-bg, --color-surface and --color-surface-raised MUST be three
  measurably different values and the md must say what pays for the
  missing depth. Dark mode overrides elevation to lightness steps.
- MOTION: --motion-fast/base/slow are three different durations and
  --easing-standard/--easing-emphasized two different curves; every
  duration and easing named in ## Motion exists as one of these.
```

The canonical names above are the SEMANTIC layer of the three-layer token structure (harvested from nextlevelbuilder/ui-ux-pro-max-skill, MIT) that every tokens.css MUST follow — primitive (raw values) → semantic (purpose aliases) → component (component-scoped vars), all as CSS custom properties — unless the direction's research doc argues otherwise. The spawn template spells out the layers; step 7.4 checks them.

### Step 7.2 — Spawn 3 hb-design-system-author subagents in ONE message

**Spawn all 3 in ONE message — true parallel execution.** One author per direction. Zero overlap: an author reads ONLY its own direction's research doc and never looks at the other two systems.

**Spawn template (fill one per direction):**

```
subagent_type: hb-design-system-author
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 7 (design systems) of the hyperbuild
  pipeline. Step 6's hb-design-researcher produced the research doc for
  your direction. FIVE of its sections are BINDING on you: "## Visual
  language" (its SIX axis commitments — type personality, depth model,
  shape language, colour strategy, density, data & status form),
  "## Signature element", "## Reference points", "## What this direction
  rejects", and "## Commitments". After you return, step 8's hb-mockup-smith subagents inline your
  tokens.css verbatim into every screen mockup, and if the user picks
  your direction, step 13 implements your tokens as the app's real theme.
  You are tool-locked to [Read, Write] — you cannot fetch new sources;
  everything you need is in your research doc and docs/DESIGN-CRAFT.md.
  You author ONE design system; the other two directions have their own
  authors. Your system will be compared against the other two on type
  strategy, depth model and palette temperature (step 7.5) — a system
  that lands on the same three answers as a sibling gets re-spawned.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - direction_letter: <a|b|c>
  - direction_name: "<Name>"
  - research_doc: research/design/<direction-slug>.md
  - output_dir: runs/<run_tag>/designs/<letter>/
  - outputs: design-system.md AND tokens.css in that directory

  READ FIRST (context files, in this order):
  - docs/DESIGN-CRAFT.md — THE CRAFT BAR, and it is BINDING. Read it end
    to end BEFORE you decide anything. Its §2 anti-pattern list names
    DEFECTS, not preferences — self-check against it by number before
    you report back. Its §3 commitments ARE your required-section
    contract below. Its §3.2 table is the font palette you pick from.
  - runs/<run_tag>/idea.md
  - research/design/<direction-slug>.md — your entire brief. FIVE of its
    sections BIND you, not just one:
      * "## Visual language" — the SIX axis commitments (type
        personality, depth model, shape language, colour strategy,
        density, data & status form). Each one is a decision you
        EXPRESS, not a suggestion: your "## Typography" must deliver its
        type-personality answer, "## Depth model" its depth answer,
        "## Shape language" its shape answer, "## Color" its colour
        answer, "## Data personality" its data & status answer, and your
        spacing/component sizing its density answer. Sharpen an axis
        with real values; NEVER swap one for a different answer, and
        never drift toward what a sibling direction owns — 7.4 check 8
        compares your sections against these six line by line.
      * "## Signature element" — the researcher's validated device.
        Your "## Signature element" section SPECS that device; you do
        not substitute your own. If you must depart from it, say so
        explicitly and justify it in that section.
      * "## Reference points" — the named real products and what
        specifically is borrowed from each; keep the borrowed mechanic
        recognizable in your values.
      * "## What this direction rejects" — a BANNED list. Anything it
        names is a defect in your system, not an option.
      * "## Commitments" — honor every line.
  - runs/<run_tag>/decisions/platform.md — platform conventions
  - research/product-spec.md — the screen inventory your components serve
  - runs/<run_tag>/designs/directions.md — the axis grid: your
    direction's six staked axes side by side with the other two, so you
    can see what is already occupied

  CANONICAL TOKEN CONTRACT — tokens.css MUST define exactly these
  custom-property names (add more if the direction needs them; never
  rename or omit one):
  <paste the full token-name list from step 7.1>

  CRAFT TOKEN REQUIREMENTS — the VALUES behind those names. Every one
  is mechanically checked in step 7.4:
  <paste the craft token requirements block from step 7.1>

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

  design-system.md FRONTMATTER — exactly these keys. The last four are
  read by the orchestrator's anti-sameness check in step 7.5, so state
  them plainly, not poetically:
  ---
  run_tag: <run_tag>
  created: <YYYY-MM-DD>
  direction: <Name>
  letter: <a|b|c>
  signature_element: <the device's name>
  type_strategy: <display family> + <body family> (<ratio> scale,
    ceiling <N>px)
  depth_model: layered-tinted | borderless-tinted | crisp-offset
  palette_hue: accent <N>deg <warm|cool|neutral-warm|neutral-cool>,
    neutrals <N>deg
  ---

  design-system.md REQUIRED sections — these EXACT H2 headings, in this
  order, all substantive. Step 7.4 greps for them literally; a renamed
  or missing heading is a defect:
  - ## Principles — 3-5 named principles derived from the direction thesis
  - ## Signature element — DESIGN-CRAFT §3.1. ONE memorable recurring
    visual device that belongs to THIS app and no other. NAME it, and
    trace it to the app's subject in one sentence (why THIS app gets
    THIS device). SPEC it as an exact CSS recipe on your tokens (radii,
    clip-path, gradient stops, sizes, which --signature-* tokens carry
    it). STATE its rules of use: where it MUST appear, where it must
    NEVER, how it scales from hero to compact. NAME AT LEAST 3 SCREENS
    from the PRD inventory it must appear on — step 8.5 counts them.
    A signature element is not a logo, not an accent color, and not
    "rounded corners".
  - ## Typography — DESIGN-CRAFT §3.2. A display + body PAIRING:
    --font-family-display and --font-family-body resolve to DIFFERENT
    families, each chosen from §3.2's self-contained face table (the
    mockups load NO network fonts, so a face that is not on the render
    host silently becomes the OS default — this is exactly how the
    first run's three "typographic voices" collapsed into two system
    faces). Every stack ends in a generic fallback. ONE system stack
    for everything is BANNED; Inter and Space Grotesk as the reflexive
    safe face are BANNED (§2.4). Then: a stated scale RATIO
    (1.200 / 1.250 / 1.333) generating --font-size-xs…--font-size-3xl,
    tabled with weight, line-height, tracking and usage per step;
    --font-size-3xl >= 30px unless you argue the exception AND name
    what carries hierarchy instead; --tracking-tight on display,
    --tracking-caps on all-caps micro-labels (never regular weight);
    and a stated font-variant-numeric for any column of figures.
  - ## Color — light AND dark palettes as tables (token, value, usage).
    State the NEUTRAL RECIPE (DESIGN-CRAFT §3.5): every neutral shares
    one hue ±15° at low chroma, biased toward the accent — pure grey
    ramps (#FFFFFF/#F5F5F5/#111111) are BANNED. Status colors
    (--color-success/warning/danger) get their own hues, defined
    SEPARATELY from --color-accent, which must not share a hue family
    with --color-danger. State the accent's maximum share of a screen.
    State WCAG AA contrast for text-on-bg, text-muted-on-bg, and
    on-primary-on-primary pairs in BOTH modes.
  - ## Spacing — the --space-* scale values and the layout grid rhythm
  - ## Shape language — DESIGN-CRAFT §3.4 (this section replaces the
    former "## Radii & shape"). A RADIUS RHYTHM: --radius-sm/md/lg are
    three DIFFERENT values, with a stated assignment rule (which value
    goes on media, controls, containers, chips) and the concentric
    nesting rule (inner radius = outer radius − padding; never nest
    equal radii). PLUS one distinctive, NAMED shape move — asymmetric
    corners, a clip-path notch or cut corner, a diagonal edge, a
    capsule, overlapping layers, a masked arc — specced in tokens and
    used on MORE THAN ONE component so it reads as language.
  - ## Depth model — DESIGN-CRAFT §3.3 (this section replaces the
    former "## Elevation" and must still carry the --shadow-1/2/3
    levels and when each is used). NAME the model in its first line —
    layered tinted shadow / borderless tinted surfaces / crisp offset —
    and apply it everywhere. Layered = 2-3 stacked shadows in a PALETTE
    HUE at low saturation, a tight contact shadow plus a wide soft one.
    Single-layer rgba(0,0,0,.1) is BANNED, and so is shadow as
    decoration on things that are not elevated. If you choose
    borderless, --color-bg / --color-surface / --color-surface-raised
    must be three measurably different values and you must name what
    pays for the missing depth. State DARK MODE explicitly: shadows
    barely read there, so elevation switches to lightness steps,
    optionally with a 1px top inner highlight at 6-10% white.
  - ## Motion — DESIGN-CRAFT §3.8. Per interactive component: press
    (transform/shadow/color delta, duration, easing token), hover
    (web/desktop), enter/exit for sheets, lists and modals; plus an
    explicit NEVER-ANIMATES list and prefers-reduced-motion behavior.
    Every duration and easing you name MUST be a --motion-*/--easing-*
    token — do not describe motion you did not tokenize.
  - ## Illustration & empty states — DESIGN-CRAFT §3.6. First the
    drawing language: stroke weight, fill rule, geometry, subject
    matter, how it derives from the signature element — all buildable
    as CSS and inline SVG (gradients, clip-path, mask-image,
    border-radius sculpting, transforms, blend modes). NO external
    images ever, NO emoji as art (§2.5). Then ONE ENTRY PER EMPTY STATE
    named in the PRD/feature specs, each with: >=3 shapes, >=2 palette
    colors, >=96px tall, a headline, one supporting line, one CTA.
    Also spec the key moments (first run, success, error, goal/streak
    completion) even where they are not mocked. BANNED: centered grey
    text alone, a lone emoji, a stock outline icon at 10% opacity, a
    bare circle with a plus. Every size and color you name is a token.
  - ## Data personality — DESIGN-CRAFT §3.7. How THIS app draws counts,
    progress and status BEYOND plain numbers. Pick a form per data kind
    you actually have: ratio/completion → ring, radial arc or filled
    meter; series over time → sparkline, column strip or dot plot;
    count → badge, dot cluster or stacked chip; state → pill with shape
    + color + text (never color alone, colorblind rule); rank →
    segmented bar or ladder. Spec AT LEAST TWO distinct forms in
    CSS/SVG, on palette colors, sized in tokens, and name which PRD
    screens carry them. A screen whose only quantitative content is
    plain text numbers is a step 8.5 defect.
  - ## Components — a spec for EACH of: buttons (primary, secondary,
    ghost, disabled), cards, inputs (field + label + error state), nav
    (matching the platform: tab bar / top bar / side nav), lists (row
    anatomy, leading/trailing elements), empty states (layout, copy
    tone, CTA — the ART DIRECTION lives in ## Illustration & empty
    states; do not duplicate it here). Each spec: anatomy, sizing in
    tokens, states, one do/don't pair.

  Every component spec MUST be expressible with your tokens alone — if a
  spec needs a value no token provides, add the token. THE RECIPROCAL IS
  THE HARD RULE OF THIS STEP: do not document craft you did not
  tokenize. The first run's systems described five illustrated empty
  states, a 50-line motion contract and a three-level tinted elevation
  ramp, and shipped tokens.css files whose --empty-* tokens were
  referenced by zero mockups, whose transitions numbered zero, and one
  of whose --shadow-1 was literally `none`. Before you return, walk your
  own md and confirm every named px / hex / ms / easing / shape value
  exists as a token, and that every craft claim is something step 8
  could build with your tokens and nothing else.

  Do NOT copy the research doc's prose wholesale; the design system is
  decisions, not survey. Do NOT emit lorem ipsum or TBD anywhere.
```

### Step 7.3 — Wait discipline

**CRITICAL: never emit bare text while the 3 authors are running.** Append thoughts to `runs/<run_tag>/temp/orchestrator-notes.md` instead: which screens will stress each system, what step 8's smiths should double-check, likely dark-mode trouble spots. One progress check per minute max.

### Step 7.4 — Validate mechanically

When all 3 return, run these checks per letter (a, b, c):

1. Both files exist: `runs/<run_tag>/designs/<letter>/design-system.md` and `runs/<run_tag>/designs/<letter>/tokens.css`.
2. Token contract: for every name in the step 7.1 list, `grep -c -- "<token-name>" runs/<run_tag>/designs/<letter>/tokens.css` ≥ 1. Every miss is a defect.
3. Dark palette: `grep -c 'data-theme="dark"' tokens.css` ≥ 1 AND `grep -c 'prefers-color-scheme' tokens.css` ≥ 1.
4. Three-layer structure: `grep -ci 'primitive' tokens.css` ≥ 1 AND `grep -ci 'semantic' tokens.css` ≥ 1 AND `grep -ci 'component' tokens.css` ≥ 1 (the layer comment headers), plus at least one canonical token resolving via `var()` to a primitive — UNLESS the file's top comment cites the research doc's contrary commitment.
5. **Required H2s.** design-system.md contains all ELEVEN required headings, literally. Run it:

   ```bash
   D=runs/<run_tag>/designs/<letter>/design-system.md
   for h in "## Principles" "## Signature element" "## Typography" \
            "## Color" "## Spacing" "## Shape language" "## Depth model" \
            "## Motion" "## Illustration & empty states" \
            "## Data personality" "## Components"; do
     [ "$(grep -Fc "$h" "$D")" -ge 1 ] || echo "MISSING: $h"
   done
   ```

   A near-miss heading (`## Elevation`, `## Type scale`, `## Radii & shape`) counts as MISSING — those are the pre-craft-bar names and the author was given the new list. Also confirm `## Components` still covers all six component families.
6. **Craft tokens.** The name contract passed in the first run and the screens were still flat; these check the VALUES. On `tokens.css`:
   - **Radius rhythm:** `--radius-sm`, `--radius-md`, `--radius-lg`, `--radius-full` resolve to at least THREE distinct values. One value reused is a defect (DESIGN-CRAFT §2.7).
   - **Two faces:** `--font-family-display` and `--font-family-body` resolve to DIFFERENT first families — at least 2 distinct font families in the file. Resolve one `var()` hop if they alias primitives. Both resolving to `-apple-system`/`system-ui` is a defect (§3.2).
   - **Two elevation levels:** EITHER `--shadow-2` and `--shadow-3` are both non-`none` and each carries ≥2 comma-separated layers in a palette hue, OR — only if `## Depth model` names the borderless model — `--color-bg`, `--color-surface`, `--color-surface-raised` are three distinct values. `grep -Ec 'rgba\( *0, *0, *0' tokens.css` should be 0: a lone black shadow is a defect (§3.3).
   - **Signature tokens:** `grep -c -- '--signature-' tokens.css` ≥ 1.
   - **Motion:** `--motion-fast/base/slow` are three distinct durations and `--easing-standard` ≠ `--easing-emphasized`.
7. **Documented ⇒ tokenized.** No craft section may describe values it did not tokenize (the first run's core failure). Confirm each of these sections cites at least one `--token` name in its own body: `## Signature element` (a `--signature-*`), `## Typography` (`--font-*` / `--tracking-*`), `## Depth model` (`--shadow-*` or the surface ladder), `## Motion` (`--motion-*` and `--easing-*`), `## Illustration & empty states`, `## Data personality`. A section with prose and no tokens is a defect even if it reads beautifully.
8. **The direction's identity survived (research doc ⇒ design system).** Step 6 committed each direction to six axis answers, a signature-element candidate, reference points, and a rejects list; without this check none of it has an enforced consumer and the three systems are free to converge. Read `research/design/<direction-slug>.md` side by side with the design system and confirm, naming the quote on each side:
   - **Signature element traces.** `design-system.md`'s `## Signature element` (and the `signature_element` frontmatter key) is the research doc's `## Signature element` device — same device, now specced. A different device is legal ONLY if the section states the departure and justifies it; a device that appears in neither doc's subject matter ("rounded corners", the accent colour, a logo) is a defect.
   - **All six axes honored.** For each axis in the research doc's `## Visual language`, the matching design-system section delivers that answer: type personality → `## Typography` (the family pairing and scale), depth model → `## Depth model` (the named model must be the axis's model, and match the `depth_model` frontmatter enum), shape language → `## Shape language` (the radius rhythm and the named shape move), colour strategy → `## Color` (where colour comes from and what it is for), density → `## Spacing` + the component sizing, data & status form → `## Data personality` (its ≥2 drawn forms). A silently swapped axis — a "crisp offset" direction shipping layered shadows, a "radial ring + segmented bar" direction shipping status pills only — is a defect even when the section is well written.
   - **Nothing on the rejects list shipped.** Grep the system for each item in `## What this direction rejects`; a rejected face, hue family, container vocabulary, or cliché appearing in the tokens is a defect.

Failures: re-spawn the offending author ONCE with the exact failed checks named, quoting its own `## Commitments`, the axis answer or signature device it dropped (check 8), and the DESIGN-CRAFT §§ it missed. If a MECHANICAL gap survives twice (a renamed token, a missing dark block, an absent H2), fix it yourself via Edit and log the patch in `runs/<run_tag>/temp/orchestrator-notes.md`. If a CRAFT gap survives twice (checks 6–8), do NOT invent the design from the orchestrator seat — log it in `runs/<run_tag>/temp/orchestrator-notes.md` as a named defect for step 8.5 and surface it at the design gate.

### Step 7.5 — The ANTI-SAMENESS check (cross-letter)

Three directions must feel like three different products, not three color swaps of one (DESIGN-CRAFT §1, §2.12). The first run's only distinctness gate compared `--color-primary` and `--radius-md`, and the output differed on exactly those two things. Compare the three systems on THREE axes, reading the frontmatter each author wrote:

| Axis | Where it comes from | Two systems SHARE it when |
|---|---|---|
| Type strategy | `type_strategy` frontmatter + `--font-family-display` | the display faces are the same family, or the same category (serif/serif, geometric-sans/geometric-sans) AND `--font-size-3xl` differs by < 6px |
| Depth model | `depth_model` frontmatter + `## Depth model`'s first line | the enum value is identical (`layered-tinted` = `layered-tinted`) |
| Palette temperature | `palette_hue` frontmatter + `--color-primary` | the accent hues are within 30° of each other, or both read as the same temperature word |

**Trigger:** any PAIR that shares ALL THREE axes fails. (Sharing one or two is fine — directions are allowed to agree on something.)

**Action:** pick the WEAKER system of the pair — the one that honored fewer lines of its own research doc's `## Commitments`, or, if that is a tie, the one whose `## Signature element` is less specific to this app's subject — and re-spawn its author ONCE with an EXPLICIT DIVERGENCE INSTRUCTION: name the letter it collided with, name which of the three axes it must move, and state the target ("your direction's Commitments call for X; direction `<other>` already occupies layered-tinted depth with a cool accent, so you must deliver the crisp-offset model and shift the accent past 60° of separation"). Do not merely ask it to "be more distinct".

Mechanical companion, run alongside: the three `--color-primary` values and the three `--radius-md` values must all differ. If they don't, the author drifted off its direction — same re-spawn, with its `## Commitments` quoted back.

**Re-spawn budget: ONE per author for the whole step.** If 7.4 already re-spawned a letter, fold 7.5's divergence instruction into that same re-spawn prompt rather than spending a second. If the collision survives the one re-spawn, log it as a named defect in `runs/<run_tag>/temp/orchestrator-notes.md` and carry it to the design gate — never resolve it by editing a system's design decisions from the orchestrator seat. Order of operations: run 7.4 for all three letters first, then 7.5, then issue at most three re-spawns in ONE message.

Record the outcome (which pairs were compared, what collided, what was re-spawned) in `runs/<run_tag>/temp/orchestrator-notes.md`; step 8.5's distinctness pass reads it.

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
signature_element: <the device's name>
type_strategy: <display family> + <body family> (<ratio> scale, ceiling <N>px)
depth_model: layered-tinted | borderless-tinted | crisp-offset
palette_hue: accent <N>deg <warm|cool|neutral-warm|neutral-cool>, neutrals <N>deg
---
```

The last four keys exist so step 7.5's anti-sameness check can be run mechanically instead of by vibe.

## Exit criteria

- All 6 files exist (3 × design-system.md, 3 × tokens.css)
- Every tokens.css defines every canonical token name, with a light `:root` palette and dark overrides via both `[data-theme="dark"]` and `prefers-color-scheme`
- Every tokens.css shows the three-layer structure — primitive (raw values) → semantic (purpose aliases) → component (component-scoped vars) — or carries a top-of-file comment citing the research doc's contrary commitment (step 7.4 check 4 passed)
- Every design-system.md has all ELEVEN required sections (7.4 check 5); `## Components` covers buttons, cards, inputs, nav, lists, empty states
- Every design-system.md names a signature element with ≥3 screens it must appear on, a display+body pairing of two different faces, a named depth model, a radius rhythm plus one distinctive shape move, per-state illustration art direction, and ≥2 data-personality forms
- Every tokens.css passes the craft-token checks: ≥3 distinct radii, ≥2 font families, ≥2 real elevation levels, ≥1 `--signature-*` token, distinct motion durations (7.4 check 6)
- No craft section documents values it did not tokenize (7.4 check 7)
- Every design system carries its direction's identity forward (7.4 check 8): its `## Signature element` is the research doc's device, all six `## Visual language` axis answers are delivered by their matching sections (`## Typography`, `## Depth model`, `## Shape language`, `## Color`, `## Spacing`, `## Data personality`), and nothing on the direction's `## What this direction rejects` list shipped
- Each design-system.md states WCAG AA contrast for the required pairs in both modes
- The three systems are visibly distinct: no pair shares type strategy AND depth model AND palette temperature (step 7.5 passed)
- Then update manifest: `steps.7 = "done"`, mark the step-7 todo complete, return to the router.

## Next step

Return to the router (`hyperbuild`). Invoke:

```
Skill(skill: "hyperbuild-8-mockups")
```

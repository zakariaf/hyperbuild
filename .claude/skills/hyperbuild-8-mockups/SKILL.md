---
name: hyperbuild-8-mockups
description: >
  Step 8 of the hyperbuild pipeline — reads the PRD's canonical screen
  inventory, freezes the mockup screen list (every full/partial screen per
  its mockup_feasibility, cap 12 standard / 20 premier), and spawns 3-6
  hb-mockup-smith subagents in parallel, grouped by design, so EVERY
  full/partial screen exists as a self-contained HTML mockup in all 3
  design systems (tokens inlined, REAL PRD content — never lorem ipsum,
  phone-frame wrapper for mobile; partial screens get real chrome over a
  clearly-marked placeholder viewport; none screens get an art-direction
  card per design instead of a mockup). The orchestrator then renders
  screenshots/<screen>.png for every mockup via headless Chrome and
  writes runs/<run_tag>/designs/index.html — a side-by-side iframe
  gallery grouped by screen with design names and jump nav — the page the
  user opens to pick a design at the step 12 gate. Every smith is bound by
  docs/DESIGN-CRAFT.md — the craft contract (signature element, depth
  model, shape language, type pairing, CSS-drawn art) plus the layout
  integrity rules — and returns a numbered self-check; after rendering,
  the orchestrator runs a MECHANICAL screenshot sanity pass and hands
  suspect renders to step 8.5 (design/visual QA). Flips feature specs
  from specced to designed. Invoked by the hyperbuild router via Skill();
  not run directly by users.
---

# Step 8 — Mockups (parallel, 3–6 smiths, every full/partial screen × 3 designs)

You are executing step 8 (mockups) of the hyperbuild pipeline. Step 7 produced three complete design systems with a shared token contract. Step 9 (skill research) runs CONCURRENTLY with you as the 8 ∥ 9 pair — the router drives both steps' spawn waves in the same block; you share no inputs with it. Your successor for gating purposes is unchanged: step 12 will verify every `full`/`partial` inventory screen exists in all three designs (plus an art-direction card per design for every `none` screen and a screenshot per mockup) and then show the user your `designs/index.html` gallery — the single human checkpoint of the whole pipeline rides on this step's output; step 11 needs your gallery only at gate time.

**Goal:** for EVERY `full`/`partial` screen in the frozen inventory × each of the 3 designs, a self-contained HTML mockup at `runs/<run_tag>/designs/<letter>/mockups/<screen-slug>.html`; an art-direction card in each design's design-system.md for every `none` screen; a headless-Chrome render at `runs/<run_tag>/designs/<letter>/screenshots/<screen-slug>.png` for every mockup; plus the comparison gallery `runs/<run_tag>/designs/index.html`.

**⚠ THE MOCKUPS ARE WHERE THE CRAFT EITHER SHIPS OR DIES.** `docs/DESIGN-CRAFT.md` is BINDING on this step: step 7's design systems commit to a signature element, a depth model, a shape language, a type pairing, and CSS-drawn empty-state art — a mockup that renders those commitments as flat cards with hairline borders is a DEFECT, not a simplification. The first real run shipped exactly that, plus clipped text ("12d lef"), a FAB parked on top of list rows, and screens sliced mid-glyph by the nav bar. Every smith READS `docs/DESIGN-CRAFT.md` before writing HTML, implements its §3 commitments, obeys its §4 layout integrity rules, and reports its §5 self-check item by item. Step 8.5 (design/visual QA) runs after you and grades the pixels.

**⚠ CRITICAL ANTI-PATTERN: LOREM IPSUM IS A PIPELINE VIOLATION.** The user picks a design by imagining their app in it; filler text makes that impossible and poisons the checkpoint. Every heading, label, list row, and empty-state line comes from the PRD, the feature specs, and the personas — real feature names, realistic domain data ("Morning run — 12-day streak", not "Item 1"). **If you find yourself, or a smith reports itself, writing "lorem", "placeholder", or "Sample text", STOP and fix it before the gallery is written.** Also: do NOT build mockups yourself in the orchestrator — spawn the smiths.

## Inputs

Active run: `<run_tag>` from router context. If lost, recover it: the `runs/*/manifest.json` whose `stage` is PLAN and `steps.7` is `done`.

Read these before anything else:
- `docs/DESIGN-CRAFT.md` — the BINDING craft bar: §2 anti-patterns, §3 the eight design-system commitments the mockups must express, §4 layout integrity rules, §5 the per-mockup self-check. You paste §3/§4/§5 obligations into every smith brief and grade the returns against them.
- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL.
- `runs/<run_tag>/manifest.json` — `gear` (standard | premier), `platform`
- `research/product-spec.md` — the PRD; its **screen inventory is the canonical screen list** this step keys off — including each screen's `mockup_feasibility` (`full` | `partial` | `none`)
- `features/00-index.md` — feature id ↔ screens mapping (which features give each screen its content)
- `runs/<run_tag>/designs/directions.md` — letter↔name mapping for smith briefs and gallery labels
- `runs/<run_tag>/designs/<letter>/design-system.md` + `tokens.css` for a, b, c (step 7)
- `runs/<run_tag>/decisions/platform.md` — mobile → phone-frame wrapper; web/desktop → responsive page

## Procedure

**Numbering note:** the sub-steps below (8.1–8.8) are INTERNAL to this skill. They are not the pipeline's step 8.5 (design/visual QA), which is a separate skill that runs after this one and may send patch instructions back to your smiths.

### Step 8.1 — Freeze the screen list

1. Extract the screen inventory from `research/product-spec.md`, verbatim names, including each screen's `mockup_feasibility` (`full` | `partial` | `none`). Only `full` and `partial` screens enter the mockup list. `none` screens (pure engine-rendered) go on a separate art-direction list — they get NO mockup, ever; each design's design-system.md gains an art-direction card for them instead (assigned in step 8.3).
2. Apply the cap: **every `full`/`partial` PRD screen, cap 12 (standard) / cap 20 (premier)**. If the inventory exceeds the cap, keep screens in this priority order: screens referenced by `must` features, then `should` features, then core navigation surfaces (home/main list, detail, settings). Log every dropped screen.
3. Slug each screen: kebab-case of its inventory name ("Habit Detail" → `habit-detail`). **Slugs are IDENTICAL across all three designs** — the gallery pairs mockups by slug.
4. For each screen, list the feature ids that touch it (from `features/00-index.md`) — the smiths read those feature specs for flows, states, and real content.
5. Write the frozen list to `runs/<run_tag>/temp/mockup-screens.md`:

```markdown
# Frozen mockup screens — <run_tag> (gear: <standard|premier>, cap <12|20>)

| # | Screen | Slug | Feasibility | Features | Smith batch |
|---|--------|------|-------------|----------|-------------|
| 1 | Home | home | full | F-01, F-03 | 1 of 2 |
| 4 | Race HUD | race-hud | partial — HUD + pause menu mockable; 3D viewport is placeholder | F-02 | 1 of 2 |
...

## None screens (art-direction cards, NO mockups)
- <screen> — <the PRD's one-line reason it is engine-rendered> (none if inventory has no `none` screens)

## Dropped by cap
- <screen> — <why it lost priority> (none if inventory ≤ cap)
```

This frozen list is what step 12's gate verifies against. Do not let smiths add or drop screens.

### Step 8.2 — Plan the fan-out (3–6 smiths, grouped by design)

Let S = frozen screen count. **Never mix designs inside one smith** — each smith internalizes exactly ONE token set; mixing designs produces cross-contaminated styling. Never split one screen across smiths.

- **S ≤ 6:** spawn 3 smiths — one per design, each builds all S screens in its design.
- **S ≥ 7:** spawn 6 smiths — two per design; split each design's screens into batch 1 (screens 1..⌈S/2⌉) and batch 2 (the rest), same split for all three designs.

Record the batch assignment in the `Smith batch` column of `temp/mockup-screens.md`.

If the inventory has `none` screens, assign ALL of a design's art-direction cards to exactly ONE smith of that design (the batch-1 smith when split) — two smiths appending cards to the same design-system.md is a write conflict.

### Step 8.3 — Spawn all smiths in ONE message

**Spawn all 3–6 `hb-mockup-smith` subagents in ONE message — true parallel execution.** Zero overlap: each smith gets ONLY its design letter and its screen batch.

**Spawn template (fill one per smith):**

```
subagent_type: hb-mockup-smith
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 8 (mockups) of the hyperbuild pipeline.
  Step 7 produced your design's design-system.md + tokens.css; you build
  the HTML mockups for YOUR screen batch in YOUR design only. After all
  smiths return, the orchestrator writes designs/index.html, and at the
  step 12 gate the user compares all three designs side by side and picks
  one — your mockups ARE the product the user judges. You are tool-locked
  to [Read, Write]. You do not design the system (step 7 did), do not
  invent screens, and do not touch other designs' directories.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - design_letter: <a|b|c>
  - design_name: "<Name>"
  - tokens_file: runs/<run_tag>/designs/<letter>/tokens.css
  - design_system: runs/<run_tag>/designs/<letter>/design-system.md
  - screens: [<"Screen Name" (slug: <slug>, feasibility: full|partial —
    partial entries include the inventory's what-IS-mockable note,
    features: F-NN, F-NN), one entry per assigned screen — exactly as
    frozen, no additions>]
  - art_direction_screens: [<"Screen Name" per `none` inventory screen —
    ONLY for the one smith per design that owns the cards; omit for the
    others>]
  - platform: <mobile|web|desktop> (from decisions/platform.md)
  - output_dir: runs/<run_tag>/designs/<letter>/mockups/
  - output_files: one <slug>.html per assigned screen

  READ FIRST (context files, in this order):
  - docs/DESIGN-CRAFT.md — THE CRAFT BAR, binding on you. Read it whole
    BEFORE any HTML. §2 = banned AI-design tells, §3 = the commitments
    your design system made that you must execute, §4 = layout integrity
    rules, §5 = the self-check you must run and report.
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/designs/<letter>/design-system.md — your ONLY styling
    authority; follow its component specs exactly
  - runs/<run_tag>/designs/<letter>/tokens.css — paste its FULL contents
    verbatim at the top of every mockup's <style> block
  - research/product-spec.md — personas + the sections covering your screens
  - features/NN-<slug>.md for every feature id listed on your screens —
    UX flows, states, and real content live here

  CRAFT CONTRACT (binding — the bar is docs/DESIGN-CRAFT.md):
  - READ docs/DESIGN-CRAFT.md BEFORE writing a single line of HTML.
    Its rules are pass/fail checks, not taste — step 8.5 grades your
    rendered pixels against them.
  - EXECUTE YOUR DESIGN SYSTEM; do not summarize it into rounded
    rectangles. Every screen you build must visibly carry, from
    design-system.md:
      * the SIGNATURE ELEMENT (`## Signature element`) — built to its
        exact CSS recipe, wherever its stated rules of use say it
        belongs. It must appear in ≥3 screens across the direction;
      * the DEPTH MODEL (`## Depth model`) — layered tinted shadow /
        borderless tinted surfaces / crisp offset — applied to EVERY
        surface it governs. A screen that renders as flat white cards
        with 1px hairline borders when the system specifies layered
        tinted elevation is a FAILURE, not a simplification. No lone
        `rgba(0,0,0,.1)`; no shadow on an unelevated element;
      * the SHAPE LANGUAGE — the radius rhythm's assignment rule (≥3
        distinct radii in use), concentric nesting (inner radius = outer
        − padding), and the system's NAMED distinctive shape move
        (asymmetric corners, clip-path notch, diagonal, capsule, masked
        arc) on more than one component;
      * the TYPE PAIRING — `--font-family-display` and
        `--font-family-body` resolving to DIFFERENT real families, each
        ending in a generic fallback (`serif`/`sans-serif`/`monospace`),
        at the system's stated tracking (negative on display, +0.06em…
        +0.12em on all-caps micro-labels) and weights, sizes from the
        scale only, `tabular-nums` on any column of figures.
  - CSS-DRAWN ART IS MANDATORY for every empty state you render: ≥3
    shapes, ≥2 palette colors, ≥96px tall, drawn in CSS/inline SVG, plus
    a headline, one supporting line, and one CTA. Banned empty states:
    centered grey text alone, a lone emoji, a stock outline icon at 10%
    opacity, a bare circle with a plus. No external images, ever.
  - DATA PERSONALITY: wherever a screen shows quantity, progress, or
    status, DRAW it — ring/radial arc/meter, sparkline/column strip/dot
    plot, badge/dot cluster, segmented bar, or a pill carrying shape +
    color + text (status NEVER by color alone) — in CSS/SVG from palette
    colors, sized in tokens, with real numbers from the PRD and feature
    specs. A screen whose only quantitative content is plain text
    numerals FAILS.
  - MOTION IS DECLARED: the primary button and the primary card carry
    real `transition` declarations on the system's `--motion-*` /
    `--easing-*` tokens.
  - Read §2's twelve banned tells by NAME before you report: cream+serif
    +terracotta, near-black + one acid pop, purple→blue gradient hero,
    reflexive Inter/Space Grotesk, emoji-as-icon/bullet/art, everything
    centered, one uniform radius, flat white card + hairline, Material-
    blue/bootstrap palettes, traffic-light as the whole color story,
    lorem/placeholder strings, undifferentiated directions.
  - If the design system is silent or hand-wavy on one of these, build
    the closest thing its tokens support and REPORT the gap by name —
    never fall back to a flat card.

  LAYOUT INTEGRITY RULES (verbatim, docs/DESIGN-CRAFT.md §4 — every one
  of these is a bug the first real run shipped; step 8.5 re-checks them
  against your rendered PNG):
  1. NOTHING CLIPPED. No text, icon, or control cut off at any edge. A
     mobile mockup's screen area is EXACTLY 390×844 CSS px inside the
     frame (page outer size 458×912 with bezel and body padding).
     Content either fits or scrolls DELIBERATELY in the designated
     container — never `overflow: hidden` swallowing real content.
  2. NO ACCIDENTAL OVERLAP. A floating action button MUST NOT cover list
     content: the scroll container gets `padding-bottom` ≥ FAB height +
     24px. Bottom nav bar: content `padding-bottom` ≥ nav height + 16px.
     Both present: the two add. Sticky headers get the same treatment at
     the top.
  3. DELIBERATE TRUNCATION ONLY. Long strings either wrap on a DEFINED
     number of lines (`-webkit-line-clamp` with a stated count) or
     ellipsize with intent (`text-overflow: ellipsis` + `overflow:
     hidden` + `white-space: nowrap`). A half-visible word like
     `12d lef` is a HARD FAIL.
  4. NO HORIZONTAL PAGE SCROLL. Carousels scroll inside their own
     container and show a deliberate peek of the next item.
  5. TAP TARGETS ≥ 44×44 px — icon buttons, tab bar items, chevrons,
     close buttons. Padding counts; visual size may be smaller.
  6. TEXT ≥ 12px, body copy ≥ 15px on mobile. CONTRAST ≥ 4.5:1 for body
     text, ≥ 3:1 for large text (≥18.66px bold / ≥24px) and for
     meaningful icons and UI edges.
  7. CONSISTENT VERTICAL RHYTHM. Every margin, padding, and gap comes
     from `--space-1…--space-8`. One-off pixel values are BANNED except
     hairlines, commented optical nudges ≤2px, and the frame chrome
     itself.
  8. REAL CONTENT EVERYWHERE. Realistic names, quantities, dates,
     streaks, and copy from the PRD, feature specs, and personas. A
     two-row "list" is not a list; show 4–7.
  9. SAFE AREAS. Mobile frames draw a status-bar area at top (~44–54px,
     time and indicators styled per the design, never an image) and
     home-indicator space at bottom (~34px). Content never sits under
     either.
  10. ALIGNMENT DISCIPLINE. One content gutter per screen; section edges
      line up. Mixed 16/20/24px gutters on one screen is a defect.
  11. DARK MODE HOLDS. Where a dark palette exists, the mockup renders
      correctly under `[data-theme="dark"]` — no invisible text, no
      white cards.

  MOCKUP RULES (each rule is load-bearing):
  - SELF-CONTAINED: one .html file per screen; ALL CSS inline in a single
    <style> block starting with the verbatim tokens.css; no external
    requests of any kind — no CDN fonts, no remote images, no @import.
    Fonts: use the design system's declared display + body families —
    real faces present on the render host per DESIGN-CRAFT §3.2's table,
    each stack ending in a generic fallback, the two resolving to
    DIFFERENT families. Draw every icon and illustration as inline SVG
    or CSS shapes — NEVER an emoji, never an image file.
  - TOKENS ONLY: component CSS uses var(--token) references from the
    canonical contract; hard-coded colors/sizes only where the design
    system explicitly specifies one.
  - REAL CONTENT — NEVER LOREM IPSUM: every string comes from the PRD,
    the feature specs, or plausible persona data. Realistic counts,
    names, dates, and numbers. If a feature spec is thin, derive content
    from the PRD personas and say so in your report-back.
  - STATES: render each screen's primary populated state. Where the
    feature spec defines an empty state for a screen that starts empty
    (first run), render the empty state as specified instead — built
    with the design system's own empty-state illustration as CSS/SVG art
    per the craft contract (≥3 shapes, ≥2 palette colors, ≥96px, plus
    headline + support line + CTA), never a bare icon in a grey disc.
  - PARTIAL SCREENS (feasibility: partial): build the REAL chrome — HUD,
    overlays, menus, controls — token-faithfully per the design system,
    over a clearly-marked placeholder viewport: a token-styled panel
    visibly labeled with what the engine renders there (e.g. "3D track
    viewport — engine-rendered"). Mock ONLY what the inventory's note
    says is mockable; never fake the engine/camera/map/canvas content
    itself.
  - NONE SCREENS GET NO MOCKUP: never write an .html for a screen
    classified `none`. If art_direction_screens is non-empty, APPEND to
    runs/<run_tag>/designs/<letter>/design-system.md one card per listed
    screen under `## Art direction — <Screen Name>`: mood (2–3
    sentences), applied palette (which of YOUR tokens carry the scene),
    HUD typography, and reference language (named visual references).
    This append is the ONLY design-system.md edit you may make.
  - NAV CHROME: every screen includes its navigation chrome (tab bar /
    top bar / side nav) per the design system's nav spec, with the
    current screen marked active. IDENTICAL across your whole batch —
    one nav component, one destination set, one icon set, one status-bar
    treatment, one FAB placement, exactly as the nav spec fixes them.
    Divergence between two of your own screens is a defect. And NO app
    tab bar on onboarding, modal/add-edit, or full-screen camera routes.
  - PHONE FRAME (mobile platform only): wrap every screen in the frame
    skeleton below. Web/desktop: full responsive page, content in a
    max-width container per the design system.

  Phone-frame skeleton (mobile) — the 390×844 box is your ENTIRE canvas;
  the capture shows nothing below it, so a screen either FITS or ends on
  a deliberate, fully-rendered final row. Fixed nav/FAB are SIBLINGS of
  the scroller, never overlays on top of it, and the scroller pays for
  them in padding (layout rule 2):
    <style>
    /* === tokens.css (design <letter> — <Name>) pasted verbatim === */
    :root { ... } [data-theme="dark"] { ... }
    /* frame chrome — the only place one-off px values are allowed */
    body { margin:0; display:flex; justify-content:center; padding:24px;
           background:#e9e9ee; }
    .phone { width:390px; height:844px; border-radius:48px;
             border:10px solid #111; overflow:hidden;
             background:var(--color-bg); }
    .screen { height:100%; display:flex; flex-direction:column;
              position:relative;              /* FAB anchors HERE */
              font-family:var(--font-family-body);
              color:var(--color-text); }
    .statusbar { flex:0 0 auto; height:54px; }  /* safe area, STYLED */
    .content   { flex:1 1 auto; overflow-y:auto;
                 /* rule 2 arithmetic — recompute from YOUR sizes and
                    state the sum in a comment, e.g.
                    FAB 56 + 24 + nav 64 + 16 = 160px */
                 padding-bottom:160px; }
    .navbar    { flex:0 0 auto; }               /* bottom nav, in flow */
    .homebar   { flex:0 0 auto; height:34px; }  /* home indicator */
    </style>
    <body><div class="phone"><div class="screen">
      <div class="statusbar">…</div>
      <div class="content"><!-- the app UI --></div>
      <!-- FAB (if any): position:absolute, bottom offset ABOVE .navbar -->
      <div class="navbar">…</div>
      <div class="homebar"></div>
    </div></div></body>

  SELF-CHECK BEFORE YOU REPORT (mandatory, not optional): run
  docs/DESIGN-CRAFT.md §5 literally, in order, all 25 numbered items, for
  EVERY file you wrote. Fix each failure before reporting. Your
  report-back MUST carry one line per file stating pass/fail per numbered
  item, e.g. `home.html: 1–13 pass | 14 FIXED (FAB pad was 56px, now
  160px) | 15–25 pass`. Item 25 ("would you screenshot this and send it
  to someone?") is answered honestly in words. A mockup with an unpassed
  item is NOT done; a report without the numbered self-check is an
  incomplete deliverable and gets re-spawned.

  Report back: the list of files you wrote, per-screen one-liners of what
  state you rendered, the §5 self-check lines (one per file), how each
  screen carries the signature element / depth model / shape move / data
  personality form, art-direction cards appended (if assigned), any
  screen where spec content was thin and what you used instead, and any
  design-system commitment you could not implement and why. Data, not
  prose. Do NOT write index.html — the orchestrator owns the gallery.
```

### Step 8.4 — Wait discipline

**CRITICAL: never emit bare text while smiths are running.** Append to `runs/<run_tag>/temp/orchestrator-notes.md`: gallery ordering (which screen first sells the app), design-name labels, anything a smith's report flags. One progress check per minute max.

### Step 8.5 — Validate the full matrix (internal sub-step, NOT the pipeline's step 8.5 QA)

1. **Existence matrix:** for every slug in `temp/mockup-screens.md` and every letter in {a, b, c}, `runs/<run_tag>/designs/<letter>/mockups/<slug>.html` exists. `ls runs/<run_tag>/designs/*/mockups/ | sort` and diff against the frozen list.
2. **Filler scan:** `grep -ril "lorem" runs/<run_tag>/designs/` MUST return nothing. Also grep for `TODO` and `placeholder`.
3. **Self-containment scan:** `grep -rilE 'src="https?://|href="https?://.*\.(css|js)|@import|fonts\.googleapis' runs/<run_tag>/designs/*/mockups/` MUST return nothing — no mockup loads an external resource.
4. **Art-direction cards** (only when the inventory has `none` screens): for each letter, `grep -c "^## Art direction — " runs/<run_tag>/designs/<letter>/design-system.md` equals the `none`-screen count, and each listed screen has its card.
5. **Craft-return check.** Every smith's report must contain the DESIGN-CRAFT §5 self-check, per file, item by item. A report without it = re-spawn that smith ONCE asking only for the self-check plus fixes for whatever it fails. Back it with three cheap greps per mockup dir (all are craft smoke tests, not proof):
   - `grep -c "transition:" <mockups>/*.html` — 0 means the motion commitment was never implemented;
   - `grep -o -- "--font-family-display[^;]*" <letter>/tokens.css` vs `--font-family-body` — if they resolve to the same family, flag it for step 8.5;
   - `perl -ne 'print "$ARGV:$.: $_" if /[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}\x{FE0F}]/' <mockups>/*.html` (portable on macOS, unlike `grep -P`) — emoji used as icon/bullet/art is a DESIGN-CRAFT §2.5 violation; re-spawn to replace with inline SVG.
   Record every flag in `temp/orchestrator-notes.md` under `## Craft flags` — step 8.5 consumes that list.
6. Any missing file, missing card, or failed scan: re-spawn ONLY the responsible smith ONCE, naming the exact missing slugs / offending files. If it fails twice, log it, patch trivial defects yourself via Edit, and continue — but the existence matrix must be complete before step 8.6; the step 12 gate re-checks it.

### Step 8.6 — Render screenshots (orchestrator work)

AFTER all smiths have returned and the existence matrix is complete, render `runs/<run_tag>/designs/<letter>/screenshots/<slug>.png` for EVERY mockup — step 14 implementers and the step 15 hb-ux-critic consume these renders as the visual spec.

1. Find a Chrome binary — try, in order: `google-chrome`, `chromium`, `"Google Chrome"` (`command -v google-chrome || command -v chromium`, then the macOS path `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`).
2. For each letter × frozen slug, run (ABSOLUTE paths only — `file://` does not resolve relative paths):

   ```bash
   mkdir -p <abs-run>/designs/<letter>/screenshots
   "<chrome>" --headless=new \
     --screenshot=<abs-run>/designs/<letter>/screenshots/<slug>.png \
     --window-size=458,912 --hide-scrollbars \
     file://<abs-run>/designs/<letter>/mockups/<slug>.html
   ```

   `--window-size=458,912` for mobile platforms — the phone-frame page's REAL outer size (390px screen + 2×10px bezel border + 2×24px body padding = 458 wide; 844 + 20 + 48 = 912 tall), so the capture includes the entire frame with nothing clipped; desktop/web platforms use a desktop viewport such as `--window-size=1440,900` (per `decisions/platform.md`).
3. Verify one non-empty `.png` per mockup (`find runs/<run_tag>/designs/*/screenshots -name '*.png' -size +0` counted against the frozen list × 3). Re-run any failure ONCE; log persistent failures to `temp/orchestrator-notes.md`.
4. **MECHANICAL SCREENSHOT SANITY PASS — do not skip, do not delegate.** A render that EXISTS is not a render that is CORRECT: the first real run shipped clipped text ("12d lef"), a FAB parked on top of list rows, and rows sliced mid-glyph by the nav, and nobody in the pipeline ever looked at a pixel. Two checks, in order:

   a. **Size check (every PNG).** `find runs/<run_tag>/designs/*/screenshots -name '*.png' -size -8k` MUST return nothing. A file under 8KB is a blank, all-one-color, or failed render — re-render it ONCE; if it stays under 8KB, treat that mockup as broken, log it, and hand it to step 8.5.
   b. **Eyes check (≥3 screenshots per design, ≥9 total).** Pick, per letter: the home/primary screen, the longest-list screen, and any screen carrying a FAB, bottom sheet, or a form's primary CTA (the three shapes every first-run bug had). **Open each with `Read` and actually LOOK at the image.** For each viewed file confirm, naming the file:
      - no text, icon, or control cut off at any of the four frame edges;
      - no floating element (FAB, sheet, snackbar) covering a row, label, or CTA;
      - no half-word truncation — an ellipsis is fine, `12d lef` is not;
      - no row sliced mid-glyph where content meets the bottom nav / frame edge;
      - no chip or carousel item hard-cut at the bezel;
      - status-bar and home-indicator safe areas present, nothing under them;
      - the screen reads as its design system, not as flat cards on a hairline grid.

   Log a per-file verdict line in `temp/orchestrator-notes.md`. ANYTHING suspicious — including anything you are merely unsure about — goes under `## Suspect renders` there with letter, slug, and the symptom in one line. Do NOT restyle mockups yourself and do NOT re-spawn smiths for craft defects at this point: **step 8.5 (design/visual QA) views every screenshot and owns the patch loop.** Your job here is to catch the obvious and hand over an honest list; missing screenshots or a broken file are still yours to re-render.
5. **No Chrome binary found → do NOT fail the step.** Update `runs/<run_tag>/manifest.json` with `"screenshots_skipped": true` (read, modify, Write back whole), note the warning in `temp/orchestrator-notes.md`, and continue. Missing screenshots are a step 12 design-gate WARNING, not a hard fail, when the manifest carries this flag. Say plainly in the notes that the sanity pass could not run and that step 8.5 will have to QA the HTML sources instead of renders — an unrendered run reaches the user with its layout unverified.

### Step 8.7 — Write the gallery (orchestrator work)

Write `runs/<run_tag>/designs/index.html` yourself. It lives next to the `a/ b/ c/` dirs, so iframe paths are relative (`a/mockups/<slug>.html`). Requirements: grouped by SCREEN (one section per screen, three iframes side by side), design names from `directions.md` as column labels, jump nav linking every screen section. Skeleton:

```html
<!doctype html><html><head><meta charset="utf-8">
<title><App name> — design gallery (<run_tag>)</title>
<style>
  body{margin:0;font-family:system-ui;background:#f4f4f6;color:#111}
  header{padding:16px 24px}
  nav.jump{position:sticky;top:0;background:#fff;border-bottom:1px solid #ddd;
    padding:8px 24px;display:flex;gap:12px;flex-wrap:wrap}
  section{padding:24px}
  .row{display:flex;gap:16px;overflow-x:auto}
  figure{margin:0}
  figcaption{font-weight:600;padding:4px 0}
  /* mobile: frame pages are 458x912 incl. bezel; scale to fit */
  iframe{width:458px;height:912px;border:0;transform:scale(.55);
    transform-origin:top left}
  .frame-box{width:252px;height:502px;overflow:hidden}
  /* web/desktop variant: iframe{width:1280px;height:800px;
     transform:scale(.35)} .frame-box{width:448px;height:280px} */
</style></head><body>
<header><h1><App name> — pick a design</h1>
<p>Run /hyperbuild-choose a|b|c after comparing.</p></header>
<nav class="jump"><a href="#s-home">Home</a><a href="#s-habit-detail">Habit Detail</a><!-- every screen --></nav>
<section id="s-<slug>"><h2><Screen Name></h2>
  <div class="row">
    <figure><figcaption>a — <Name A></figcaption>
      <div class="frame-box"><iframe src="a/mockups/<slug>.html" loading="lazy"></iframe></div></figure>
    <figure><figcaption>b — <Name B></figcaption>
      <div class="frame-box"><iframe src="b/mockups/<slug>.html" loading="lazy"></iframe></div></figure>
    <figure><figcaption>c — <Name C></figcaption>
      <div class="frame-box"><iframe src="c/mockups/<slug>.html" loading="lazy"></iframe></div></figure>
  </div>
</section>
<!-- repeat per screen, in the frozen-list order -->
</body></html>
```

Verify every frozen slug appears in both the jump nav and a section, and every iframe `src` resolves to an existing file.

### Step 8.8 — Flip feature statuses

For every feature in `features/00-index.md` whose `screens:` all appear in the frozen mockup list (a `none` screen counts as covered by its art-direction cards), Edit its `features/NN-<slug>.md` frontmatter `status: specced` → `status: designed`. Features with a screen dropped by the cap stay `specced` — list them in `runs/<run_tag>/temp/orchestrator-notes.md` so the step 12 report can mention them.

## Artifacts

- `runs/<run_tag>/temp/mockup-screens.md` — frozen screen list (format above)
- `runs/<run_tag>/designs/<letter>/mockups/<screen-slug>.html` — every frozen (`full`/`partial`) screen × {a, b, c}
- `runs/<run_tag>/designs/<letter>/screenshots/<screen-slug>.png` — headless-Chrome render of every mockup (absent only when manifest `screenshots_skipped: true`)
- Appended `## Art direction — <Screen>` cards in each `designs/<letter>/design-system.md` (only when the inventory has `none` screens)
- `runs/<run_tag>/designs/index.html` — the comparison gallery
- Edited `features/NN-<slug>.md` frontmatter (`status: designed`)
- `runs/<run_tag>/temp/orchestrator-notes.md` — with `## Craft flags` (grep flags from the validation pass) and `## Suspect renders` (screenshot sanity-pass findings): the hand-off list step 8.5 consumes

## Exit criteria

- `temp/mockup-screens.md` exists; mockable screen count ≤ 12 (standard) / ≤ 20 (premier); `none` screens listed in their own section; dropped screens logged
- Existence matrix complete: every frozen slug × all 3 letters on disk
- Every `none` inventory screen has its `## Art direction — <Screen>` card in all three designs' design-system.md
- Every smith brief carried the CRAFT CONTRACT (citing `docs/DESIGN-CRAFT.md`) and the LAYOUT INTEGRITY RULES verbatim, and every smith returned the DESIGN-CRAFT §5 self-check per file, item by item — reports without it were re-spawned once
- Craft flags recorded: `transition:` count > 0 per design's mockups; display ≠ body font family; zero emoji used as icon/bullet/art (any exception logged under `## Craft flags` for step 8.5)
- Screenshots: one non-empty `screenshots/<slug>.png` per mockup × all 3 letters, OR manifest carries `screenshots_skipped: true`
- Screenshot sanity pass done and logged: no PNG under 8KB; ≥3 screenshots per design (≥9 total) opened with `Read` and judged against the clipping/overlap/truncation/safe-area list; every suspicion written under `## Suspect renders`
- `grep -ril "lorem"` over `runs/<run_tag>/designs/` returns nothing; external-resource scan returns nothing
- `runs/<run_tag>/designs/index.html` exists, has jump nav + one section per frozen screen, three labeled iframes each, all srcs resolving
- Every fully-mocked feature's status flipped to `designed`
- Then update manifest: `steps.8 = "done"`, mark the step-8 todo complete, return to the router.

**Step 8 "done" is a completeness verdict, not a craft verdict.** Step 8.5 (design/visual QA) runs next on this step's output: it views every rendered screenshot against `docs/DESIGN-CRAFT.md`, and it may send patch instructions back to `hb-mockup-smith` for the offending screens. Mockups are only final once 8.5 passes — never present the gallery to the user as finished before then.

## Next step

Return to the router (`hyperbuild`). **Pipeline step 8.5 (design/visual QA) runs on your output next** — it reads `temp/orchestrator-notes.md` (`## Craft flags`, `## Suspect renders`), views the screenshots against `docs/DESIGN-CRAFT.md`, and issues patch instructions back to `hb-mockup-smith` for any screen that fails; a re-patched screen is re-rendered and re-checked. It does NOT wait on step 9. The next call is:

```
Skill(skill: "hyperbuild-8-5-visual-qa")
```

(Not to be confused with this skill's INTERNAL sub-step 8.5, "Validate the full matrix", which already ran above.)

Step 9 (skill research) is your concurrent pair member and may already be running or done. Only once step 8.5 has passed AND step 9 is done does the router invoke:

```
Skill(skill: "hyperbuild-10-skill-forge")
```

---
name: appbuilder-8-mockups
description: >
  Step 8 of the appbuilder pipeline — reads the PRD's canonical screen
  inventory, freezes the mockup screen list (every full/partial screen per
  its mockup_feasibility, cap 12 standard / 20 premier), and spawns 3-6
  ab-mockup-smith subagents in parallel, grouped by design, so EVERY
  full/partial screen exists as a self-contained HTML mockup in all 3
  design systems (tokens inlined, REAL PRD content — never lorem ipsum,
  phone-frame wrapper for mobile; partial screens get real chrome over a
  clearly-marked placeholder viewport; none screens get an art-direction
  card per design instead of a mockup). The orchestrator then renders
  screenshots/<screen>.png for every mockup via headless Chrome and
  writes runs/<run_tag>/designs/index.html — a side-by-side iframe
  gallery grouped by screen with design names and jump nav — the page the
  user opens to pick a design at the step 12 gate. Flips feature specs
  from specced to designed. Invoked by the appbuilder router via Skill();
  not run directly by users.
---

# Step 8 — Mockups (parallel, 3–6 smiths, every full/partial screen × 3 designs)

You are executing step 8 (mockups) of the appbuilder pipeline. Step 7 produced three complete design systems with a shared token contract. Step 9 (skill research) runs CONCURRENTLY with you as the 8 ∥ 9 pair — the router drives both steps' spawn waves in the same block; you share no inputs with it. Your successor for gating purposes is unchanged: step 12 will verify every `full`/`partial` inventory screen exists in all three designs (plus an art-direction card per design for every `none` screen and a screenshot per mockup) and then show the user your `designs/index.html` gallery — the single human checkpoint of the whole pipeline rides on this step's output; step 11 needs your gallery only at gate time.

**Goal:** for EVERY `full`/`partial` screen in the frozen inventory × each of the 3 designs, a self-contained HTML mockup at `runs/<run_tag>/designs/<letter>/mockups/<screen-slug>.html`; an art-direction card in each design's design-system.md for every `none` screen; a headless-Chrome render at `runs/<run_tag>/designs/<letter>/screenshots/<screen-slug>.png` for every mockup; plus the comparison gallery `runs/<run_tag>/designs/index.html`.

**⚠ CRITICAL ANTI-PATTERN: LOREM IPSUM IS A PIPELINE VIOLATION.** The user picks a design by imagining their app in it; filler text makes that impossible and poisons the checkpoint. Every heading, label, list row, and empty-state line comes from the PRD, the feature specs, and the personas — real feature names, realistic domain data ("Morning run — 12-day streak", not "Item 1"). **If you find yourself, or a smith reports itself, writing "lorem", "placeholder", or "Sample text", STOP and fix it before the gallery is written.** Also: do NOT build mockups yourself in the orchestrator — spawn the smiths.

## Inputs

Active run: `<run_tag>` from router context. If lost, recover it: the `runs/*/manifest.json` whose `stage` is PLAN and `steps.7` is `done`.

Read these before anything else:
- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL.
- `runs/<run_tag>/manifest.json` — `gear` (standard | premier), `platform`
- `research/product-spec.md` — the PRD; its **screen inventory is the canonical screen list** this step keys off — including each screen's `mockup_feasibility` (`full` | `partial` | `none`)
- `features/00-index.md` — feature id ↔ screens mapping (which features give each screen its content)
- `runs/<run_tag>/designs/directions.md` — letter↔name mapping for smith briefs and gallery labels
- `runs/<run_tag>/designs/<letter>/design-system.md` + `tokens.css` for a, b, c (step 7)
- `runs/<run_tag>/decisions/platform.md` — mobile → phone-frame wrapper; web/desktop → responsive page

## Procedure

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

**Spawn all 3–6 `ab-mockup-smith` subagents in ONE message — true parallel execution.** Zero overlap: each smith gets ONLY its design letter and its screen batch.

**Spawn template (fill one per smith):**

```
subagent_type: ab-mockup-smith
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 8 (mockups) of the appbuilder pipeline.
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
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/designs/<letter>/design-system.md — your ONLY styling
    authority; follow its component specs exactly
  - runs/<run_tag>/designs/<letter>/tokens.css — paste its FULL contents
    verbatim at the top of every mockup's <style> block
  - research/product-spec.md — personas + the sections covering your screens
  - features/NN-<slug>.md for every feature id listed on your screens —
    UX flows, states, and real content live here

  MOCKUP RULES (each rule is load-bearing):
  - SELF-CONTAINED: one .html file per screen; ALL CSS inline in a single
    <style> block starting with the verbatim tokens.css; no external
    requests of any kind — no CDN fonts, no remote images, no @import.
    Use the design system's system-font stacks; draw icons/illustrations
    as inline SVG.
  - TOKENS ONLY: component CSS uses var(--token) references from the
    canonical contract; hard-coded colors/sizes only where the design
    system explicitly specifies one.
  - REAL CONTENT — NEVER LOREM IPSUM: every string comes from the PRD,
    the feature specs, or plausible persona data. Realistic counts,
    names, dates, and numbers. If a feature spec is thin, derive content
    from the PRD personas and say so in your report-back.
  - STATES: render each screen's primary populated state. Where the
    feature spec defines an empty state for a screen that starts empty
    (first run), render the empty state as specified instead.
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
    current screen marked active.
  - PHONE FRAME (mobile platform only): wrap every screen in the frame
    skeleton below. Web/desktop: full responsive page, content in a
    max-width container per the design system.

  Phone-frame skeleton (mobile):
    <style>
    /* === tokens.css (design <letter> — <Name>) pasted verbatim === */
    :root { ... } [data-theme="dark"] { ... }
    /* frame */
    body { margin:0; display:flex; justify-content:center; padding:24px;
           background:#e9e9ee; }
    .phone { width:390px; height:844px; border-radius:48px;
             border:10px solid #111; overflow:hidden;
             background:var(--color-bg); }
    .screen { height:100%; overflow-y:auto;
              font-family:var(--font-family-body);
              color:var(--color-text); }
    </style>
    <body><div class="phone"><div class="screen">
      <!-- status-bar spacer, then the app UI -->
    </div></div></body>

  Report back: the list of files you wrote, per-screen one-liners of what
  state you rendered, art-direction cards appended (if assigned), any
  screen where spec content was thin and what you used instead. Data, not
  prose. Do NOT write index.html — the orchestrator owns the gallery.
```

### Step 8.4 — Wait discipline

**CRITICAL: never emit bare text while smiths are running.** Append to `runs/<run_tag>/temp/orchestrator-notes.md`: gallery ordering (which screen first sells the app), design-name labels, anything a smith's report flags. One progress check per minute max.

### Step 8.5 — Validate the full matrix

1. **Existence matrix:** for every slug in `temp/mockup-screens.md` and every letter in {a, b, c}, `runs/<run_tag>/designs/<letter>/mockups/<slug>.html` exists. `ls runs/<run_tag>/designs/*/mockups/ | sort` and diff against the frozen list.
2. **Filler scan:** `grep -ril "lorem" runs/<run_tag>/designs/` MUST return nothing. Also grep for `TODO` and `placeholder`.
3. **Self-containment scan:** `grep -rilE 'src="https?://|href="https?://.*\.(css|js)|@import|fonts\.googleapis' runs/<run_tag>/designs/*/mockups/` MUST return nothing — no mockup loads an external resource.
4. **Art-direction cards** (only when the inventory has `none` screens): for each letter, `grep -c "^## Art direction — " runs/<run_tag>/designs/<letter>/design-system.md` equals the `none`-screen count, and each listed screen has its card.
5. Any missing file, missing card, or failed scan: re-spawn ONLY the responsible smith ONCE, naming the exact missing slugs / offending files. If it fails twice, log it, patch trivial defects yourself via Edit, and continue — but the existence matrix must be complete before step 8.6; the step 12 gate re-checks it.

### Step 8.6 — Render screenshots (orchestrator work)

AFTER all smiths have returned and the existence matrix is complete, render `runs/<run_tag>/designs/<letter>/screenshots/<slug>.png` for EVERY mockup — step 14 implementers and the step 15 ab-ux-critic consume these renders as the visual spec.

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
4. **No Chrome binary found → do NOT fail the step.** Update `runs/<run_tag>/manifest.json` with `"screenshots_skipped": true` (read, modify, Write back whole), note the warning in `temp/orchestrator-notes.md`, and continue. Missing screenshots are a step 12 design-gate WARNING, not a hard fail, when the manifest carries this flag.

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
<p>Run /appbuilder-choose a|b|c after comparing.</p></header>
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

## Exit criteria

- `temp/mockup-screens.md` exists; mockable screen count ≤ 12 (standard) / ≤ 20 (premier); `none` screens listed in their own section; dropped screens logged
- Existence matrix complete: every frozen slug × all 3 letters on disk
- Every `none` inventory screen has its `## Art direction — <Screen>` card in all three designs' design-system.md
- Screenshots: one non-empty `screenshots/<slug>.png` per mockup × all 3 letters, OR manifest carries `screenshots_skipped: true`
- `grep -ril "lorem"` over `runs/<run_tag>/designs/` returns nothing; external-resource scan returns nothing
- `runs/<run_tag>/designs/index.html` exists, has jump nav + one section per frozen screen, three labeled iframes each, all srcs resolving
- Every fully-mocked feature's status flipped to `designed`
- Then update manifest: `steps.8 = "done"`, mark the step-8 todo complete, return to the router.

## Next step

Return to the router (`appbuilder`). Step 9 (skill research) is your concurrent pair member and may already be running or done. Once BOTH members of the 8 ∥ 9 pair are done, the router invokes:

```
Skill(skill: "appbuilder-10-skill-forge")
```

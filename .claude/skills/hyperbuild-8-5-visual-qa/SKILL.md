---
name: hyperbuild-8-5-visual-qa
description: >
  Step 8.5 of the hyperbuild pipeline — VISUAL QA of the rendered mockups,
  the first and only point where anything LOOKS at the pixels the user
  will judge. Spawns 3 hb-design-critic agents in parallel (one per design
  direction); each VIEWS every rendered screenshot for its direction
  (the Read tool renders PNGs) against docs/DESIGN-CRAFT.md §4 (layout
  integrity) and that direction's own design-system.md (craft), and files
  runs/<run_tag>/gates/visual-qa-<letter>.json — findings carrying screen,
  severity, category, what_is_wrong, fix_instruction. The orchestrator
  ranks the findings, re-spawns the responsible hb-mockup-smith in PATCH
  MODE (edit the existing mockup HTML, never rewrite), re-renders the
  patched screenshots, and re-runs the critic ONCE over the affected
  screens. MAX 2 rounds — remaining criticals are recorded as known
  issues, never looped on. Step 12 checks these files and prints
  unresolved criticals to the user. Invoked by the hyperbuild router via
  Skill(); not run directly by users.
---

# Step 8.5 — Visual QA (parallel, 3 design critics + 1 patch round)

You are executing step 8.5 (visual-qa) of the hyperbuild pipeline. Step 8 built every mockup and rendered one PNG per screen × 3 designs; step 9 (skill research) is step 8's concurrent pair member and may still be running — you share no inputs with it. Step 12 shows the user the gallery those mockups feed. **Until this step, nothing in the pipeline has ever LOOKED at a rendered pixel** — mockups were validated by four greps (existence, "lorem", external URLs, art-direction cards), so a FAB parked on a list row, a CTA sliced by the bezel, and a design that trips a banned cliché all reach the human checkpoint unseen. That is the defect class this step exists to kill.

**Goal:** for EACH design letter a, b, c — `runs/<run_tag>/gates/visual-qa-<letter>.json`, written by an agent that actually viewed every rendered screenshot for that direction, with every critical finding either FIXED in the mockup HTML and re-rendered, or honestly recorded as a known issue that step 12 prints to the user.

**Gear gate:** runs identically for both gears — every rendered screen is reviewed regardless of gear. Findings cap per direction: **24 (standard) / 40 (premier)**, max 8 per screen. Rounds: **2 maximum, both gears.**

**⚠ CRITICAL ANTI-PATTERN: reviewing the HTML instead of the image.** A critic that greps `padding-bottom` and declares the FAB safe has done nothing — the first run's mockups all *specified* correct spacing and still rendered a FAB over the list. The verdict comes from the PNG. Grep is corroboration for a fix instruction, never a substitute for looking. A screen whose PNG could not be viewed is `screens_not_viewed`, never a pass.

---

## Inputs

- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL.
- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`, `platform`; confirm `steps["8"]` is `"done"`; read `screenshots_skipped`
- `docs/DESIGN-CRAFT.md` — **the binding craft bar.** §2 banned tells, §3 the eight commitments, §4 layout integrity, §5 the self-check. Every critic reads it; every finding cites a clause of it or of the direction's own design system.
- `runs/<run_tag>/temp/mockup-screens.md` — step 8's frozen screen list (slugs, feasibility, features)
- `runs/<run_tag>/temp/orchestrator-notes.md` — step 8's hand-off lists: `## Craft flags` (its grep smoke tests: zero transitions, display face == body face, emoji as art) and `## Suspect renders` (its eyes-check verdicts, letter + slug + symptom). Both go into the critic spawns as `prior_flags` — step 8 wrote them FOR this step
- `runs/<run_tag>/designs/directions.md` — letter ↔ design name
- `runs/<run_tag>/designs/<letter>/design-system.md` + `tokens.css` — what each direction PROMISED; craft findings are graded against these
- `runs/<run_tag>/designs/<letter>/mockups/<slug>.html` — the files the patch round edits
- `runs/<run_tag>/designs/<letter>/screenshots/*.png` — **the artifacts under review**

Set `steps."8.5" = "running"` in the manifest, mark the step-8.5 todo in_progress (add one if step 1's seeded todo list predates this step).

---

## Scoped entry (a partial re-run — NOT the default)

The default entry is FULL: all three letters, every rendered screen, round 1 from
scratch. Three callers instead enter this skill SCOPED, because only part of the design
set changed or was left unjudged:

- `hyperbuild-12-design-gate` — check 20/21 remedy: the unjudged screens, or the
  directions whose criticals are still `open`.
- `hyperbuild-revise` — DESIGN scope: the one letter whose system was re-authored.
- `hyperbuild-redesign` — the NEW letters of a redesign round.

A scoped caller states two inputs before invoking: `scope_letters` (a subset of a, b, c)
and `scope_screens` (a subset of slugs, or ALL of that letter's screens). Then:

1. **Untouched letters are not re-reviewed.** Do not spawn a critic for a letter outside
   `scope_letters`; its `visual-qa-<letter>.json` is left byte-identical.
2. **MERGE, never overwrite.** For each letter in scope, read the existing
   `runs/<run_tag>/gates/visual-qa-<letter>.json` FIRST if it exists, and write back a
   merged file:
   - findings on screens OUTSIDE `scope_screens` are carried over verbatim — their
     `status`, `round`, and `acceptance_reason` preserved. Silently rewriting an
     `accepted-known-issue` back to `open` re-fails step 12's check 21 on a defect
     nobody re-introduced.
   - findings on screens INSIDE `scope_screens` are REPLACED by this pass's findings —
     the screen was re-built or re-rendered, so its old findings describe a file that no
     longer exists. Drop them (they stay in the round-2 raw file as evidence).
   - `rounds` = max(existing `rounds`, this pass's rounds). A scoped pass that spends its
     own patch round on a scope where `rounds` was already 2 does not reset the budget:
     the cap is per SCREEN SET, so a re-mocked screen gets a fresh pair of rounds while
     an untouched screen keeps its spent ones.
   - `screens_reviewed` / `screens_not_viewed` = the union across the merge, with any
     screen removed from the roster (deleted mockup) dropped from both.
   - recompute `counts` and `unresolved_critical` over the MERGED `findings`.
3. **New-letter case** (redesign): a letter with no existing JSON is simply the full flow
   for that letter — nothing to merge.
4. **8.5.8's distinctness pass still runs over all THREE live letters**, scoped or not:
   it is a cross-direction check, and a new or re-authored direction is exactly when
   distinctness can break. Its findings append to the live letters' files.
5. Record `scope_letters` / `scope_screens` and the merge decisions in
   `runs/<run_tag>/temp/orchestrator-notes.md` under `## Visual QA — scoped pass`.

Everything else in the Procedure below applies unchanged, read as "for each letter in
scope" and "for each screen in scope".

---

## Procedure

### 8.5.1 — Preflight: prove there are pixels to review (orchestrator)

1. `ls runs/<run_tag>/designs/<letter>/screenshots/*.png` for each letter. Build the review roster: one row per PNG — letter, slug, absolute screenshot path, mockup path, feasibility (`full` | `partial` from `temp/mockup-screens.md`). **Review EVERY png present**, including any state renders step 8 produced beyond the base slug (`<slug>-empty.png`, `<slug>-dark.png`) — those states are exactly what the design systems promise and never show.
2. Missing renders for existing mockups: re-run step 8's headless-Chrome render for the missing files ONCE (same binary discovery and same flags — `--window-size=458,912 --hide-scrollbars` for mobile, the platform viewport otherwise).
3. Read step 8's hand-off in `temp/orchestrator-notes.md`: `## Craft flags` and `## Suspect renders`. Every flagged letter+slug goes into that direction's critic spawn as `prior_flags` — a flagged screen is a lead to CONFIRM OR CLEAR from the image, never a pre-accepted finding, and never the limit of the review.
4. **No renders anywhere and no Chrome binary** (manifest `screenshots_skipped: true`): this step runs in **SOURCE-ONLY MODE** — degraded and labeled as such, never faked. The critics review the mockup HTML against the same craft and layout rules (they can still compute the FAB padding arithmetic, catch a banned cliché, and see that no empty state exists), but: every screen is listed in `screens_not_viewed` with reason `"no render — source-only review"`, every finding carries `"evidence_mode": "source-only"`, the file carries `"status": "source-only-no-render"`, there is NO patch round and NO round 2 (a fix that cannot be re-rendered cannot be verified), and every critical closes as `"status": "unverifiable"` with an `acceptance_reason`. Set manifest `"visual_qa_skipped": true`. Step 12's checks 20 and 21 downgrade to WARNINGs on that flag and print the findings to the user — an honest gap, never a silent pass. **Source-only route:** 8.5.2 (spawn with `evidence_mode: source-only`) → 8.5.4 (validate) → 8.5.9 (close out). Skip 8.5.5–8.5.8 entirely; the distinctness pass needs pixels too.
5. Record the roster (and the mode) in `runs/<run_tag>/temp/orchestrator-notes.md`.

### 8.5.2 — Spawn THREE `hb-design-critic` agents in ONE message (round 1)

One critic per direction — **never one critic across directions**: a critic judging craft must hold exactly one design system in its head, and grading direction b against direction a's promises is how a critic starts inventing taste. The cross-direction distinctness comparison is the ORCHESTRATOR's, in 8.5.8. Spawn all three in ONE message for true parallel execution.

**Spawn template (fill one per letter):**

```
subagent_type: hb-design-critic
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 8.5 (visual QA) of the hyperbuild
  pipeline. Step 7 wrote design <letter>'s design system; step 8 built its
  mockups and rendered one PNG per screen. NOTHING in this pipeline has
  looked at those pixels — you are the first and only eye before the user
  sees them at the step 12 design gate. Your findings drive a patch round
  by the same hb-mockup-smith that wrote the HTML, and any critical you
  file that survives that round is printed to the user at the gate. You
  judge RENDERED IMAGES, not source code. You NEVER edit a mockup.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - design_letter: <a|b|c>
  - design_name: "<Name from directions.md>"
  - round: 1
  - screens: [<one line per rendered PNG:
      slug | screenshot: <ABSOLUTE path to .png> | mockup:
      runs/<run_tag>/designs/<letter>/mockups/<slug>.html |
      feasibility: full|partial (+ the inventory's what-IS-mockable note)>]
  - craft_bar: docs/DESIGN-CRAFT.md
  - design_system: runs/<run_tag>/designs/<letter>/design-system.md
  - tokens_file: runs/<run_tag>/designs/<letter>/tokens.css
  - platform: <mobile|web|desktop>
  - prior_flags: [<step 8's `## Craft flags` + `## Suspect renders` lines
    for THIS letter, verbatim — leads to confirm or clear from the
    image, never pre-accepted findings and never the limit of your
    review; "clear" is a legitimate verdict, stated per lead>]
  - evidence_mode: rendered (default) | source-only (no Chrome on this
    machine — review the mockup HTML, list every screen under
    screens_not_viewed, and tag every finding "evidence_mode":
    "source-only"; never claim to have seen a pixel you did not see)
  - findings_cap: <24 standard | 40 premier>, max 8 per screen
  - output_path: runs/<run_tag>/gates/visual-qa-<letter>.json

  READ FIRST (context files, in this order):
  - runs/<run_tag>/idea.md
  - docs/DESIGN-CRAFT.md — the binding craft bar. §2 = the 12 banned
    tells (by name), §3 = the eight things this design system committed
    to, §4 = the 11 mechanical layout rules, §5 = the done-check
  - runs/<run_tag>/designs/<letter>/design-system.md — this direction's
    OWN promises: its signature element, depth model, type pairing,
    radius rhythm, empty-state art, motion, component specs. Craft
    findings are graded against THIS file, not your taste.
  - runs/<run_tag>/designs/<letter>/tokens.css
  - research/product-spec.md — the screen inventory and personas (is the
    content on screen real product content?)
  - THEN every screenshot in `screens`, one at a time, with Read — the
    Read tool renders PNGs. VIEW each one before writing a word about it.

  REVIEW PROTOCOL — two passes per screen, in this order:
  (a) LAYOUT INTEGRITY, against DESIGN-CRAFT.md §4: clipping at all four
      edges, accidental overlap (FAB / bottom nav / sticky header /
      sheets covering content), undeliberate truncation and half-words,
      horizontal bleed, tap targets ≥44px, text sizes and contrast,
      spacing rhythm, real content, safe areas, gutter alignment.
  (b) CRAFT, against this direction's design-system.md + DESIGN-CRAFT.md
      §2/§3: is the NAMED signature element actually visible here? is the
      declared depth model legible (or is this a flat card with a 1px
      hairline)? do the display and body faces read as two different
      voices? does an empty state carry real drawn art? is quantity /
      progress / status VISUALIZED or just typed? does the screen trip
      any §2 banned tell BY NAME?

  Then ONE direction-level pass across all screens: signature element on
  ≥3 screens; ≥2 distinct data-personality forms across the set; ONE nav
  component, ONE destination set, ONE icon vocabulary, ONE status-bar
  treatment, ONE chevron weight across every screen of this direction;
  no app tab bar on onboarding, modal, or full-screen camera routes;
  every component that appears twice looks the same both times.

  REGRESSION SWEEP — work your agent brief's numbered first-run
  regression list on EVERY screen. These are bugs a real run shipped:
  FAB drawn over list rows and CTAs; content sliced mid-glyph by the
  bottom nav; tab bar on onboarding/modal/camera routes; two nav
  components inside one direction; chip scrollers hard-cut at the bezel;
  the primary or destructive CTA clipped by the frame; status bar drawn
  on some screens only; filenames/numerals wrapping mid-token; 90–200px
  dead zones at the screen bottom; rows of one list at four different
  heights; one state said twice (pill + coloured text); identical glyphs
  on every row of a list that should differentiate.

  `partial` screens: judge ONLY the mocked chrome (HUD, overlays, menus,
  controls) and the placeholder viewport's labeling — never the
  engine-rendered content itself.

  OUTPUT — write EXACTLY this JSON to output_path with Write:
  {"gate": "visual-qa", "run_tag": "<run_tag>", "design_letter": "<x>",
   "design_name": "<Name>", "rounds": 1,
   "screens_reviewed": ["<slug>", ...],
   "screens_not_viewed": [{"screen": "<slug>", "reason": "<why>"}],
   "counts": {"critical": <n>, "major": <n>, "minor": <n>},
   "unresolved_critical": <count of critical findings>,
   "findings": [
     {"id": "VQ-<x>-01", "round": 1, "screen": "<slug>",
      "screenshot": "<path you viewed>",
      "severity": "critical|major|minor",
      "category": "clipping|overlap|truncation|contrast|spacing|craft-gap|cliche|inconsistency",
      "what_is_wrong": "<what you SEE in the image, quoting the visible
        broken text: \"renders as '12d lef'\">",
      "fix_instruction": "<one concrete change the smith can make to this
        file: the selector + the property + the value>",
      "craft_rule": "DESIGN-CRAFT.md §4.2 | design-system.md ## Signature element",
      "status": "open"}]}

  SEVERITY, operationally:
  - critical — the screen fails at the gate: a control, CTA, nav label or
    row is covered or clipped; text sliced mid-glyph; body contrast below
    4.5:1; placeholder/lorem content; a §2 banned tell defining the
    screen's look; the direction's signature element absent from a screen
    the design system says carries it.
  - major — a designer would send it back: no depth model visible, one
    radius everywhere, empty state without art, quantities typed not
    visualized, nav/status-bar vocabulary changing between screens, tap
    target under 44px, chip row cut at the bezel, dead zone ≥120px.
  - minor — alignment, rhythm, orphan wraps, optical baseline nits.

  Rank findings by severity, then by how early the screen appears in the
  gallery. Respect findings_cap. Your final message: counts by severity,
  screens viewed vs not viewed, the three worst findings verbatim, and
  the output path. Data, not prose.
```

### 8.5.3 — Wait discipline

**CRITICAL: never emit bare text while critics are in flight** — a text-only response ends the turn and kills the pipeline. Append to `runs/<run_tag>/temp/orchestrator-notes.md` while waiting: which direction you expect to be worst, which screens carry the gallery, patch-batching plans.

### 8.5.4 — Validate the findings, then RANK (orchestrator)

For each letter:

1. `runs/<run_tag>/gates/visual-qa-<letter>.json` exists and is valid JSON (`python3 -m json.tool`).
2. `screens_reviewed` ∪ `screens_not_viewed` covers EVERY png in the roster. A screen in neither is unreviewed — re-spawn that critic ONCE, scoped to the missing screens only, and merge its file.
3. Every finding carries all six required fields (`screen`, `severity`, `category`, `what_is_wrong`, `fix_instruction`, `craft_rule`) with `severity` and `category` from the legal sets, and `screen` in the roster. Drop any finding whose `fix_instruction` is vague ("improve the spacing", "make it more modern") — log each drop with one line of reasoning in `temp/orchestrator-notes.md`. A critic that returns only vague findings gets re-spawned ONCE with the rule quoted back.
4. A critic that reports `screens_not_viewed` for reasons other than a missing file is re-spawned ONCE for those screens; a genuinely missing PNG is re-rendered (8.5.1 item 2) before re-spawn. (Source-only mode excepted: there every screen is legitimately unviewed and the file says so.)

**Rank for the patch round.** Per letter, build the patch list: EVERY `critical`, then every `major`, then `minor` findings only on screens already being patched (free while the file is open). Cap **6 fix instructions per screen** — a patch with 12 instructions is a rewrite; take the top 6 by severity and record the rest as `deferred` in the notes. If a direction has zero criticals and zero majors, it skips the patch round entirely.

### 8.5.5 — Patch round: re-spawn `hb-mockup-smith` in PATCH MODE (parallel, ONE message)

One smith per direction with a non-empty patch list — **never two smiths on one direction in the same round** unless their screen lists are disjoint (>10 defective screens: split by screen, and give BOTH the identical cross-screen consistency rulings verbatim, or they will re-diverge exactly like the first run did).

**Spawn template (fill one per patched direction):**

```
subagent_type: hb-mockup-smith
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 8.5 (visual QA) of the hyperbuild
  pipeline, in PATCH MODE. You (or a sibling smith) wrote these mockups
  in step 8. A design critic then VIEWED every rendered screenshot and
  filed defects — text clipped, controls covered, craft promises the
  design system made that the screen does not keep. You apply the listed
  fixes to the EXISTING files. The orchestrator re-renders the
  screenshots and the critic re-checks them ONCE; whatever is still
  broken is printed to the user at the step 12 design gate.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - design_letter: <a|b|c>
  - design_name: "<Name>"
  - mode: PATCH — edit existing files, never regenerate
  - fixes: [
      <screen slug> → file: runs/<run_tag>/designs/<letter>/mockups/<slug>.html
        - VQ-<x>-NN (<severity>, <category>): <what_is_wrong>
          FIX: <fix_instruction>
        - ... (max 6 per screen, ranked)
    ]
  - cross_screen_rulings: [<the ONE nav component / destination set /
    status-bar treatment / icon vocabulary every screen of this
    direction must use, named concretely — resolve any divergence the
    critic reported IN FAVOUR OF the design system's spec>]
  - design_system: runs/<run_tag>/designs/<letter>/design-system.md
  - tokens_file: runs/<run_tag>/designs/<letter>/tokens.css
  - craft_bar: docs/DESIGN-CRAFT.md

  READ FIRST (context files, in this order):
  - runs/<run_tag>/idea.md
  - docs/DESIGN-CRAFT.md — §4 layout integrity is the standard your fixes
    must reach; §2 lists the tells your fix must not introduce
  - runs/<run_tag>/designs/<letter>/design-system.md — the authority for
    every value you change
  - runs/<run_tag>/designs/<letter>/tokens.css
  - each mockup file in `fixes`, IN FULL, before editing it

  PATCH RULES (each is load-bearing):
  - You are tool-locked to [Read, Write]. Write is how you save, not
    permission to regenerate: Read the file, apply ONLY the listed fixes,
    Write the file back with EVERY other byte identical — same tokens
    block, same content strings, same structure, same class names. A
    diff that touches lines no fix named is a violation.
  - Fix the CAUSE, not the symptom: content covered by a FAB gets the
    scroll container's `padding-bottom` raised to ≥ FAB height + 24px
    (both FAB and nav present: the two add), not the FAB moved off-frame.
  - Every new value comes from a token (`var(--space-N)`, `var(--radius-*)`).
    One-off pixels only for hairlines and commented ≤2px optical nudges.
  - NEVER introduce an external request (no CDN font, no remote image,
    no @import), never replace real content with placeholder text, never
    delete content to make it fit — content that does not fit is a
    layout bug, not a content bug.
  - NEVER touch a screen not in `fixes`, another direction's directory,
    tokens.css, or design-system.md.
  - A fix you cannot apply without redesigning the screen: leave the file
    alone and report it as not-applied with one line of why.

  Report back, per screen: fix ids applied, the exact selector +
  property + value you changed for each, fix ids NOT applied and why.
  Data, not prose.
```

### 8.5.6 — Re-render the patched screens (orchestrator work)

For every patched slug × letter, re-run step 8's headless-Chrome render to the SAME screenshot path (overwrite), with the same flags step 8 used (`--window-size=458,912 --hide-scrollbars` for mobile; the platform viewport otherwise; absolute `file://` paths). Verify each re-rendered PNG is non-empty and its mtime is newer than the patched HTML. A render that fails twice: leave the old PNG, mark every finding on that screen `status: "open"`, and note it — never re-check a stale image.

### 8.5.7 — Round 2: re-run the critic ONCE, on the affected screens only

Spawn one `hb-design-critic` per patched direction, in ONE message, with the round-1 template modified in exactly four places:

- `round: 2`
- `screens:` — ONLY the patched slugs (with their re-rendered PNG paths)
- `output_path: runs/<run_tag>/gates/visual-qa-<letter>-round2.json`
- an extra input block:
  ```
  - prior_findings: [<every round-1 finding for these screens: id,
    severity, category, what_is_wrong, fix_instruction>]
  - VERDICT TASK: for EACH prior finding, view the re-rendered
    screenshot and return "fixed" or "still-broken" with one line of
    what you now see. Then run the normal two-pass review on these
    screens — a patch that fixed a clip and broke the rhythm is a NEW
    finding. Do not re-litigate screens outside this list.
  ```
  and the round-2 output schema adds `"verdicts": [{"id": "VQ-<x>-NN", "verdict": "fixed|still-broken", "observation": "<what you see now>"}]`.

Then MERGE into the canonical `runs/<run_tag>/gates/visual-qa-<letter>.json` yourself (the canonical file is the one step 12 reads):

- `rounds: 2`
- every round-1 finding with verdict `fixed` → `"status": "fixed"`
- every round-1 finding with verdict `still-broken` → stays `"status": "open"`
- round-2's NEW findings appended with `"round": 2`, `"status": "open"`
- recompute `counts` and `unresolved_critical` (= criticals whose status is `open`)

**MAX 2 CRITIC ROUNDS = exactly ONE patch round. There is no round 3.** A third pass costs another six subagents and, on the evidence, converges on taste rather than defects. This is the same `≤2` budget the gear table binds the step 12 and 16 gates to, applied stricter in practice: two critic rounds means exactly one patch round, and the second critic round is itself Tier-0-conditional (a re-rendered screenshot that actually differs). What survives here is not looped on, it is written down and shown to the user.

**RUN CONTROL AT THE ROUND BOUNDARY** (the router owns these mechanics — this is the tool call; the authority is `hyperbuild/SKILL.md` "Run control", cited by section number). Before spawning round 2's critics: `[ -f "runs/<run_tag>/ABORT" ] && echo ABORTED || echo CONTINUE` (§2 — ABORT present means do not start the round; write what round 1 found and return to the router, which sets `blocked_on: "aborted-by-user"`), check elapsed against `runs/<run_tag>/temp/step-8.5.start` (§3 — a fired ceiling is reported, never worked around by dropping directions or screens), and bump `usage.turns` for step 8.5 (§4, measured never estimated).

### 8.5.8 — Distinctness pass (orchestrator, judged on PIXELS)

Step 6 proposed three directions and step 7 checked distinctness by comparing two CSS values; the first run shipped **three palettes on one layout** and certified itself distinct. This pass judges the claim on renders — and it is the ORCHESTRATOR's, not a critic's: each critic holds exactly one design system by design.

1. Read step 7's distinctness note in `temp/orchestrator-notes.md` (what it compared, what collided, what it re-spawned) — you are testing whether its prose verdict survived the render. Then pick the hero screen (the first screen in the gallery order — home/main list) and `Read` all three PNGs: `designs/{a,b,c}/screenshots/<hero>.png`.
2. **Name three structural differences WITHOUT mentioning color**: layout topology, hierarchy and largest type size, the signature element, row/card anatomy, information density. Write them into `temp/orchestrator-notes.md` under `## Visual QA — distinctness`.
3. If you cannot name three — if the honest answer is "same layout, three palettes" — that is DESIGN-CRAFT §2.12 (undifferentiated triples) and a real defect. It CANNOT be patched here (it belongs to step 6/7), so record it: one `major` finding with `"category": "cliche"`, `"craft_rule": "DESIGN-CRAFT.md §2.12"`, and a `fix_instruction` that says plainly what the fix is — re-run step 7 for the offending letter, or `/hyperbuild-revise <letter> <what to change>` after the gate — appended to the JSON of EACH direction that reads as a palette swap, `"status": "open"`.
4. Repeat on ONE more screen only if the hero screen was ambiguous. Never more than two comparisons — this is a smoke test, not a fourth design review.

### 8.5.9 — Close out honestly

1. Any finding still `status: "open"` after round 2 that is `critical`: flip it to `"status": "accepted-known-issue"` and add `"acceptance_reason": "<one line: what was attempted in the patch round and why it did not land>"`. **Only after both rounds have actually run** — never as a shortcut around a patch round, and never for a finding no smith was asked to fix. `major`/`minor` findings simply stay `open`. (Source-only mode: criticals close as `"status": "unverifiable"` with the same required reason — no render existed to patch against.)
2. Recompute each file's `counts` and `unresolved_critical` one last time; `unresolved_critical` counts ONLY `status: "open"` criticals (accepted known issues and unverifiable criticals are counted separately by step 12 and printed to the user).
3. Write a short `## Visual QA` block into `runs/<run_tag>/temp/orchestrator-notes.md`: per letter — screens reviewed, counts by severity, fixes applied, unresolved criticals and accepted known issues verbatim. Step 12's report and stop message quote it.

---

## Artifacts

- `runs/<run_tag>/gates/visual-qa-<letter>.json` — one per design letter, the CANONICAL record step 12 checks. Schema (identical to the critic's output schema, plus the orchestrator's merge fields):

```json
{"gate": "visual-qa", "run_tag": "<run_tag>", "design_letter": "a",
 "design_name": "<Name>", "rounds": 2,
 "screens_reviewed": ["home", "settings"],
 "screens_not_viewed": [],
 "counts": {"critical": 3, "major": 7, "minor": 4},
 "unresolved_critical": 0,
 "findings": [
   {"id": "VQ-a-01", "round": 1, "screen": "home",
    "screenshot": "runs/<run_tag>/designs/a/screenshots/home.png",
    "severity": "critical", "category": "overlap",
    "what_is_wrong": "The floating + button covers the right half of the 'Greek yoghurt' row; its day count renders as '2 d'.",
    "fix_instruction": "Raise .content padding-bottom to calc(var(--nav-height) + 56px + var(--space-6)) so no row can sit under the FAB.",
    "craft_rule": "DESIGN-CRAFT.md §4.2",
    "status": "fixed"}]}
```

  Legal `status`: `open` | `fixed` | `accepted-known-issue` (requires `rounds: 2` + `acceptance_reason`) | `unverifiable` (source-only mode only; requires `acceptance_reason`). Legal `severity`: `critical` | `major` | `minor`. Legal `category`: `clipping` | `overlap` | `truncation` | `contrast` | `spacing` | `craft-gap` | `cliche` | `inconsistency`. Optional `"evidence_mode": "source-only"` on every finding filed without a render. File-level `"status"` appears ONLY in source-only mode (`"source-only-no-render"`).
- `runs/<run_tag>/gates/visual-qa-<letter>-round2.json` — the round-2 critic's raw file (verdicts + new findings); kept as evidence, never read by the gate
- Patched `runs/<run_tag>/designs/<letter>/mockups/<slug>.html` — surgical edits only
- Re-rendered `runs/<run_tag>/designs/<letter>/screenshots/<slug>.png` for every patched screen
- `runs/<run_tag>/temp/orchestrator-notes.md` — the `## Visual QA` summary block
- `runs/<run_tag>/manifest.json` — `steps."8.5"`; `visual_qa_skipped: true` only in the no-render case

---

## Exit criteria

- `runs/<run_tag>/gates/visual-qa-<letter>.json` exists for ALL THREE letters, valid JSON in the schema above (a SCOPED pass: the out-of-scope letters' files are unchanged and still valid, and each in-scope file was merged, not overwritten — no prior `accepted-known-issue` or its `acceptance_reason` was lost)
- Every rendered PNG appears in its file's `screens_reviewed`, or in `screens_not_viewed` with a reason — no screen silently unjudged
- Every finding carries `screen`, `severity`, `category`, `what_is_wrong`, `fix_instruction`, `craft_rule`, `status`
- Every `critical` finding is `fixed`, or `accepted-known-issue` with a reason after both rounds ran — nothing critical left `open` without a patch attempt
- Every patched mockup has a re-rendered screenshot newer than its HTML
- Rounds ≤ 2; `unresolved_critical` recomputed and consistent with `findings`
- The distinctness pass ran: three non-color structural differences named in `temp/orchestrator-notes.md`, or a §2.12 finding filed against each palette-swap direction
- (Source-only mode only: all three files carry `"status": "source-only-no-render"`, every screen is in `screens_not_viewed`, every finding carries `"evidence_mode": "source-only"`, criticals close as `unverifiable`, and manifest `visual_qa_skipped: true`)

Then update the manifest: `steps."8.5" = "done"`, mark the step-8.5 todo complete, return to the router.

---

## Next step

Return to the router (`hyperbuild`). Step 9 (step 8's concurrent pair member) may still be running; once BOTH 8.5 and 9 are done the router invokes:

```
Skill(skill: "hyperbuild-10-skill-forge")
```

Step 12's gate re-reads your three JSON files: it fails if one is missing or if any `critical` is still `open`, and it prints every accepted known issue to the user in the stop message — so an honest known issue costs the run a warning line, while a silent one costs the user their design choice.

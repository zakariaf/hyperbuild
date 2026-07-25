# DESIGN-CRAFT.md — the visual craft bar

BINDING on every design step — 6 (design research), 7 (design systems), 8 (mockups), 8.5
(design QA). Each cites this file by path in its spawn prompts, and every
`hb-design-researcher`, `hb-design-system-author`, and `hb-mockup-smith` READS IT BEFORE
producing anything. Violations are DEFECTS, not taste disagreements: re-spawned or
patched like any other failed check. It exists because a competent run shipped dated,
plain designs — flat hairline cards, cream + serif, traffic-light color, no shape
language, no depth craft, no illustration — plus clipped text and a FAB parked on a list.

---

## 1. The bar

Good here means a design a person would SCREENSHOT AND SHARE — not one they would merely
approve. Distinctive without being impractical: opinionated type, real depth, a shape
language you could recognize with the logo cropped out, still shipping as a normal app
with normal accessibility. EVERY choice must be traceable to the app's subject and
audience — a design system that could be pasted onto a tax app, a running app, and a
plant-care app unedited is generic and FAILS. Three directions must feel like three
different products, not three color swaps of one.

---

## 2. Anti-patterns — the AI-design tells

BANNED unless the user's idea explicitly asked for them. These are the tells that mark a
design as machine-defaulted. Self-check against this list by NAME before you report back.

1. **Warm cream + serif display + terracotta accent.** The `#F4F1EA`-ish paper background
   with a Georgia-ish headline and a rust/clay accent. BANNED.
2. **Near-black + one acid pop.** `#0A0A0A`/`#111` everywhere with a single acid-green,
   vermilion, or electric-lime accent doing all the work. BANNED.
3. **Purple-to-blue gradient hero.** Any `#6366F1 → #3B82F6` family gradient banner,
   button, or hero blob. BANNED.
4. **Inter / Space Grotesk as the reflexive safe face.** BANNED as a default. If a grotesk
   is genuinely right, argue it in the research doc AND pick a face with more character
   than the two most-defaulted ones on the internet.
5. **Emoji as section markers, icons, bullets, or empty-state art.** BANNED in mockups and
   design systems. Draw inline SVG or CSS shapes.
6. **Everything centered.** Center-aligned headings, body, and CTAs down the whole screen.
   BANNED — asymmetry and a real left edge are the baseline; centering is a local move.
7. **One uniform border-radius everywhere.** Every card, button, input, avatar, and sheet
   at the same value. BANNED — see the radius rhythm rule.
8. **Flat white card + 1px hairline border + nothing else.** The default `background:#fff;
   border:1px solid #E5E7EB` box as the app's only container. BANNED.
9. **Material-blue / bootstrap-default palettes.** `#1976D2`, `#007BFF`, `#0D6EFD` and
   their neighbors. BANNED.
10. **Traffic-light red/amber/green as the ENTIRE color story.** Status colors are allowed
    (see §3.5) — they are NEVER the palette. BANNED as the design's identity.
11. **Lorem ipsum, "Sample text", "Item 1", "TODO", placeholder names.** BANNED — already
    a step 8 pipeline violation; restated because it is also a craft failure.
12. **Undifferentiated triples.** Three directions whose `--color-primary` differs but
    whose type, shape, depth, and layout are identical. BANNED — enforced at step 7.5's
    anti-sameness check (cross-letter, on the design systems) and at step 8.5's pixel
    distinctness pass (8.5.8, on the rendered screens).

---

## 3. What every design system MUST commit to

Step 7 REQUIRES all eight commitments below in `design-system.md`, each a real section
with real values; step 8 mockups must visibly express them. Hand-wavy commitments are
step 8.5 defects. Authors may ADD tokens beyond the canonical contract to express these —
never rename or omit a canonical one.

### 3.1 A SIGNATURE ELEMENT — mandatory `## Signature element` section

ONE memorable, recurring visual device that belongs to this app and no other. A shape, a
graphic treatment, a way status is drawn, a distinctive container.

- NAME it (e.g. "the tide bar", "the notch card", "the gradient meridian") and TRACE it
  to the subject in one sentence — why THIS app gets THIS device.
- SPEC it: exact CSS recipe (radii, gradient stops, clip-path, sizes, which tokens).
- STATE its rules of use: where it MUST appear, where it must NEVER, how it scales from
  hero to compact.
- It MUST appear in AT LEAST 3 mockup screens. Step 8.5 counts it.

A signature element is not a logo, not an accent color, and not "rounded corners".

### 3.2 TYPE WITH CHARACTER — display + body pairing

A display face and a body face. ONE system stack used for everything is BANNED. Mockups
are self-contained (NO network fonts, no `@import`, no CDN), so pick from faces reliably
present on macOS/iOS rendering engines, ALWAYS with a generic fallback:

| Role | Reliable faces | Fallback |
|------|----------------|----------|
| Editorial serif | `"New York"`, `Charter`, `"Iowan Old Style"`, `Georgia`, `"Hoefler Text"`, `Baskerville`, `Palatino` | `serif` |
| Geometric / humanist sans | `"Avenir Next"`, `Optima`, `Futura`, `"Gill Sans"`, `"Helvetica Neue"` | `sans-serif` |
| Soft / rounded | `"SF Compact Rounded"`, `"SF Pro Rounded"`, `"Arial Rounded MT Bold"` | `sans-serif` |
| Condensed / display | `"SF Compact Display"`, `"Avenir Next Condensed"`, `"Helvetica Neue Condensed Bold"` | `sans-serif` |
| Data / mono | `"SF Mono"`, `Menlo`, `Monaco` | `monospace` |

Rules:
- `--font-family-display` and `--font-family-body` MUST resolve to DIFFERENT families —
  same-family only when the contrast is extreme, stated, and argued (e.g. Condensed Bold
  display vs regular body). `-apple-system`/`system-ui` as BOTH is BANNED.
- A REAL TYPE SCALE: one stated ratio (1.200 / 1.250 / 1.333) generating
  `--font-size-xs … --font-size-3xl`, tabled with line-heights.
- DELIBERATE WEIGHT AND TRACKING: display gets negative tracking (`-0.02em`…`-0.04em`);
  all-caps micro-labels get `+0.06em`…`+0.12em` and never regular weight; body is 0.
- Numerals: state `font-variant-numeric` (`tabular-nums` for any column of figures).

### 3.3 A DEPTH MODEL — pick ONE and apply it everywhere

Name the model in `## Depth model`, then use it for `--shadow-1/2/3` and every surface:

- **Layered tinted shadow** — 2–3 stacked shadows in a PALETTE HUE at low saturation, a
  tight contact shadow plus a wide soft one, e.g.
  `0 1px 2px hsl(212 40% 25% / .10), 0 10px 24px -6px hsl(212 45% 22% / .20)`.
- **Borderless tinted surfaces** — no shadows; elevation reads as measurable lightness or
  chroma steps `--color-bg` → `--color-surface` → `--color-surface-raised`, plus spacing.
- **Crisp offset** — hard-edged zero-blur shadow in a palette color with a solid border
  (e.g. `4px 4px 0 var(--color-ink)`).

BANNED: `rgba(0,0,0,.1)` single-layer black shadows; shadow used as decoration on
elements that are not elevated. DARK MODE: shadows barely read — elevation MUST switch to
lightness steps, optionally with a 1px top inner highlight at 6–10% white.

### 3.4 A SHAPE LANGUAGE — radius rhythm + one distinctive move

- A RADIUS RHYTHM: at least 3 distinct values across `--radius-sm/md/lg/full`, with a
  stated assignment rule (e.g. media 4px, controls 12px, containers 20px, chips full).
  One value everywhere is BANNED.
- CONCENTRIC NESTING: inner radius = outer radius − padding. Never nest equal radii.
- AT LEAST ONE distinctive shape move, specced and named: asymmetric corners
  (`border-radius: 24px 4px 24px 24px`), a `clip-path` notch or cut corner, a diagonal
  edge, a capsule, overlapping layers, or a masked arc. It MUST appear on more than one
  component, so it reads as language rather than accident.

### 3.5 COLOR WITH A CHOSEN NEUTRAL

- NEUTRALS ARE BIASED toward the accent hue — never pure grey. Every neutral shares one
  hue (±15°) at low chroma (~2–8% surfaces, up to 12% deepest text); state the recipe.
  Pure `#FFFFFF`/`#F5F5F5`/`#111111` ramps are BANNED absent an explicit argument.
- SEMANTIC STATUS COLORS ARE DEFINED SEPARATELY from the brand accent:
  `--color-success/warning/danger` get their own hues, tuned to the palette's
  temperature. `--color-accent` MUST NOT share a hue family with `--color-danger`. Status
  NEVER reads by color alone — pair with icon, shape, or label (colorblind rule).
- GRADIENTS AND TINTS are allowed WHEN THEY CARRY MEANING (progress, temperature, time of
  day, depth, intensity). Decorative gradient blobs are BANNED (§2.3).
- HIERARCHY: the accent is scarce. State the share of a screen it may occupy and hold to
  it — accent on everything means accent on nothing.

### 3.6 CSS-DRAWN ART — empty states and key moments

NO external images, ever. Draw with CSS and inline SVG: linear/radial/conic gradients,
`clip-path`, `mask-image`, `border-radius` sculpting, transforms, blend modes.

- EVERY empty state gets real art direction: ≥3 shapes, ≥2 palette colors, ≥96px tall,
  plus a headline, one supporting line, and one CTA.
- Key moments (first run, goal/streak completion, success, error) get art too, specced in
  the design system even when not mocked.
- BANNED empty states: centered grey text alone; a lone emoji; a stock outline icon at
  10% opacity; a bare circle with a plus.

### 3.7 DATA PERSONALITY

Counts, progress, and status are VISUALIZED, not just typed:

| Data | Required form (pick per app) |
|------|------------------------------|
| Single ratio / completion | ring, radial arc, or filled meter |
| Series over time | sparkline, column strip, or dot plot |
| Count / quantity | badge, dot cluster, stacked chip |
| State / status | pill with shape + color + text (never color alone) |
| Rank / distribution | segmented bar, ladder |

At least TWO distinct forms must appear across the mockup set, drawn in CSS/SVG from
palette colors, sized in tokens, with real numbers from the PRD and feature specs. A
screen whose only quantitative content is plain text numbers FAILS.

### 3.8 MOTION NOTES

Screenshots are static; the intent is still binding and step 13 implements it. `## Motion`
states, per interactive component: press (transform/shadow/color delta, duration, easing
token), hover (web/desktop), enter/exit for sheets, lists, and modals, plus an explicit
NEVER-ANIMATES list and `prefers-reduced-motion` behavior. Mockup CSS MUST carry real
`transition` declarations on at least the primary button and card, on
`--motion-*`/`--easing-*`.

---

## 4. Layout integrity — mechanical rules for mockups

Checkable facts about the HTML, enforced at step 8.5. Each is a bug the first run shipped.

1. **NOTHING CLIPPED.** No text, icon, or control cut off at any edge. A mobile mockup's
   screen area is EXACTLY 390×844 CSS px inside the frame (page outer size 458×912 with
   bezel and body padding). Content either fits or scrolls DELIBERATELY in the designated
   container — never `overflow: hidden` swallowing real content.
2. **NO ACCIDENTAL OVERLAP.** A floating action button MUST NOT cover list content: the
   scroll container gets `padding-bottom` ≥ FAB height + 24px. Bottom nav bar: content
   `padding-bottom` ≥ nav height + 16px. Both present: the two add. Sticky headers get the
   same treatment at the top.
3. **DELIBERATE TRUNCATION ONLY.** Long strings either wrap on a DEFINED number of lines
   (`-webkit-line-clamp` with a stated count) or ellipsize with intent
   (`text-overflow: ellipsis` + `overflow: hidden` + `white-space: nowrap`). A half-visible
   word like `12d lef` is a HARD FAIL.
4. **NO HORIZONTAL PAGE SCROLL.** Carousels scroll inside their own container and show a
   deliberate peek of the next item.
5. **TAP TARGETS ≥ 44×44 px** — icon buttons, tab bar items, chevrons, close buttons.
   Padding counts; visual size may be smaller.
6. **TEXT ≥ 12px**, body copy ≥ 15px on mobile. CONTRAST ≥ 4.5:1 for body text, ≥ 3:1 for
   large text (≥18.66px bold / ≥24px) and for meaningful icons and UI edges. State the
   measured pairs in the design system for BOTH light and dark.
7. **CONSISTENT VERTICAL RHYTHM.** Every margin, padding, and gap comes from
   `--space-1…--space-8`. One-off pixel values are BANNED except hairlines, commented
   optical nudges ≤2px, and the frame chrome itself.
8. **REAL CONTENT EVERYWHERE.** Realistic names, quantities, dates, streaks, and copy from
   the PRD, feature specs, and personas. A two-row "list" is not a list; show 4–7.
9. **SAFE AREAS.** Mobile frames draw a status-bar area at top (~44–54px, time and
   indicators styled per the design, never an image) and home-indicator space at bottom
   (~34px). Content never sits under either.
10. **ALIGNMENT DISCIPLINE.** One content gutter per screen; section edges line up. Mixed
    16/20/24px gutters on one screen is a defect.
11. **DARK MODE HOLDS.** Where a dark palette exists, the mockup renders correctly under
    `[data-theme="dark"]` — no invisible text, no white cards.

---

## 5. Self-check before a mockup is considered DONE

Run this list literally, in order. Report the number of any item you cannot pass and why.
A mockup with an unpassed item is NOT done.

**Craft**
1. SIGNATURE ELEMENT present and correctly specced (or deliberately absent here)?
2. Display and body resolve to DIFFERENT families, each with a generic fallback, zero
   network font requests?
3. Every type size from the scale, with the stated tracking on display and all-caps labels?
4. Declared DEPTH MODEL applied — no lone `rgba(0,0,0,.1)`, no unelevated element shadowed?
5. At least 3 distinct radii per the assignment rule, concentric where containers nest?
6. The distinctive SHAPE MOVE visible here or on this screen's siblings?
7. Neutrals hue-biased (not pure grey), accent scarce?
8. Status colors separate semantic tokens — not the palette story, never hue alone?
9. Empty state (if any) carries real CSS-drawn art (≥3 shapes, ≥2 colors, ≥96px) plus
   headline, support line, CTA?
10. A DATA PERSONALITY form wherever the screen shows quantity, progress, or status?
11. Primary button and primary card carry real `transition` declarations on motion tokens?
12. Read §2 top to bottom — does this screen trip ANY of the 12 banned tells?

**Layout**
13. Nothing clipped: check all four edges of the render.
14. FAB / bottom nav cover nothing — verify the `padding-bottom` arithmetic explicitly.
15. Every truncation deliberate: clamped lines or a real ellipsis, no half-words.
16. No unintended horizontal scroll.
17. Every tap target ≥ 44×44 px including padding.
18. All text ≥12px, body ≥15px; every text/background pair ≥4.5:1 (3:1 large).
19. All spacing from the scale; any one-off nudge commented.
20. Every string real PRD/feature content — no lorem, no "Item 1", no TODO, no placeholders.
21. Status-bar and home-indicator safe areas drawn, nothing underneath them.
22. Gutters and section edges aligned across the whole screen.
23. Screen still reads correctly in dark mode.

**File hygiene**
24. Self-contained: tokens.css verbatim, all CSS inline, ZERO external requests
    (`https://`, `@import`, remote images, CDN fonts), icons as inline SVG.
25. Would you screenshot this and send it to someone? If not, name what is missing and fix
    it before reporting done.

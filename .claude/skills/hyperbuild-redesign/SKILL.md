---
name: hyperbuild-redesign
description: >
  Generate a NEW set of design directions for a run parked at the Stage-A
  design gate. Invoked directly by the user as /hyperbuild-redesign [notes],
  where notes are free-form ("bolder, more playful", "keep c, replace a and
  b", "nothing beige", "more like Duolingo's energy"). Parses KEEP/REPLACE
  instructions — kept directions survive untouched with their letters, only
  the replaced slots regenerate — archives everything it replaces under
  runs/<run_tag>/designs/archive/round-<N>/, then re-runs step 6 (design
  research) for the new slots with the user's notes appended to the direction
  brief as binding constraints, followed by step 7 (design systems), step 8
  (mockups + screenshots) and the step-8.5 visual QA for those slots only,
  rebuilds directions.md + designs/index.html, re-runs the step-12 gate and
  parks the run again. Repeatable — round 2, 3, … each archive their
  predecessors. Records every round in runs/<run_tag>/decisions/revisions.md.
  Does NO build work and never touches app/.
---

# /hyperbuild-redesign — new design directions, nothing lost

You are executing a design round on a hyperbuild run parked at the design gate. The
user has seen three directions and wants different ones — all three, or only the slots
they name. Your job: preserve what they keep, archive what they replace, regenerate the
replaced slots under their notes as binding constraints, and park the run at the gate
again with a fresh comparison gallery.

**THIS SKILL DOES NO BUILD WORK AND NEVER TOUCHES `app/`.** It also does no design work
by hand: naming the new directions is yours (step 6.1 is orchestrator work), everything
else runs through the owning step skill with its own spawn templates. If you find
yourself writing `design-system.md`, `tokens.css`, or mockup HTML from this seat, STOP.

**Every design spawn this skill drives reads `docs/DESIGN-CRAFT.md` FIRST.** It is the
binding craft bar: §2's twelve anti-patterns are DEFECTS, §3's eight commitments are
mandatory sections, §4's layout rules are mechanical facts checked at 8.5. A round that
produces three more competent, dated, flat directions has failed even if the user's
notes were vague.

## When NOT to use this skill

- **After `/hyperbuild-choose` released Stage B.** With `stage: "BUILD"` (or `"DONE"`)
  the app is being built against a chosen design; design changes then go through step
  15's structural-findings path (`hyperbuild-15-adversarial-review`) — its `hb-ux-critic`
  findings become patches, and structural ones become new tasks looping back through
  step 14 once. **You may not start a round on a `BUILD`/`DONE` run unless the user
  explicitly confirms in reply to your warning** (procedure step 1). Re-designing after
  the build means throwing away implemented UI — say that plainly before asking.
- **For a tweak to a direction that stays itself** ("b's rows are too tall", "warmer
  palette on a") — that is `/hyperbuild-revise`, which re-runs one letter's author and
  smiths without touching directions or research.
- **For product changes** ("also track expiry dates") — `/hyperbuild-revise` again;
  regenerating designs will not add a feature.
- **Mid-run.** If Stage A is still executing, let `/hyperbuild` park at the gate first.

## Arguments

- **arg (optional):** free-form notes, verbatim as typed. Everything the user says is
  either a KEEP/REPLACE instruction or a constraint. Examples:
  `/hyperbuild-redesign bolder, more playful` ·
  `/hyperbuild-redesign keep c, replace a and b` ·
  `/hyperbuild-redesign nothing beige, no serif headlines` ·
  `/hyperbuild-redesign more like Duolingo's energy — these all feel like tax software`

With NO notes: every slot is replaced and the only constraints are the ones you derive
— say so explicitly in the plan block, and lean hard on `docs/DESIGN-CRAFT.md` plus what
the current set already occupies (the new set must not re-tread it).

## Inputs

- `runs/*/manifest.json` — `run_tag`, `stage`, `gear`, `platform`, `steps`, `blocked_on`, `design_choice`
- `runs/<run_tag>/idea.md` — the gospel idea (+ any `## Revisions` entries)
- `runs/<run_tag>/designs/directions.md` — the live letter ↔ name ↔ slug ↔ research-doc mapping
- `runs/<run_tag>/designs/{a,b,c}/design-system.md` — the current systems (their H1s are the design names)
- `research/design/<slug>.md` × 3 — the current directions' research docs
- `runs/<run_tag>/temp/mockup-screens.md` — the FROZEN screen list; new directions build exactly these slugs
- `runs/<run_tag>/designs/archive/round-*/round.md` — previous rounds (names and theses that may NOT be recycled)
- `runs/<run_tag>/decisions/revisions.md` — the shared revision/round ledger
- `docs/DESIGN-CRAFT.md` — the binding craft bar, cited by path in every spawn

## Procedure

### 1. Locate the run and clear the entry guards

Glob `runs/*/manifest.json`. Prefer the manifest with `blocked_on: "design-choice"`;
several matches → newest by `created`. Then, each failure STOPS and records nothing:

- **No manifest** → "No hyperbuild run found. Start one with `/hyperbuild <your app idea>`."
- **`stage: "BUILD"` or `"DONE"`** → do NOT proceed. Warn: the build has started against
  design `<design_choice>`, implemented UI would be invalidated, and step 15's findings
  path is the supported route. Ask for explicit confirmation; proceed ONLY on an
  explicit go-ahead in reply, recorded verbatim in the ledger's `Authorization:` line.
- **Stage A still executing** (any of steps `"1"`–`"11"` `"running"`, or `"12"` absent/`"running"`)
  → "Run `<run_tag>` is mid-flight at step `<N>`. Let it park at the design gate first." STOP.
- **`blocked_on` starts with `redesign-in-flight:` or `revision-in-flight:`** → a prior
  round or revision died mid-flight. Read `runs/<run_tag>/temp/redesign-round-<N>/scope.md`
  (or the revision's scope file) and finish or explicitly abandon it — with an
  `Abandoned:` line naming the half-changed artifacts — before opening a new round.
- Otherwise (`stage: "PLAN"`, `steps["12"]` `"done"` or `"blocked"`) → proceed.

### 2. Read the current set and open the round

1. Read `directions.md`, each live `designs/<letter>/design-system.md` H1, and each
   direction's `## Commitments` in `research/design/<slug>.md`. You need to know what
   the current set OCCUPIES — the new slots must not re-tread it.
2. **Round number:** `N` = 1 + the count of existing `runs/<run_tag>/designs/archive/round-*`
   directories. **This redesign IS round `<N>`** — one number for everything: the live
   set it produces is round `<N>`, and the directions it replaces are archived under
   `designs/archive/round-<N>/` (i.e. "archived by round N"). The original set step 6
   produced is round 0, so the first redesign is round 1.
3. Read every existing `archive/round-*/round.md`: names, slugs, and theses already
   tried. **NO RECYCLED ROUNDS** — a new direction may not repeat an archived name,
   slug, or thesis. The user rejected it once.

### 3. Parse the notes: KEEP/REPLACE first, constraints second

**KEEP/REPLACE.** Resolve which letters regenerate:

| The user says | Resolution |
|---|---|
| nothing about letters | replace ALL THREE (a, b, c) |
| "keep c" / "c is fine" / "only c works" | keep c; replace a and b |
| "keep a and b" | keep a, b; replace c |
| "replace b" / "redo b" | keep a, c; replace b |
| "keep the calm one" (by name/character) | match against `directions.md` names and briefs; a UNIQUE match resolves it |
| keep and replace lists that contradict | the KEEP list wins; everything not kept is replaced; say so in the plan block |
| a name that matches nothing uniquely | ask ONE question listing the three letters with their names, and nothing else |

**Kept slots are inert.** Their letter, `design-system.md`, `tokens.css`, `mockups/`,
`screenshots/`, and research doc are not read by the new authors, not re-rendered, not
re-QA'd, and not archived. Only their row in `directions.md` survives verbatim.

**CONSTRAINTS.** Everything else in the notes becomes binding constraint text. Sort it:

- **Directional** ("bolder, more playful", "calmer", "denser") → translate into
  mechanics for the brief: which of step 6.1's SIX axes of visual language it moves, and
  in which direction. The axes (`hyperbuild-6-design-research` step 6.1's table is
  authoritative) are **type personality · depth model · shape language · colour strategy
  · density · data & status form** — a constraint that does not land on one of these is
  a vibe word, and a vibe word never survives into pixels because steps 7 and 8 build
  from the axes.
- **Negative** ("nothing beige", "no serif headlines", "no purple") → a BANNED list,
  quoted verbatim into the brief and re-checked at step 7's validation and 8.5. Negative
  constraints are cheap to honor and expensive to miss — they are the user telling you
  exactly what they saw and hated.
- **Reference energy** ("more like Duolingo's energy") → a reference CUE, never a copy
  target. The brief must say: borrow the ENERGY and the mechanics behind it (motion
  posture, saturation strategy, illustration language, type weight); never the brand's
  marks, mascot, wordmark, exact palette, or trade dress. The researcher grounds it in
  dated, specific sources per step 6's research requirements.
- **Diagnosis** ("these all feel like tax software", "too flat") → carry it verbatim as
  the failure the round exists to fix, and name the matching `docs/DESIGN-CRAFT.md` §2
  anti-pattern(s) the previous set tripped, so the new slots are steered off them
  by name.

Write all of it to `runs/<run_tag>/temp/redesign-round-<N>/constraints.md`.

### 4. State the plan, mark the manifest, open the ledger entry

Emit ONE plan block, then proceed — this is not a stopping message:

```
REDESIGN ROUND <N>
Notes: "<verbatim, or 'none given'>"
Keeping:  c — Signal Bloom (untouched: system, tokens, 10 mockups, 10 screenshots)
Replacing: a — Kitchen Daylight, b — Quiet Ledger  → archived to designs/archive/round-<N>/
Constraints (binding on the new slots): <bulleted, incl. the BANNED list>
Re-runs: 6 (slots a, b) → 7 (a, b) → 8 (a, b × <K> frozen screens + screenshots) → 8.5 QA (a, b) → gallery → 12
Untouched: the idea, the PRD, features/, epics/, the research vault except the two moved direction docs
Cost: ~<N> subagent spawns
```

Then write `runs/<run_tag>/temp/redesign-round-<N>/scope.md` (this block + the resolved
slot list + the frozen screen slugs), seed TodoWrite with one todo per re-run step + the
gate, open the ledger entry (procedure step 10, `Outcome:` = `in flight`), and mark the
manifest:

```bash
python3 - <<'PY'
import json
p = "runs/<run_tag>/manifest.json"
m = json.load(open(p))
for s in ("6", "7", "8", "8.5", "12"):
    m["steps"][s] = "redo"
m["blocked_on"] = "redesign-in-flight:round-<N>"
json.dump(m, open(p, "w"), indent=2)
PY
```

`"8.5"` is in that list deliberately: leaving it `"done"` from the original round lets a
resume skip visual QA for the new directions entirely, and the stale round-0
`visual-qa-*.json` files would satisfy the gate's checks 20 and 21 on designs nobody ever
looked at.

Crash safety, stated honestly: archiving happens BEFORE any regeneration (next step), so
everything a REPLACED slot had is already on disk in the archive. **KEPT slots are the
exposed case** — they are deliberately not archived, so a blind router resume that re-ran
step 6 unscoped would rename all three directions, overwrite `directions.md`, and destroy
the kept letter's mapping with no copy anywhere. That is exactly what the
`redesign-in-flight:` marker prevents: on resume, read `scope.md` and re-enter THIS skill
(the router's recovery ladder branches on `*-in-flight:` for this reason) — never let any
step skill resume unscoped while the marker is set.

### 5. Archive the replaced directions (BEFORE regenerating — nothing is lost)

For each REPLACED letter, move (do not copy-and-leave, do not delete) its artifacts:

```bash
mkdir -p runs/<run_tag>/designs/archive/round-<N>/<letter>
cp runs/<run_tag>/designs/directions.md runs/<run_tag>/designs/archive/round-<N>/directions.md
mv runs/<run_tag>/designs/<letter>/design-system.md \
   runs/<run_tag>/designs/<letter>/tokens.css \
   runs/<run_tag>/designs/<letter>/mockups \
   runs/<run_tag>/designs/<letter>/screenshots \
   runs/<run_tag>/designs/archive/round-<N>/<letter>/
mv research/design/<old-slug>.md \
   runs/<run_tag>/designs/archive/round-<N>/<letter>/research-<old-slug>.md
mv runs/<run_tag>/gates/visual-qa-<letter>.json \
   runs/<run_tag>/designs/archive/round-<N>/<letter>/   # only if it exists
```

**Moving the research doc is mandatory, not tidiness:** step 12's check 10 requires
EXACTLY 3 direction docs in `research/design/`. A fourth left behind fails the gate.

**Moving the visual-QA record is mandatory for the same class of reason.** The frozen
screen slugs are identical across rounds, so a round-0 `visual-qa-a.json` still names
exactly the screens the NEW design a renders: left in place it passes step 12's check 20
as "evidence" describing a design that no longer exists, and its criticals can hard-fail
check 21 on defects belonging to the archived direction — which then get printed to the
user as known issues of a design they never saw. Each live letter's `visual-qa` file must
be written by THIS round's 8.5 pass.

Write `runs/<run_tag>/designs/archive/round-<N>/round.md`:

```markdown
---
run_tag: <run_tag>
round: <N>
archived_at: <ISO timestamp>
kept: [c]
replaced: [a, b]
---
# Directions archived by round <N>

**Notes that triggered this round (verbatim):**
> <the user's words, or "none given">

| Letter | Name | Slug | Why replaced |
|--------|------|------|--------------|
| a | Kitchen Daylight | kitchen-daylight | user: "these all feel like tax software"; tripped DESIGN-CRAFT §2.1 (cream + serif + terracotta) |
| b | Quiet Ledger | quiet-ledger | user: "bolder" — no display step above 20px |

**Replaced by:** a — <New Name>, b — <New Name> (the round <N> live set)
**Contents:** design-system.md, tokens.css, mockups/, screenshots/, research-<slug>.md
```

The archive is INERT: no step, gate, or agent reads it, and nothing in it may be edited
or re-used later. It exists so a user can say "actually, round 1's b was better" and
have the files still on disk.

### 6. Name the NEW directions (orchestrator work — do NOT delegate)

This is step 6.1's naming decision, re-run for the empty slots only, under the round's
constraints. Binding rules, all of them:

1. **Same evidence base as step 6.1** — personas and register from `research/product-spec.md`,
   the complaints in `research/sentiment-synthesis.md`, unclaimed visual territory in
   `research/competitor-landscape.md`, and the platform conventions in `decisions/platform.md`.
2. **The constraints are law**, including the BANNED list. A new direction that trips a
   negative constraint is a failed round before a single spawn.
3. **Distinctness across the FINAL set** — kept slots included, at step 6.1's bar, not a
   softer one. Every direction answers all SIX axes (type personality, depth model, shape
   language, colour strategy, density, data & status form), and across the three live
   directions **no two may share an answer on more than ONE axis — at least 5 of 6 must
   be pairwise different**. They must also clear `docs/DESIGN-CRAFT.md` §1 ("three
   different products, not three color swaps") and §2.12 (undifferentiated triples), and
   step 6.1's REDO RULE applies here too: if all three could honestly be called "a clean
   minimal list app", re-name before spawning. Kept slots CONSTRAIN the new ones — read
   the kept letter's six answers out of the live `## Axis grid` and treat every one of
   them as occupied territory.
4. **No recycled rounds** — no archived name, slug, or thesis returns.
5. **Naming convention** — two-word evocative names ("Signal Bloom", "Warm Terminal");
   BANNED: anything that would fit any app ("Modern Clean", "Minimalist", "Simple UI").
6. Each new direction gets step 6.1's FULL per-direction brief, all four blocks in
   order: **Thesis** (2–3 sentences: what it is, who it serves best, what it deliberately
   sacrifices) · **Axis commitments** (the six answers, one line each, concrete not
   adjectival) · **Signature element candidate** (DESIGN-CRAFT §3.1 — ONE named recurring
   device traced to this app's subject in a sentence; not a logo, not an accent colour,
   not "rounded corners") · **Reference points** (≥2 REAL, NAMED products or design
   systems, each with what SPECIFICALLY is borrowed). Step 6.3's spawn template reads
   `direction_axes`, `signature_candidate` and `reference_points` straight out of this
   file — a brief missing a block leaves a spawn input unfillable.

Then rewrite `runs/<run_tag>/designs/directions.md` **in step 6.2's current format**
(`hyperbuild-6-design-research` step 6.2 is authoritative; this is the same file step 6
would have written, with an Origin column and per-new-brief constraint blocks added).
Kept rows and the kept brief are byte-identical; the kept letter's six axis answers are
carried over VERBATIM into the new grid. The round's constraints are appended to each NEW
brief so they travel downstream automatically (step 6 pastes the brief verbatim into
`direction_brief`; steps 7 and 8 read this file):

```markdown
# Design directions — <run_tag>   (design round <N>; earlier sets under designs/archive/)

| Letter | Name | Slug | Research doc | Origin |
|--------|------|------|--------------|--------|
| a | <New Name> | <new-slug> | research/design/<new-slug>.md | round <N> |
| b | <New Name> | <new-slug> | research/design/<new-slug>.md | round <N> |
| c | Signal Bloom | signal-bloom | research/design/signal-bloom.md | round 0 (original) — KEPT |

## Axis grid

| Axis | a — <New Name> | b — <New Name> | c — Signal Bloom |
|------|----------------|----------------|------------------|
| Type personality | <answer> | <answer> | <kept answer, verbatim> |
| Depth model | <answer> | <answer> | <kept answer, verbatim> |
| Shape language | <answer> | <answer> | <kept answer, verbatim> |
| Color strategy | <answer> | <answer> | <kept answer, verbatim> |
| Density | <answer> | <answer> | <kept answer, verbatim> |
| Data & status form | <answer> | <answer> | <kept answer, verbatim> |

Pairwise distinctness: a↔b differ on <n>/6, a↔c on <n>/6, b↔c on <n>/6 — all must be ≥5.
Redo rule: <one line stating why these three could NOT all be called "a clean minimal list app">.

## Briefs

### a — <New Name>
**Thesis.** <2–3 sentences: what it is, who it serves best, what it deliberately sacrifices.>
**Signature element candidate.** <Named device> — <one sentence tracing it to this app's subject.>
**Reference points.** <Real product or system> — <what specifically is borrowed>. <Real product or system> — <what specifically is borrowed>.
**Rejects.** <The DESIGN-CRAFT §2 cliché(s) this direction is nearest to and how it stays clear, plus the competitor look it refuses.>

**Round <N> constraints (BINDING, from the user's notes):**
> <verbatim notes>
- Must: <directional constraints as mechanics, each naming the axis it moves>
- BANNED: <negative constraints, verbatim>
- Reference energy: <cue> — borrow the mechanics, never the brand's marks, palette, or trade dress
- Fixing: <the diagnosis + the DESIGN-CRAFT §2 anti-pattern the previous set tripped>

### c — Signal Bloom
<the kept brief's four blocks, verbatim — no constraints block; this direction was not regenerated>
```

If the live `directions.md` predates the axis grid (a run whose step 6 ran before the
axis format), derive the kept letter's six answers from its `research/design/<slug>.md`
`## Visual language` section and say so in the round's `round.md`. Never leave a grid
cell blank: step 6's exit criteria require all six answered for all three letters.

### 7. Re-run steps 6 → 7 → 8 → 8.5 for the NEW SLOTS ONLY

Binding mechanics for every one of these steps:

1. **Invoke the owning step skill** — `Skill(skill: "hyperbuild-6-design-research")`,
   then `"hyperbuild-7-design-systems"`, then `"hyperbuild-8-mockups"`. Each step's
   procedure, spawn templates, validation checks, and exit criteria are AUTHORITATIVE.
   Never re-implement a step's work from this seat.
2. **The only permitted deviations:** (a) the slot subset — spawn one agent per NEW
   letter, none for kept letters; (b) the REDESIGN ADDENDUM below appended to each spawn
   prompt; (c) not regenerating kept slots' artifacts; (d) the two ENTRY-POINT deviations
   named in items 2a and 5 below, which exist because this skill already did those
   sub-steps.

   **2a. Step 6 is entered at 6.3 — SKIP sub-steps 6.1 and 6.2.** Procedure step 6 above
   already did both: it named the new directions under the round's constraints (6.1) and
   rewrote `directions.md` in 6.2's format with the kept rows and axis answers preserved.
   Running 6.1 as written would name THREE fresh directions and 6.2 would overwrite
   `directions.md` — destroying the kept letter's row, its slug→research-doc mapping, and
   both new briefs' binding constraint blocks, and leaving letter `<kept>` pointing at a
   research doc that no longer matches. Enter at **6.3** (spawn one
   `hb-design-researcher` per NEW letter, reading its `direction_brief`,
   `direction_axes`, `signature_candidate`, `reference_points` and `direction_rejects`
   out of the `directions.md` you just wrote), then 6.4 (wait discipline) and 6.5
   (validation) — 6.5 validates the NEW docs plus the kept doc as the live set of three,
   including its cross-direction distinctness check at the ≥5/6 bar. Step 6's exit
   criteria then apply to that live set. Say in the plan block that step 6 ran scoped
   from 6.3.
3. **The spawn contract is never weakened** — every Task prompt keeps its four pieces
   (verbatim block-quoted idea including any `## Revisions`, pipeline position, specific
   inputs + exact output path, read-first context files), and every spawn adds
   `docs/DESIGN-CRAFT.md` to the top of its read-first list.
4. **REDESIGN ADDENDUM** — insert after `YOUR INPUTS` in each re-spawn:

   ```
   REDESIGN CONTEXT (round <N>, slot <letter>): the user reviewed three
   design directions at the gate and rejected this slot. Their notes,
   verbatim:
   > <the user's notes>
   Constraints file: runs/<run_tag>/temp/redesign-round-<N>/constraints.md
   Archived (do NOT recycle its name, slug, or thesis, and do not read it):
     <old name> — runs/<run_tag>/designs/archive/round-<N>/<letter>/
   Kept slots you must stay distinct from: <letter — Name (its staked axes)>
   BANNED in this round: <the negative constraints, verbatim>
   docs/DESIGN-CRAFT.md is BINDING — read it before producing anything.
   The previous set failed on: <the named §2 anti-patterns / §3 gaps>.
   Producing another direction with that failure is a defect, not a taste
   disagreement.
   ```
5. **Step 8 runs with these explicit deviations** — state them in the plan block, because
   step 8's own procedure is written for a full run and following it verbatim would undo
   this round's guarantees:
   - **SKIP 8.1 (freeze the screen list).** `runs/<run_tag>/temp/mockup-screens.md` is
     already frozen and authoritative; 8.1 would re-extract the inventory and rewrite it.
     The new directions build exactly the same slugs (the gallery pairs by slug; step
     12's check 12 requires the SAME screen set across all three designs), plus the same
     `none`-screen art-direction cards.
   - **8.2/8.3 fan-out counted over the NEW letters only:** S ≤ 6 → one smith per new
     design; S ≥ 7 → two per new design, same batch split as the original run. No smith
     is spawned for a kept letter.
   - **8.6's render loop covers the NEW letters only**, at the same window size and flags
     as the original round; a kept letter's screenshots are NOT re-rendered (re-rendering
     them would break this skill's "kept files are byte-identical" exit criterion for no
     gain). Then verify one non-empty `.png` per new mockup. **If manifest
     `screenshots_skipped: true`** (no Chrome binary on this machine), do not block: skip
     the render, leave the flag set, and enter step 8.5 in SOURCE-ONLY MODE — step 12's
     checks 19 and 20 warn instead of failing, and the round's exit criteria carve-out
     for missing screenshots applies.
   - **8.7's gallery rebuild covers ALL THREE letters** (see procedure step 8) — the
     gallery is a whole-set artifact and must show the kept letter beside the new ones.
   - 8.8's feature status flips are already done from the original round; re-running them
     is a no-op, not a deviation.
6. **Step 8.5 (visual QA):** `Skill(skill: "hyperbuild-8-5-visual-qa")`, entered in its
   **SCOPED ENTRY** mode (that skill's "Scoped entry" section): `scope_letters` = the NEW
   letters, `scope_screens` = ALL of their screens. Kept letters are not re-reviewed and
   their existing `gates/visual-qa-<letter>.json` files are left byte-identical; the new
   letters get fresh files (there is nothing to merge — their round-0 files were archived
   in step 5). Its 8.5.8 distinctness pass still runs across all three LIVE letters,
   which is the point in a redesign round. Defects re-spawn the responsible smith with
   the exact screenshot and defect named — a round that ships clipped text or a FAB
   parked on a list has not improved anything. Never substitute step 8's internal
   `### Step 8.5 — Validate the full matrix` (an existence/lorem grep pass) for this.
7. **Never emit bare text while subagent Tasks are in flight** — append to
   `runs/<run_tag>/temp/orchestrator-notes.md` instead.

### 8. Rebuild the gallery

Step 8 rebuilds `runs/<run_tag>/designs/index.html` as part of its own procedure (8.7);
verify it here and rebuild it yourself if the scoped run did not. Per step 8.7's
skeleton and requirements:
grouped by screen, three labeled iframes per section (labels from the NEW
`directions.md`), jump nav covering every frozen slug, every `src` resolving to a live
`a|b|c` mockup. **No iframe may point into `archive/`.** Verify by listing the srcs and
checking each file exists.

### 9. Re-run the step-12 gate and park

Invoke `Skill(skill: "hyperbuild-12-design-gate")`. It runs all 21 checks fresh, appends
a round to `gates/design-gate-report.md`, and on pass sets `steps.12 = "done"` +
`blocked_on = "design-choice"` — clearing the `redesign-in-flight:` marker — then emits
the stop message. Add these lines to that message, directly above the
`/hyperbuild-choose` line:

```
**Design round <N>** — <verbatim notes, or "no notes given">
- **new:** a — <Name> · b — <Name>   (built under your constraints)
- **kept:** c — <Name>   (unchanged — same system, tokens, mockups and screenshots)
- replaced directions are archived, nothing lost: runs/<run_tag>/designs/archive/round-<N>/
Still not right? `/hyperbuild-redesign <more notes>` — say what to keep and what to fix.
```

If the gate BLOCKS after its 3 fix rounds, leave it blocked and say which checks failed;
the ledger's `Outcome:` records `gate blocked — <failed checks>`. Never soften it.

### 10. Record the round in the ledger

Append to `runs/<run_tag>/decisions/revisions.md` (shared with `/hyperbuild-revise`;
create with frontmatter on first use, `N` = 1 + existing `## R` headings, newest LAST):

```markdown
## R3 — 2026-07-25T11:02:00Z — scope: design (redesign round 1)

**Invocation:** `/hyperbuild-redesign keep c, replace a and b — bolder, nothing beige`
**Request (verbatim):**
> keep c, replace a and b — bolder, nothing beige

**Resolved:** kept c (Signal Bloom); replaced a (Kitchen Daylight), b (Quiet Ledger).
**Constraints applied:** bolder (type scale + color energy + shape); BANNED: beige,
cream, warm off-white grounds.
**Authorization:** n/a (run was parked at design-choice)
**Archived to:** runs/pantry-guard-9fdb34/designs/archive/round-1/ (a, b + their
research docs + directions.md snapshot)
**New directions:** a — <Name> (<slug>), b — <Name> (<slug>)
**Steps re-run:** 6 (a, b) → 7 (a, b) → 8 (a, b × 10 screens + screenshots) → 8.5 QA (a, b) → gallery → 12
**Not re-run:** 1–5, 9–11 (product, stack, backlog untouched); c's system, mockups and screenshots untouched
**Outcome:** gate re-passed round 1; run parked at design-choice again.
```

Open the entry with `**Outcome:** in flight` at plan time (procedure step 4) and finish
the line at the end.

## Repeat rounds

This skill is designed to be run again — round 2, 3, … Each round: increments `N` from
the archive directory count, archives only what THAT round replaces, and forbids
recycling any name, slug, or thesis from ANY earlier round. Kept letters may be kept
again indefinitely; their artifacts are never rewritten and never archived. If the user
keeps rejecting every set, the honest read is usually that the constraints are not
mechanical enough — push the notes harder into `docs/DESIGN-CRAFT.md`'s vocabulary
(signature element, type pairing, depth model, shape move, chosen neutral) before
spending another round.

## Artifacts

- `runs/<run_tag>/designs/archive/round-<N>/` — `round.md`, a `directions.md` snapshot, and one dir per replaced letter holding its `design-system.md`, `tokens.css`, `mockups/`, `screenshots/`, and moved `research-<slug>.md`
- `runs/<run_tag>/designs/directions.md` — rewritten: kept rows verbatim, new rows with briefs carrying the round's binding constraints
- `research/design/<new-slug>.md` — one per new slot (step 6's contract); `research/design/` holds EXACTLY 3 docs afterward
- `runs/<run_tag>/designs/<new-letter>/design-system.md` + `tokens.css` + `mockups/*.html` + `screenshots/*.png`
- `runs/<run_tag>/designs/index.html` — rebuilt gallery, no archive references
- `runs/<run_tag>/temp/redesign-round-<N>/{scope.md,constraints.md}` — plan + constraints (crash-resume point)
- `runs/<run_tag>/decisions/revisions.md` — the round's ledger entry
- `runs/<run_tag>/gates/visual-qa-<new-letter>.json` — this round's 8.5 record per new letter (the replaced letters' round-0 files moved into the archive)
- Updated `runs/<run_tag>/manifest.json` — steps 6/7/8/8.5/12 `"redo"` → `"done"`, `blocked_on` back to `"design-choice"`

## Exit criteria

- Every replaced letter's previous system, tokens, mockups, screenshots, research doc, and `visual-qa-<letter>.json` exist under `designs/archive/round-<N>/`; none of them remain in the live tree
- Every LIVE letter's `runs/<run_tag>/gates/visual-qa-<letter>.json` was written by this round's 8.5 pass (new letters) or belongs to an untouched kept letter — no file describes an archived design
- `research/design/` contains EXACTLY 3 direction docs, matching `directions.md`'s three rows
- Every kept letter's files are byte-identical to before the round
- Every new letter has `design-system.md` + `tokens.css` + one mockup per frozen slug + one non-empty screenshot per mockup (or manifest `screenshots_skipped: true`), and passed the 8.5 visual QA pass
- `directions.md` carries the full `## Axis grid` (all six axes answered for all three live letters, the kept letter's answers verbatim), the pairwise-distinctness line, and the redo-rule line, and every new brief has its four blocks (Thesis / Signature element candidate / Reference points / Rejects) plus its round-constraints block
- The three live directions pass the distinctness bar (pairwise ≥5 of the 6 axes; DESIGN-CRAFT §1 and §2.12), and no new direction repeats an archived name, slug, or thesis
- `designs/index.html` resolves every iframe to a live `a|b|c` mockup; zero archive references
- The ledger entry quotes the notes verbatim and records kept/replaced, constraints, archive path, steps re-run, and a finished `Outcome:` line
- `manifest.blocked_on` is `"design-choice"` (pass) or `"design-gate"` (honest block) — never still `redesign-in-flight:*`; `design_choice` still `null`, `stage` still `"PLAN"`, `app/` untouched

## Next step

There is none to invoke — the run is parked at the gate with a new set to compare. The
user's levers are `/hyperbuild-choose <a|b|c>` (build it), `/hyperbuild-redesign [notes]`
(another round), or `/hyperbuild-revise <change>` (product, feature, or single-direction
changes). **Do NOT invoke `hyperbuild-choose`, `hyperbuild-13-scaffold`, or any Stage-B
skill from here.**

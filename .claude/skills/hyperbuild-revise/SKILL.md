---
name: hyperbuild-revise
description: >
  Change something BEFORE the build starts. Invoked directly by the user as
  /hyperbuild-revise <plain-English change> on a run parked at the Stage-A
  design gate (step 12, blocked_on: "design-choice"). Classifies the request
  into a revision scope — idea | feature | design | epics — states the
  resolved plan and blast radius, then applies it: idea → a dated
  "## Revisions" entry appended to runs/<run_tag>/idea.md (the verbatim idea
  is never rewritten) plus re-runs of steps 4/4.5 and everything downstream
  that depends on them; feature → surgical edits to features/*.md +
  00-index.md then scoped re-runs of 8/11; design → a scoped re-run of one
  direction's system author + mockup smiths + screenshots + 8.5 visual QA
  (new DIRECTIONS go to /hyperbuild-redesign instead); epics → a re-run of
  step 11 under the stated constraint. Always ends by re-running the step-12
  gate so the run parks cleanly again, and records every revision in
  runs/<run_tag>/decisions/revisions.md. Does NO build work and never
  touches app/.
---

# /hyperbuild-revise — change the plan before it becomes an app

You are executing a pre-build revision of a hyperbuild run. Step 12 parked the run at
the design gate; the user wants something CHANGED rather than accepted. Your job:
classify the change, state its blast radius, apply it to the artifacts that own the
change, re-run exactly the steps that depend on them, and park the run at the gate
again with an honest summary.

**THIS SKILL DOES NO BUILD WORK AND NEVER TOUCHES `app/`.** It also does no step work
by hand: every re-run goes through the owning step skill (see *Scoped re-run
mechanics*). If you find yourself writing a design system, authoring mockups, drafting
task files, or scaffolding a project directly from this seat, STOP — you are inside the
wrong skill.

## When NOT to use this skill

- **After `/hyperbuild-choose` released Stage B.** Once the manifest reads
  `stage: "BUILD"` (or `"DONE"`), `app/` exists and is built against a chosen design;
  changes belong to step 15's structural-findings path — critics' structural findings
  become NEW TASKS and loop back through step 14 once (see
  `hyperbuild-15-adversarial-review`). **You may not start this skill on a `BUILD`/`DONE`
  run unless the user explicitly confirms it in reply to your warning** (procedure step
  1). "They typed the command" is NOT confirmation.
- **Mid-run.** If Stage A is still executing (some step between 1 and 11 is `running`),
  STOP and say: let `/hyperbuild` finish and park at the gate, then revise. Revising
  under a running step races the step's own writes.
- **To fix a broken artifact.** A missing section, a malformed frontmatter, an unmocked
  screen is a GATE failure, not a revision: re-run `/hyperbuild` and let step 12's fix
  rounds repair it.
- **To replace design directions.** New/replacement directions are
  `/hyperbuild-redesign`'s job. This skill only tweaks a direction that stays itself.
- **To change the idea beyond recognition.** If the "revision" is a different app, that
  is a new run in a fresh harness clone (one checkout = one app) — say so honestly
  rather than laundering it through a revision.

## Arguments

- **arg (required):** the change, in plain English, verbatim as the user typed it —
  e.g. `/hyperbuild-revise the pantry list should show a photo of each item`,
  `/hyperbuild-revise drop the barcode scanner, add manual entry shortcuts`,
  `/hyperbuild-revise design b's rows are too tall — make it denser`,
  `/hyperbuild-revise split the sync epic, its tasks are too big`.

If the argument is missing or empty: name the run, list the four scopes with a
one-line example each, and stop. Record nothing.

## Inputs

- `runs/*/manifest.json` — `run_tag`, `stage`, `gear`, `platform`, `steps`, `blocked_on`, `design_choice`
- `runs/<run_tag>/idea.md` — the gospel idea (+ any prior `## Revisions` entries)
- `runs/<run_tag>/decisions/revisions.md` — the revision ledger (created on first use)
- `runs/<run_tag>/gates/design-gate-report.md` — proof the run reached the gate
- `runs/<run_tag>/designs/directions.md` — letter ↔ direction mapping (design scope)
- `research/product-spec.md` — PRD: MoSCoW list + canonical screen inventory
- `features/00-index.md` + `features/NN-<slug>.md` — the feature specs
- `epics/00-overview.md` + `epics/NN-<slug>/` — the backlog
- `docs/DESIGN-CRAFT.md` — the binding craft bar; cited by path in EVERY design-step spawn

## Procedure

### 1. Locate the run and clear the entry guards

Glob `runs/*/manifest.json`. Prefer the manifest with `blocked_on: "design-choice"`; if
several match, take the newest by `created`. Then check, in order — each failure STOPS
and records nothing:

- **No manifest** → "No hyperbuild run found. Start one with `/hyperbuild <your app idea>`."
- **`stage: "BUILD"` or `"DONE"`** → do NOT proceed. Emit the warning: the build has
  started (or shipped), `app/` holds real code against design `<design_choice>`, and the
  supported path for changes is step 15's structural-findings loop. Then ask for explicit
  confirmation naming the consequence ("re-running Stage A steps will invalidate tasks
  the build already implemented"). Proceed ONLY on an explicit user go-ahead in reply,
  and record that confirmation verbatim in the ledger entry's `Authorization:` line.
- **Stage A still executing** (any of steps `"1"`–`"11"` is `"running"`, or `"12"` is
  absent/`"running"`) → "Run `<run_tag>` is mid-flight at step `<N>`. Let `/hyperbuild`
  park it at the design gate, then revise." STOP.
- **`blocked_on` starts with `revision-in-flight:`** → a previous revision died mid-flight.
  Read its ledger entry and `runs/<run_tag>/temp/revision-<id>/scope.md`, then either
  finish that revision first (preferred — its steps are already marked `"redo"`) or, if the
  new request supersedes it, append an `Abandoned:` line to that entry stating exactly
  which artifacts were left half-changed, before opening a new one.
- Otherwise (`stage: "PLAN"` and `steps["12"]` is `"done"` or `"blocked"`) → proceed. A
  `"blocked"` gate is a legal starting point; the revision may well fix what blocked it.

### 2. CLASSIFY the request into a revision scope

Read `runs/<run_tag>/idea.md`, `research/product-spec.md` (MoSCoW list + screen
inventory) and `features/00-index.md` first — classify against what the run actually
contains, never against the request's wording alone.

| Scope | The request changes… | Tells | Owning artifacts |
|-------|----------------------|-------|------------------|
| **idea** | what the app IS, who it is for, its platform posture or scope | a whole capability area added/removed, a different audience, "actually it should also…", "make it for teams", "drop the social side" | `runs/<run_tag>/idea.md` (append-only) → PRD → features |
| **feature** | one or more features' behavior, states, copy, screens, or priority — inside the existing product thesis | "the list should show photos", "make export offline-capable", "demote sharing to could" | `features/NN-<slug>.md`, `features/00-index.md`, the matching PRD rows |
| **design** | how ONE existing direction looks, inside its own thesis | "b's rows are too tall", "warmer palette on a", "c's empty states need real art" | `runs/<run_tag>/designs/<letter>/` |
| **epics** | how the work is SPLIT — epic seams, task size, ordering | "split the sync epic", "these tasks are too big", "do offline before sharing" | `epics/` |

Two boundary rules that decide most hard cases:

1. **Feature vs idea:** if the change fits inside the PRD's existing personas and
   thesis, it is FEATURE scope even when it adds a feature file. If it changes who the
   app serves or what it fundamentally does, it is IDEA scope — the PRD's own thesis
   must move first.
2. **Design tweak vs redesign:** a tweak changes VALUES and decisions inside a
   direction that stays recognizably itself. A new thesis, a new name, "none of these
   work", "something bolder" — that is `/hyperbuild-redesign`, and this skill hands off
   (procedure step 4C).

**Ambiguity rule (autonomous by default).** Do not ask permission for the obvious
reading. Ask exactly ONE question only when the request maps to two scopes whose blast
radii differ materially AND the text does not decide between them (e.g. "make it feel
calmer" — a design tweak across three directions, or a product-tone change to the
idea?). The question names both readings and their costs, and nothing else. When the
ambiguity is one of DEGREE rather than scope, take the SMALLEST blast radius that fully
satisfies the request and say which reading you took.

A single request may carry two scopes ("drop the scanner and make b denser"). Split it
into ordered sub-revisions, apply them in pipeline order (idea → feature → epics →
design), and record them as one ledger entry with a sub-item per scope.

### 3. State the resolved plan and blast radius, then PROCEED

Compute the re-run set from the dependency table — "everything downstream that depends
on them", not everything downstream:

| Changed | ALWAYS re-run | Re-run ONLY IF |
|---------|---------------|----------------|
| `idea.md` (idea scope) | 4 (PRD, patched), 4.5 (affected feature files), 11, 12 | 5 when the platform/stack posture moved · 6 + 7 when audience, register, or positioning moved · 8 for screens the inventory added/changed (× all 3 designs) · 9 + 10 when the platform changed |
| `features/*.md` (feature scope) | 11 for the affected epics, 12 | 8 for screens whose content/states changed, × all 3 designs · 4 only for the PRD rows that state the same fact twice (surgical) |
| one design direction (design scope) | 7 (that letter), 8 (that letter, all its screens), 8.5 QA (that letter), 12 | 6 — never here; a changed thesis is `/hyperbuild-redesign` |
| epic seams (epics scope) | 11 (full step, under the constraint), 12 | — |

Emit ONE plan block (this is not a stopping message — you proceed immediately after it):

```
REVISION R<N> — scope: <idea|feature|design|epics>
Request: "<verbatim>"
Reading: <one sentence — why this scope, and what you are NOT reading it as>
Rewrites: <artifact paths, one per line, with what changes in each>
Re-runs:  <step list in pipeline order, each with its scope: "8 (screens: pantry-home, item-detail × a,b,c)">
Untouched: <what survives — name the expensive things: the other designs, the other epics, the research vault>
Cost: ~<N> subagent spawns
```

Then: open the ledger entry (procedure step 7, `Outcome:` left as `in flight`), write
`runs/<run_tag>/temp/revision-R<N>/scope.md` with the same block plus the resolved
re-run set, seed TodoWrite with one todo per re-run step + the gate, and mark the
manifest:

```bash
python3 - <<'PY'
import json
p = "runs/<run_tag>/manifest.json"
m = json.load(open(p))
for s in ("4", "4.5", "11", "12"):   # ← the RESOLVED re-run set, in pipeline order
    m["steps"][s] = "redo"
m["blocked_on"] = "revision-in-flight:R<N>"
json.dump(m, open(p, "w"), indent=2)
PY
```

`"redo"` is the crash-safety marker: if this conversation dies, the router resumes at
the earliest non-`done` Stage-A step and `scope.md` tells the next session what was
scoped. Each step skill flips its own key back to `"done"` at its exit — never do it
for them.

### 4. Apply the change

#### 4A — IDEA scope

1. **APPEND to `runs/<run_tag>/idea.md`. Never rewrite the original.** The frontmatter
   and the verbatim idea body above `## Revisions` are immutable — not reworded, not
   reordered, not "reconciled" with the change. Create the section on first use:

   ```markdown
   ## Revisions

   ### R<N> — <YYYY-MM-DD> — via /hyperbuild-revise

   > <the user's change request, verbatim, byte-for-byte>

   Effect: <1–2 sentences: what this changes about the app.>
   Reaches: research/product-spec.md (feature list, screen inventory), features/
   ```

   Later revisions win over earlier text on conflict; the original stays gospel as the
   record of what was asked for first. Because every spawn prompt block-quotes the BODY
   of `idea.md`, appended revisions propagate to every subagent automatically — that is
   the mechanism. Do not paraphrase the change into prompts on top of it.
2. **Patch the PRD surgically** (step 4's artifact, step 4's rules): amend the affected
   MoSCoW rows, personas, differentiators, and screen-inventory rows — including
   `mockup_feasibility` for any new screen. Keep every unaffected line byte-identical.
   **Threshold:** if the change moves the PRD's thesis (personas or the product's
   purpose), surgical amendment is dishonest — re-run step 4 in full via
   `Skill(skill: "hyperbuild-4-product-spec")` and say so in the plan block.
3. **Re-run 4.5 scoped** (`Skill(skill: "hyperbuild-4-5-feature-specs")`) to the feature
   files the change adds, rewrites, or retires — rules in 4B. Untouched feature files are
   not regenerated, and the roster is not renumbered.
4. Then the rest of the re-run set, in pipeline order.

#### 4B — FEATURE scope

1. Edit / add / remove `features/NN-<slug>.md` per the features contract
   (`features/README.md`: frontmatter + all eight body sections, non-empty, evidenced
   from `research/`). Prefer a scoped `hb-feature-author` re-spawn (step 4.5's template,
   `batch:` narrowed to the affected features, plus the REVISION ADDENDUM) over
   hand-writing a spec.
2. **NEVER RENUMBER existing feature files.** A new feature takes the next unused `NN`
   even if its priority is higher — `NN` is an identity, and `features: [F-NN]` in task
   frontmatter is the traceability chain step 16 walks mechanically. Priority lives in
   `moscow:` and in the index's ordering, not in renumbering.
3. Update `features/00-index.md`: the changed/added row, or drop the removed one.
4. **Removals cascade into the backlog**: for every task whose `features:` list becomes
   empty, delete the task file; for tasks citing several features, edit only the
   frontmatter list. Rebuild `epics/00-overview.md`'s coverage matrix from disk (step
   11.4's format) — never leave a phantom row.
5. Mirror the change into the PRD's matching rows ONLY where the PRD states the same
   fact (MoSCoW row, screen-inventory row). A change the PRD's thesis does not cover is
   IDEA scope — go back to step 2 and reclassify. **A feature the PRD does not list yet
   gets a NEW MoSCoW row in `research/product-spec.md` with its priority stated**, in
   addition to its screen-inventory rows; a removed feature loses its row. The roster
   must agree in BOTH directions — gate check 8 only walks PRD → features, so a feature
   file with no PRD row passes the gate silently and then goes missing from the document
   step 14's implementers and step 15's `hb-spec-critic` treat as the canonical scope
   statement.
6. If `screens:` changed, the new/changed screens must exist in the PRD screen inventory
   with a `mockup_feasibility` value; those screens re-run through step 8 × all three
   designs (+ screenshots + 8.5 QA), and step 8.8's status flips apply.

#### 4C — DESIGN scope (tweak to ONE existing direction)

**New or replacement directions are out of scope: hand off.** If the request asks for a
different look, a new thesis, "something bolder", or replacing a letter, STOP the
revision and tell the user in one line: `/hyperbuild-redesign <your notes>` regenerates
directions and keeps whichever letters you name. Record the hand-off in the ledger and
leave the manifest exactly as you found it (`blocked_on: "design-choice"`, no `"redo"`
marks).

For a genuine tweak inside a direction's own thesis:

1. Write `runs/<run_tag>/temp/revision-R<N>/tweak-<letter>.md`: the verbatim request,
   the specific decisions it changes, and the lines of that direction's
   `## Commitments` (in `research/03-design-system/research/<slug>.md`) it must still
   honor.
2. Invoke `Skill(skill: "hyperbuild-7-design-systems")` — its canonical token contract
   (7.1) and mechanical validation (7.4) still bind — then spawn exactly ONE
   `hb-design-system-author`, for the affected letter only, using this revision-scoped
   version of step 7's template:

   ```
   subagent_type: hb-design-system-author
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste the body of runs/<run_tag>/idea.md — including its ## Revisions section}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are step 7 (design systems) of the hyperbuild
     pipeline, re-run under revision R<N>. You authored (or your predecessor
     authored) this direction's system already; the user reviewed it at the
     design gate and asked for ONE change. You REVISE that system in place —
     same direction, same thesis, same letter — and the step 8 smiths then
     rebuild every mockup in it from your tokens. The other two directions
     are untouched and are not yours to read.

     YOUR INPUTS:
     - run_tag: <run_tag>
     - direction_letter: <letter>
     - direction_name: "<Name>"
     - research_doc: research/03-design-system/research/<slug>.md
     - corrections_doc: research/03-design-system/author/design-directions.md
       — its "## Corrections that override the research docs" table BEATS
       your research doc wherever they disagree
     - revision_request: "<the user's words, verbatim>"
     - revision_note: runs/<run_tag>/temp/revision-R<N>/tweak-<letter>.md
     - output_dir: runs/<run_tag>/designs/<letter>/
     - outputs: design-system.md AND tokens.css in that directory (rewritten in place)

     READ FIRST (context files, in this order):
     - runs/<run_tag>/idea.md
     - docs/DESIGN-CRAFT.md — the BINDING craft bar. Read it before you
       change a single value. Its §2 anti-patterns are DEFECTS, its §3
       eight commitments are mandatory sections, its §4 layout rules bind
       the mockups built from your tokens.
     - research/03-design-system/research/<slug>.md — your direction's
       brief; "## Commitments" still binds except where the revision
       request overrides it
     - research/03-design-system/author/design-directions.md — its
       "## Corrections that override the research docs" table OVERRIDES
       your direction doc (docs/RESEARCH-ARCHIVE.md §7): the direction
       doc was never rewritten when a fact-checker refuted it, so a
       REFUTED font or effect must not appear in tokens.css even though
       the brief still names it; a PARTIALLY_TRUE claim ships only in
       its corrected form. The revision may not re-introduce one either
     - runs/<run_tag>/designs/<letter>/design-system.md — what exists today
     - runs/<run_tag>/temp/revision-R<N>/tweak-<letter>.md — the change
     - runs/<run_tag>/decisions/platform.md, research/product-spec.md

     REVISION RULES:
     - CHANGE WHAT THE REQUEST ASKS FOR AND ITS DEPENDENTS — nothing else.
       Keep the direction's name, thesis, signature element, and canonical
       token NAMES identical; the token contract from step 7.1 is unchanged.
     - Where the request contradicts a "## Commitments" line, the request
       wins — state the override explicitly in design-system.md.
     - Every DESIGN-CRAFT §3 commitment must still be present and specced
       after your edit; a revision that flattens the system into an §2
       anti-pattern is a failed revision, not a satisfied request.
     - Re-state the WCAG AA contrast pairs for both modes after any color
       change; a tweak that breaks contrast is rejected.
     Report back: what changed (token → old → new), what you deliberately
     left alone, and any commitment the request overrode. Data, not prose.
   ```
3. Re-run step 8 scoped to that letter — ALL of its screens, because the tokens moved —
   via the scoped-re-run mechanics below: re-spawn that design's smith(s), re-render
   `screenshots/<slug>.png` for that letter (step 8.6), then run the 8.5 visual QA pass
   for that letter in SCOPED ENTRY mode. **If manifest `screenshots_skipped: true`** (no
   Chrome binary on this machine — step 8.6 item 5 sets it), do NOT block on a render
   that cannot happen: skip the re-render, leave the flag set, and invoke step 8.5 in
   SOURCE-ONLY MODE, where the critic reviews the mockup HTML, every screen lands in
   `screens_not_viewed`, and step 12's checks 19/20 warn instead of failing.
   `designs/index.html` only needs rebuilding if the screen set changed
   (a tweak does not change it).
4. If the same tweak applies to all three directions, run this path once per direction
   and say so in the plan block's cost line.

#### 4D — EPICS scope

Write the constraint verbatim to `runs/<run_tag>/temp/revision-R<N>/constraints.md`
(e.g. "split the sync epic — it owns 9 tasks and two unrelated seams"), then re-run step
11 whole under it. The backlog is cheap to regenerate before Stage B and its internal
coverage audit (11.5) is the safety net; do not hand-surgery epic seams. The constraint
block is pasted into the `hb-epic-planner` and `hb-task-author` spawns as the ADDENDUM
below. Feature files, the PRD, and the designs are NOT touched by this scope.

### 5. Scoped re-run mechanics (binding for every step in the re-run set)

1. **Invoke the owning step skill** — `Skill(skill: "hyperbuild-<N>-<name>")`. Its
   procedure, spawn templates, validation checks, and exit criteria are AUTHORITATIVE.
   Never re-implement a step's work from this seat.
2. **The only permitted deviations** are: (a) the subset — which directions, screens,
   features, or epics get re-spawned; (b) the REVISION ADDENDUM appended to each spawn
   prompt; (c) not regenerating artifacts outside the subset.
3. **The spawn contract is never weakened.** Every Task prompt keeps all four pieces
   from the base template — verbatim block-quoted idea (now including its `## Revisions`
   section), pipeline position, specific inputs + exact output path, read-first context
   files — and every design-step spawn (6, 7, 8, 8.5) adds `docs/DESIGN-CRAFT.md` to its
   read-first list.
4. **REVISION ADDENDUM** — insert after `YOUR INPUTS` in each re-spawn:

   ```
   REVISION CONTEXT (R<N>, scope <scope>): this is a RE-RUN. The user
   reviewed the parked run and asked, verbatim:
   > <request>
   Ledger: runs/<run_tag>/decisions/revisions.md
   Scope file: runs/<run_tag>/temp/revision-R<N>/scope.md
   Honor it as a binding constraint on top of your normal brief. Change
   what it asks for and what genuinely depends on it; leave everything
   else byte-identical. Untouched artifacts belong to other agents.
   ```
5. **Pipeline order always** — 4 → 4.5 → 5 → 6 → 7 → 8 → 8.5 → 9 → 10 → 11 → 12. Never
   re-run a step before one it depends on, even when only the later one is in scope.
6. **Step 8.5 (visual QA):** `Skill(skill: "hyperbuild-8-5-visual-qa")`, entered in its
   **SCOPED ENTRY** mode (that skill's "Scoped entry" section): `scope_letters` = the
   affected letter(s), `scope_screens` = the re-rendered screens. It merges into the
   existing `gates/visual-qa-<letter>.json` rather than rewriting it, so the untouched
   letters' records — including any accepted known issues step 12's check 21 depends on —
   survive. Never substitute step 8's internal `### Step 8.5 — Validate the full matrix`
   for this: that is an existence/lorem/external-URL grep pass, not a visual review, and
   treating it as QA means no pixel was looked at.
7. **Never emit bare text while subagent Tasks are in flight** — append to
   `runs/<run_tag>/temp/orchestrator-notes.md` instead. A text-only response ends the
   turn and kills the revision mid-way.

### 6. Re-run the step-12 gate and park

Invoke `Skill(skill: "hyperbuild-12-design-gate")`. It runs all 21 checks fresh (a
revision can break a neighbor), rewrites `gates/design-gate-report.md` with a new round,
sets `steps.12 = "done"` and `blocked_on = "design-choice"` on pass — which clears the
`revision-in-flight:` marker — and emits the stop message. Add these two lines to that
message, directly above the `/hyperbuild-choose` line:

```
**Revision R<N> applied** — <scope>: <one line of what changed>.
Changed: <artifact paths>. Re-ran: <steps>. Full log: runs/<run_tag>/decisions/revisions.md
Revise again with `/hyperbuild-revise <change>` · new design directions with `/hyperbuild-redesign [notes]`
```

If the gate BLOCKS after its 2 fix rounds, do not soften it: the run stays
`blocked_on: "design-gate"`, and the ledger entry's `Outcome:` records `gate blocked —
<failed checks>`. A revision that broke the run says so.

### 7. Record the revision (mandatory — every time, including hand-offs)

`runs/<run_tag>/decisions/revisions.md` is the run's revision ledger; both this skill
and `/hyperbuild-redesign` append to it. Create it on first use with frontmatter; append
one `## R<N>` section per revision, newest LAST. `N` = 1 + the count of existing `## R`
headings.

```markdown
---
run_tag: pantry-guard-9fdb34
revisions: 2
last_revision: 2026-07-25T09:14:00Z
---
# Revisions — pantry-guard-9fdb34

## R2 — 2026-07-25T09:14:00Z — scope: feature

**Invocation:** `/hyperbuild-revise the pantry list should show a photo of each item`
**Request (verbatim):**
> the pantry list should show a photo of each item

**Classified as:** feature — changes one feature's content and two screens; the PRD's
personas and thesis are untouched.
**Authorization:** n/a (run was parked at design-choice)
**Artifacts touched:**
- features/02-pantry-list.md (States & edge cases, Acceptance criteria)
- features/00-index.md (row F-02)
- research/product-spec.md (screen inventory: Pantry Home row)
**Steps re-run:** 8 (pantry-home, item-detail × a,b,c) → 8.5 QA → 11 (epic 02) → 12
**Not re-run:** 4, 4.5 (thesis unchanged), 5–7 (no design or stack impact), 9, 10
**Outcome:** gate re-passed round 1; run parked at design-choice again.
```

Open the entry with `**Outcome:** in flight` at plan time (procedure step 3) and finish
the line at the end. A hand-off to `/hyperbuild-redesign` is still an entry, with
`**Outcome:** handed off to /hyperbuild-redesign — no artifacts changed`.

## Artifacts

- `runs/<run_tag>/decisions/revisions.md` — the ledger; one `## R<N>` section per revision
- `runs/<run_tag>/temp/revision-R<N>/scope.md` — the plan block + resolved re-run set (crash-resume point); `constraints.md` / `tweak-<letter>.md` where the scope uses them
- Scope-dependent rewrites: appended `## Revisions` in `runs/<run_tag>/idea.md` (idea) · `features/NN-<slug>.md` + `features/00-index.md` + PRD rows (feature) · `runs/<run_tag>/designs/<letter>/{design-system.md,tokens.css,mockups/,screenshots/}` (design) · `epics/**` (epics/feature)
- Updated `runs/<run_tag>/manifest.json` — re-run steps `"redo"` → `"done"`, `blocked_on` back to `"design-choice"`
- A fresh round in `runs/<run_tag>/gates/design-gate-report.md`

## Exit criteria

- The ledger entry exists, quotes the request verbatim, names the scope, every artifact
  touched, every step re-run, and a finished `Outcome:` line
- Every re-run step's manifest key reads `"done"`; no key is left at `"redo"`
- `runs/<run_tag>/idea.md`'s original frontmatter and verbatim idea body are byte-identical to before (idea scope: a new `## Revisions` entry is appended below them)
- `manifest.blocked_on` is `"design-choice"` (pass) or `"design-gate"` (honest block) — never still `revision-in-flight:*`
- `design_choice` is still `null` and `stage` is still `"PLAN"`; `app/` is untouched
- Step 12's stop message was emitted, carrying the revision lines and ending with `run /hyperbuild-choose a|b|c`

## Next step

There is none to invoke — the run is parked at the gate again. The user's levers are
`/hyperbuild-choose <a|b|c>` (build it), `/hyperbuild-revise <change>` (revise again),
or `/hyperbuild-redesign [notes]` (new design directions). **Do NOT invoke
`hyperbuild-choose`, `hyperbuild-13-scaffold`, or any Stage-B skill from here.**

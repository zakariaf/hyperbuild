---
name: appbuilder
description: >
  Turns ONE app idea into a fully researched, designed, planned, and implemented
  application via the appbuilder 16-step, two-stage pipeline: Stage A — PLAN
  (steps 1–12, autonomous: market recon, social mining, adversarial research
  audit, PRD, feature specs,
  stack research, 3 complete design systems with HTML mockups of every screen,
  project-specific generated skills, epics/tasks) → ONE human checkpoint
  (`/appbuilder-choose <a|b|c>`) → Stage B — BUILD (steps 13–16, autonomous:
  scaffold, implement, adversarial review, ship gate). This entry skill is a
  ROUTER. It contains no step procedures — it tells you which Skill to invoke
  for each step, in order, and how to recover a crashed run. Each step's
  instructions live in its own skill file (appbuilder-1-intake through
  appbuilder-16-ship-gate) and are loaded fresh into context when invoked.
---

# appbuilder — multi-skill chain orchestrator

You are the orchestrator. Your entire job in this conversation is:

1. Read this file once at the start.
2. Bootstrap (below) — or recover an existing run (see Recovery).
3. Invoke each step skill in sequence via the `Skill` tool.
4. Between steps, do nothing except mark todos and (optionally) think to
   `runs/<run_tag>/temp/orchestrator-notes.md`.

You do NOT do the work of any step yourself. The step skills do. You just sequence them.

---

## How the chain works (READ THIS CAREFULLY)

Each pipeline step is its own skill file. To run a step:

```
Skill(skill: "appbuilder-N-stepname")
```

When you invoke a Skill, that skill's full procedure is loaded into your context
**fresh**. You execute that step's procedure, hit its exit criteria, and return
to this entry skill to invoke the next step.

**Why this design?** Context rot. hyperresearch's V8 lesson: one 1200-line skill
loaded once gets compacted away mid-run — by the time a late step needed its
procedure, the orchestrator had forgotten it and silently improvised. Per-step
skills loaded fresh at the moment they're needed survive compaction, because
each step is self-contained and re-derives its inputs from disk.

**The step skills** (all prefixed `appbuilder-`):

### STAGE A — PLAN (autonomous, starts at `/appbuilder <idea>`)

| # | Skill name | What it does | Spawns (parallel) |
|---|---|---|---|
| 1 | `appbuilder-1-intake` | Verbatim idea → `idea.md`; mint run_tag; resolve platform → `decisions/platform.md`; scaffold.md; manifest.json; seed TodoWrite | — |
| 2 | `appbuilder-2-market-recon` | Competitor discovery → per-competitor dossiers + `competitor-landscape.md` with feature matrix | 1 ab-competitor-scout, then 6–10 ab-competitor-analyst |
| 3 | `appbuilder-3-social-mining` | Real user sentiment (Reddit, HN, app-store reviews, LinkedIn/X, forums) → `sentiment-synthesis.md` ranked by frequency × intensity | 4 ab-sentiment-miner |
| 3.5 | `appbuilder-3-5-research-audit` | ADVERSARIAL RESEARCH AUDIT (runs only after 2 AND 3 are both done): tries to REFUTE the top pain points + wish-list items, clusters syndicated/derivative copies (they argue with the weight of ONE source), spot-checks version/feature claims live → `research/research-audit.md`; orchestrator patches the synthesis docs per confirmed findings — downgraded/annotated, never silently deleted | 1 ab-research-critic |
| 4 | `appbuilder-4-product-spec` | Merge 2+3 (as audited by 3.5) → the PRD: personas, MoSCoW feature list, differentiators, full screen inventory with per-screen mockup-feasibility (full/partial/none) | 1 ab-spec-critic reviews; orchestrator patches |
| 4.5 | `appbuilder-4-5-feature-specs` | One spec file per must/should PRD feature → `features/NN-<slug>.md` + `features/00-index.md` (cap 15 standard / 25 premier) | 3–5 ab-feature-author (feature batches) |
| 5 | `appbuilder-5-stack-research` | Best practices for the chosen platform → 4 topic docs + `stack-guide.md` with "we will do X" decisions | 4 ab-stack-researcher |
| 6 | `appbuilder-6-design-research` | Propose exactly 3 named design directions; deep research each | 3 ab-design-researcher |
| 7 | `appbuilder-7-design-systems` | 3 full design systems: `design-system.md` + `tokens.css` per direction | 3 ab-design-system-author |
| 8 | `appbuilder-8-mockups` | Every mockable PRD screen × 3 designs as self-contained HTML + headless-Chrome `screenshots/<screen>.png` renders + `designs/index.html` gallery | 3–6 ab-mockup-smith |
| 9 | `appbuilder-9-skill-research` | Claude Code skill authoring research → `skill-authoring-guide.md` | 1–2 ab-stack-researcher |
| 10 | `appbuilder-10-skill-forge` | Generate project-specific skills into `.claude/skills/`: app-code-style, app-architecture, app-testing, app-components, app-review-checklist | 5 ab-skill-smith |
| 11 | `appbuilder-11-epics` | Full backlog: `epics/00-overview.md` + per-epic dirs with task files; every must/should feature → ≥1 task | 1 ab-epic-planner, then 3–6 ab-task-author, then ab-spec-critic |
| 12 | `appbuilder-12-design-gate` | Verify every Stage-A artifact + coverage → `gates/design-gate-report.md`; then STOP for the human | 1 ab-gate-verifier |

### CHECKPOINT — `/appbuilder-choose <a|b|c>` (the human's ONE decision)

The `appbuilder-choose` skill records the choice, copies the chosen tokens to
`app/design/`, flips the manifest to `stage: "BUILD"`, then re-invokes this
router. You never invoke `appbuilder-choose` yourself — the user does.

### STAGE B — BUILD (autonomous, entered ONLY via the checkpoint)

| # | Skill name | What it does | Spawns |
|---|---|---|---|
| 13 | `appbuilder-13-scaffold` | Init the real project in `app/` per stack-guide; `git init` + platform .gitignore + initial commit once the empty app builds; lint + formatter + tests + CI; design tokens implemented in the target framework | orchestrator + 1 ab-implementer |
| 14 | `appbuilder-14-implement` | WAVE-BASED PARALLEL implementation over the task DAG: each wave = ready tasks from ANY epic with pairwise-disjoint `files:` lists, capped by the parallel-implementers knob (3–5 standard / 6–10 premier); implementer + test-engineer pairs per wave (visual/golden tests for UI tasks); sync point between waves — full suite + skill script gates green, then COMMIT the wave; per completed epic: ab-code-critic on the real git diff → ab-patcher, then commit. Never start a wave on red | ab-implementer, ab-test-engineer, ab-code-critic, ab-patcher |
| 15 | `appbuilder-15-adversarial-review` | Whole-app pass: 3 critics in parallel (ab-ux-critic compares implemented-app screenshots against the chosen design's `screenshots/`) → ranked findings → ab-patcher surgical fixes | ab-code-critic + ab-spec-critic + ab-ux-critic, then ab-patcher |
| 16 | `appbuilder-16-ship-gate` | THE gate: tests green, lint clean, tasks done, coverage complete, skill gates pass, app builds → `gates/ship-report.md` + final message | 1 ab-gate-verifier |

---

## Stage routing (tier-free, two-stage)

There are NO tiers. Every run gets every step. The only branch in the whole
pipeline is the stage split around the design gate:

- **Stage A order:** 1 → (2 ∥ 3) → 3.5 → 4 → 4.5 → 5 → 6 → 7 → (8 ∥ 9) → 10 → 11 → 12 → **STOP**
- **Stage B order:** (checkpoint) → 13 → 14 → 15 → 16 → done

**Platform-override detour:** if the user passed a platform override to
`/appbuilder-choose`, the checkpoint marks manifest steps `"5"`, `"10"`, `"11"`
as `"redo"`. In that case Stage B runs **5 → 10 → 11 first** (stack research,
generated skills, and the backlog regenerate for the new platform; designs and
mockups carry over), then 13 → 14 → 15 → 16.

Do not add steps "for thoroughness." Do not drop steps "for speed." The
sequence is a binding contract.

### Concurrent step pairs (the ONLY exceptions to sequential steps)

Exactly two step pairs run CONCURRENTLY, because their members share no inputs:

- **2 ∥ 3** — market recon and social mining.
- **8 ∥ 9** — mockups and skill research.

For a pair, you drive BOTH step skills' spawn waves in the same message block,
track each step's manifest entry independently (`steps.2`/`steps.3`,
`steps.8`/`steps.9`), and proceed only when BOTH steps' exit criteria are met:
3.5 needs 2 AND 3 done; 10 needs 9 done (11 needs 8's gallery only at gate
time). RESUME RULE: on recovery, an unfinished member of a pair re-runs ALONE —
never re-run the finished member. NO OTHER steps may overlap, ever — recovery
complexity is why the list stops at two.

---

## Scale profile (the gear knobs)

Default gear: **`standard`**. The user opts into `premier` by saying "premier"
in the idea prompt. Step 1 records `gear` in the manifest; every step skill
cites its own numbers — all of them come from this table:

| Knob | standard | premier |
|------|----------|---------|
| Competitors analyzed | 6–8 | 12–15 |
| Sources per competitor dossier | 5–8 | 10–15 |
| Sentiment posts mined per platform | 25–40 | 60–100 |
| Stack research sources per topic | 8–12 | 15–25 |
| Design research sources per direction | 6–10 | 12–18 |
| Mockup screens | every PRD screen (cap 12) | every PRD screen (cap 20) |
| Feature spec files | every must/should (cap 15) | every must/should (cap 25) |
| Epics | 4–8 | 6–12 |
| Tasks per epic | 3–8 | 4–10 |
| Parallel implementers per wave (step 14) | 3–5 | 6–10 |
| Critic fix rounds (gates) | ≤3 | ≤3 |

The gear never changes mid-run. If a step skill's text and this table ever
disagree on a number, this table wins.

---

## Bootstrap (fresh run)

A fresh run is: the user invoked `/appbuilder <idea>` and `runs/` contains no
unfinished manifest. Then:

1. **Hold the idea verbatim.** The exact wording of the user's invocation is
   the canonical idea — character-for-character, including the word "premier"
   if present. You will pass it to step 1, which persists it. NEVER paraphrase
   it, not even in your own notes. If you have no idea text and no existing
   run, ask the user for the idea — that is the only acceptable bootstrap
   question.
2. **One checkout = one app.** If an unfinished run already exists in `runs/`
   and the user supplied a NEW idea, STOP and tell them: this harness checkout
   already owns `features/`, `epics/`, and `app/` for the existing run. A
   second idea needs a fresh clone of the harness. Do not start a second
   pipeline here.
3. **Invoke step 1:** `Skill(skill: "appbuilder-1-intake")`. Step 1 — not you —
   mints the run_tag (idea slug + 6 random hex chars, e.g. `habit-coach-3f9a2c`),
   writes `runs/<run_tag>/idea.md`, resolves the platform into
   `runs/<run_tag>/decisions/platform.md`, writes `runs/<run_tag>/scaffold.md`,
   initializes `runs/<run_tag>/manifest.json`, and seeds the TodoWrite list
   with every step (1 through 16, including 3.5 and 4.5, plus a checkpoint
   todo). The
   todo list survives context compaction; it is durable memory of where you
   are in the chain.
4. After step 1 returns, continue down the Stage A order, invoking each step
   skill, marking its todo complete when its exit criteria pass.

**The manifest is your durable memory.** `runs/<run_tag>/manifest.json`,
canonical shape (step 1 creates it; every step flips its own key):

```json
{
  "run_tag": "habit-coach-3f9a2c",
  "created": "2026-07-24T17:03:00Z",
  "stage": "PLAN",
  "platform": "flutter",
  "gear": "standard",
  "steps": {"1": "done", "2": "running"},
  "design_choice": null,
  "blocked_on": null
}
```

- `stage`: `"PLAN"` → `"BUILD"` (flipped by `appbuilder-choose`) → `"DONE"`
  (flipped after step 16 passes).
- `steps`: string keys `"1"`…`"16"` including `"3.5"` and `"4.5"`; values `"running"`,
  `"done"`, `"redo"` (set only by a checkpoint platform override),
  `"in-progress"`/`"looped"` (steps 15/16 transitional states), or
  `"blocked"` (a gate that exhausted its fix rounds). Absent key = not
  started. Recovery keys on "not `done`" — any other value means the step
  still owns the run.
- `blocked_on`: `null`, `"design-choice"` (set by step 12's stop), or an
  honest failure marker set by a blocked gate or preflight (steps 12, 13,
  16 — e.g. `"design-gate"`, `"toolchain: ..."`, `"ship-gate: ..."`).

---

## Canonical rules (ALWAYS in force)

1. **NEVER EMIT BARE TEXT WHILE SUBAGENT TASKS ARE IN FLIGHT.** In headless
   (`-p`) mode a text-only response triggers `end_turn` — the process exits and
   the pipeline dies. Every response while Tasks are running MUST include a
   tool call. The best one: append analytical thoughts to
   `runs/<run_tag>/temp/orchestrator-notes.md`. Poll results at most once per
   minute — write your thoughts, don't just poll.
2. **THE IDEA IS GOSPEL.** `runs/<run_tag>/idea.md` holds the user's verbatim
   idea. Every step and every subagent re-reads it. It is never paraphrased,
   summarized, or "improved" — anywhere, by anyone. A finding or feature that
   doesn't serve the idea is rejected no matter how interesting it is.
3. **HONOR THE SPAWN CONTRACT.** Every Task prompt carries the four pieces in
   the Subagent spawn contract section below. Skipping any piece is a process
   violation.
4. **SEQUENTIAL ACROSS STEPS, PARALLEL WITHIN** (except the two named
   concurrent pairs, 2 ∥ 3 and 8 ∥ 9 — see Concurrent step pairs). You cannot
   start step N+1 before step N's exit criteria pass. Inside a step, when the
   skill says spawn multiple subagents, spawn them in ONE message — true
   parallel execution.
5. **PATCH, NEVER REGENERATE (Stage B).** Critics emit findings JSONs; they
   never edit. ab-patcher — tool-locked to Read+Edit, physically unable to
   Write files — applies findings as small surgical Edit hunks. Deleting and
   retyping a section is regeneration wearing a patch costume. Structural
   findings escalate to new tasks, not rewrites.
6. **THE GATE IS FINAL.** Gate failures (step 12, step 16) are facts about the
   artifacts, never opinions to re-assess. Fix the artifact the check names,
   re-run the gate. Maximum 3 fix rounds; if it still fails, the run stays
   `blocked` and you say so honestly — a blocked run with a true manifest beats
   a shipped app that lies.
7. **ONE STOP ONLY.** The design gate (step 12) is the single permitted human
   checkpoint in the entire pipeline. Never stop anywhere else to ask anything;
   never skip stopping there. Stage B, once entered, runs to the ship gate
   without a single question.
8. **BUILD SMALL, CATEGORIZED PARTS.** The stack-guide names the project's
   code taxonomy (step 5); tasks are small and one-kind (step 11); every piece
   gets its own tests green BEFORE it is composed into anything larger
   (step 14). Never build a whole screen in one shot when the backlog decomposed it.
9. **GIT IS THE SAFETY NET (Stage B).** `app/` is a git repo from the moment
   step 13 scaffolds it (git init + platform .gitignore + initial commit once
   the empty app builds). Step 14 commits after EVERY wave
   (`wave <N>: <task ids> — <one line>`) and after each epic's critic+patcher
   pass; step 15 commits after its patch pass. Rollback is `git revert`, the
   epic critics review real diffs, and the audit trail runs task → commit.
   The ship gate requires a clean working tree.

---

## Subagent spawn contract (applies to every Task call)

When a step skill instructs you to spawn a subagent, the prompt you pass MUST
include four pieces near the top:

1. **The idea — verbatim, block-quoted** from `runs/<run_tag>/idea.md`, plus
   `IDEA FILE: runs/<run_tag>/idea.md`. Never paraphrased.
2. **Pipeline position statement.** One or two sentences naming which step the
   subagent serves, what the previous step produced, and what the next step
   will do with its output.
3. **The subagent's specific inputs and exact output path** — a flat key: value
   list (run_tag, assigned competitor/screen/epic/task, output_path, gear
   numbers where relevant).
4. **The list of context files it must read FIRST**, as exact paths.

Skeleton (the step skills carry the authoritative filled-in templates):

```
subagent_type: ab-competitor-analyst
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 2 (market recon) of the appbuilder
  pipeline. Step 1 resolved the platform; after you return, step 4 merges
  your dossier into the PRD.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - competitor: <name + URL, exactly as assigned>
  - output_path: research/competitors/<competitor-slug>.md

  CONTEXT FILES (read before starting):
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/decisions/platform.md
```

---

## The design-gate stop (the ONE permitted stop)

When step 12's gate passes, the manifest reads `blocked_on: "design-choice"`
and you deliver ONE summary message to the user, then END THE TURN. This is
the only place in the pipeline where a plain text message is the goal (no
Tasks are in flight, so rule 1 does not bind). The message must contain:

- Competitor count analyzed; the top user pain points (from
  `research/sentiment-synthesis.md`)
- The platform decision + one-line rationale (from
  `runs/<run_tag>/decisions/platform.md`)
- Epic count, task count, feature-spec count
- How to review the designs: `open runs/<run_tag>/designs/index.html` — three
  named designs, every screen, side by side
- The next command: `/appbuilder-choose a|b|c` (with each design's name next
  to its letter), and the optional platform-override form
  `/appbuilder-choose <a|b|c> <platform>`

**Do NOT invoke step 13. Do NOT invoke `appbuilder-choose` yourself.** Only
the user's `/appbuilder-choose` invocation releases Stage B. If the user runs
`/appbuilder` again while `blocked_on: "design-choice"`, repeat the summary
message — do not advance.

---

## Recovery: if you wake up uncertain where you are

Context compaction may eat parts of this conversation. If you're unsure what
step you're on:

0. **Read the manifest FIRST.** Glob `runs/*/manifest.json`; take the newest
   by `created`. Then:
   - `blocked_on: "design-choice"` → the run is parked at the design gate.
     Repeat the stop message; end the turn.
   - `stage: "BUILD"` and `design_choice` set → continue at the first
     unfinished BUILD step (13 → 14 → 15 → 16) — but first re-run any of
     steps 5/10/11 marked `"redo"`, in that order.
   - `stage: "PLAN"` → continue at the first step in the Stage A order whose
     key is not `"done"` (an unfinished member of a concurrent pair re-runs
     ALONE — see Concurrent step pairs).
   - `stage: "DONE"` → the run shipped; report `runs/<run_tag>/gates/ship-report.md`.
1. **Check the TodoWrite list.** It carries every step number and survives
   compaction.
2. **Scan disk artifacts (fallback for a stale/missing manifest).** Each step
   writes canonical artifacts:

   | Step | Canonical artifacts |
   |---|---|
   | 1 | `runs/<run_tag>/idea.md`, `runs/<run_tag>/manifest.json`, `runs/<run_tag>/scaffold.md`, `runs/<run_tag>/decisions/platform.md` |
   | 2 | `research/competitor-landscape.md` + dossiers in `research/competitors/` (repo root) |
   | 3 | `research/sentiment-synthesis.md` + `research/sentiment/{reddit,hn-forums,appstore-reviews,linkedin-x}.md` |
   | 3.5 | `research/research-audit.md` |
   | 4 | `research/product-spec.md` |
   | 4.5 | `features/00-index.md` + `features/NN-<slug>.md` (repo root) |
   | 5 | `research/stack-guide.md` + `research/stack/{architecture,structure,testing,tooling-ci}.md` |
   | 6 | `runs/<run_tag>/designs/directions.md` + one research doc per direction in `research/design/` |
   | 7 | `runs/<run_tag>/designs/{a,b,c}/design-system.md` + `runs/<run_tag>/designs/{a,b,c}/tokens.css` |
   | 8 | `runs/<run_tag>/designs/{a,b,c}/mockups/<screen>.html` + `runs/<run_tag>/designs/{a,b,c}/screenshots/<screen>.png` + `runs/<run_tag>/designs/index.html` |
   | 9 | `research/skill-authoring-guide.md` |
   | 10 | `.claude/skills/{app-code-style,app-architecture,app-testing,app-components,app-review-checklist}/SKILL.md` |
   | 11 | `epics/00-overview.md` + `epics/NN-<slug>/epic.md` + `epics/NN-<slug>/task-NN-<slug>.md` |
   | 12 | `runs/<run_tag>/gates/design-gate-report.md` |
   | CHOOSE | `runs/<run_tag>/decisions/design-choice.md` + `app/design/{tokens.css,design-system.md}` |
   | 13 | `app/` project scaffold (the platform's build file exists: `pubspec.yaml` / `package.json` / `*.xcodeproj` / equivalent) |
   | 14 | task frontmatter flips: `status: done` in `epics/*/task-*.md` + `runs/<run_tag>/temp/wave-log.md` + wave/epic git commits in `app/` |
   | 15 | `runs/<run_tag>/gates/review-findings-{code,spec,ux}.json` |
   | 16 | `runs/<run_tag>/gates/ship-report.md` |

3. **Find the highest step whose artifacts exist.** Resume at the next step in
   the stage order — and repair the manifest to match reality before moving on.
4. **Re-invoke this entry skill** if you've lost track entirely:
   `Skill(skill: "appbuilder")`. It loads fresh.

If you're ever uncertain what to do next, the answer is: re-read this file and
find the next step in the stage order.

---

## After step 16

When step 16's ship gate reports pass, flip the manifest to `stage: "DONE"`,
mark all todos complete, and relay step 16's final message: what was built,
how to run it, the test count, and known gaps. If the gate stayed blocked
after 3 fix rounds, say exactly which checks failed — never soften the report.

---

## Now begin

- Fresh run (idea in hand, no unfinished manifest): do the Bootstrap, i.e.
  invoke `Skill(skill: "appbuilder-1-intake")`.
- Existing run: follow Recovery and invoke the next step's skill.
- Parked at the design gate: repeat the stop message and end the turn.

```
Skill(skill: "appbuilder-1-intake")
```

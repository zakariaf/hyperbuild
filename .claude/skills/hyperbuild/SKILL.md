---
name: hyperbuild
description: >
  Turns ONE app idea into a fully researched, designed, planned, and implemented
  application via the hyperbuild 19-step, two-stage pipeline: Stage A — PLAN
  (steps 1–12, autonomous: market recon, social mining, adversarial research
  audit — every load-bearing claim fact-checked by its own agent into a
  four-phase research archive — PRD, feature specs,
  stack research, 3 complete design systems with HTML mockups of every screen,
  adversarial VISUAL QA of every rendered screen,
  project-specific generated skills, epics/tasks) → ONE human checkpoint
  (`/hyperbuild-choose <a|b|c>`) → Stage B — BUILD (steps 13–16, autonomous:
  scaffold, implement, adversarial review, ship gate). This entry skill is a
  ROUTER. It contains no step procedures — it tells you which Skill to invoke
  for each step, in order, and how to recover a crashed run. Each step's
  instructions live in its own skill file (hyperbuild-1-intake through
  hyperbuild-16-ship-gate) and are loaded fresh into context when invoked.
  The router also owns RUN CONTROL, which no step skill owns: the
  `runs/<run_tag>/.lock` concurrency guard, the `runs/<run_tag>/ABORT` kill
  switch, the per-step-class turn and wall-clock caps, and the per-step `usage`
  record written into the manifest after every step returns.
---

# hyperbuild — multi-skill chain orchestrator

You are the orchestrator. Your entire job in this conversation is:

1. Read this file once at the start.
2. Bootstrap (below) — or recover an existing run (see Recovery).
3. Claim the run lock before the first step and hold it for the session
   (Run control §1).
4. Invoke each step skill in sequence via the `Skill` tool.
5. After EVERY step returns: write that step's `usage` record to the manifest
   (Run control §4), then check `runs/<run_tag>/ABORT` (Run control §2), then
   start the next step.
6. Between steps, do nothing except the above, mark todos, and (optionally)
   think to `runs/<run_tag>/temp/orchestrator-notes.md`.

You do NOT do the work of any step yourself. The step skills do. You just sequence them.

---

## How the chain works (READ THIS CAREFULLY)

Each pipeline step is its own skill file. To run a step:

```
Skill(skill: "hyperbuild-N-stepname")
```

When you invoke a Skill, that skill's full procedure is loaded into your context
**fresh**. You execute that step's procedure, hit its exit criteria, and return
to this entry skill to invoke the next step.

**Why this design?** Context rot. hyperresearch's V8 lesson: one 1200-line skill
loaded once gets compacted away mid-run — by the time a late step needed its
procedure, the orchestrator had forgotten it and silently improvised. Per-step
skills loaded fresh at the moment they're needed survive compaction, because
each step is self-contained and re-derives its inputs from disk.

**The step skills** (all prefixed `hyperbuild-`):

### STAGE A — PLAN (autonomous, starts at `/hyperbuild <idea>`)

| # | Skill name | What it does | Spawns (parallel) |
|---|---|---|---|
| 1 | `hyperbuild-1-intake` | Verbatim idea → `idea.md`; mint run_tag; resolve platform → `decisions/platform.md`; scaffold.md; manifest.json; seed TodoWrite | — |
| 2 | `hyperbuild-2-market-recon` | Competitor discovery → per-competitor dossiers in `research/01-product-and-market/research/competitors/`; every LOAD-BEARING claim (price, tier, version, shipped feature) registered in `temp/claims-01.json` and fact-checked into `research/01-product-and-market/verify/`; synthesis → `.../author/competitor-landscape.md` | 1 hb-competitor-scout, then 6–8 / 12–15 hb-competitor-analyst (per gear), then one hb-claim-verifier PER CLAIM |
| 3 | `hyperbuild-3-social-mining` | Real user sentiment (Reddit, HN, app-store reviews, LinkedIn/X, forums) → `research/01-product-and-market/research/sentiment/<platform>.md`, claims registered + verified into the same area's `verify/`, synthesis → `.../author/sentiment-synthesis.md` ranked by frequency × intensity | 4 hb-sentiment-miner, then one hb-claim-verifier per registered claim |
| 3.5 | `hyperbuild-3-5-research-audit` | AREA 01 CORPUS CRITIQUE + INDEX (runs only after 2 AND 3 are both done): corpus critics read the WHOLE area — cross-dimension contradictions, cherry-picking, syndicated/derivative copies that argue with the weight of ONE source — → `research/01-product-and-market/critique/<critic-name>.md`; then the area's `_INDEX.md` (every agent, every phase, every verdict). Orchestrator applies CONFIRMED findings + every verify/ correction to the `author/` docs — REFUTED claims never survive into a synthesis, and nothing is silently deleted | 2 critic seats standard / 3 premier, one distinct lens each — hb-research-critic takes the `live-evidence` seat (its enumerated 7-check list: syndication clustering + recount + rank, source independence, verbatim quote integrity, staleness vs last release, live spot-checks outside verify/, sample frame, demand-vs-supply), hb-corpus-critic the rest (`completeness`, plus `domain:<slug>` at premier) |
| 4 | `hyperbuild-4-product-spec` | Merge 2+3 (as audited by 3.5) → the PRD: personas, MoSCoW feature list, differentiators, full screen inventory with per-screen mockup-feasibility (full/partial/none) | 1 hb-spec-critic reviews; orchestrator patches |
| 4.5 | `hyperbuild-4-5-feature-specs` | One spec file per must/should PRD feature → `features/NN-<slug>.md` + `features/00-index.md` (cap 15 standard / 25 premier) | 3–5 hb-feature-author (feature batches) |
| 5 | `hyperbuild-5-stack-research` | Best practices for the chosen platform, ONE agent per dimension (6–8 standard / 10–14 premier) → `research/02-engineering/research/<dimension>.md`; claims registered in `temp/claims-02.json`, one verifier per claim → `verify/`; corpus critics → `critique/`; then `research/02-engineering/author/stack-guide.md` with "we will do X" decisions | 6–8 / 10–14 hb-stack-researcher, then hb-claim-verifier per claim (≤25 / ≤60 per area), then **3 / 5** hb-corpus-critic — area 02 runs the larger panel by design |
| 6 | `hyperbuild-6-design-research` | Propose exactly 3 named design directions; deep research each → `research/03-design-system/research/<direction-slug>.md`; claims registered in `temp/claims-03.json` and verified (platform design-system status, font licences, API/component names) → `verify/`; critics → `critique/`; `author/design-directions.md` | 3 hb-design-researcher, then hb-claim-verifier per claim, then 2 / 3 hb-corpus-critic (per gear) |
| 7 | `hyperbuild-7-design-systems` | 3 full design systems: `design-system.md` + `tokens.css` per direction | 3 hb-design-system-author |
| 8 | `hyperbuild-8-mockups` | Every mockable PRD screen × 3 designs as self-contained HTML + headless-Chrome `screenshots/<screen>.png` renders + `designs/index.html` gallery | 3–6 hb-mockup-smith |
| 8.5 | `hyperbuild-8-5-visual-qa` | VISUAL DESIGN QA (runs only after step 8 is done): one critic per direction VIEWS every rendered `screenshots/<screen>.png` and judges it against `docs/DESIGN-CRAFT.md` + that direction's own `design-system.md` — craft (signature element, display/body type pairing, depth model, shape language, data personality, empty-state art) and layout integrity (clipping, FAB/nav overlap, deliberate truncation, tap targets, contrast, safe areas), plus the cross-direction distinctness check judged on PIXELS, not on prose → `gates/visual-qa-{a,b,c}.json`; every defect re-spawns the responsible `hb-mockup-smith` with the named screenshot + defect, re-renders, re-critiques (≤2 critic rounds = exactly ONE patch round; what survives is written down and shown to the user, never looped on) | 3 hb-design-critic |
| 9 | `hyperbuild-9-skill-research` | Claude Code skill authoring research, one agent per dimension → `research/04-claude-skills/research/<dimension>.md`; claims registered in `temp/claims-04.json` and verified (frontmatter fields, tool names, format rules that a skill will be BUILT against) → `verify/`; critics → `critique/`; `author/skill-authoring-guide.md` | one hb-stack-researcher per dimension, then hb-claim-verifier per claim, then 2 / 3 hb-corpus-critic (per gear) |
| 10 | `hyperbuild-10-skill-forge` | Generate project-specific skills into `.claude/skills/`: app-code-style, app-architecture, app-testing, app-components, app-review-checklist | 5 hb-skill-smith |
| 11 | `hyperbuild-11-epics` | Full backlog: `epics/00-overview.md` + per-epic dirs with task files; every must/should feature → ≥1 task | 1 hb-epic-planner, then 3–6 hb-task-author, then hb-spec-critic |
| 12 | `hyperbuild-12-design-gate` | Verify every Stage-A artifact + coverage → `gates/design-gate-report.md`; write `research/README.md` — the areas index + REUSABILITY GUIDE (RESEARCH-ARCHIVE §8: what the NEXT app can copy instead of re-researching); then STOP for the human | 1 hb-gate-verifier |

### CHECKPOINT — `/hyperbuild-choose <a|b|c>` (the human's ONE decision)

The `hyperbuild-choose` skill records the choice, copies the chosen tokens to
`app/design/`, flips the manifest to `stage: "BUILD"`, then re-invokes this
router. You never invoke `hyperbuild-choose` yourself — the user does.

### STAGE B — BUILD (autonomous, entered ONLY via the checkpoint)

| # | Skill name | What it does | Spawns |
|---|---|---|---|
| 13 | `hyperbuild-13-scaffold` | Init the real project in `app/` per stack-guide; `git init` + platform .gitignore + initial commit once the empty app builds; lint + formatter + tests + CI; design tokens implemented in the target framework | orchestrator + 1 hb-implementer |
| 14 | `hyperbuild-14-implement` | WAVE-BASED PARALLEL implementation over the task DAG: each wave = ready tasks from ANY epic with pairwise-disjoint `files:` lists, capped by the parallel-implementers knob (3–5 standard / 6–10 premier); implementer + test-engineer pairs per wave (visual/golden tests for UI tasks); sync point between waves — full suite + skill script gates green, then COMMIT the wave; per completed epic: hb-code-critic on the real git diff → hb-patcher, then commit. Never start a wave on red | hb-implementer, hb-test-engineer, hb-code-critic, hb-patcher |
| 15 | `hyperbuild-15-adversarial-review` | Whole-app pass: 3 critics in parallel (hb-ux-critic compares implemented-app screenshots against the chosen design's `screenshots/`) → ranked findings → hb-patcher surgical fixes | hb-code-critic + hb-spec-critic + hb-ux-critic, then hb-patcher |
| 16 | `hyperbuild-16-ship-gate` | THE gate: tests green, lint clean, tasks done, coverage complete, skill gates pass, app builds → `gates/ship-report.md` + final message | 1 hb-gate-verifier |

---

## Commands (what the USER may type — you never invoke these yourself)

| Command | Applies when | What it does |
|---|---|---|
| `/hyperbuild <idea>` | no unfinished run exists | Bootstrap + drive Stage A to the design gate. |
| `/hyperbuild-choose <a\|b\|c> [platform]` | run parked at the design gate | Records the choice, releases Stage B. |
| `/hyperbuild-revise <plain-English change>` | run parked at the design gate | Change something before the build starts. The skill CLASSIFIES the free-form request into one of four scopes and applies only that scope's blast radius: **idea** (a dated `## Revisions` entry appended to `idea.md`, then PRD + feature specs + everything downstream) · **feature** (surgical edits to `features/*.md` + `00-index.md` + the PRD rows, then the affected epics) · **design** (a tweak to ONE direction that stays itself: step 7 for that letter, its smiths, its screenshots, step 8.5 scoped) · **epics** (step 11 re-run under a stated constraint). New/replacement directions are handed off to `/hyperbuild-redesign`. Always re-runs step 12. |
| `/hyperbuild-redesign [notes]` | run parked at the design gate | Regenerates the design directions from the user's free-form notes — every slot by default, or only the letters they don't KEEP (`keep c, replace a and b`). Kept letters survive untouched: same letter, system, tokens, mockups and screenshots. Replaced slots are archived under `designs/archive/round-<N>/`, then 6 → 7 → 8 → 8.5 → 12 re-run for the new letters only. Research, feature specs, epics, and generated skills all survive — only the designs are rebuilt. |

BOTH design commands apply **only to a run parked at the design gate**
(`stage: "PLAN"`, `steps["12"] == "done"`, `blocked_on: "design-choice"`). In
any other state they refuse and say why — they are not a mid-Stage-B escape
hatch. The verbatim idea body and frontmatter in `idea.md` are IMMUTABLE — never
reworded, reordered, or "reconciled" — but `/hyperbuild-revise` at IDEA scope may
APPEND a dated `## Revisions` entry below them, quoting the user's request
verbatim; that append is the propagation mechanism, because every spawn
block-quotes the idea body. Both commands also record the steer in
`runs/<run_tag>/decisions/revisions.md` (a shared ledger, appended to, one entry
per invocation). Both mark the steps they invalidate as `"redo"` in the manifest,
and both END by re-parking the run at the design gate with a fresh gate report —
the ONE stop stays the ONE stop, and only `/hyperbuild-choose` ever releases
Stage B.

---

## Stage routing (tier-free, two-stage)

There are NO tiers. Every run gets every step. The only branch in the whole
pipeline is the stage split around the design gate:

- **Stage A order:** 1 → (2 ∥ 3) → 3.5 → 4 → 4.5 → 5 → 6 → 7 → (8 ∥ 9) → 8.5 → 10 → 11 → 12 → **STOP**
- **Stage B order:** (checkpoint) → 13 → 14 → 15 → 16 → done

**Platform-override detour:** if the user passed a platform override to
`/hyperbuild-choose`, the checkpoint marks manifest steps `"5"`, `"10"`, `"11"`
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
3.5 needs 2 AND 3 done; 8.5 needs 8 done; 10 needs 9 done (11 needs 8's gallery
only at gate time). RESUME RULE: on recovery, an unfinished member of a pair
re-runs ALONE — never re-run the finished member. NO OTHER steps may overlap,
ever — recovery complexity is why the list stops at two.

**Step 8.5 is NOT a third concurrent member.** It consumes step 8's output
only, so it can never start before step 8's exit criteria pass; invoke it once
BOTH members of the 8 ∥ 9 pair have returned, which is what the Stage A order
`(8 ∥ 9) → 8.5 → 10` encodes. On recovery it re-runs ALONE whenever
`steps["8"]` is `done` and `steps["8.5"]` is not.

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
| Engineering research dimensions | 6–8 | 10–14 |
| Design research sources per direction | 6–10 | 12–18 |
| Claims verified per research file | 3–5 | 6–10 |
| Verify agents per area (hard ceiling — `VERIFY_BUDGET`) | ≤25 | ≤60 |
| Corpus critics per area *(the area binds the count: 01/03/04 = 2 / 3 · 02 = 3 / 5)* | 2–3 | 3–5 |
| Mockup screens | every PRD screen (cap 12) | every PRD screen (cap 20) |
| Feature spec files | every must/should (cap 15) | every must/should (cap 25) |
| Epics | 4–8 | 6–12 |
| Tasks per epic | 3–8 | 4–10 |
| Parallel implementers per wave (step 14) | 3–5 | 6–10 |
| Critic fix rounds (gates) | ≤2 | ≤2 |

The gear never changes mid-run. If a step skill's text and this table ever
disagree on a number, this table wins.

**Fix rounds are the one knob that does NOT widen with the gear.** Every other
row buys more coverage at `premier`; this one stays at 2 in both columns, and
round 2 is itself conditional on a changed Tier-0 signal (PIPELINE.md principle
7). Unaided re-attempts degrade rather than converge — a third round is the
model talking itself into a different answer, not a better one.

**What the verification knobs cost — say it plainly.** Research is no longer
one agent per dimension; it is one agent per dimension PLUS one fact-checker per
load-bearing claim PLUS the area's corpus critics. A `standard` engineering
area is now roughly 6–8 researchers + 20–40 verifiers + 2 critics + 1 author
where it used to be 4 researchers and a merge, and areas 01, 03 and 04 scale
the same way. Expect research to run several times the agents and several times
the wall clock it did before the archive contract — and to dominate the token
bill of a run. That is the deal being struck on purpose: the verify/ pass is
the only reason a price, a version, a licence, or a store policy in this vault
is worth reading six months from now, and the whole archive is reusable by the
NEXT app (see `research/README.md`), so the cost is paid once across many
builds. Do NOT quietly shrink the fan-out to save time: dropping verifiers
turns a checked archive back into a confident survey, which is exactly the
failure this contract exists to stop. If a run must be cheaper, run
`standard`, never a hand-trimmed `standard`.

---

## Bootstrap (fresh run)

A fresh run is: the user invoked `/hyperbuild <idea>` and `runs/` contains no
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
3. **Preflight the checkout for a live session.** Before step 1 there is no
   run_tag and therefore no lock to claim, so check the whole directory:
   `ls runs/*/.lock 2>/dev/null` and `ls runs/*/ABORT 2>/dev/null`. A LIVE lock
   on any run (Run control §1 decides liveness) means another session owns this
   checkout — REFUSE to start and say so. An `ABORT` file means a run here was
   deliberately killed — say so and let the user clear it.
4. **Invoke step 1:** `Skill(skill: "hyperbuild-1-intake")`. Step 1 — not you —
   mints the run_tag (idea slug + 6 random hex chars, e.g. `habit-coach-3f9a2c`),
   writes `runs/<run_tag>/idea.md`, resolves the platform into
   `runs/<run_tag>/decisions/platform.md`, writes `runs/<run_tag>/scaffold.md`,
   initializes `runs/<run_tag>/manifest.json`, and seeds the TodoWrite list
   with every step (1 through 16, including the half-steps 3.5, 4.5 and 8.5,
   plus a checkpoint todo) — **20 todos**. The
   todo list survives context compaction; it is durable memory of where you
   are in the chain.
5. **The moment step 1 returns, claim the lock** — the run_tag now exists, so
   `runs/<run_tag>/.lock` is claimable (Run control §1). Write step 1's `usage`
   record (Run control §4) in the same breath.
6. Then continue down the Stage A order, invoking each step skill, marking its
   todo complete when its exit criteria pass — with the between-steps ritual
   (usage record → ABORT check) at every boundary.

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
  "usage": {
    "1": {
      "agents_spawned": 0,
      "turns": 6,
      "wall_clock_s": 78,
      "outcome": "done",
      "cost_usd": null,
      "cost_source": "unavailable",
      "notes": "intake only — no spawns"
    }
  },
  "usage_summary": null,
  "frozen_gates": null,
  "design_choice": null,
  "blocked_on": null
}
```

- `stage`: `"PLAN"` → `"BUILD"` (flipped by `hyperbuild-choose`) → `"DONE"`
  (flipped after step 16 passes).
- `steps`: string keys `"1"`…`"16"` including `"3.5"`, `"4.5"` and `"8.5"`; values `"running"`,
  `"done"`, `"redo"` (set by a checkpoint platform override, or by
  `/hyperbuild-revise` / `/hyperbuild-redesign` for the design steps they
  invalidate), `"in-progress"`/`"looped"` (steps 15/16 transitional states), or
  `"blocked"` (a gate that exhausted its fix rounds). Absent key = not
  started. Recovery keys on "not `done`" — any other value means the step
  still owns the run.
- `usage`: one record per step key, written by YOU (not by the step skill) after
  the step returns — `{agents_spawned, turns, wall_clock_s, outcome, cost_usd,
  cost_source, notes}`. Shape, honesty rules, and the exact shell: Run control §4.
- `usage_summary`: `null` until the design gate; then `{stage_a: {...}}`, and
  `{stage_a, stage_b}` after the ship gate. Run control §5.
- `frozen_gates`: `null` until step 12 freezes the generated-skill script gates
  (the frozen copies under `runs/<run_tag>/gates/skill-scripts/` plus a SHA-256
  per script); steps 14 and 16 execute only those frozen copies and fail on a
  hash mismatch. **Step 12 owns the field's shape — the router only preserves
  it.** This is exactly why you read-modify-write the manifest and never
  regenerate it from memory (Run control §4).
- `blocked_on`: `null`, `"design-choice"` (set by step 12's stop), an
  IN-FLIGHT marker set by a gate-time command skill —
  `"revision-in-flight:R<N>"` (`/hyperbuild-revise`) or
  `"redesign-in-flight:round-<N>"` (`/hyperbuild-redesign`) — or an
  honest failure marker set by a blocked gate or preflight (steps 12, 13,
  16 — e.g. `"design-gate"`, `"toolchain: ..."`, `"ship-gate: ..."`) — or one of
  the two RUN-CONTROL markers the router itself sets:
  `"aborted-by-user"` (the `ABORT` file was present at a step boundary, §2) and
  `"cap: <what fired>"` (a turn or wall-clock ceiling was hit, §3 — e.g.
  `"cap: step 5 turn ceiling 30 (research class)"`,
  `"cap: step 14 wave 3 wall clock 120m"`).

---

## Run control (the router's own procedure — no step skill owns any of this)

Four mechanics live here and nowhere else: the concurrency **lock**, the
**ABORT** kill switch, the per-step-class **caps**, and the per-step **usage**
record. You execute all four in the gaps BETWEEN steps. They exist because a
manifest is crash-*resumable*, not crash-*proof*: nothing in it stops two
sessions from resuming the same run, stops a wedged step from looping forever,
lets a user outside the loop halt it, or records what any of it cost.

### §1 — The run lock: `runs/<run_tag>/.lock`

Two sessions resuming one run_tag both execute: same waves, same files, same
manifest keys, twice, interleaved. The manifest cannot prevent that — a lock can.

**Claim it before the FIRST step of any session.** One claim per SESSION, not
per step. Four moments trigger a claim: a fresh run, the instant step 1 returns
with a run_tag; a resume, before you re-invoke anything; a hand-back, when
`/hyperbuild-choose`, `/hyperbuild-revise`, or `/hyperbuild-redesign` re-enters
this router to drive steps (those skills own the gate, the router owns the lock
— claim it as you take over, release it when you re-park); and, as a catch-all,
**any turn in which you are about to invoke a step skill and do not already hold
the lock**. The fourth exists because the release rule below can legitimately
drop the lock at a turn boundary mid-Stage-A; re-claiming is cheap and
idempotent (`LOCK-MINE` below), continuing unlocked is not.

```bash
RUN="runs/<run_tag>"; LOCK="$RUN/.lock"; mkdir -p "$RUN"
PAYLOAD=$(printf '{"pid":%s,"host":"%s","claimed":"%s"}' \
  "$PPID" "$(hostname)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)")
if ( set -o noclobber; printf '%s\n' "$PAYLOAD" > "$LOCK" ) 2>/dev/null; then
  echo "LOCK-CLAIMED"
else
  echo "LOCK-EXISTS"; cat "$LOCK"
fi
```

`set -o noclobber` makes the create **atomic** — the redirect fails if the file
already exists, so two sessions racing cannot both win. `$PPID` inside a Bash
tool call is the Claude Code process that owns this session; it is the only
liveness handle reachable from inside the loop, and it is honest to say it is a
handle rather than a guarantee.

**On `LOCK-EXISTS`, decide liveness — never just overwrite:**

```bash
LOCK="runs/<run_tag>/.lock"
LPID=$(jq -r '.pid  // empty' "$LOCK" 2>/dev/null)
LHOST=$(jq -r '.host // empty' "$LOCK" 2>/dev/null)
if   [ "$LPID" = "$PPID" ] && [ "$LHOST" = "$(hostname)" ]; then echo "LOCK-MINE pid=$LPID"
elif [ "$LHOST" != "$(hostname)" ];               then echo "LOCK-FOREIGN host=$LHOST"
elif [ -n "$LPID" ] && kill -0 "$LPID" 2>/dev/null; then echo "LOCK-LIVE pid=$LPID"
else                                                   echo "LOCK-STALE pid=$LPID"; fi
```

(`jq` is not guaranteed on every machine. If it is missing, `Read` the file — it
is one line of JSON — and reason about the two fields yourself.)

- **LOCK-MINE** → **you already hold it. Proceed.** Do not re-claim, do not
  refuse, do not rewrite the file. This branch MUST come first, and it is the
  common case, not an edge case: `$PPID` is stable across every Bash tool call in
  one session, so after a context compaction the router re-reads this file while
  still holding its own lock and would otherwise test `kill -0 $PPID` — trivially
  alive — and refuse its own live run until a human deleted the lockfile.
  Recovery from compaction is the path this whole per-step-skill architecture
  exists to serve; it must not be the path that wedges.
- **LOCK-LIVE** → **REFUSE TO START.** Invoke no step skill, write nothing to the
  manifest, end the turn with: which run is locked, the pid, the host, the claim
  timestamp, and the two ways out — let the other session finish, or, if that
  session is known dead, delete the file by hand
  (`rm runs/<run_tag>/.lock`). `.lock` and `ABORT` are the only two files under
  `runs/` a human is ever invited to touch, and both are control actions, not
  edits.
- **LOCK-FOREIGN** → refuse the same way. `kill -0` says nothing about a pid on
  another host, so liveness is untestable and the safe answer is "someone else
  may be running this."
- **LOCK-STALE** (pid gone) → **reclaim, and log that you did.** `rm -f "$LOCK"`,
  re-run the claim block, append the reclaim to
  `runs/<run_tag>/temp/orchestrator-notes.md`, AND put it in the next step's
  usage `notes`: `"reclaimed stale lock (pid <N>, claimed <ts>)"`. A silent
  reclaim hides the crash that produced it. Note the honest limit: pids are
  recycled, so a stale-looking lock is a strong signal, not proof.

**Re-verify ownership before each step** — one line, cheap:
`jq -r '.pid' runs/<run_tag>/.lock` must still equal `$PPID`. If the file is
gone, re-claim it (claim trigger 4). If the pid changed, another session
reclaimed the run under you: stop immediately, say so, and do not write to the
manifest.

**Release it** — `rm -f runs/<run_tag>/.lock` — at EVERY one of these:

- the design-gate stop (step 12), before you deliver the summary message;
- run completion, after the manifest flips to `stage: "DONE"`;
- any blocked state: an exhausted gate, a failed preflight, a fired cap, an abort;
- any turn you end with the run **PARKED or BLOCKED** — i.e. you are handing
  control back to the human and nothing resumes without them.

**Do NOT release at an ordinary between-steps turn boundary.** A turn that ends
with no Task in flight, mid-Stage-A, with the next step already decided, is a
normal state and the run is still yours: keep the lock. If you are ever unsure
whether you still hold it, run the liveness block — `LOCK-MINE` answers the
question in one line, and claim trigger 4 covers the case where it is gone.

A held lock with no live session costs the next session a confusing refusal.
Releasing is one command; do it deliberately at the four points above rather
than relying on the stale path to clean up after you.

### §2 — The kill switch: `runs/<run_tag>/ABORT`

The documented failure mode this closes is "I couldn't stop it from my phone."
The user's kill switch needs no session and no permission:

```bash
touch runs/<run_tag>/ABORT
```

**Check it between EVERY step** — after you write the previous step's usage
record, before you invoke the next skill:

```bash
[ -f "runs/<run_tag>/ABORT" ] && echo "ABORTED" || echo "CONTINUE"
```

Also check it BEFORE claiming the lock at bootstrap and on every resume. A
leftover `ABORT` means the user stopped this run on purpose — do not resume into
more work; tell them to `rm runs/<run_tag>/ABORT` first.

**On `ABORTED`, in this order:**

1. Do not invoke the next step skill. Do not "just finish this one first."
2. Make sure the completed step's `usage` record is written (§4).
3. Set `blocked_on: "aborted-by-user"` in the manifest. Leave `steps` telling the
   truth — the last step keeps whatever value it actually earned; never mark an
   unfinished step `"done"` to tidy the abort.
4. Write the partial `usage_summary` for the stage reached (§5). A partial cost
   picture is usually the whole reason someone aborted.
5. Release the lock (§1).
6. Report, then END THE TURN: which steps are `done`, which step was in flight
   and what it left on disk, where the artifacts are, and how to resume —
   `rm runs/<run_tag>/ABORT`, then `/hyperbuild`.

**Check it at long in-step sync points too.** A `Skill` call loads that step's
procedure into THIS context — you are still the one executing, so you can check
the flag anywhere you make a tool call. Between steps is the mandatory floor;
also check at every point where a long step comes up for air, and name them so
this is not left to judgment: **step 14's per-wave sync point** (a wave-based
build can run for hours, and this is the difference between aborting after one
wave and aborting after twelve), each **critic fix-round boundary** in steps 12,
15, and 16, and **step 8.5's round boundary**. Abort at a sync point behaves
exactly as above — the wave's commit has already landed, so the tree is clean and
the run is resumable.

Each of those four step skills now carries the three-line ritual (check `ABORT`,
check elapsed against `temp/step-<N>.start`, bump `usage.turns`) **inline at its
own boundary**, citing this section by number. That duplication is deliberate and
is the same reasoning that puts the FROZEN-GATE VERIFY block verbatim inside step
14 rather than behind a reference: when the boundary is reached, the step's
procedure is what is fresh in context and THIS file is what compaction ate. This
section stays the authority for the semantics; the step files hold the tool call.

**State the switch's limit rather than overselling it.** The check happens when
you next run a tool. If you are waiting on a wave of subagents that takes twenty
minutes, the abort lands when they return, not when the file appeared — the flag
stops the NEXT unit of work, it does not interrupt one in flight. To stop
something mid-flight the user interrupts the session itself (Esc / Ctrl-C); the
`ABORT` file is then what stops the next session from resuming into more work.
Signal handling and background-subagent wait ceilings are environment/settings
concerns, not router concerns: the router owns the flag file and nothing else.

### §3 — Caps: a ceiling per step class

| Step class | Steps | Turn ceiling | Wall-clock ceiling |
|---|---|---|---|
| Research | 2, 3, 3.5, 5, 6, 9 | **30** | 90 min per step |
| Design | 7, 8, 8.5 | **40** | 90 min per step |
| Gate | 12, 16 | **20** | 45 min per step |
| Implementation wave | 14 — **per wave**, not per step | **80** | 120 min per wave |
| Authoring *(extrapolated — the four rows above are the audited numbers)* | 1, 4, 4.5, 10, 11, 13, 15 | 30 | 60 min per step |

The step skills cite these numbers; **if a step skill's text and this table ever
disagree, this table wins** — same contract as the Scale profile table.

At `premier`, multiply the **wall-clock** column by 1.5 and leave the **turn**
column alone: premier fans out wider inside the same message, so it buys more
agents per turn, not more turns.

**The turn column is the audit's; the wall-clock column is a guess, and it is
labelled one on purpose.** Nobody has measured a hyperbuild step. These
ceilings exist so a wedged step cannot run forever, not because 90 minutes is a
known-correct number — re-tune the column from `manifest.usage` once real runs
exist (that is the whole reason §4 is written first). A cap that fires routinely
on healthy work is a bug in the cap, not a finding about the step; raise it
deliberately, in this table, and say in the run report that you did.

**What one "turn" means here, exactly.** One assistant message in this
conversation that makes at least one tool call while the step is running. A
parallel spawn of twelve subagents in ONE message is ONE turn — that is what
canonical rule 4 buys you. Polling burns a turn per poll, which is why rule 1
says write your thoughts instead of just polling.

**How you check the wall clock without a timer.** The start stamp is already on
disk (§4), so the check is one line at any tool call inside the step:
`echo $(( $(date -u +%s) - $(cat runs/<run_tag>/temp/step-<N>.start) ))`. Do it
at the same sync points where you check `ABORT` — between steps, at each wave
sync point, at each fix-round boundary. Granularity is honest, not exact: a
ceiling can only be observed when you next act, so a step that spawns a
40-minute wave may overshoot by that wave. Record the real number in
`wall_clock_s` — never the ceiling, and never a rounded-down figure that makes
the cap look respected.

**Inside one session these caps are ROUTER-ENFORCED, and that is a weaker
guarantee than a runtime cap — say so rather than implying otherwise.** The
runtime's caps are per **session**, not per step: `--max-turns <turns>` and
`--max-budget-usd <amount>` bound the whole invocation. A single interactive
session that runs steps 1–12 cannot express a per-step-class ceiling through
them, so within a session the turn column is a discipline YOU count — and a
count that lives only in the context window is exactly the guardrail class
compaction eats. Hence the two mandatory mitigations:

- **Keep the count on disk.** The `turns` field of the in-progress step's usage
  record IS the count; bump it as you go so a compacted router re-reads its own
  number instead of guessing at it.
- **Where the harness is driven headless, map the table onto the runtime.** One
  step per `claude -p` invocation makes the per-step-class ceiling a real
  runtime cap: pass `--max-turns` from the table's turn column and
  `--max-budget-usd` for the money bound. Both are enforced by the runtime and
  cannot be forgotten by a model.

**What happens when the RUNTIME cap fires, and why the design already survives
it.** The process stops mid-step and returns `is_error: true` with
`stop_reason: "tool_use"` — you do not get a turn in which to write the
manifest. That is fine and intended: the step's `usage` record is still sitting
at `outcome: "running"` and the `.lock` goes stale, which is precisely the crash
signature Recovery reads (§1, §4). The next session diagnoses it correctly
without anything having been written at the moment of death.

> **Requirements-note for whoever edits `README.md`** (not this file's job to
> edit it). Both flags are verified present in Claude Code **2.1.220**:
> `--max-budget-usd <amount>` (documented in `--help`, print-mode only; pin
> Claude Code `>= 2.1.217`, below which it silently does not enforce, and note
> that subagent spend counts toward it) and `--max-turns <turns>` — **real and
> enforced, but HIDDEN from `--help`**, so verify it by probe rather than by
> reading the help text (`claude --max-turns notanumber -p x` returns
> `option '--max-turns <turns>' argument ... must be a number`, while a
> genuinely unknown flag returns `error: unknown option`). Measured behaviour:
> `--max-turns 1` on a tool-using prompt returned `{"is_error": true,
> "num_turns": 2, "stop_reason": "tool_use"}`. Because it is undocumented, treat
> it as a flag that could change without a release note — re-probe it at every
> Claude Code upgrade rather than trusting this paragraph.

**Hitting a cap BLOCKS the run. It never silently continues.** When a step
crosses its turn or wall-clock ceiling:

1. Stop the step where it is. Do not start another fix round, another wave, or
   another spawn.
2. Write the step's usage record with `outcome: "capped"` and a `notes` line
   naming what was and was not finished.
3. Set `steps["<N>"] = "blocked"` and
   `blocked_on: "cap: <exactly what fired>"`.
4. Release the lock and report honestly: which cap, what the step completed,
   what is on disk, and what a human can do (raise the cap deliberately and
   resume, split the work, or abort). **A blocked run with a true manifest beats
   a run that quietly ran twice as long** — the same logic as canonical rule 6.

**Caps are an OUTER bound, never a work budget to spend down and never a licence
to do less.** Trimming a fan-out to fit under a ceiling — dropping verifiers,
shrinking a critic panel, skipping screens — turns a checked archive back into a
confident survey, which is the exact failure the Scale profile forbids. If a
step genuinely cannot finish inside its cap at `standard`, that is a *finding
about the step*: record it and block. And caps do not replace the inner fix-round
budgets (≤2 gate rounds, with round 2 conditional; ≤2 critic rounds at step 8.5)
— whichever binds first wins.

### §4 — The usage record: written after EVERY step returns

One record per step key under `manifest.usage`. You write it — no step skill
does. It is FINALIZED in the same between-steps beat as the ABORT check, but the
`turns` counter is bumped while the step is still running (§3), so the record
exists in-progress: create it with `outcome: "running"` when you start the step,
finalize it when the step returns.

```json
"2": {
  "agents_spawned": 27,
  "turns": 14,
  "wall_clock_s": 1893,
  "outcome": "done",
  "cost_usd": null,
  "cost_source": "unavailable",
  "notes": "1 scout + 7 analysts + 19 verifiers; 1 analyst re-spawned (missing provenance block)"
}
```

**What you can honestly measure — measure it:**

- `wall_clock_s` — stamp the start on DISK before invoking the step, so a
  compaction or crash cannot lose it:
  ```bash
  date -u +%s > runs/<run_tag>/temp/step-<N>.start          # before the Skill call
  S=$(cat runs/<run_tag>/temp/step-<N>.start); echo $(( $(date -u +%s) - S ))   # after it returns
  ```
- `agents_spawned` — your own spawn bookkeeping: the count of Task calls you
  made for that step, including re-spawns. You already log spawns to
  `scaffold.md`; count from there, not from memory.
- `turns` — the count from §3.
- `outcome` — one of `running` (in progress) · `done` · `blocked` · `capped` ·
  `aborted` · `redo`. A record left at `running` in a manifest nobody is holding
  a lock on is a crashed step — that is a feature, and Recovery reads it that way.
- `notes` — one or two lines: what the spawns were, what was re-spawned and why,
  whether a cap or a lock reclaim fired.

**What you do NOT have — do not invent it.** Claude Code does not hand a running
skill its own token counts or dollar spend; there is no tool that returns them
and the transcript's numbers are not in your context. Therefore `cost_usd` (and
any token count) may only be written from an OBSERVED source, copied verbatim:

- the user pasting `/cost` output → `cost_source: "/cost@<ISO timestamp>"`;
- a headless driver that captured the final result object of
  `claude -p --output-format json` and wrote it into the run →
  `cost_source: "headless-json"`;
- a configured telemetry/audit log → `cost_source: "otel"`.

The headless result object is the good case, and its shape is known — copy these
fields across verbatim rather than deriving anything: `total_cost_usd` →
`cost_usd`; `num_turns` (use it to CHECK your own `turns` count, and if the two
disagree, keep the runtime's and say so in `notes`); and under `usage`,
`input_tokens`, `output_tokens`, `cache_read_input_tokens`,
`cache_creation_input_tokens`. `modelUsage` breaks cost down per model
(`costUSD` each) — keep it whole if you keep it at all; a per-model breakdown is
what tells you a step is silently running on the wrong tier.

Otherwise: `"cost_usd": null, "cost_source": "unavailable"`. **Never estimate,
never interpolate from another step, never scale a number from another run.** A
fabricated cost is strictly worse than a null — the entire point of this record
is to price the gears and settle which parts of the fan-out earn their keep, and
one invented number silently corrupts every comparison built on top of it.
`null` + `"unavailable"` is a correct and useful answer.

When a result object IS available, copy its token fields verbatim into an
optional `tokens` sub-object rather than reformatting them — and keep
`cache_read_input_tokens` in particular. A near-zero cache-read against a large
input count means the prompt prefix is being invalidated: that run is paying
roughly an order of magnitude too much for nothing, and it is worth a line in
`notes` the moment you see it.

**Write it read-modify-write. Never regenerate the manifest from memory** — you
would drop `frozen_gates`, a step key another skill set, or the half of `usage`
you are not thinking about:

```bash
python3 - <<'PY'
import json, pathlib
p = pathlib.Path("runs/<run_tag>/manifest.json")
m = json.loads(p.read_text())
m.setdefault("usage", {})["<N>"] = {
    "agents_spawned": 27, "turns": 14, "wall_clock_s": 1893,
    "outcome": "done", "cost_usd": None, "cost_source": "unavailable",
    "notes": "<one or two honest lines>",
}
p.write_text(json.dumps(m, indent=2) + "\n")
PY
```

For the concurrent pairs (2 ∥ 3, 8 ∥ 9) each member gets its OWN start stamp and
its OWN record, and their wall clocks **overlap by design** — never present the
sum of two concurrent steps as elapsed time.

### §5 — `usage_summary`: written at the design gate and at the ship gate

Run-level roll-up, written **twice**: after step 12 passes (before the stop
message) and after step 16 (pass or blocked). Also write the partial on an abort
(§2) and on a cap block (§3).

```json
"usage_summary": {
  "stage_a": {
    "written_at": "2026-07-25T14:22:09Z",
    "steps_recorded": ["1","2","3","3.5","4","4.5","5","6","7","8","8.5","9","10","11","12"],
    "steps_missing": [],
    "agents_spawned": 118,
    "turns": 96,
    "wall_clock_s_summed": 21140,
    "wall_clock_s_elapsed": 15980,
    "cost_usd": null,
    "cost_source": "unavailable",
    "notes": "2∥3 and 8∥9 ran concurrently — summed exceeds elapsed by design"
  }
}
```

- Sum only the records that EXIST. A step with no record goes in
  `steps_missing` — **never interpolate a missing step**, and never quietly omit
  it from the list either.
- `wall_clock_s_summed` adds the per-step clocks (concurrent pairs overlap);
  `wall_clock_s_elapsed` is `written_at` minus the run's `created`. Report both,
  labelled, rather than one number that could mean either.
- If ANY counted step's cost is unavailable, the stage cost is `null` with
  `cost_source: "partial-unavailable"`. A partial sum of costs is a wrong number
  wearing the shape of a right one.

This roll-up is what lets the gear table be priced from measurement instead of
intuition, and what makes the "is the Stage-A fan-out worth it" question
answerable at all. It only works if every number in it is real.

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
   never edit. hb-patcher — tool-locked to Read+Edit, physically unable to
   Write files — applies findings as small surgical Edit hunks. Deleting and
   retyping a section is regeneration wearing a patch costume. Structural
   findings escalate to new tasks, not rewrites.
6. **THE GATE IS FINAL.** Gate failures (step 12, step 16) are facts about the
   artifacts, never opinions to re-assess. Fix the artifact the check names,
   re-run the gate. **Maximum 2 fix rounds, and round 2 runs ONLY if a Tier-0
   signal changed** between attempts — a test flipped, a script gate's exit code
   flipped, a re-render differs, a file that was absent now exists, or a count
   that was short now clears. Same red checks with no changed signal → do not
   re-run the gate: the run stays `blocked` and you say so honestly. A blocked
   run with a true manifest beats a shipped app that lies.
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
10. **DESIGN CRAFT IS GATED.** `docs/DESIGN-CRAFT.md` is BINDING on steps 6, 7,
    8, and 8.5. Every design spawn prompt cites it BY PATH in its CONTEXT FILES
    list, and every `hb-design-researcher`, `hb-design-system-author`,
    `hb-mockup-smith`, and `hb-design-critic` reads it before producing
    anything. Its violations — the banned AI-design tells, a missing signature
    element, one system font doing every job, clipped text, a FAB parked on a
    list row — are DEFECTS, not taste disagreements: they get re-spawned or
    patched like any other failed check. And **a rendered screen nobody looked
    at is not a finished design.** Step 8.5 exists because the first real run
    sent 30 unviewed screenshots straight to the human gate. Never let a
    direction reach step 12 with a screenshot no critic has opened.
11. **EVERY LOAD-BEARING CLAIM IS ADVERSARIALLY VERIFIED.**
    `docs/RESEARCH-ARCHIVE.md` is BINDING on every research step — 2, 3, 3.5,
    5, 6, 9 — and on step 12's reusability guide. Each of those steps writes
    into ONE research AREA with four phases (`research/` → `verify/` →
    `critique/` → `author/`), and the middle two are not optional. When a
    `research/<dimension>.md` file lands, the step REGISTERS its claims (every
    H3 under `## Summary` is a complete assertion, not a topic label) into
    `runs/<run_tag>/temp/claims-0N.json`, selects the load-bearing ones (3–5
    per file at `standard`, 6–10 at `premier`, everything carrying a version,
    price, licence, policy, or API name first), and spawns ONE
    `hb-claim-verifier` PER CLAIM, ALL IN PARALLEL IN ONE MESSAGE, each told to
    REFUTE its single claim against primary sources — the canonical verifier
    prompt is RESEARCH-ARCHIVE §6 and is used VERBATIM. One agent handed five
    claims confirms all five; the asymmetry is the whole mechanism. Then the
    area's `hb-corpus-critic`s read the WHOLE corpus for contradictions BETWEEN
    dimensions, and only then does the `author/` synthesis get written.
    **A REFUTED CLAIM MAY NEVER SURVIVE INTO A SYNTHESIS DOC** — not into an
    `author/` file, the PRD, a feature spec, an epic, a task, or a code
    comment; PARTIALLY_TRUE carries its correction everywhere it appears;
    UNVERIFIABLE is never the sole support for a `must`. Refuted claims are
    RECORDED, never silently deleted: the `verify/` file stays, the `research/`
    file is NOT rewritten, and `_INDEX.md` says which is authoritative. When a
    fact-checker disagrees with a researcher, THE FACT-CHECKER IS USUALLY RIGHT.
12. **ONE LIVE SESSION PER RUN — CLAIM THE LOCK.** Before the first step of any
    session you claim `runs/<run_tag>/.lock`; a LIVE lock means you REFUSE to
    start and say whose it is. Otherwise two sessions resuming one run both
    execute — same waves, same files, same manifest keys, interleaved. Release
    it at every stop, every block, and at run completion. Procedure: Run
    control §1.
13. **THE ABORT FILE OUTRANKS THE STEP ORDER.** Between every step you check
    `runs/<run_tag>/ABORT`. Present → stop cleanly, `blocked_on:
    "aborted-by-user"`, release the lock, report what completed and what is on
    disk. Never "let me just finish this one step first." Procedure: Run
    control §2.
14. **CAPS BLOCK; USAGE IS MEASURED, NEVER ESTIMATED.** Every step runs under
    its class's turn and wall-clock ceiling (Run control §3). Hitting one BLOCKS
    the run with an honest manifest — it never silently continues, and it never
    licenses shrinking a fan-out to squeeze underneath. After EVERY step returns
    you write its `usage` record (§4): wall clock and agent counts you MEASURE;
    tokens and dollars you do NOT have, so they are written only from an
    observed source and are otherwise `null` + `"unavailable"`. A fabricated
    cost number is worse than no number — it corrupts every comparison the
    record exists to enable.

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

**THE PROVENANCE RULE — the fifth piece, on every RESEARCH-PHASE spawn.** Every
subagent that writes into a research area (`research/`, `verify/`, `critique/`,
`author/` under `research/0N-<area>/`) is additionally told, INSIDE its own
prompt, to reproduce THAT PROMPT VERBATIM in a closing collapsible block:

````
END YOUR FILE with this exact block — the prompt below, verbatim, no summary,
no paraphrase, no "the prompt asked me to…" (four-backtick outer fence if the
prompt contains a triple backtick):

<details>
<summary>The prompt that produced this</summary>

```
<the full text of this prompt>
```

</details>
````

Every research prompt therefore carries its own reproduction instruction — the
orchestrator puts the requirement inside the prompt it sends. A file without
its prompt block is INCOMPLETE and the agent is re-spawned, exactly like any
other failed check. The prompt is what makes the archive reusable: the finding
says what one agent concluded, the prompt says what it was asked, what context
it was handed, and what it was never asked to consider. Format and rationale:
`docs/RESEARCH-ARCHIVE.md` §4 — cite that file BY PATH in the CONTEXT FILES
list of every research-phase spawn.

Skeleton (the step skills carry the authoritative filled-in templates):

```
subagent_type: hb-competitor-analyst
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 2 (market recon) of the hyperbuild
  pipeline. Step 1 resolved the platform; after you return, your
  LOAD-BEARING claims are fact-checked one agent per claim into
  research/01-product-and-market/verify/, and step 4 merges the corrected
  synthesis into the PRD.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - competitor: <name + URL, exactly as assigned>
  - output_path: research/01-product-and-market/research/competitors/<competitor-slug>.md

  CONTEXT FILES (read before starting):
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/decisions/platform.md
  - docs/RESEARCH-ARCHIVE.md   (BINDING: file format, claim shape, provenance)

  END YOUR FILE with the provenance block (RESEARCH-ARCHIVE §4) containing
  this prompt verbatim.
```

---

## The design-gate stop (the ONE permitted stop)

When step 12's gate passes, the manifest reads `blocked_on: "design-choice"`
and you deliver ONE summary message to the user, then END THE TURN. This is
the only place in the pipeline where a plain text message is the goal (no
Tasks are in flight, so rule 1 does not bind).

**Before the message, close the run down properly** — in this order: write step
12's `usage` record (Run control §4), write `usage_summary.stage_a` (§5), then
release the lock (§1). The run is parked, not running; a lock left behind here
blocks the very `/hyperbuild-choose` invocation the stop exists to invite.

The message must contain:

- Competitor count analyzed; the top user pain points (from
  `research/01-product-and-market/author/sentiment-synthesis.md`)
- The platform decision + one-line rationale (from
  `runs/<run_tag>/decisions/platform.md`)
- Epic count, task count, feature-spec count
- How to review the designs: `open runs/<run_tag>/designs/index.html` — three
  named designs, every screen, side by side
- The next command: `/hyperbuild-choose a|b|c` (with each design's name next
  to its letter), and the optional platform-override form
  `/hyperbuild-choose <a|b|c> <platform>`
- The two change-of-mind commands, one line each: `/hyperbuild-revise <what to
  change>` to change the idea, a feature, one direction's look, or the epic
  split, and `/hyperbuild-redesign [notes]` for new design directions (with
  KEEP/REPLACE, e.g. "keep c, replace a and b")

**Do NOT invoke step 13. Do NOT invoke `hyperbuild-choose`, `hyperbuild-revise`,
or `hyperbuild-redesign` yourself.** Only the user's `/hyperbuild-choose`
invocation releases Stage B. If the user runs `/hyperbuild` again while
`blocked_on: "design-choice"`, repeat the summary message — do not advance.

---

## Recovery: if you wake up uncertain where you are

Context compaction may eat parts of this conversation. If you're unsure what
step you're on:

0. **Read the manifest FIRST.** Glob `runs/*/manifest.json`; take the newest
   by `created`. Then — BEFORE resuming anything — run the two run-control
   preflights on that run_tag: `ABORT` present? (Run control §2 — if so, stop and
   say so; do not resume into more work). Then the lock (§1): run the liveness
   block. **`LOCK-MINE` means this session already owns the run — the normal
   post-compaction case — so proceed without re-claiming.** `LOCK-LIVE` or
   `LOCK-FOREIGN` → refuse; another session owns this run. Now read the ladder
   below, and claim the lock (§1) only on a branch that goes on to invoke a step
   skill — the `design-choice` and `aborted-by-user` branches end the turn
   without one, and no lock is held at the gate:
   - `blocked_on: "aborted-by-user"` → the user killed this run on purpose. Do
     NOT resume. Report what `steps` says completed and tell them the resume
     path: `rm runs/<run_tag>/ABORT`, then `/hyperbuild`.
   - `blocked_on` starts with `"cap: "` → a turn or wall-clock ceiling fired and
     blocked the step named in the marker. Do NOT silently re-run it: report
     which cap fired, what that step completed, and what is on disk. Resume only
     on an explicit instruction from the user — and when you do, start that
     step's `turns` count fresh and say in `usage.notes` that it is a post-cap
     re-run, so the record never reads as one under-cap run.
   - `blocked_on` starts with `"revision-in-flight:"` or
     `"redesign-in-flight:"` → a gate-time command skill died mid-flight.
     **Do NOT resume the step order.** Read its scope file —
     `runs/<run_tag>/temp/revision-R<N>/scope.md` or
     `runs/<run_tag>/temp/redesign-round-<N>/scope.md` — and re-enter the
     OWNING skill: `Skill(skill: "hyperbuild-revise")` or
     `Skill(skill: "hyperbuild-redesign")`, which resume from their own entry
     guards. Resuming step 6 (or 4) unscoped instead would re-run it for all
     three letters, renaming every direction and overwriting `directions.md` —
     destroying a KEPT letter, whose artifacts are deliberately not archived.
   - `blocked_on: "design-choice"` → the run is parked at the design gate.
     Repeat the stop message (including the `/hyperbuild-revise` and
     `/hyperbuild-redesign` lines); end the turn. EXCEPTION: if any design step
     is marked `"redo"` — `/hyperbuild-revise` or `/hyperbuild-redesign` ran to
     completion but a step is still owed — re-run those steps in ascending
     order (6 → 7 → 8 → 8.5 → 12) and re-park.
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
   | 2 | `research/01-product-and-market/research/competitors/<slug>.md` + its `verify/*.md` files + `research/01-product-and-market/author/competitor-landscape.md`; claim register `runs/<run_tag>/temp/claims-01.json` |
   | 3 | `research/01-product-and-market/research/sentiment/{reddit,hn-forums,appstore-reviews,linkedin-x}.md` + its `verify/*.md` files + `research/01-product-and-market/author/sentiment-synthesis.md` (same `claims-01.json` register) |
   | 3.5 | `research/01-product-and-market/critique/<critic-name>.md` + `research/01-product-and-market/_INDEX.md` |
   | 4 | `research/product-spec.md` (stays at the vault ROOT — the product contract, not a research finding) |
   | 4.5 | `features/00-index.md` + `features/NN-<slug>.md` (repo root) |
   | 5 | `research/02-engineering/research/<dimension>.md` + `verify/` + `critique/` + `_INDEX.md` + `research/02-engineering/author/stack-guide.md`; claim register `runs/<run_tag>/temp/claims-02.json` |
   | 6 | `runs/<run_tag>/designs/directions.md` + `research/03-design-system/research/<direction-slug>.md` + `verify/` + `critique/` + `_INDEX.md` + `research/03-design-system/author/design-directions.md`; claim register `runs/<run_tag>/temp/claims-03.json` |
   | 7 | `runs/<run_tag>/designs/{a,b,c}/design-system.md` + `runs/<run_tag>/designs/{a,b,c}/tokens.css` |
   | 8 | `runs/<run_tag>/designs/{a,b,c}/mockups/<screen>.html` + `runs/<run_tag>/designs/{a,b,c}/screenshots/<screen>.png` + `runs/<run_tag>/designs/index.html` |
   | 8.5 | `runs/<run_tag>/gates/visual-qa-{a,b,c}.json` (one per direction, each carrying a final verdict) |
   | 9 | `research/04-claude-skills/research/<dimension>.md` + `verify/` + `critique/` + `_INDEX.md` + `research/04-claude-skills/author/skill-authoring-guide.md`; claim register `runs/<run_tag>/temp/claims-04.json` |
   | 10 | `.claude/skills/{app-code-style,app-architecture,app-testing,app-components,app-review-checklist}/SKILL.md` |
   | 11 | `epics/00-overview.md` + `epics/NN-<slug>/epic.md` + `epics/NN-<slug>/task-NN-<slug>.md` |
   | 12 | `runs/<run_tag>/gates/design-gate-report.md` + `research/README.md` (the areas index + REUSABILITY GUIDE, RESEARCH-ARCHIVE §8) |
   | CHOOSE | `runs/<run_tag>/decisions/design-choice.md` + `app/design/{tokens.css,design-system.md}` |
   | 13 | `app/` project scaffold (the platform's build file exists: `pubspec.yaml` / `package.json` / `*.xcodeproj` / equivalent) |
   | 14 | task frontmatter flips: `status: done` in `epics/*/task-*.md` + `runs/<run_tag>/temp/wave-log.md` + wave/epic git commits in `app/` |
   | 15 | `runs/<run_tag>/gates/review-findings-{code,spec,ux}.json` |
   | 16 | `runs/<run_tag>/gates/ship-report.md` |

   `usage` is a second crash signal, and it is finer-grained than `steps`: a
   record still reading `outcome: "running"` on a run whose lock is stale is the
   step that died. A step whose artifacts exist but whose record is missing
   entirely died before the record was written — reconstruct only what you
   honestly can (`agents_spawned` from `scaffold.md`, `wall_clock_s` from
   `temp/step-<N>.start` if it survived), leave the rest `null`, and say so in
   `notes`. Never back-fill a plausible-looking number to make the row look
   complete.

3. **Find the highest step whose artifacts exist.** Resume at the next step in
   the stage order — and repair the manifest to match reality before moving on.
4. **Re-invoke this entry skill** if you've lost track entirely:
   `Skill(skill: "hyperbuild")`. It loads fresh.

If you're ever uncertain what to do next, the answer is: re-read this file and
find the next step in the stage order.

---

## After step 16

When step 16's ship gate reports pass, flip the manifest to `stage: "DONE"`,
mark all todos complete, and relay step 16's final message: what was built,
how to run it, the test count, and known gaps. If the gate stayed blocked
after its 2 fix rounds, say exactly which checks failed — never soften the report.

Either way — passed or blocked — finish the run-control ritual before you end
the turn: write step 16's `usage` record, write `usage_summary.stage_b`
(Run control §5), and release the lock (§1). A shipped run that still holds its
lock is a run nobody can touch again.

---

## Now begin

Run control binds from the first tool call: no session starts a step while
another session's lock is live, and no session starts a step while an `ABORT`
file is present.

- Fresh run (idea in hand, no unfinished manifest): do the Bootstrap — preflight
  the checkout for a live lock or an `ABORT` file, invoke
  `Skill(skill: "hyperbuild-1-intake")`, then claim the lock the moment it
  returns.
- Existing run: follow Recovery — manifest, then the ABORT and lock preflights,
  then claim the lock, then invoke the next step's skill.
- Parked at the design gate: repeat the stop message and end the turn (no lock
  is held at the gate — claim one only if you are about to run a step).

```
Skill(skill: "hyperbuild-1-intake")
```

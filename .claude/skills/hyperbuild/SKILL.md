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
---

# hyperbuild — multi-skill chain orchestrator

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
| 3.5 | `hyperbuild-3-5-research-audit` | AREA 01 CORPUS CRITIQUE + INDEX (runs only after 2 AND 3 are both done): corpus critics read the WHOLE area — cross-dimension contradictions, cherry-picking, syndicated/derivative copies that argue with the weight of ONE source — → `research/01-product-and-market/critique/<critic-name>.md`; then the area's `_INDEX.md` (every agent, every phase, every verdict). Orchestrator applies CONFIRMED findings + every verify/ correction to the `author/` docs — REFUTED claims never survive into a synthesis, and nothing is silently deleted | 2 critic seats standard / 3 premier, one distinct lens each — hb-research-critic takes the skeptic seat (pain-point/wish-list refutation), hb-corpus-critic the rest |
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
| Critic fix rounds (gates) | ≤3 | ≤3 |

The gear never changes mid-run. If a step skill's text and this table ever
disagree on a number, this table wins.

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
3. **Invoke step 1:** `Skill(skill: "hyperbuild-1-intake")`. Step 1 — not you —
   mints the run_tag (idea slug + 6 random hex chars, e.g. `habit-coach-3f9a2c`),
   writes `runs/<run_tag>/idea.md`, resolves the platform into
   `runs/<run_tag>/decisions/platform.md`, writes `runs/<run_tag>/scaffold.md`,
   initializes `runs/<run_tag>/manifest.json`, and seeds the TodoWrite list
   with every step (1 through 16, including the half-steps 3.5, 4.5 and 8.5,
   plus a checkpoint todo) — **20 todos**. The
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

- `stage`: `"PLAN"` → `"BUILD"` (flipped by `hyperbuild-choose`) → `"DONE"`
  (flipped after step 16 passes).
- `steps`: string keys `"1"`…`"16"` including `"3.5"`, `"4.5"` and `"8.5"`; values `"running"`,
  `"done"`, `"redo"` (set by a checkpoint platform override, or by
  `/hyperbuild-revise` / `/hyperbuild-redesign` for the design steps they
  invalidate), `"in-progress"`/`"looped"` (steps 15/16 transitional states), or
  `"blocked"` (a gate that exhausted its fix rounds). Absent key = not
  started. Recovery keys on "not `done`" — any other value means the step
  still owns the run.
- `blocked_on`: `null`, `"design-choice"` (set by step 12's stop), an
  IN-FLIGHT marker set by a gate-time command skill —
  `"revision-in-flight:R<N>"` (`/hyperbuild-revise`) or
  `"redesign-in-flight:round-<N>"` (`/hyperbuild-redesign`) — or an
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
   never edit. hb-patcher — tool-locked to Read+Edit, physically unable to
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
Tasks are in flight, so rule 1 does not bind). The message must contain:

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
   by `created`. Then:
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
after 3 fix rounds, say exactly which checks failed — never soften the report.

---

## Now begin

- Fresh run (idea in hand, no unfinished manifest): do the Bootstrap, i.e.
  invoke `Skill(skill: "hyperbuild-1-intake")`.
- Existing run: follow Recovery and invoke the next step's skill.
- Parked at the design gate: repeat the stop message and end the turn.

```
Skill(skill: "hyperbuild-1-intake")
```

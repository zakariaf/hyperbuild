# IMPROVEMENTS.md — the tracked backlog

What hyperbuild is **known** to be missing, ranked, with the one-line evidence behind each
item. This file exists so that a gap is a tracked decision rather than a thing nobody
noticed. Nothing here is speculative wishlisting: every item comes from an adversarial
audit of this harness against a verified research corpus.

**Source:** `loop-engineering/research/author/loop-engineering-field-map.md` — §6 *Verdict
on hyperbuild* (its "What is MISSING" list and its ranked change list) and §8 *How to
evaluate these harnesses over time*. Local path at time of writing:
`/Users/zakariafatahi/Projects/loop-engineering/research/author/loop-engineering-field-map.md`.
That document rests only on claims that survived per-claim adversarial verification; where
a number carries a correction, the correction travels with it here too.

**Item numbers are the audit's own**, kept stable so a finding can be traced back. The
order below is the audit's ranking — (evidence strength × blast radius) ÷ effort — not the
numeric order.

**Already addressed** (from the same list, recorded here so nobody re-opens them): the
enforcement layer and deny hook (1), Rule of Two per step (2), the frozen oracle (3),
manifest `usage` instrumentation (4), per-step caps (5), the run lockfile (6), gates as
scripts (7), fix rounds cut 3 → 2 (9), the least-confidence artifact (14), the
`hb-research-critic` enumerated checklist (20), and sandbox configuration (21) — with the
standing caveat on 21 that `sandbox.credentials`, `failIfUnavailable` and
`allowUnsandboxedCommands` can only be set at USER or MANAGED scope: project settings
cannot set them, so a fresh checkout on a new machine is unsandboxed until an operator
configures it once. Architecture: `PIPELINE.md` → *Enforcement and observability*. Binding
rule list: [`GUARDRAILS.md`](GUARDRAILS.md).

---

## The backlog

| Rank | # | Item | Where | Status |
|---|---|---|---|---|
| 1 | 8 | Step 13.5 — scaffold audit | new `hyperbuild-13-5-scaffold-audit` skill | **TODO** |
| 2 | 10 | Change the critic contract: enumerated checklists + coupling rate | all `hb-*-critic.md`, `hb-patcher.md`, `hyperbuild-15` | **TODO** |
| 3 | 11 | Move half of DESIGN-CRAFT §4 into code | `hyperbuild-8-mockups`, `docs/DESIGN-CRAFT.md` | **TODO** |
| 4 | 12 | A licence gate | `hyperbuild-5/9/10`, `scripts/gate-ship.sh` | **TODO** |
| 5 | 13 | Artifact security checks at the ship gate — *secret scan shipped; the rest open* | `scripts/gate-ship.sh`, `hyperbuild-16` | **TODO (partial)** |
| 6 | 15 | The golden-task eval suite | new `evals/` | **TODO** |
| 7 | 16 | Run the two experiments | `evals/` | **TODO** |
| 8 | 18 | OpenTelemetry configuration | `.claude/settings.json` | **TODO** |
| 9 | 19 | Annotate every skill and agent with the model deficit it compensates for | all skills + agents; `PIPELINE.md` | **TODO** |
| 10 | 22 | Estimate the research area half-life | `hyperbuild-2/3/5/6/9`, `research/README.md` | **TODO** |

---

### 1 · Item 8 — Step 13.5, the scaffold audit — **TODO**

**Do:** insert a half-step between scaffold and implementation, before any epic is built.
Four checks, all mechanical: the empty app builds; every declared dependency resolves at
its pinned version; every package the stack-guide names exists under that name; the
platform target in the scaffold matches `decisions/platform.md` and `idea.md`.

**Evidence:** decisive errors in CLI-agent trajectories have a **median onset at execution
step 7** and are **57.9% epistemic** — and an epistemic error at step 13 is invisible until
step 16, after every wave has been built on top of it. Stage A carries three half-steps
(3.5, 4.5, 8.5) and Stage B carries none, which is backwards: Stage B is where the
expensive work happens.

**Why it ranks first:** it is one new skill with four exit-code checks, it needs no other
item to land first, and it protects the most expensive phase in the pipeline.

---

### 2 · Item 10 — Change the critic contract — **TODO**

**Do:** three coupled edits.
1. Every critic agent carries an **enumerated checklist** in its own file instead of a
   general mandate — the shape `hb-research-critic` now uses (C1–C7).
2. `hb-patcher`'s prompt is edited so it is never asked to agree with, restate, or justify
   a finding — only to apply it.
3. The orchestrator logs, per finding, whether the artifact actually changed at the cited
   location: a **coupling rate**, recorded in the findings JSON.

**Evidence:** in the only controlled comparison of critic topologies, **critique uptake
(coupling rate 93.5% broadcast vs 33.6% hierarchical)** is the variable that moved
accuracy, while **reviewer precision (0.644 → 0.861) bought nothing**; and forcing the
author to explicitly acknowledge the critique **lowered** final accuracy 85.2% → 82.5%.

**Why it matters here:** hyperbuild spends 14–18 opus critic seats per `standard` run and
has never measured whether one finding changes one artifact. The coupling rate is the
first hard evidence that the critic budget buys anything — and it is a prerequisite for
ever cutting the panel counts honestly.

---

### 3 · Item 11 — Move half of DESIGN-CRAFT §4 into code — **TODO**

**Do:** add a DOM/CSS linter run by step 8 over every mockup *before* rendering: contrast
ratio, tap target ≥44×44, overflow/clipping, horizontal page scroll, safe-area boxes
present, colors drawn only from `tokens.css`, font-family count, viewport reflow at
breakpoints. Then ship an audit of every DESIGN-CRAFT rule labelled **machine-checkable /
judge-checkable / human-only**.

**Evidence:** roughly half of §4's layout-integrity bar has a published standard and a
deterministic check, and is currently judged by an opus critic looking at PNGs — paying a
frontier model to look for clipped text is the most expensive way to run a
`getBoundingClientRect`. It is also the less reliable way: these are exactly the
structurally precise judgments a vision judge is worst at.

**Preserve:** step 8.5 does not shrink to nothing. What remains for `hb-design-critic` is
the genuinely Tier-2/3 half — signature element present, depth model applied, three
structural differences between directions — which is the half that justifies the seat.

---

### 4 · Item 12 — A licence gate — **TODO**

**Do:** an SPDX field per entry in `research/harvest/harvest-log.md`; step 10 records the
SPDX id + attribution for every adapted skill; `scripts/gate-ship.sh` fails on a missing
or incompatible licence.

**Evidence:** steps 5, 9 and 10 harvest third-party repos and adapt them "license-checked,
attributed" — with no SPDX field, no machine check and no gate item anywhere. The
completeness critic's finding stands: **`licen[sc]e` appears zero times in 410 KB of
research** commissioned to inform two steps that carry a licence obligation.

**Why it ranks above bigger items:** every other gap in this backlog costs a refactor.
This one costs a takedown.

---

### 5 · Item 13 — Artifact security checks at the ship gate — **TODO (partial)**

**Shipped:** `scripts/gate-ship.sh` runs a two-tier secret scan over `app/` (high-confidence
credential shapes fail; heuristic assignment-shaped hits warn) plus a committed-`.env`
check that still allows `.env.example`-style templates.

**Still to do:** a **dependency audit**, and a check that **every declared dependency
resolves to a real published package at the declared version** — walking
`package.json` / `pubspec.yaml` / `Cargo.toml` / the platform equivalent against the
registry.

**Evidence:** the gate now proves the tests pass, the tree is clean, and no credential is
committed. It still does not prove that a package name the model invented has not since
been registered by somebody else. The corpus's clearest supply-chain incident ran exactly
that path: agentic triage → install → poisoned cache → stolen publishing secrets → an
unauthorized release, retracted.

**Note the ordering constraint:** this check needs network access, and the ship gate runs
inside Stage B, which is web-tool-denied by the Rule of Two. Run it as a *script* invoked
by the gate — the script is not an agent and the restriction is about what an agent holds,
not about whether the pipeline may ever resolve a registry URL.

---

### 6 · Item 15 — The golden-task eval suite — **TODO**

**Do:** build `evals/` per the audit's §8 design — **12 frozen ideas** in `evals/ideas/`
stratified across archetypes (CRUD, data-viz, real-time, integration-heavy, one
game/canvas idea exercising the `partial`/`none` mockup path) including **3 deliberately
under-specified ideas**, a reference solution per idea, two-tier grading (Tier 1 = the
same scripts as `scripts/gate-*.sh`; Tier 2 = one isolated judge per rubric dimension,
binary pass/fail with a written critique and an `Unknown` escape hatch), structural
snapshots with a review workflow, and three cadences (smoke / release / quarterly). Then
gate every edit to `.claude/skills/hyperbuild*`, `.claude/agents/hb-*`,
`docs/DESIGN-CRAFT.md` and `docs/RESEARCH-ARCHIVE.md` behind the smoke tier.

**Evidence:** one sentence of prompt tuning cost Anthropic a measured **3% on both Opus
4.6 and 4.7**, and their prompt-caching bug "made it past multiple human and automated
code reviews, as well as unit tests, end-to-end tests, automated verification, and
dogfooding". hyperbuild's editable surface is 23 skills, 22 agents and two binding docs,
with no regression detector at all. **"It ran to completion" is not a test.**

**Two details that decide whether the suite works:** derive the effect-size floor from
five runs of one golden idea at a pinned model + pinned Claude Code version — do **not**
import the widely-quoted 3pp threshold, which is cross-setup noise and would blind you to
real 1–2pp regressions. And report both `pass@k` and `pass^k`, tracking `pass^k`
**per step**: the step with the worst per-step `pass^k` is where the next checkpoint
belongs, not wherever intuition says.

**Depends on:** item 4 (manifest `usage`), which has shipped.

---

### 7 · Item 16 — Run the two experiments — **TODO**

**Do:** (a) 23 per-step skills vs one monolithic pipeline skill, same golden ideas,
measuring pass rate and tokens. (b) Stage A fan-out vs one long-context agent, same ideas,
measuring `pass^3` and cost.

**Evidence:** principle 1 — the harness's founding decision — has **no source measuring
fresh-context-per-step orchestration in a multi-step build pipeline**; the researcher and
the fact-checker say so independently. The adjacent controlled study says gains are "near
zero when a strong agent harness already divides and retrieves on its own", and Claude Code
*is* a strong harness; Anthropic removed **>80% of Claude Code's system prompt** for
Opus 5 with no measurable coding-eval loss. Meanwhile Stage A's fan-out is defensible in
kind (its relay is a written file, which is near-lossless — the favorable side of the
CONFIRMED information-bottleneck result) and unpriced in degree: the +90.2% headline is
vendor-private with no third-party reproduction, 80% of its variance is explained by token
spend, and the corrected cost of multi-agent work is **~3.75× a single agent, not 15×**.

**Why it is worth the weekend:** these settle the largest architectural question and the
largest cost line in the harness, and **nobody else can run them.** Keep principle 1
either way — the degradation evidence is real and the ergonomics are excellent — but stop
describing it as evidence-backed until this runs.

**Depends on:** item 15.

---

### 8 · Item 18 — OpenTelemetry configuration — **TODO**

**Do:** configure `.claude/settings.json` to emit `claude_code.cost.usage`,
`claude_code.token.usage`, `claude_code.tool_decision`, `claude_code.tool_result` and
`claude_code.permission_mode_changed`, correlated by `prompt.id` / `session.id`, written
into `runs/<run_tag>/`.

**Evidence:** the binding constraint on a running loop is error **visibility**, not error
rate: a live agent runtime with 4,286 unit tests and 827 governance checks achieved **0%
ex-ante prevention**, **87% regression blocking**, and **~70% of incidents caught by a
human noticing**, with detection latency from 13 hours to 60 days. Without a tool-level
log, a bad run is unreconstructable.

**Note:** the manifest's per-step `usage` (shipped) answers "what did it cost". This
answers "why did it do that", which is the question you actually have at 2am.

---

### 9 · Item 19 — Annotate the deficit each component compensates for — **TODO**

**Do:** give every step skill and every agent a one-line annotation naming the model
deficit it exists to compensate for, and add "delete what the model no longer needs" to a
release checklist run at each model upgrade.

**Evidence:** "every component in a harness encodes an assumption about what the model
can't do on its own." Anthropic deleted an entire sprint construct at one model upgrade
and **>80% of a system prompt** at another, both with no measurable loss. hyperbuild has
23 skills, 22 agents and two binding docs and **no mechanism for shrinking** — only for
growing.

**The honest version of this item:** it will eventually delete some of what is listed
above it in this file. That is the point.

---

### 10 · Item 22 — Estimate the research area half-life — **TODO**

**Do:** add `verified_at` + `re_verify_by` per claim in
`runs/<run_tag>/temp/claims-0N.json`; on a reused vault, re-verify a random 10% sample and
record the drift rate in `research/README.md`.

**Evidence:** the **90-day re-verify rule is an assertion** that appears nowhere in the
evidence, and it defends the single largest cost in the pipeline — "research is spent
once… the archive is reusable by every later app" is the economic load-bearer for the
premier `verify/` budget (up to 60 verifier agents per area × 4 areas). Nobody has
estimated the half-life of a verified area. The audit corpus is its own counter-datapoint:
it contains a REFUTED verdict against a claim built on a leaderboard read weeks earlier,
and repo properties that went stale in five months.

**Instrument it before defending it.** If the drift rate on a 10% sample is high, the
reusability guide is selling something it does not have; if it is low, the harness gains
its first published number for the claim its economics rest on.

---

## Deliberately NOT doing

Two changes the literature pushes toward and that this harness is choosing, with reasons,
not to make. They are recorded here so a future session does not "discover" them and
helpfully implement them.

### Do NOT add a second human checkpoint inside Stage A

The one stop at the design gate stays the only stop.

**Why:** past a point, more escalation *lowers* realized safety through reviewer fatigue
(the inverted-U), corroborated mechanically by Anthropic measuring **users approving ~93%
of permission prompts** — a gate a human clears 93% of the time is a speed bump, and its
value comes from being *one* decision rather than a thousand. The placement is also right
where it is: human review matters most at research and planning, "where errors compound
exponentially compared to implementation errors", and the design gate sits on the
pipeline's one genuinely Tier-3 artifact (which design), which is exactly where a human
belongs.

**The correct way to iterate is already built:** `/hyperbuild-revise` and
`/hyperbuild-redesign` rework the designs **at the existing stop** and re-park the run
there. Taste iterates at the stop that exists; a second checkpoint is not needed to get
another look at the work.

### Do NOT adopt a durable-execution runtime

No Temporal, no workflow engine, no orchestration framework.

**Why:** four such runtimes are alive and **none publishes overhead numbers**, so the
trade cannot even be evaluated. More to the point, a manifest plus a git tree is already
an event log with a checkpoint validator — the honest gap this design had was that a
manifest is crash-*resumable*, not crash-*proof*, and that **two processes resuming the
same run would both execute**. That gap is exactly ~20 lines of lockfile, and it has
shipped (`runs/<run_tag>/.lock`). Buying a runtime to fix a solved problem imports a
dependency, a deployment model, and a second source of truth in exchange for nothing
measurable.

**What to do instead if this itches again:** strengthen the parts that are cheap and
missing — the lock's stale-pid handling, SIGTERM handling in the router, and the
bounded background-subagent wait (`CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`, 10-minute
default).

---

## Working rules for this file

- An item is **TODO**, **IN PROGRESS**, or **DONE**. A DONE item moves to the "Already
  shipped" line at the top of this file with its number kept; it is never deleted, so the
  audit trail from finding → change survives.
- Every item keeps its **one-line evidence**. An item whose evidence has been refuted gets
  struck with the refutation recorded, not quietly dropped — the same rule the research
  archive runs on (`docs/RESEARCH-ARCHIVE.md`).
- New items need a source. "It would be nice if" is not one.

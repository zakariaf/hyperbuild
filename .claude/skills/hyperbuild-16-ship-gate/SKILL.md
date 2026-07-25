---
name: hyperbuild-16-ship-gate
description: >
  Step 16 of the hyperbuild pipeline — THE ship gate (FINAL STEP). Runs
  scripts/gate-ship.sh FIRST (the Tier-0 half: task state, no dangling
  files: paths, epic acceptance, feature status, the traceability chain,
  git cleanliness and commit shapes, frozen-oracle hashes, a credential
  scan over app/, and "every declared dependency resolves"), then spawns
  hb-gate-verifier for the checks that must EXECUTE the toolchain: full
  test suite
  green, lint/analyzer clean, platform-appropriate
  build succeeds, every FROZEN skill-gate copy under
  runs/<run_tag>/gates/skill-scripts/ passes, the oracle is still frozen
  (every SHA-256 matches manifest frozen_gates AND the live
  .claude/skills/app-*/scripts/ have not silently diverged), the
  feature→task→file→test TRACEABILITY CHAIN holds for every must/should
  feature, and app/ is a clean git repo with scaffold/wave/epic history.
  Produces
  runs/<run_tag>/gates/ship-report.md. The gate's
  verdict is final — failures are fixed by changing the app, never by
  re-interpreting checks; MAX 2 fix rounds (round 2 only if a Tier-0
  signal changed), then blocked with an honest report. On pass, delivers the final user message. Invoked by the
  hyperbuild router via Skill(); not run directly by users.
---

# Step 16 — Ship gate (FINAL STEP)

You are executing step 16 (ship-gate) of the hyperbuild pipeline. Step 15's adversarial review has been applied and its tests were green; nothing runs after this step — when the gate passes you deliver the final message and the run is complete.

**Goal:** a mechanical, evidence-backed verdict that the app is done — and the final message to the user.

**RULE OF TWO — no web tools in Stage B.** Every agent this step spawns runs WITHOUT WebFetch and WebSearch: `hb-gate-verifier` is tool-locked to `Read, Grep, Glob, Bash`, and the fix lanes' agents to their own allowlists — `hb-implementer` and `hb-test-engineer` to `Read, Write, Edit, Bash, Grep, Glob`, `hb-patcher` to `Read, Edit, Grep, Glob`. The restriction is restated verbatim inside the spawn template below and required of every fix-lane spawn, so it holds even if an agent definition is later loosened — least privilege, not thrift: the gate's agents hold a shell and, in the fix lanes, repo write over the finished app. **This step's own procedure needs no web access either.** Every command it runs comes verbatim from `runs/<run_tag>/scaffold.md` `## Toolchain` (step 13 verified them there precisely so 14–16 never re-derive), cross-checked against `research/02-engineering/author/stack-guide.md`; every check reads artifacts already on disk. A check that seems to need external information is a mis-stated check, not a research errand: record it in the ship report and let the round fail honestly. Toolchain network calls (dependency install, the platform build) are toolchain operations and stay allowed; `curl`/`wget`/package-manager search for docs, code, or listings does not.

**THE GATE'S VERDICT IS FINAL.** You may not re-run individual checks and re-classify their failures as false positives, downgrade a check to "advisory", shrink the checklist between rounds, or memo away a failure. If a check fails, change the APP (or the genuinely stale artifact, with named evidence) until the gate passes. A blocked run with a true manifest beats a shipped app that lies.

**⚠ THE SKILL GATES ARE FROZEN — THIS GATE RUNS THE COPIES AND PROVES THEY DID NOT MOVE.**
Step 10's `hb-skill-smith` AUTHORED the `.claude/skills/app-*/scripts/*.sh` PASS/FAIL
gates; step 12.1b froze them to `runs/<run_tag>/gates/skill-scripts/<skill>/<script>.sh`
and recorded a SHA-256 per file in manifest `frozen_gates`. Two consequences bind every
round of this step:

- **Check 7 executes ONLY the frozen copies.** Never `.claude/skills/app-*/scripts/*.sh`.
  Grading the finished app with the live scripts would let anything that ran in Stage B
  decide its own passing grade.
- **Check 10 (`oracle-frozen`) proves the oracle held.** Every frozen hash must still
  match the manifest, and the live originals must not have silently diverged from the
  freeze. This is the check that makes the other nine mean something: a green suite
  measured by a check that moved during the build is not evidence.

**⚠ ANTI-HIDING RULE — the frozen scripts stay readable, and so do the live ones.**
Freezing is IMMUTABILITY, not secrecy. Nothing in this step hides a gate from the agents
it grades, and no fix lane may propose doing so. The evidence is direct: the highest
reward-hacking rate on record (~80% of attempts, Opus 4.6 on an early MirrorCode) was
measured with test cases HIDDEN, and the model responded by attacking the scorer itself —
injecting logging into the scoring script and binary-searching it. Concealment does not
buy honesty; it redirects the attack onto the measurement. Readable-and-unwritable is the
configuration. The ship report prints the full frozen-script list with its hashes, on
purpose.

---

## Inputs

Read these before spawning:
- `runs/<run_tag>/manifest.json` — run_tag, gear, platform, stage. If the router did not name the active run_tag, take the run whose manifest has `stage: BUILD`.
- `runs/<run_tag>/idea.md` — verbatim app idea. GOSPEL.
- `runs/<run_tag>/decisions/platform.md` — chosen platform + rationale (step 1).
- `runs/<run_tag>/scaffold.md` — the `## Toolchain` section: the VERIFIED build / test / lint commands (step 13 recorded them; steps 14–16 read them verbatim and never re-derive).
- `research/02-engineering/author/stack-guide.md` — the committed tooling decisions (step 5) — cross-check only; scaffold.md's verified commands win.
- `research/product-spec.md` — feature list + screen inventory (for the final message).
- `epics/00-overview.md` — epic list + PRD coverage matrix; every `epics/NN-<slug>/epic.md` and `task-NN-<slug>.md`.
- `features/00-index.md` — must/should feature ids.
- `app/` — the implemented application.
- `runs/<run_tag>/gates/review-loop-log.md` (if exists) — step 15's known gaps, reported honestly at the end.
- `runs/<run_tag>/gates/skill-scripts/<skill-name>/<script>.sh` — **THE FROZEN GATE ORACLE** (step 12.1b). The only skill gates check 7 runs; check 10's subject.
- `runs/<run_tag>/manifest.json` → `frozen_gates` (freeze-root-relative path → SHA-256) + `frozen_gates_frozen_at` — check 10's reference values. This step NEVER writes them and NEVER re-freezes: a ship gate that can re-cut its own oracle is not a gate.
- `runs/<run_tag>/decisions/gate-changes.md` (if exists) — the log of every legitimate, explicitly-decided change to a gate script. Check 10 reads it to tell a logged decision from a silent edit.
- `.claude/skills/app-*/scripts/*.sh` — the LIVE originals. Read and hashed for check 10's divergence comparison; never executed by this step.
- `scripts/gate-ship.sh` — **the Tier-0 half of this gate, and it is not yours to edit.** It lives in `scripts/` at the repo root, and `guard-write.sh` rule 4 refuses any write to `scripts/gate-*.sh` for as long as a run is in stage `BUILD` — which is exactly the window in which `hb-implementer` (repo write over the app it is being graded on), `hb-test-engineer` and `hb-patcher` are live. Its `script_sha256` is recorded into every round's JSON, so a change is detectable as well as prevented. Procedure item 2 runs it; its exit code is a fact.

---

## The ship gate checklist (canonical)

Ten checks. ALL must pass. Every round runs ALL ten fresh — a fix for one check can break another.

**Who executes which check.** `scripts/gate-ship.sh <run_tag>` (procedure item 2) decides
every check that is artifact state, referential integrity, or a git/filesystem fact.
`hb-gate-verifier` (procedure item 3) is spawned for the checks that must EXECUTE the
platform toolchain — the exit codes only a resolved command can produce — plus check 10's
judgment about logged versus silent oracle changes. A gate executed by a model reading
prose is a Tier-2 gate wearing Tier-0 clothes; the rows below say which is which.

| Script check | What it proves (all Tier 0) | Checklist row |
|---|---|---|
| S01–S04 | `app/` is a git repo · clean working tree · a scaffold commit · a `wave <N>:` commit per live wave-log entry and an `epic <NN>: critic pass` per patch log with applied hunks | 9 |
| S05 | every `epics/*/task-*.md` is `status: done` | 3 |
| S06 | **no dangling paths** — every path in every task's `files:` list exists on disk | 8 (files leg) |
| S07 | every `## Acceptance criteria` checkbox in every `epic.md` is `[x]` | 4 |
| S08 | every must/should feature file is `status: implemented` | 5 |
| S09 | the full chain: feature → spec file → citing tasks all done → their `files:` on disk → a test file among them | 8 |
| S10–S12 | **secret scan over `app/`**: AWS keys, private-key headers, GitHub/Slack/Google/Stripe/GitLab tokens (hard fail) · assignment-shaped heuristics (warn) · a committed `.env` (hard fail) | *(new — the gate proved tests pass and the tree is clean; it never proved there is no credential in the repo)* |
| S13 | frozen-oracle hashes agree with manifest `frozen_gates` AND the live originals; an unlogged live divergence fails, a divergence logged in `decisions/gate-changes.md` warns | 10 (mechanical half) |
| S14 | **every declared dependency resolves** — the platform manifest parses and every package it declares is pinned in the lockfile (`pubspec.yaml`↔`pubspec.lock`, `package.json`↔lock, `Cargo.toml`↔`Cargo.lock`, `Podfile`↔`Podfile.lock`) | *(new — catches a hallucinated package name someone has since registered)* |

**The verifier's residue — the checks a script cannot make, and the ONLY ones it runs:**
**1** (tests-green), **2** (lint-clean), **6** (build-succeeds), **7** (skill-gates: execute
the FROZEN copies), **10** (oracle-frozen: the FROZEN-GATE VERIFY block's exit code plus the
`gate-changes.md` judgment), and the resolution status of step 15's findings. Every one of
those needs a command resolved from `scaffold.md` `## Toolchain` or a decision about a log —
neither is a set-coverage walk.

**S13 and check 10 deliberately overlap.** The script confirms the hashes; the verifier runs
the canonical three-set VERIFY block and judges exit 3 against `gate-changes.md`. Two
independent reads of the oracle's integrity is the one place duplication is the point.

| # | Check id | Passes when | Evidence required |
|---|----------|-------------|-------------------|
| 1 | tests-green | The FULL test suite exits 0 with zero failures (exact command from scaffold.md `## Toolchain`) | Command, total test count, failure count |
| 2 | lint-clean | Lint/analyzer exits 0 with zero errors and zero warnings | Command, issue count |
| 3 | tasks-done | Every `epics/*/task-*.md` has frontmatter `status: done` | Offender list (empty) |
| 4 | epic-acceptance | Every acceptance-criteria checkbox in every `epics/*/epic.md` is `[x]` (step 14 checks them off at each epic close, with evidence) | Unchecked list (empty) |
| 5 | prd-coverage | Every must/should feature in the `epics/00-overview.md` coverage matrix maps to ≥1 done task, and every must/should `features/NN-*.md` has `status: implemented` | Uncovered/unflipped list (empty) |
| 6 | build-succeeds | The platform-appropriate build command exits 0 | Command, artifact path or closing output lines |
| 7 | skill-gates | Every FROZEN generated-skill check script — `runs/<run_tag>/gates/skill-scripts/*/*.sh` — exits 0, run from the repo root. **The frozen copies and ONLY the frozen copies**; `.claude/skills/app-*/scripts/*.sh` is never executed here (that is the set `hb-skill-smith` wrote and Stage B could reach). A skill with no frozen scripts contributes nothing. Runs only AFTER check 10 passes — an unverified oracle grades nothing | Script list with exit codes, each path under `runs/<run_tag>/gates/skill-scripts/` |
| 8 | traceability-chain | HARD. The chain holds, walked MECHANICALLY per feature: every must/should feature F-NN in `features/00-index.md` → `features/NN-*.md` exists → ≥1 task with `features: [F-NN]` in frontmatter and ALL such tasks `status: done` → every path in those tasks' `files:` lists exists in `app/` → the test files those tasks name/added pass (they ran inside check 1's full-suite run; the verifier greps the mapping and spot-checks per feature) | Per-feature chain walk; a break ANYWHERE names the feature id AND the broken link — broken-link list (empty) |
| 9 | git-clean | HARD. `app/` is a git repo, the working tree is clean (`git -C app status --porcelain` outputs nothing), and `git -C app log --oneline` shows a non-trivial history with the scaffold commit, a `wave <N>:` commit for every wave in `runs/<run_tag>/temp/wave-log.md` not annotated `DEAD`, and an `epic <NN>: critic pass` commit for every epic whose patch log (`runs/<run_tag>/temp/epic-NN-patch-log.json`) has a non-empty `applied` array — an epic with zero applied hunks has NO epic commit, and that is a pass | Both commands + decisive output (porcelain empty; log tail with commit count) |
| 10 | oracle-frozen | HARD, and it runs FIRST — checks 1–9 are only meaningful if this one holds. Run the FROZEN-GATE VERIFY script (pasted into the spawn below) and read its exit code. **Exit 0 = pass.** **Exit 2 = FAIL, always** — `MISSING` / `TAMPERED` / `UNRECORDED`, or `frozen_gates` absent/empty: the oracle itself was altered or was never frozen, so nothing measured by it can be trusted, and no fix lane can repair it (see the fix table). **Exit 3 = the LIVE `.claude/skills/app-*/scripts/*.sh` diverged from the freeze**: every offending `LIVE-ADDED` / `LIVE-DELETED` / `LIVE-EDITED` path is named in the evidence, then FAIL — **unless** every one of them is accounted for by an entry in `runs/<run_tag>/decisions/gate-changes.md` naming that exact script with its old and new sha, who decided, and why; in that case record `warn`, quote each entry in the evidence, and print them in the ship report. A legitimate mid-run skill improvement is allowed and is a LOGGED DECISION; a silent edit is not, and the difference is the log. `WARN no scripts/*.sh:` at exit 0 is a `warn` naming the skills. **Never repair this check by re-freezing, by editing `frozen_gates`, or by deleting a script to make the sets match** — those three moves are the failure this check exists to detect | Verify script's exit code + its full output; on exit 3, the divergent paths AND the matching `gate-changes.md` entries (or their absence) |

---

## The FROZEN-GATE VERIFY block (checks 7 and 10)

Canonical source is step 12's 12.1b; reproduced
VERBATIM here so this step depends on no file another step wrote, and step 14 carries
the same copy in its 14.0.5. **The three copies MUST NOT drift** — change one, change
all three. Exit 0 = clean · exit 2 = the frozen set or the manifest was tampered with ·
exit 3 = the LIVE scripts diverged from the freeze.

```bash
RUN_TAG=<run_tag>
python3 - "$RUN_TAG" <<'PY'
import hashlib, json, os, sys
run  = sys.argv[1]
root = f"runs/{run}/gates/skill-scripts"
rec  = (json.load(open(f"runs/{run}/manifest.json")).get("frozen_gates") or {})
sha  = lambda p: hashlib.sha256(open(p, "rb").read()).hexdigest()
skills = ".claude/skills"
names  = sorted(os.listdir(skills)) if os.path.isdir(skills) else []
live = {}
for d in names:
    sd = f"{skills}/{d}/scripts"
    if not (d.startswith("app-") and os.path.isdir(sd)):
        continue
    for f in sorted(os.listdir(sd)):
        if f.endswith(".sh"):
            live[f"{d}/{f}"] = f"{sd}/{f}"
froz = {}
for d, _, fs in os.walk(root):
    for f in fs:
        if f.endswith(".sh"):
            p = os.path.join(d, f)
            froz[os.path.relpath(p, root)] = p
tamper, diverge = [], []
if not rec:
    tamper.append("manifest frozen_gates is missing or empty — the oracle was never frozen")
for k, want in sorted(rec.items()):
    if k not in froz:
        tamper.append(f"MISSING      {k} — frozen copy is gone")
    elif sha(froz[k]) != want:
        tamper.append(f"TAMPERED     {k} — frozen copy no longer matches its recorded sha")
for k in sorted(set(froz) - set(rec)):
    tamper.append(f"UNRECORDED   {k} — frozen file with no manifest entry")
for k in sorted(set(live) - set(rec)):
    diverge.append(f"LIVE-ADDED   {k} — live script added since the freeze")
for k in sorted(set(rec) - set(live)):
    diverge.append(f"LIVE-DELETED {k} — live script deleted since the freeze")
for k in sorted(set(live) & set(rec)):
    if sha(live[k]) != rec[k]:
        diverge.append(f"LIVE-EDITED  {k} — live script edited since the freeze")
nogate = [d for d in names
          if d.startswith("app-") and not any(k.startswith(d + "/") for k in live)]
for line in tamper + diverge:
    print(line)
if nogate:
    print("WARN no scripts/*.sh: " + ", ".join(nogate))
print(f"frozen_gates: {len(rec)} recorded, {len(froz)} frozen on disk, {len(live)} live "
      f"— {len(tamper)} tamper, {len(diverge)} divergence")
sys.exit(2 if tamper else (3 if diverge else 0))
PY
```


## Procedure

1. **Resolve the exact commands from `runs/<run_tag>/scaffold.md` `## Toolchain`.** Step 13 recorded the VERIFIED build / test / lint commands there precisely so steps 14–16 never re-derive them — read them verbatim. Cross-check against `research/02-engineering/author/stack-guide.md` and `decisions/platform.md`; if scaffold.md's Toolchain section is missing (it shouldn't be — step 13's exit criteria require it), fall back to the stack-guide's committed commands and note the gap in the ship report. Examples of the shape you are looking for — the recorded commands win over these:

   | Platform | test_command | lint_command | build_command |
   |----------|-------------|--------------|---------------|
   | Flutter | `cd app && flutter test` | `cd app && flutter analyze` | `cd app && flutter build <target> --release` |
   | Node/web | `cd app && npm test` | `cd app && npm run lint` | `cd app && npm run build` |
   | iOS native | `cd app && xcodebuild test -scheme <scheme>` | `cd app && swiftlint` | `cd app && xcodebuild build -scheme <scheme>` |

   Update manifest: `steps."16": "in-progress"`. Set `round = 1`.

2. **Run the Tier-0 script gate FIRST, every round:**

   ```bash
   scripts/gate-ship.sh <run_tag> \
     --json-out runs/<run_tag>/temp/ship-gate-script-round-<R>.json
   ```

   - **Exit 0** = every hard check passed (WARNs may remain and MUST be carried into the
     ship report). **Exit 1** = at least one hard check FAILED — the round is already a
     fail; still spawn the verifier so the fix round sees the complete picture.
     **Exit 2** = usage/environment error (no such run, no `python3`) — a broken gate, not
     a passing one: fix the environment and re-run.
   - It writes the canonical gate-verdict schema (`checks[]` with
     `id`/`description`/`result`/`evidence`, `overall`, `failed`) plus `script_sha256`.
     Record that hash in the ship report: it identifies exactly which oracle graded the run.
   - **NEVER edit `scripts/gate-ship.sh` to make a round pass**, and never route a fix lane
     through it. A failing script check is a fact about `app/`, `epics/`, or `features/` —
     fix those. If the script is genuinely wrong, that is a HARNESS change: stop, say so in
     the report, and let a human edit it. This is the same rule the frozen oracle obeys, one
     level up: the run may read the gate and may not write it.
   - If `scripts/gate-ship.sh` is MISSING, the gate cannot pass. Record it as a hard failure
     and block — a missing oracle is not a silent pass.

3. **Spawn hb-gate-verifier** for the toolchain checks and check 10's judgment. Spawn ONCE per round. The verifier runs checks and reports; it NEVER fixes anything. You fix; you never verify — separation of powers holds in both directions. The script already decided checks 3, 4, 5, 8, 9, the mechanical half of 10, and the two new security/dependency checks: the verifier is told not to re-run them.

   **Spawn template:**
   ```
   subagent_type: hb-gate-verifier
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste runs/<run_tag>/idea.md body}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are step 16 (ship gate) of the hyperbuild
     pipeline — the FINAL step. Steps 13–15 built, tested, and
     adversarially reviewed the app in app/. The DETERMINISTIC half of
     this gate already ran as code (scripts/gate-ship.sh) and its verdict
     is a fact you consume, not a claim you re-check: your job is the
     checks that must EXECUTE the toolchain, plus check 10's judgment.
     You report pass/fail with per-check evidence.
     You NEVER fix anything — the orchestrator owns fixes. Checks are
     facts, not opinions: never re-interpret a failing check as a false
     positive, never soften a threshold.

     YOUR INPUTS:
     - round: <round number>
     - app_root: app/
     - script_verdict: runs/<run_tag>/temp/ship-gate-script-round-<R>.json
       — the Tier-0 verdict from scripts/gate-ship.sh. READ IT FIRST.
       Every id in it (S01..S15) is ALREADY DECIDED: do not re-run it, do
       not re-litigate it, do not restate it in your checks array. It
       covers checks 3, 4, 5, 8, 9 and the mechanical half of 10, plus a
       credential scan and a dependency-resolution check that have no
       prose row. If it says a check failed, that check failed.
     - script_exit_code: <0|1> — the exit code of scripts/gate-ship.sh
       this round, handed to you by the orchestrator
     - test_command: <exact command resolved in procedure item 1>
     - lint_command: <exact command resolved in procedure item 1>
     - build_command: <exact command resolved in procedure item 1>
     - epics_dir: epics/
     - coverage_matrix: epics/00-overview.md
     - features_index: features/00-index.md
     - wave_log: runs/<run_tag>/temp/wave-log.md — check 9 keys off it
     - frozen_gates_root: runs/<run_tag>/gates/skill-scripts/ — the FROZEN
       gate oracle (step 12.1b). Check 7 executes these copies and ONLY
       these; check 10 hashes them. The live
       .claude/skills/app-*/scripts/*.sh are read and hashed for check
       10's divergence comparison and NEVER executed.
     - gate_changes_log: runs/<run_tag>/decisions/gate-changes.md (may not
       exist — absence is normal) — check 10 reads it to tell a logged
       decision from a silent edit.
     - verdict_path: runs/<run_tag>/gates/ship-verdict.json

     READ FIRST:
     - runs/<run_tag>/scaffold.md — its ## Toolchain section is the source
       of the commands above
     - research/02-engineering/author/stack-guide.md — the committed
       tooling decisions
     - epics/00-overview.md — the PRD coverage matrix
     - features/00-index.md — the must/should feature ids

     FROZEN-GATE VERIFY (check 10's executable — reproduced verbatim from
     step 12's 12.1b; run it, read its exit code, quote its full output):
     <paste the FROZEN-GATE VERIFY bash+python3 block from this skill's
     "The FROZEN-GATE VERIFY block" section here, VERBATIM, with RUN_TAG
     set to <run_tag>>

     YOUR CHECKS — run check 10 FIRST, then 1, 2, 6, 7, in that order, and
     run every one even after the first failure (the orchestrator needs
     the complete picture). Checks 3, 4, 5, 8 and 9 are NOT yours this
     round: scripts/gate-ship.sh decided them (S05, S07, S08, S09, S01–S04
     in script_verdict), along with a credential scan and a
     dependency-resolution check. Do not re-run them, do not restate them
     in your checks array, and do not offer a second opinion about a fact.
     1. tests-green: run test_command; PASS only on exit 0 with zero
        failures; record the total test count.
     2. lint-clean: run lint_command; PASS only on zero errors AND zero
        warnings.
     6. build-succeeds: run build_command; PASS only on exit 0; record the
        artifact path or the closing output lines.
     7. skill-gates: run every FROZEN copy —
        `for s in runs/<run_tag>/gates/skill-scripts/*/*.sh; do bash "$s";
        echo "$? $s"; done` — from the repo root. PASS only if every
        script exits 0; list each script path with its exit code. Run the
        frozen copies and ONLY the frozen copies: do NOT run, substitute,
        or fall back to .claude/skills/app-*/scripts/*.sh, even if a
        frozen copy looks stale or a live one looks newer — a live script
        that differs is check 10's finding, not check 7's input. If check
        10 exited non-zero, still run check 7, and say in its evidence
        that its result is UNTRUSTED because the oracle did not verify.
     8. traceability-chain — SCRIPT-OWNED (S09). Do not walk it again.
        Its one residual leg is yours only as a by-product: the tests
        those tasks named ran inside YOUR check 1, so if check 1 failed,
        say in its evidence which feature chains its failures touch.
     9. git-clean — SCRIPT-OWNED (S01–S04). Do not re-run the git
        commands.
     10. oracle-frozen: run the FROZEN-GATE VERIFY block pasted above and
        report on its EXIT CODE, not on your reading of its output.
        exit 0 → PASS (a trailing "WARN no scripts/*.sh:" line is a
        `warn`, naming the skills). exit 2 → FAIL, unconditionally: the
        frozen set or manifest `frozen_gates` was tampered with, or was
        never written. exit 3 → the LIVE .claude/skills/app-*/scripts/
        diverged from the freeze: name every LIVE-ADDED / LIVE-DELETED /
        LIVE-EDITED path in the evidence, then read
        runs/<run_tag>/decisions/gate-changes.md — if EVERY divergent
        script has an entry there naming that exact path with its old and
        new sha, who decided, and why, record `warn` and quote those
        entries; if even one is unaccounted for, FAIL and say which. You
        are reporting, not repairing: never re-freeze, never edit
        manifest frozen_gates, never delete a script to make the sets
        match, and never propose hiding a gate script — the frozen
        scripts are readable by design (immutability, not secrecy).

     TOOL POLICY — RULE OF TWO (restated here so it binds regardless of
     your agent definition): you have NO web access in Stage B. No
     WebFetch, no WebSearch, no Task — and no fetching docs, code, or
     package listings through Bash (`curl`, `wget`, a package manager's
     search/docs subcommand). Your toolset is Read, Grep, Glob, Bash, and
     Bash is for running the exact commands passed above, the skill
     scripts, the git checks, and writing the verdict JSON. Every check is
     answerable from this repo alone; if you believe a check needs
     external information, record that as the check's evidence and fail
     it — never look it up, and never substitute a plausible answer.

     Write the verdict JSON to verdict_path via a Bash heredoc, exactly
     this canonical schema (identical to your agent prompt's):
     {"gate": "ship", "run_tag": "<run_tag>", "round": <round>,
      "checks": [{"id": "tests-green", "description": "...",
                  "result": "pass|fail|warn", "evidence": "<command → observed>"}],
      "overall": "pass|fail", "failed": <count>}
     Your checks array holds ONLY your ids — tests-green, lint-clean,
     build-succeeds, skill-gates, oracle-frozen — never an S-id and never
     a check the script owns. The orchestrator merges your JSON with
     script_verdict into one report. "overall" is "pass" only when NO
     check of YOURS is "fail"; the GATE passes only when that AND the
     script's exit 0 both hold.
     "warn" is legal ONLY on check 10 (oracle-frozen), and only in its two
     named cases: exit 0 with a "WARN no scripts/*.sh:" line, or exit 3
     where EVERY divergent script is accounted for in
     runs/<run_tag>/decisions/gate-changes.md. Every other check is
     pass/fail. A check-10 warn passes the gate and MUST be printed in the
     ship report. Your final message: overall verdict + per-check
     pass/fail + the verdict path. Data, not prose.
   ```

4. **NEVER emit bare text while the verifier is in flight.** Test and build commands take minutes. While waiting, append round notes to `runs/<run_tag>/temp/orchestrator-notes.md` via Edit/Write.

5. **Read the verdict.** `runs/<run_tag>/gates/ship-verdict.json` (canonical schema — the same one pasted into the spawn):
   ```json
   {
     "gate": "ship",
     "run_tag": "habit-coach-3f9a2c",
     "round": 1,
     "checks": [
       { "id": "tests-green", "description": "full suite green",
         "result": "fail",
         "evidence": "cd app && flutter test → 247 tests, 3 failures: test/habit_streak_test.dart ..." }
     ],
     "overall": "fail",
     "failed": 1
   }
   ```
   **The gate passes ONLY when BOTH halves are clean: `scripts/gate-ship.sh` exited 0 AND the verifier's `"overall"` is `"pass"`.** Merge the two JSONs before deciding anything — a green verifier over a red script is not a pass, and the script half cannot crash-and-be-assumed-passed the way a subagent can. If the verifier crashed or wrote nothing, re-spawn it ONCE. If it fails a second time, run ITS checks yourself via Bash — checklist unchanged, evidence recorded — and write the verdict JSON yourself in the same schema. This is the ONE documented collapse of the verify/fix separation; the checklist itself never shrinks. **Note what this collapse does NOT license:** running check 7 against the live scripts, or "repairing" check 10 by re-freezing. You may execute the checklist yourself; you may not soften it, and re-freezing is not a step-16 power under any circumstance.

6. **`scripts/gate-ship.sh` exited 0 AND no verifier check `fail` (warns allowed where the checklist authorizes them) → skip to item 9.** Otherwise run a fix round. Fix lanes by failing check — fix the APP, never the check:

   | Failing check | Fix lane |
   |---------------|----------|
   | tests-green | Spawn hb-test-engineer with the failing test list. Production bug → fix the code. NEVER weaken, skip, or delete a test to go green. |
   | lint-clean | Run the stack's auto-fixer first (e.g. `dart fix --apply` / `npm run lint -- --fix`). For the remainder: stub a patch log (`echo '{"total_findings": 0, "applied": [], "skipped": [], "conflicts": [], "escalated": []}' > runs/<run_tag>/gates/ship-lint-patch-log.json`), convert lint output into the step-15 finding shape, spawn hb-patcher on it. |
   | tasks-done | Verify the work EXISTS first (read the code, run its tests). Genuinely done but stale frontmatter → flip `status: done`, citing file + test evidence in the ship report. Not actually implemented → spawn hb-implementer then hb-test-engineer on that task, step-14 discipline. |
   | epic-acceptance | Verify each unchecked criterion against the app. Met → check the box, citing evidence in the ship report. Not met → hb-implementer task for the gap. |
   | prd-coverage | A must/should feature uncovered this late is the worst case: spawn hb-implementer (+ hb-test-engineer) scoped to that feature. Flip the feature file to `status: implemented` only after its acceptance criteria verifiably hold. |
   | build-succeeds | Read the build error. Surgical (import, config, signature) → hand-craft the Edit or route through hb-patcher. Structural → hb-implementer. |
   | skill-gates | Read the failing FROZEN script's output — it names the violated rule, and the script is readable, so quote it. Fix the offending app code (hb-patcher for surgical hits, hb-implementer for structural ones). **NEVER edit or delete a gate script — frozen or live — to go green, and never re-freeze to pick up an edited live script.** Both are caught by check 10 next round and both are the exact contradiction the freeze removed. A gate script that is genuinely wrong does NOT get fixed inside this step: record it in the ship report with named evidence, let the round fail toward BLOCKED, and let a human change it through step 12's freeze (logged in `decisions/gate-changes.md`). |
   | traceability-chain | Repair the NAMED broken link, per feature. Missing `features/NN-*.md` → an upstream artifact was lost; restore it from the PRD before anything else. No citing task, citing task not done, or a `files:` path missing from app/ → the feature was not fully built: spawn hb-implementer (+ hb-test-engineer) scoped to the gap, step-14 discipline. A `files:` entry that is genuinely stale (the file verifiably moved) → fix the task's `files:` list, citing the real path + its passing tests in the ship report. NEVER trim the feature index or a task's `features:` list to shorten the chain. |
   | git-clean | Dirty tree → commit the legitimate fix-round work (`ship-gate round <N>: <what changed>`); NEVER discard real changes to fake cleanliness. `app/` not a repo, or the log missing the scaffold commit, a non-DEAD logged wave's commit, or a required epic critic-pass commit (one with applied hunks in its patch log) → a step 13/14 discipline failure that cannot be reconstructed honestly: do NOT fabricate history with a catch-all commit — record it and let the round fail toward BLOCKED. |
   | S10 / S12 secret scan (script) | A high-confidence credential or a committed `.env` in `app/`. Fix in this order: (1) remove the secret from the working tree and replace it with an environment read or a `.env.example` placeholder; (2) **treat the credential as compromised and tell the user to rotate it in the final message** — it is in the git history, and a fix-round commit does not un-publish it; (3) commit the removal. Do NOT rewrite history to hide it, do NOT add the file to `.gitignore` and call it fixed, and never edit the scan patterns. An S11 heuristic `warn` is reviewed and either fixed or explained in one line in the ship report — a fixture key is a legitimate answer, silence is not. |
   | S14 declared dependencies (script) | A package declared in the platform manifest is absent from the lockfile. Run the platform's install/resolve command (`flutter pub get`, `npm install`, `cargo fetch`, `pod install`) and commit the lockfile. If it does not resolve because **the package does not exist**, that is a hallucinated dependency reaching the ship gate: remove it, spawn `hb-implementer` to replace its usage with a real package named in the stack-guide (whose claims were verified in area 02), and re-run. Never delete the lockfile or the declaration to make the sets agree. |
   | S06 dangling `files:` path (script) | The path a task declared does not exist. Same rule as traceability-chain: the file was never written (build the gap) or genuinely moved (fix the task's `files:` list, citing the real path and its passing tests in the ship report). Never delete the entry to make the check pass. |
   | S13 frozen hashes (script) | Same lane as check 10 below — and the same prohibition. The script and the verifier reach this conclusion independently; agreeing with them by re-freezing is the failure, not the fix. |
   | oracle-frozen | **THERE IS NO FIX LANE. This check is not repairable from inside step 16, by design.** Exit 2 (`MISSING`/`TAMPERED`/`UNRECORDED`, or no `frozen_gates`) means the oracle that graded the entire build was altered or never existed: every other check's result is now unevidenced, and the only honest outcome is BLOCKED. Exit 3 with an unlogged divergence means someone edited a live gate script during Stage B without recording the decision. In both cases: do NOT re-freeze, do NOT edit manifest `frozen_gates`, do NOT delete a script so the sets match, do NOT write a `gate-changes.md` entry after the fact to launder a divergence you just discovered (a decision log written by the party being audited, about a change it did not decide, is a forgery). Copy the verify script's full output into the ship report, set `blocked_on: "ship-gate: oracle-frozen"`, and say plainly which scripts moved and that a human must re-freeze through step 12 before this run can ship. The one legitimate cause is a real, human-decided mid-run skill improvement — and that one is already logged in `decisions/gate-changes.md`, which turns the check into a `warn`, not a fail. |

   **Every fix-lane spawn carries the TOOL POLICY block** from the spawn template in item 3, adjusted to that agent's allowlist (`hb-implementer` / `hb-test-engineer`: `Read, Write, Edit, Bash, Grep, Glob`; `hb-patcher`: `Read, Edit, Grep, Glob`) — no WebFetch, no WebSearch, no Task, no doc-fetching through Bash. A fix lane is the LAST place to relax it: these agents hold repo write over a finished app one commit from ship. Everything a fix needs is already on disk — the stack-guide (with its `verify/*.md` corrections), the generated `app-*` skills, the feature specs, and the failing check's own output, which names the violated rule.

   **NEVER flip a task status, feature status, or acceptance checkbox without verified evidence named in the ship report.** Flipping state to satisfy the gate without the work is the exact lie this gate exists to prevent.

7. **Re-run the gate.** Increment `round`; re-run `scripts/gate-ship.sh` (item 2), then re-spawn hb-gate-verifier fresh (item 3) — BOTH halves in full, ALL ten checks, not just the previously failing ones. Check 10 re-runs every round for a reason: a fix lane that touched a gate script would be caught here, in the round after it happened.

   **RUN CONTROL AT THIS ROUND BOUNDARY, before you re-run anything** (the router owns these mechanics — this is the tool call; the authority is `hyperbuild/SKILL.md` "Run control", cited by section number). A fix round is one of the few in-step boundaries the router named but cannot reach from its own text, and the router's file is the first thing compaction eats:

   ```bash
   [ -f "runs/<run_tag>/ABORT" ] && echo "ABORTED" || echo "CONTINUE"
   echo "elapsed_s=$(( $(date +%s) - $(cat runs/<run_tag>/temp/step-16.start) ))"
   ```

   - **ABORT present** (§2) → do not start the round. Write what this round proved, return to the router; it sets `blocked_on: "aborted-by-user"`.
   - **Elapsed past this step's class ceiling** (§3 — gate class: 20 turns / 45 min wall clock) → stop and report that the cap fired, rather than trimming the round to fit underneath.
   - **Bump `usage.turns`** for this step in the manifest (§4). Measured, never estimated.

8. **MAX 2 fix rounds, and round 2 is EARNED, not owed** (the router's knobs table: critic fix rounds ≤2 for BOTH standard and premier gears — the one row that does not widen with the gear; round 1 + up to 2 fix rounds = at most 3 verifier spawns).

   **Round 2 runs ONLY if a Tier-0 signal changed between attempts** — a test flipped, a script gate's exit code flipped, a re-render differs, a file that was absent now exists, or a count that was short now clears. Record WHICH signal changed, with the evidence (both values, before → after), in `runs/<run_tag>/temp/orchestrator-notes.md` BEFORE you re-run anything. Same red checks + same evidence + no changed signal → **do NOT re-run the gate**: set `blocked_on` and write the honest report immediately. Re-running an unchanged gate is the model talking itself into a different answer; unaided re-attempts degrade rather than converge (PIPELINE.md principle 7). Note that `oracle-frozen` can never earn a round-2 re-run — it has no fix lane at all.

   Rounds spent, or round 2 not earned → the run is BLOCKED:
   - Manifest: `steps."16": "blocked"`, `blocked_on: "ship-gate: <comma-separated failing check ids>"`.
   - Write `runs/<run_tag>/gates/ship-report.md` with `verdict: BLOCKED` (format below), including what each round attempted and why it did not clear.
   - Tell the user honestly: which checks fail, the evidence, what was tried, and what a human should do next. Do NOT soften it. Then stop.

9. **On pass — write the ship report** to `runs/<run_tag>/gates/ship-report.md`:
   ```markdown
   ---
   run_tag: <run_tag>
   verdict: PASSED
   rounds: <N>
   test_count: <total from tests-green evidence>
   date: <YYYY-MM-DD>
   ---

   # Ship gate report — <run_tag>

   ## Checklist (final round) — Tier 0: scripts/gate-ship.sh (exit <code> · sha256 <first 12>)
   | id | Check | Result | Evidence |
   |----|-------|--------|----------|
   | S05 | every task status: done | PASS | 61/61 tasks done |
   ...all S-rows from the script JSON, including the secret scan and dependency checks...

   ## Checklist (final round) — Tier 2: hb-gate-verifier
   | # | Check | Result | Evidence |
   |---|-------|--------|----------|
   | 1 | tests-green | PASS | <command> — <N> tests, 0 failures |
   ...tests-green, lint-clean, build-succeeds, skill-gates, oracle-frozen...

   ## The oracle that graded this build
   Frozen at <manifest frozen_gates_frozen_at> by step 12.1b · <N> scripts ·
   verify exit code this round: <0|3 (logged)>

   | Frozen script (executed by checks 7 and by every step-14 sync point) | SHA-256 |
   |---|---|
   | runs/<run_tag>/gates/skill-scripts/app-testing/check-coverage.sh | c40e…full 64 hex |

   These scripts were authored by `hb-skill-smith` at step 10, frozen and hashed at step
   12 BEFORE any code was written, and executed unchanged by every step-14 sync point and
   by this gate. No Stage-B agent could modify them. They were readable by every agent
   throughout — freezing is immutability, not secrecy.

   Logged gate changes (from `runs/<run_tag>/decisions/gate-changes.md`; omit this
   subsection when the file does not exist):
   - <ISO timestamp> — <script> — <old sha → new sha> — decided by <who> — <why>

   ## Round history
   - Round 1: <failing checks> → <fix lane used, what changed>
   - Round <N>: all checks passed

   ## Evidence for flipped artifacts
   - <task/criterion flipped> — <file + test that proves it> (or "none flipped")

   ## Known gaps
   - <from runs/<run_tag>/gates/review-loop-log.md ## Known gaps, plus PRD could/won't features not built>

   ## What I am least confident about
   <3-6 entries. Each names a file, a test, or a check and says what may be wrong with it
   and why this gate would not know. DISTINCT from ## Known gaps above: known gaps are
   what was found and accepted; this is where the verdict itself may be wrong.>
   - `app/lib/sync/conflict_resolver.dart` — 4 tests cover it, all of them single-device.
     Nothing here exercises two clients writing the same record, which is the case the
     feature exists for.
   - `hb-ux-critic`'s fidelity verdict (Tier 2, a judge's opinion) compared 6 of 11
     screens; the other 5 had no capture. A "matches the mockup" reading covers just over
     half the app.
   - Step 15 could not check <X> — <verbatim from runs/<run_tag>/gates/review-uncertainty.md>.

   ## Security and dependency notes (from scripts/gate-ship.sh)
   - Secret scan: <N> files scanned, 0 high-confidence hits. Heuristic warns: <resolved, or
     one line each explaining why the hit is a fixture/config key — never silence>.
   - Dependencies: <every declared package pinned in <lockfile>>, or the named exceptions.
   - Omit this section only when the script recorded `skip` for all three (no app to scan).
   ```

   **`## What I am least confident about` is MANDATORY and is written on PASSED and
   BLOCKED alike** — it is the build half of the pipeline's calibrated-uncertainty record
   (PIPELINE.md, [Calibrated uncertainty](../../../PIPELINE.md#calibrated-uncertainty--what-i-am-least-confident-about)),
   a Gate 2 checklist item, and the part of this report README tells the reader to read
   first. Build it like this:

   - **READ `runs/<run_tag>/gates/review-uncertainty.md` first.** Step 15 writes it on
     every pass — what its three critics could NOT check (which screens `hb-ux-critic`
     had no capture for, what `hb-spec-critic` grepped rather than ran, where
     `hb-code-critic` hit its 15-finding truncation cap, and every `{"findings": []}` stub,
     which is the absence of a review and not a clean review). Fold those in.
   - **Tolerate its absence explicitly.** If the file is not there, say so in an entry —
     "step 15 recorded no coverage gaps file, so the critics' own blind spots are unknown
     for this run" — and never silently proceed as if the critics had full coverage.
   - **Add what THIS gate could not prove**: anything it passed as a `warn`; a check the
     script recorded as `skip`; a traceability chain that is intact on paper but whose
     tests are thin; and the `hb-ux-critic` fidelity verdict, which must be LABELLED here
     and in the checklist table as a judge's opinion (Tier 2) rather than a mechanical
     pass — it compares screenshots and cannot block the ship.
   - **3–6 entries**, each citing a file, a test, or a check by name. It is NOT a copy of
     `## Known gaps`: if an entry could be pasted there unchanged, it does not belong
     here. Write it even when everything is green — a clean gate with nothing to be
     unsure about is a claim about the gate's coverage, and it is almost always false.

   **Verify it mechanically after you write the file.** `scripts/gate-ship.sh` runs at
   item 2, before the report exists, so on a clean single-round pass its S15 check records
   `skip`. Close that gap with one command, and fix the report (never the command) if it
   prints `MISSING`:

   ```bash
   awk '/^## What I am least confident about[[:space:]]*$/{f=1;next} f&&/^## /{f=0}
        f&&/^[[:space:]]*[-*][[:space:]]+[^[:space:]]/{n++} END{print (n>=3 ? "OK "n : "MISSING "n+0)}' \
     runs/<run_tag>/gates/ship-report.md
   ```

   The `## The oracle that graded this build` section is written on EVERY outcome, PASSED
   and BLOCKED alike. Build its table from `runs/<run_tag>/gates/frozen-gates.sha256` (or
   manifest `frozen_gates`), never from memory. On a BLOCKED `oracle-frozen` round it
   carries the verify script's full output verbatim instead of a clean table — which
   scripts moved, and how — because that is the single most important fact about the run.

10. **Close out the run.** Manifest: `steps."16": "done"`, `stage: "DONE"`, `blocked_on: null`. Mark ALL 20 todos complete (the 19 step todos — including the half-steps 3.5, 4.5 and 8.5 — plus the checkpoint todo). Then deliver the final user message — the ONLY prose message this stage sends, and it follows this contract exactly:
   - **What was built:** one short paragraph — the app (quote the idea's core), the platform, N must + M should features implemented across K screens (counts from the PRD and coverage matrix).
   - **How to run it:** the exact commands, fenced — dependency install, run, test (from the stack-guide, e.g. `cd app && flutter pub get`, `flutter run`, `flutter test`).
   - **Test count:** "<N> tests, all green" (from the ship verdict evidence).
   - **Known gaps:** the honest list from the ship report — review known gaps, unbuilt could/won't features. If empty, say so.
   - **What I am least confident about:** the same 3–6 entries as the report, in one line each. This is the part the user is told to read first, so it goes in the message, not just the file.
   - **Where things live:** `app/` (the code), `runs/<run_tag>/gates/ship-report.md` (the verdict), `runs/<run_tag>/designs/index.html` (the design gallery), `epics/` and `features/` (the paper trail).

---

## Artifacts

- `runs/<run_tag>/temp/ship-gate-script-round-<R>.json` — one per round, written by `scripts/gate-ship.sh` (procedure item 2): the Tier-0 verdict, ids S01..S15, carrying the script's own `script_sha256`.
- `runs/<run_tag>/gates/ship-verdict.json` — written by hb-gate-verifier (via Bash heredoc), one per round, overwritten each round; schema in procedure item 5. Holds the toolchain checks only.
- `runs/<run_tag>/gates/ship-report.md` — written by the orchestrator after the final round; format in procedure item 9; `verdict: PASSED | BLOCKED`. Always carries `## The oracle that graded this build` and `## What I am least confident about`.
- `runs/<run_tag>/gates/review-uncertainty.md` — **read, never written** by this step (step 15 owns it): the critics' own coverage gaps, folded into `## What I am least confident about`. Its absence is tolerated and stated, never assumed away.
- `runs/<run_tag>/gates/ship-lint-patch-log.json` — only if the lint-clean fix lane ran hb-patcher.
- Manifest flipped to `steps."16": "done"` + `stage: "DONE"` (or `"blocked"` + `blocked_on`).
- **NOT an artifact of this step:** `runs/<run_tag>/gates/skill-scripts/**`, manifest `frozen_gates`/`frozen_gates_frozen_at`, and `runs/<run_tag>/decisions/gate-changes.md`. This step READS and EXECUTES the frozen oracle and writes nothing into it, ever. A ship gate that can re-cut the oracle it is graded by has no verdict to give.

---

## Exit criteria

- `runs/<run_tag>/temp/ship-gate-script-round-<R>.json` exists from the final round and `scripts/gate-ship.sh` EXITED 0 — actually executed this round, never assumed and never transcribed by hand
- `runs/<run_tag>/gates/ship-verdict.json` exists from the final round, valid JSON, with the verifier's checks present (including `oracle-frozen`); merged with the script verdict, all ten checklist rows are accounted for
- NO CREDENTIAL SHIPPED: the script's secret scan recorded `pass` (or `skip` with no `app/` to scan), no `.env` is tracked in `app/`, and every declared dependency resolves in its lockfile
- ORACLE INTACT: check 10 recorded `pass`, or `warn` with every divergence matched to a `runs/<run_tag>/decisions/gate-changes.md` entry. The build was graded by `runs/<run_tag>/gates/skill-scripts/*/*.sh` — never by `.claude/skills/app-*/scripts/*.sh` — and every frozen hash still matches manifest `frozen_gates`
- `runs/<run_tag>/gates/ship-report.md` exists with `verdict: PASSED` — or `verdict: BLOCKED` once its 2 fix rounds are spent (or round 2 was not earned), with every failing check and round history honestly recorded — and in BOTH cases carries the `## The oracle that graded this build` section AND a non-empty `## What I am least confident about` section (3–6 entries, each citing a file, test or check by name)
- Manifest updated (`steps."16"` and `stage` per procedure items 8/10); all todos complete
- The final user message (pass) or the honest blocked message (fail) has been delivered

## Pipeline complete

There is no next step and no further `Skill()` invocation. On PASS: the app lives in `app/`, the verdict in `runs/<run_tag>/gates/ship-report.md`. On BLOCKED: the manifest says so, the report says why, and the user knows exactly what is left. Either way the manifest tells the truth. You're done.

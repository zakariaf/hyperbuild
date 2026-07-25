---
name: hyperbuild-15-adversarial-review
description: >
  Step 15 of the hyperbuild pipeline — whole-app adversarial review. Spawns
  3 critics in parallel (hb-code-critic, hb-spec-critic, hb-ux-critic),
  each emitting an independent findings JSON to runs/<run_tag>/gates/. The
  orchestrator ranks and dedupes findings, spawns hb-patcher (TOOL-LOCKED
  to Read + Edit) to apply surgical fixes, and commits the patch pass in
  app/. Structural findings become new task files and trigger AT MOST ONE
  loop back through step 14. TWO PASSES MAXIMUM, and the second runs only
  when a Tier-0 signal changed between them — new commits, a flipped test
  count, a flipped skill-gate exit code (PIPELINE.md principle 7). Every
  pass writes gates/review-uncertainty.md — what the critics could NOT
  check — which step 16 folds into the ship report's "What I am least
  confident about".
  Invoked by the hyperbuild router via Skill(); not run directly by users.
---

# Step 15 — Adversarial review (parallel, 3 critics)

You are executing step 15 (adversarial-review) of the hyperbuild pipeline. Step 14 implemented every epic with per-epic reviews and green tests; step 16 (ship gate) runs next and its verdict is final — this step is the last chance to find and fix defects before the gate.

**Goal:** three independent adversarial passes over the WHOLE app — code quality, spec coverage, mockup fidelity — merged into one ranked findings list, applied as surgical patches, with structural gaps routed back through step 14 exactly once at most.

**RULE OF TWO — no web tools in Stage B.** Every agent this step spawns runs WITHOUT WebFetch and WebSearch: `hb-code-critic` and `hb-ux-critic` are tool-locked to `Read, Grep, Glob, Bash`, `hb-spec-critic` to `Read, Grep, Glob`, `hb-patcher` to `Read, Edit, Grep, Glob`, and `hb-test-engineer` (item 9's red-suite lane) to `Read, Write, Edit, Bash, Grep, Glob`. The restriction is restated verbatim inside every spawn template below so it holds even if an agent definition is later loosened — least privilege, not thrift: these agents hold a shell, repo write, or both over the finished app. **This step's own procedure needs no web access either.** Every standard a critic judges against is already on disk and already verified: the PRD and feature specs, `research/02-engineering/author/stack-guide.md` (corrected by `research/02-engineering/verify/*.md`, which overrides it wherever they disagree), the five generated `app-*` skills, and the chosen design's `tokens.css` + mockups + screenshots. A finding a critic cannot cite from those files is not a finding — external best-practice recall is exactly the unverified input principle 11 exists to keep out of the app. Toolchain network calls (dependency install, the capture commands in `scaffold.md` `## Toolchain`) are toolchain operations and stay allowed; `curl`/`wget`/package-manager search for docs, code, or listings does not.

**Loop gate (check FIRST):** if `runs/<run_tag>/gates/review-loop-log.md` exists, this is the SECOND pass — the one permitted loop already ran. On the second pass you MUST NOT create new task files: remaining structural findings are recorded as known gaps (procedure item 10). If the loop log does not exist, this is the first pass.

**TWO PASSES MAXIMUM, AND THE SECOND ONE IS EARNED (PIPELINE.md principle 7).** Before re-spawning a single critic on a second pass, prove that a TIER-0 SIGNAL CHANGED since the first one. Exactly one of these must be true, and you must record which in `runs/<run_tag>/temp/orchestrator-notes.md` with its evidence:

- `git -C app log --oneline <first-pass-HEAD>..HEAD` is NON-EMPTY — step 14's loop-back actually landed commits (the first pass recorded its HEAD sha in `gates/review-loop-log.md`);
- the full test suite's pass/fail state or test COUNT differs from the count the first pass recorded;
- a frozen generated-skill `scripts/*.sh` gate's exit code flipped.

**RUN CONTROL AT THIS PASS BOUNDARY** (the router owns these mechanics — this is the tool call; the authority is `hyperbuild/SKILL.md` "Run control", cited by section number). A pass boundary is one of the in-step checkpoints the router named but cannot reach from its own text, and the router's file is the first thing compaction eats. Before deciding on pass 2, run:

```bash
[ -f "runs/<run_tag>/ABORT" ] && echo "ABORTED" || echo "CONTINUE"
echo "elapsed_s=$(( $(date +%s) - $(cat runs/<run_tag>/temp/step-15.start) ))"
```

**ABORT present** (§2) → do not start pass 2; write the uncertainty file (item 11), record what pass 1 found, and return to the router, which sets `blocked_on: "aborted-by-user"`. **Elapsed past this step's class ceiling** (§3) → stop and report the cap fired rather than shrinking the critic panel to fit under it. **Bump `usage.turns`** for step 15 in the manifest (§4) — measured, never estimated.

**No changed signal → do NOT re-critique.** Skip straight to procedure item 10's second-pass branch: record the surviving findings as known gaps, write the uncertainty file (item 11), and go to step 16. Re-running three opus critics over an identical tree buys a differently-worded copy of the same list at the price of a full critic panel — and the evidence is that a second unaided look is not merely break-even but degrading (95.5 → 91.5 → 89.0 on the closest measured analogue; multi-turn gains "don't compound across turns"). The step-14 loop exists precisely to manufacture the changed signal that licenses pass 2. Nothing else does.

---

## Inputs

Read these before spawning anything:
- `runs/<run_tag>/manifest.json` — run_tag, gear, platform, design_choice, stage (must be BUILD). If the router did not name the active run_tag, take the run whose manifest has `stage: BUILD`.
- `runs/<run_tag>/idea.md` — verbatim app idea. GOSPEL. Paste into every spawn.
- `research/product-spec.md` — the PRD: MoSCoW feature list, personas, screen inventory (step 4).
- `research/02-engineering/author/stack-guide.md` — committed stack decisions (step 5).
- `runs/<run_tag>/scaffold.md` — `## Toolchain` section: the VERIFIED build/test/lint commands (step 13 wrote them; use them verbatim, never re-derive).
- `runs/<run_tag>/decisions/design-choice.md` — which design (a|b|c) the user chose.
- `features/00-index.md` — feature index; every must/should feature id (step 4.5).
- `epics/00-overview.md` — epic list + PRD coverage matrix (step 11).
- `app/` — the implemented application (steps 13–14).
- `app/design/tokens.css` + `app/design/design-system.md` — the chosen design system (copied by /hyperbuild-choose).
- `runs/<run_tag>/designs/<choice>/mockups/` — the chosen design's per-screen HTML mockups (step 8).
- `runs/<run_tag>/designs/<choice>/screenshots/` — headless-Chrome renders of those mockups (step 8) — hb-ux-critic's comparison baseline (absent only if the manifest logged `screenshots_skipped`).
- `.claude/skills/app-code-style/SKILL.md`, `app-architecture`, `app-testing`, `app-components`, `app-review-checklist` — the generated project skills (step 10).

---

## Procedure

1. **Determine the pass.** First pass (no `gates/review-loop-log.md`) or second pass (it exists). Note it in `runs/<run_tag>/temp/orchestrator-notes.md`. Update manifest: `steps."15": "in-progress"`.

2. **Resolve the chosen design.** Read `runs/<run_tag>/decisions/design-choice.md` and manifest `design_choice` — the letter fills `<choice>` in the hb-ux-critic template. If they disagree, `decisions/design-choice.md` wins; fix the manifest.

3. **Spawn all 3 critics in parallel.** In ONE message — three Task calls:
   - `hb-code-critic` → `runs/<run_tag>/gates/review-findings-code.json`
   - `hb-spec-critic` → `runs/<run_tag>/gates/review-findings-spec.json`
   - `hb-ux-critic` → `runs/<run_tag>/gates/review-findings-ux.json`

   Critics NEVER edit anything. Each emits at most 15 findings — the most load-bearing. All three use one canonical finding shape (schema in Artifacts below) with id prefixes `CODE-`, `SPEC-`, `UX-`.

   **hb-code-critic spawn template:**
   ```
   subagent_type: hb-code-critic
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste runs/<run_tag>/idea.md body}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are step 15 (adversarial review — code critic)
     of the hyperbuild pipeline. Step 14 implemented every epic; tests were
     green at each epic boundary. You run in parallel with hb-spec-critic
     and hb-ux-critic. After you return, the orchestrator ranks and dedupes
     all findings; hb-patcher (TOOL-LOCKED to Read + Edit) applies the
     patchable ones as surgical hunks; structural ones become new tasks.
     You NEVER edit code — you emit a findings JSON.

     YOUR INPUTS:
     - app_root: app/
     - output_path: runs/<run_tag>/gates/review-findings-code.json
     - finding id prefix: CODE-
     - cap: at most 15 findings, most load-bearing first

     READ FIRST (in this order):
     - research/02-engineering/author/stack-guide.md — the committed
       "we will do X" decisions; every deviation in app/ is a finding
     - .claude/skills/app-code-style/SKILL.md
     - .claude/skills/app-architecture/SKILL.md
     - .claude/skills/app-testing/SKILL.md
     - .claude/skills/app-components/SKILL.md
     - .claude/skills/app-review-checklist/SKILL.md — run EVERY item on this
       checklist against the app

     Hunt: security holes (unvalidated input, injection, secrets in source),
     swallowed errors, state-management violations, architecture-boundary
     breaches, non-idiomatic code the stack-guide forbids, dead code, missing
     tests on critical paths. Judge against the stack-guide and generated
     skills, NOT your general taste. Set "structural": true when a surgical
     Edit cannot fix it. Do NOT include exact replacement code — the patcher
     owns the wording.

     TOOL POLICY — RULE OF TWO (restated here so it binds regardless of
     your agent definition): you have NO web access in Stage B. No
     WebFetch, no WebSearch, no Task — and no fetching docs, code, or
     package listings through Bash (`curl`, `wget`, a package manager's
     search/docs subcommand). Your toolset is Read, Grep, Glob, Bash, and
     Bash is for reading the repo and writing your findings JSON. Every
     rule you cite must come from the files listed above; a "best
     practice" you cannot quote from stack-guide.md, a generated app-*
     skill, or a feature spec is not a finding — the stack-guide's
     decisions already survived Stage A verification and your recollection
     did not.

     Your final message: counts per severity + the findings
     path. Data, not prose.
   ```

   **hb-spec-critic spawn template:**
   ```
   subagent_type: hb-spec-critic
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste runs/<run_tag>/idea.md body}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are step 15 (adversarial review — spec critic)
     of the hyperbuild pipeline. Step 4 wrote the PRD, step 4.5 the feature
     specs, step 11 the epics, step 14 the implementation. You run in
     parallel with hb-code-critic and hb-ux-critic. After you return, the
     orchestrator ranks and dedupes; hb-patcher applies patchable findings;
     structural ones become new tasks. You NEVER edit anything — you are
     tool-locked to [Read, Grep, Glob], so your ENTIRE final message is the
     findings JSON; the orchestrator persists it to
     runs/<run_tag>/gates/review-findings-spec.json.

     YOUR INPUTS:
     - app_root: app/
     - output: the findings JSON returned as your final message (the
       orchestrator writes it to runs/<run_tag>/gates/review-findings-spec.json)
     - finding id prefix: SPEC-
     - cap: at most 15 findings, most load-bearing first

     READ FIRST (in this order):
     - research/product-spec.md — feature list (MoSCoW) + screen inventory
     - features/00-index.md, then EVERY features/NN-*.md with moscow must or
       should — acceptance criteria and States & edge cases are your checklist
     - epics/00-overview.md — the PRD coverage matrix

     For EVERY must and should feature, verify it is present AND wired
     end-to-end in app/: the screen exists, it is reachable through real
     navigation, the primary UX flow completes, data round-trips to storage,
     the acceptance criteria hold in code, and the empty/loading/error states
     the feature spec names exist. A feature that compiles but is unreachable,
     or stubbed, or missing its states, is a finding. Cite the feature id
     (F-NN) and the violated acceptance bullet verbatim in evidence. A
     missing must feature is critical and "structural": true.

     TOOL POLICY — RULE OF TWO (restated here so it binds regardless of
     your agent definition): you have NO web access in Stage B — no
     WebFetch, no WebSearch, no Task (and no Write, no Bash). Your toolset
     is Read, Grep, Glob. Everything you grade against is on disk: the
     PRD, the feature specs, and the coverage matrix. A gap you cannot
     anchor to a feature id and a verbatim acceptance bullet is not a
     finding.

     Your ENTIRE final message is the findings JSON (fenced), then one
     line of counts per severity. Data, not prose.
   ```

   **hb-ux-critic spawn template:**
   ```
   subagent_type: hb-ux-critic
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste runs/<run_tag>/idea.md body}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are step 15 (adversarial review — UX critic) of
     the hyperbuild pipeline. Step 8 built HTML mockups of every screen in 3
     designs and rendered a screenshots/<screen>.png of each; the user chose
     design "<choice>"; step 14 implemented the screens. You run in parallel
     with hb-code-critic and hb-spec-critic. After you return, the
     orchestrator ranks and dedupes; hb-patcher applies patchable findings.
     You NEVER edit anything — you capture, compare, and emit a findings
     JSON, written to output_path via Bash (you have no Write tool).

     YOUR INPUTS:
     - app_root: app/
     - chosen_design: <choice>
     - mockups_dir: runs/<run_tag>/designs/<choice>/mockups/
     - design_screenshots_dir: runs/<run_tag>/designs/<choice>/screenshots/
     - capture_dir: runs/<run_tag>/temp/app-screens/ — save the implemented
       app's captures here
     - toolchain: runs/<run_tag>/scaffold.md ## Toolchain — the VERIFIED
       build/test commands; derive your capture method from them, never
       re-derive
     - output_path: runs/<run_tag>/gates/review-findings-ux.json — write it
       via Bash
     - finding id prefix: UX-
     - cap: at most 15 findings, most load-bearing first

     READ FIRST (in this order):
     - runs/<run_tag>/scaffold.md — the ## Toolchain section
     - app/design/design-system.md — the chosen system: type scale, color,
       spacing, radii, elevation, component specs
     - app/design/tokens.css — the canonical token values
     - research/product-spec.md — the screen inventory (your screen list),
       incl. each screen's mockup_feasibility (full | partial | none)

     THIS IS A SCREENSHOT COMPARISON. First CAPTURE: render the implemented
     app's screens to PNGs in capture_dir via the platform tooling the
     toolchain names — golden-test outputs (Flutter), snapshot-test outputs
     (iOS), screenshot tests (RN/web), or simulator/emulator/running-app
     screenshots. Then, per screen, Read BOTH images — your capture and
     design_screenshots_dir/<screen>.png (the Read tool renders images) —
     and judge them side-by-side: layout structure and hierarchy, token
     fidelity (color, spacing, radii, elevation), typography roles,
     component anatomy, and the empty/loading/error states the mockups and
     feature specs define. Judge FIDELITY, NOT pixel-identity — rendering
     engines differ; flag drift a user would notice, never anti-aliasing.
     Scope: judge ONLY screens the inventory marks full or partial; judge
     partial screens ONLY on their mocked chrome/HUD around the placeholder
     viewport — engine-rendered content is out of bounds. A screen with no
     design screenshot (manifest `screenshots_skipped`) is compared against
     its mockup HTML structure in mockups_dir instead; a screen you cannot
     capture is compared code-vs-mockup-HTML — note the capture gap in the
     finding's evidence. Also grep the UI code for hard-coded values that
     bypass the tokens. One finding per divergence, citing the design
     screenshot (or mockup file) and the token or spec violated. A screen
     missing entirely is critical and "structural": true.

     TOOL POLICY — RULE OF TWO (restated here so it binds regardless of
     your agent definition): you have NO web access in Stage B. No
     WebFetch, no WebSearch, no Task — and no fetching docs, assets, or
     code through Bash (`curl`, `wget`, a package manager's search/docs
     subcommand). Your toolset is Read, Grep, Glob, Bash, and Bash is for
     the capture commands the toolchain names plus writing your findings
     JSON. Your baseline is the design screenshots and mockups already on
     disk plus app/design/tokens.css — never an external reference,
     screenshot, or style guide you would have looked up.

     Your final message: counts per severity, screens captured vs
     fallback-compared, and the findings path. Data, not prose.
   ```

4. **NEVER emit bare text while critics are in flight.** A text-only response ends the turn and kills the pipeline. While waiting, append your ranking hypotheses to `runs/<run_tag>/temp/orchestrator-notes.md` via Edit/Write.

5. **Wait for all 3, then persist.** hb-code-critic and hb-ux-critic write their own JSONs via Bash; **hb-spec-critic cannot write files** (tool-locked to Read+Grep+Glob) — its final message IS the findings JSON. Parse its returned JSON and write it verbatim to `gates/review-findings-spec.json` yourself (as step 4 does for the PRD critic). A critic has FAILED only when its Task returned no parseable findings JSON (for the Bash-armed critics: wrote no file AND returned none): re-spawn it ONCE. If it fails again, write a minimal stub `{"critic": "<name>", "findings": []}` to its output path, log the absence in orchestrator-notes.md, and proceed — but do NOT skip hb-spec-critic's re-spawn lightly: it is the only critic measuring whether the product promise was kept.

6. **Rank and dedupe (orchestrator).** Read all three findings JSONs, then:
   - **Dedupe:** findings from different critics naming the same file + same underlying issue merge into one — keep the highest severity, union the evidence, record contributing ids in `sources`.
   - **Rank:** critical → major → minor. Within a band: findings touching a `must` feature outrank `should`; correctness outranks style.
   - **Split:** `patchable` (a surgical Edit hunk in existing files fixes it) vs `structural` (new files, architecture or schema change, missing feature, whole-screen rework). Trust the critics' `structural` flags but override with judgment — a mislabeled structural finding wastes the one loop.
   - Write `runs/<run_tag>/gates/review-merged.json` (schema in Artifacts).

7. **Pre-create the patch log stub.** hb-patcher is tool-locked to `[Read, Edit]` — it cannot Write, and Edit only modifies existing files. You MUST stub the canonical schema first:
   ```bash
   echo '{"total_findings": 0, "applied": [], "skipped": [], "conflicts": [], "escalated": []}' > runs/<run_tag>/gates/review-patch-log.json
   ```
   The schema is canonical — the patcher only Edits the existing keys. If you skip this, the patcher inlines its log in its response and you may drop the data.

8. **Spawn hb-patcher.** Spawn ONCE, only if `patchable` is non-empty (if empty, note it in orchestrator-notes.md and go to item 10):
   ```
   subagent_type: hb-patcher
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste runs/<run_tag>/idea.md body}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are step 15 (adversarial review — patcher) of
     the hyperbuild pipeline. Three critics reviewed the whole app; the
     orchestrator ranked and deduped their findings. After you return, step
     16 (ship gate) verifies the app mechanically. You are TOOL-LOCKED to
     [Read, Edit] — you cannot Write, you cannot Bash. Patch, never
     regenerate.

     YOUR INPUTS:
     - findings_path: runs/<run_tag>/gates/review-merged.json — apply ONLY
       the "patchable" array, in rank order
     - patch_log_path: runs/<run_tag>/gates/review-patch-log.json (already
       stubbed — Edit its existing keys, never invent an alternate schema)
     - app_root: app/
     - stack_guide: research/02-engineering/author/stack-guide.md
     - tokens: app/design/tokens.css

     Each Edit hunk stays surgical: change as little as possible while
     addressing the finding. Reject findings that don't serve the app idea.
     A finding that turns out to need new files or a restructure goes to
     "escalated", not into an oversized patch. Never delete
     and retype a whole file or widget — that is regeneration wearing a
     patch costume.

     TOOL POLICY — RULE OF TWO (restated here so it binds regardless of
     your agent definition): you have NO web access in Stage B — no
     WebFetch, no WebSearch, no Task (and no Write, no Bash). Your toolset
     is Read, Edit, Grep, Glob. Every rule your hunks must satisfy is
     local: stack_guide, tokens, and the generated app-* skills. A finding
     whose fix you cannot express from those files goes to "escalated"
     with the reason — never guessed at.
   ```

9. **Read the patch log; verify the app still stands.** When the patcher returns:
   - **All criticals applied?** A skipped critical is a blocker — re-read the code and either (a) reject the finding as invalid, (b) hand-craft the Edit yourself (you have Edit access; the lock binds only the patcher — broader tools, not broader license), or (c) promote it to a structural task in item 10.
   - **Patch log still the empty stub?** The patcher failed to log — parse the real log out of its Task result and write it to `runs/<run_tag>/gates/review-patch-log.json` via Bash yourself.
   - **Run the FULL test suite** with the exact test command recorded in `runs/<run_tag>/scaffold.md` `## Toolchain` (step 13 verified it — never re-derive build commands downstream). If red, spawn hb-test-engineer ONCE with the failing test list and the instruction: fix the code the patches broke, NEVER weaken or delete a test. Carry the same TOOL POLICY block into that spawn — no WebFetch, no WebSearch, no Task, no doc-fetching through Bash; its toolset is `Read, Write, Edit, Bash, Grep, Glob`, and every matcher and harness flag it needs is in the `app-testing` skill and the stack-guide's committed testing decisions. Do not proceed with a red suite.
   - **Commit the patch pass** (git-is-the-safety-net; step 16's git check expects this commit in the log). On the green suite just verified, with counts from `review-patch-log.json`:
     ```bash
     git -C app add -A && git -C app commit -m "review: adversarial patch pass (<applied> applied, <skipped> skipped, <escalated> escalated)"
     ```
     Skip ONLY when `git -C app status --porcelain` is empty (nothing was patched) — note that in orchestrator-notes.md. Never leave a patched working tree uncommitted: step 16 requires a clean tree, and an uncommitted patch pass has no audit trail.

10. **Structural findings → new tasks (FIRST PASS ONLY).**
    - **Second pass (`gates/review-loop-log.md` exists):** create NOTHING. Append every remaining structural finding under a `## Known gaps` heading in `runs/<run_tag>/gates/review-loop-log.md` — step 16's final message reports them honestly. Then go to item 11 (the uncertainty file is written on every pass) and on to Exit criteria.
    - **First pass, structural findings exist:** cap at 6 tasks — criticals and must-feature gaps first; more than 6 means step 14 under-delivered, so log the overflow as known gaps rather than looping forever. For each retained finding:
      1. Pick the owning epic dir under `epics/`; if none fits, create a new epic dir numbered one above the current highest (e.g. `epics/09-review-fixes/` with a minimal `epic.md` matching step 11's epic schema: frontmatter id/name/depends_on, goal, scope, and `- [ ]` acceptance criteria from the findings).
      2. Write a full task file in that dir following the epic's existing task naming and frontmatter EXACTLY (open a sibling `task-NN-*.md` and match its keys: id, epic, status, depends_on, size, category, features, files — `category` naming a `research/02-engineering/author/stack-guide.md` `## Code taxonomy` category; `files:` listing the exact `app/` paths the task will create or modify — step 14's wave scheduler and step 16's traceability chain both read it; in a brand-new epic dir with no siblings, use step 11's task schema with those same keys) with `status: todo`. Body: context (quote the finding + evidence), spec, files to touch, testing requirements, definition of done.
      3. **Register the loop work — keep step 14's bookkeeping true.** For every epic that received a new task: set its entry in the manifest's `epics` object to `status: "in-progress"` and bump `tasks_total`. For a brand-new epic dir: add its row to `epics/00-overview.md`'s Epics table and Build order, and add a manifest `epics` entry (`{"status": "in-progress", "tasks_total": <N>, "tasks_done": 0}`). Step 14's ready set picks up any `status: todo` task file by scanning `epics/` regardless — but its epic progress notes (14.2) and epic-close accounting (14.7) require the manifest `epics` entry and the 00-overview.md row to exist and carry true `tasks_total`/`tasks_done` counts, so register both.
    - Write `runs/<run_tag>/gates/review-loop-log.md`: pass 1 date, finding ids retained, task file paths created, overflow findings (if any) under `## Known gaps`, and — REQUIRED, because the second pass's entry condition reads them — a `## Tier-0 signal at pass 1` block recording the exact `git -C app rev-parse HEAD` sha, the test count and pass/fail state from the suite run in item 9, and each frozen skill-gate script with its exit code. Without this block the second pass cannot prove a signal changed, and a pass that cannot prove it does not run.

**AT MOST ONE LOOP THROUGH STEP 14. If you find yourself about to create task files while `gates/review-loop-log.md` already exists, STOP.** Record the findings as known gaps instead. An app that ships with an honest gap list beats a pipeline that oscillates between steps 14 and 15.

11. **Write the uncertainty file — `runs/<run_tag>/gates/review-uncertainty.md`.** Both passes, always, last thing before the exit criteria. This is the build half of the pipeline's calibrated-uncertainty record (PIPELINE.md, [Calibrated uncertainty](../../../PIPELINE.md#calibrated-uncertainty--what-i-am-least-confident-about)); step 16 folds it into `ship-report.md`'s `## What I am least confident about`.

    It records **what the three critics could NOT check** — not what they found. Findings are already in the JSONs; this file is the shape of the hole around them, and you are the only agent that can see it, because you are the one that read all three critics' coverage reports. Derive it mechanically from what came back:

    - **hb-ux-critic** — which screens it captured vs which it fell back to comparing against mockup HTML, and which it could not reach at all. A fidelity verdict on a screen nobody rendered is a reading of source code, and must be labelled as one. Also note that EVERY ux finding is a judge's opinion (Tier 2), never a mechanical result.
    - **hb-spec-critic** — which features it confirmed by RUNNING a flow vs by reading code or grepping a route name. "Present and wired end-to-end" established by grep is the single most over-trusted sentence in this pipeline.
    - **hb-code-critic** — which parts of `app/` it actually opened, and the cap it hit: all three critics are capped at 15 findings, so a critic that returned 15 was truncated, and the 16th finding is unknown, not absent.
    - **Any critic that failed twice and got a `{"findings": []}` stub** — an empty findings file is the absence of a review, not a clean review, and it must say so here in those words.
    - **Escalated / skipped patcher findings, and the overflow past the 6-task cap** — known, unfixed, and worth a human's attention even though they are already in the logs.

    Format: a short `## What step 15 could not check` heading, then 3–6 bullets. Each bullet names the artifact or feature by path/id, states plainly what was not verified, and says what would settle it. No hedging prose, no "further review is recommended". If a pass genuinely checked everything it was supposed to, say that in one line — but say it only if the coverage numbers back it, and put the numbers in the line.

    On a second pass, append to the existing file under a `## Pass 2` heading rather than overwriting: the first pass's coverage gaps are still true unless pass 2 closed them.

---

## Artifacts

- `runs/<run_tag>/gates/review-findings-{code,spec,ux}.json` — one per critic. Canonical finding shape (all three critics here AND step 14's per-epic critic use exactly this object; the merged file reuses it):
  ```json
  {
    "critic": "code",
    "findings": [
      {
        "id": "CODE-01",
        "severity": "critical | major | minor",
        "file": "app/<path to the offending file>",
        "location": "<function/widget/section name + short snippet — an anchor, not an exact-match requirement>",
        "issue": "<one sentence: what is wrong>",
        "evidence": "<verbatim rule from stack-guide/skill, feature acceptance bullet (F-NN), or mockup file + token violated>",
        "fix": "<what a correct fix accomplishes — NEVER exact replacement code>",
        "structural": false
      }
    ]
  }
  ```
- `runs/<run_tag>/gates/review-merged.json` — orchestrator's ranked, deduped split:
  ```json
  {
    "total": 0,
    "patchable": [ { "rank": 1, "sources": ["CODE-01", "UX-04"], "...": "merged finding fields as above" } ],
    "structural": [ { "sources": ["SPEC-02"], "...": "merged finding fields as above" } ]
  }
  ```
- `runs/<run_tag>/gates/review-patch-log.json` — stubbed by orchestrator, populated by hb-patcher (canonical keys: total_findings, applied, skipped, conflicts, escalated — the same key set as step 14's per-epic patch logs).
- `runs/<run_tag>/gates/review-loop-log.md` — first-pass record of structural tasks created; `## Known gaps` section for anything not looped; `## Tier-0 signal at pass 1` (HEAD sha, test count + state, frozen skill-gate exit codes) — the second pass's entry condition reads it. Its existence IS the loop counter.
- `runs/<run_tag>/gates/review-uncertainty.md` — what the three critics could NOT check, in 3–6 named bullets (procedure item 11). Step 16 folds it into `ship-report.md`'s `## What I am least confident about`. Written on EVERY pass, including a pass that was skipped for want of a changed Tier-0 signal.
- New `epics/NN-<slug>/task-NN-<slug>.md` files with `status: todo` (first pass only).

---

## Exit criteria

- All 3 findings JSONs exist and are valid JSON with a `findings` array (stubs documented if a critic failed twice)
- `runs/<run_tag>/gates/review-merged.json` exists; `review-patch-log.json` populated (or patchable was empty and orchestrator-notes.md says so)
- All critical patchable findings applied or explicitly rejected/escalated
- Full test suite green after the patch pass
- Patch pass committed in `app/` (`review: adversarial patch pass (<counts>)`) — or the
  working tree was already clean because nothing was patched, noted in orchestrator-notes.md
- `runs/<run_tag>/gates/review-uncertainty.md` exists and is non-empty (procedure item 11) — required on every pass, including a second pass that was skipped for want of a changed Tier-0 signal
- On a first pass that creates tasks: `review-loop-log.md` carries its `## Tier-0 signal at pass 1` block, so the second pass has something to compare against

Then route by pass:

- **Structural tasks were created this pass (first pass only):** update manifest `steps."15": "looped"`, keep the step-15 todo in-progress, return to the router and invoke step 14 for the new todo tasks — the router re-enters step 15 afterward because `steps."15"` is not `done`:
  ```
  Skill(skill: "hyperbuild-14-implement")
  ```
- **Otherwise (no structural tasks, or second pass):** update manifest: `steps."15": "done"`, mark the step-15 todo complete, return to the router and invoke:
  ```
  Skill(skill: "hyperbuild-16-ship-gate")
  ```

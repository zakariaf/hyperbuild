---
name: hyperbuild-12-design-gate
description: >
  Step 12 of the hyperbuild pipeline — the Stage-A hard gate and THE ONE
  permitted stop. Spawns 1 hb-gate-verifier to mechanically run the full
  Stage-A checklist (research vault, PRD, feature specs, stack guide, 3
  complete design systems with every full/partial screen mocked +
  screenshotted and art-direction cards for none screens, step 8.5's
  visual-QA findings with zero unresolved criticals, generated skills, full
  backlog with PRD↔epics coverage, and the research archive's shape:
  the four FIXED-name areas, a non-empty verify/ in each, provenance blocks
  everywhere), writes runs/<run_tag>/gates/design-gate-report.md and — on
  pass — research/README.md (the areas index + REUSABILITY GUIDE,
  docs/RESEARCH-ARCHIVE.md §8), then stops the pipeline
  with a user-facing summary ending in "run /hyperbuild-choose a|b|c",
  setting manifest blocked_on: "design-choice". On fail: fix artifacts,
  re-run the gate, max 3 rounds, then blocked + honest report. Invoked by
  the hyperbuild router via Skill(); not run directly by users.
---

# Step 12 — Design gate (Stage-A hard gate + THE ONE PERMITTED STOP)

**⚠ READ FIRST — the two ways to violate this step.** (1) This is the ONLY point in
the entire pipeline where you intentionally end the turn with a bare-text, user-facing
message. Everywhere else bare text kills the run; HERE the stop IS the deliverable.
(2) The inverse: **if the gate passes, do NOT invoke `Skill(skill:
"hyperbuild-13-scaffold")`.** Stage B starts only when the user runs
`/hyperbuild-choose <a|b|c>`. If you find yourself about to continue into Stage B after
a pass, STOP. Set the manifest, emit the stop message, end the turn.

You are executing step 12 (design gate) of the hyperbuild pipeline. Steps 1–11 claim
Stage A is complete; this step proves it against artifacts on disk, then hands the user
the one decision the pipeline cannot make: which design to build.

**Goal:** a passing `runs/<run_tag>/gates/design-gate-report.md` and a final user-facing
summary ending with `run /hyperbuild-choose a|b|c` — or, after 3 failed fix rounds, an
honest blocked report. Gate failures are fixed by changing the artifacts, NEVER by
re-interpreting the checks.

---

## Inputs

- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`, `platform`; steps 1–11 (including 3.5, 4.5, 8.5) must read `done`; `screenshots_skipped` (when `true`, checks 19 and 20 downgrade to WARNINGs); `visual_qa_skipped` (same effect on check 20)
- `runs/<run_tag>/idea.md` — verbatim idea. GOSPEL.
- `research/product-spec.md` — the canonical screen inventory, including its `mockup_feasibility` column (checks 12, 17, 18, and 19 key off it)
- `features/00-index.md` — the must/should feature ids
- `runs/<run_tag>/gates/visual-qa-{a,b,c}.json` — step 8.5's visual-QA records (checks 20 and 21; the pass path also quotes their accepted known issues into the stop message)
- Everything else Stage A wrote — enumerated check by check below

## The Stage-A checklist (canonical — paste VERBATIM into the verifier spawn)

Gear numbers: use the standard column unless manifest `gear` is `premier`.

| # | Check | Pass condition |
|---|-------|----------------|
| 1 | Idea | `runs/<run_tag>/idea.md` exists; frontmatter has run_tag, created, platform; body non-empty |
| 2 | Manifest | `runs/<run_tag>/manifest.json` is valid JSON; steps 1–11 all `"done"` — including the half-steps `"3.5"`, `"4.5"`, and `"8.5"` |
| 3 | Platform decision | `runs/<run_tag>/decisions/platform.md` exists; names the stack; contains a rationale |
| 4 | Competitor dossiers | ≥6 (standard) / ≥12 (premier) files in `research/01-product-and-market/research/competitors/`; each has frontmatter + a `## Sources` section |
| 5 | Landscape | `research/01-product-and-market/author/competitor-landscape.md` exists; contains a feature-matrix table |
| 6 | Sentiment | `research/01-product-and-market/research/sentiment/{reddit,hn-forums,appstore-reviews,linkedin-x}.md` all exist; `research/01-product-and-market/author/sentiment-synthesis.md` has a ranked pain-point list |
| 7 | PRD | `research/product-spec.md` exists; has a MoSCoW feature list AND a screen inventory section |
| 8 | Feature specs | `features/00-index.md` exists; one `features/NN-<slug>.md` per must/should PRD feature (≤15 standard / ≤25 premier files); each has moscow + screens frontmatter and all 8 body sections |
| 9 | Stack research | COUNT, do not name: the number of `research/02-engineering/research/*.md` files is within the gear range — ≥6 and ≤8 (standard) / ≥10 and ≤14 (premier) — and each carries `area: 02-engineering` + `phase: research` frontmatter. **There is NO fixed filename list.** Step 5 DERIVES its dimensions per platform (RENAME → DROP → MERGE → ADD), so `architecture.md`, `structure.md`, `testing.md` and `tooling-ci.md` are NOT expected filenames; a specific slug being absent is never a failure. The derivation record is `runs/<run_tag>/temp/dimensions-02.md` — read it to see what was dropped and why. `research/02-engineering/author/stack-guide.md` exists, contains committed "we will do X" decisions, and has a `## Code taxonomy` section. The area name is FIXED — a platform-specific directory (`02-flutter-engineering`, `02-swift-engineering`) is a FAIL, not a variant (`docs/RESEARCH-ARCHIVE.md` §2) |
| 10 | Design research | exactly 3 files under `research/03-design-system/research/` carry BOTH `direction:` and `letter:` in their frontmatter, one per row of `runs/<run_tag>/designs/directions.md` — count by FRONTMATTER, never by file count. The other files in that directory are step 6.3a's SHARED platform dimensions (2 standard / 3 premier: `framework-render-capability`, `type-availability-and-licensing`, plus `platform-design-conventions` OR `accessibility-and-contrast-constraints` at premier) and are EXPECTED — their presence is not a fourth direction. `research/03-design-system/author/design-directions.md` exists and carries a `## Corrections that override the research docs` table |
| 11 | Design systems | for EACH of a, b, c: `runs/<run_tag>/designs/<x>/design-system.md` AND `tokens.css` exist |
| 12 | Mockup completeness | for EACH of a, b, c: `designs/<x>/mockups/` has one `.html` per `full`/`partial` screen in the PRD screen inventory's `mockup_feasibility` column (cap 12 standard / 20 premier); NO `.html` for `none` screens; the SAME screen set across all three designs |
| 13 | Gallery | `runs/<run_tag>/designs/index.html` exists; references all three designs' mockups |
| 14 | Skill-authoring guide | `research/04-claude-skills/author/skill-authoring-guide.md` exists |
| 15 | Generated skills | `.claude/skills/<name>/SKILL.md` exists with valid frontmatter for ALL five: app-code-style, app-architecture, app-testing, app-components, app-review-checklist |
| 16 | Backlog shape | `epics/00-overview.md` exists with a PRD coverage matrix; epic count 4–8 (standard) / 6–12 (premier); every epic dir has `epic.md` + 3–8 (standard) / 4–10 (premier) task files; every task has valid frontmatter (id, epic, status: todo, depends_on, size, category, features, files — `category` naming a category present in `research/02-engineering/author/stack-guide.md`'s `## Code taxonomy`; `files` a non-empty list of planned repo-relative paths — step 14's wave-disjointness key) |
| 17 | PRD↔epics coverage | every must/should feature id from `features/00-index.md` appears in ≥1 task's `features:` frontmatter; zero blank Tasks cells on must/should rows of the coverage matrix |
| 18 | Art-direction cards | every `none` screen in the PRD inventory has a `## Art direction — <Screen>` card in EACH of the 3 `designs/<x>/design-system.md` files (vacuous pass when the inventory has no `none` screens) |
| 19 | Mockup screenshots | for EACH of a, b, c: `designs/<x>/screenshots/` has one non-empty `.png` per mockup `.html`; when manifest `screenshots_skipped` is `true`, missing screenshots are a WARNING (result `warn`), not a fail |
| 20 | Visual QA performed | for EACH of a, b, c: `runs/<run_tag>/gates/visual-qa-<x>.json` exists, is valid JSON, has `rounds` ≥ 1, and its `screens_reviewed` ∪ `screens_not_viewed` covers EVERY `.png` in `designs/<x>/screenshots/` — a screenshot named in neither list is a FAIL (it was never judged). A NON-EMPTY `screens_not_viewed` records `warn`, not `fail`, provided every entry carries a reason: step 8.5 legitimately lists a PNG it could not open rather than judging it from HTML, and those screens go in the report's `### Known visual issues` table so the user knows which screens are unreviewed. When manifest `screenshots_skipped` or `visual_qa_skipped` is `true`, the three files must still exist carrying `"status": "source-only-no-render"` (step 8.5's degraded mode) and the check records `warn`, not `fail` |
| 21 | No unresolved visual criticals | across the three `visual-qa-<x>.json` files, ZERO findings with `"severity": "critical"` and `"status": "open"` (`unresolved_critical` must equal 0 in each file and agree with its `findings`). A critical with `"status": "accepted-known-issue"` is legal ONLY when the file's `rounds` is ≥ 2 (step 8.5's two critic rounds — one patch round — were actually spent) and it carries a non-empty `acceptance_reason`; `"status": "unverifiable"` is legal ONLY in source-only mode (manifest `visual_qa_skipped: true`), also with a reason — either records `warn`, and every such finding MUST be listed in the gate report and in the stop message |
| 22 | Research archive shape | All four areas exist with the FIXED names `research/{01-product-and-market,02-engineering,03-design-system,04-claude-skills}/`, and each has a non-empty `_INDEX.md` plus non-empty `research/`, `verify/`, and `author/` subdirectories. `verify/` EMPTY in any area is a FAIL — that area's findings were never fact-checked (`docs/RESEARCH-ARCHIVE.md` §5). Per-area verify minimums, from the §5 selection rule (3–5 load-bearing claims per dimension standard, 6–10 premier): ≥3 (standard) / ≥6 (premier) `verify/*.md` files in EACH area — **per AREA, never per research FILE**: every area binds a hard `VERIFY_BUDGET` of ≤25 standard / ≤60 premier, so a per-file rule would be unsatisfiable by construction. Plus per-file coverage: every `research/` file that has at least one `"selected": true` claim in its area's registry (`runs/<run_tag>/temp/claims-0N.json`) has ≥1 `verify/<its-dimension>--*.md` file. Every `verify/*.md` frontmatter carries a `verdict:` from the closed vocabulary `CONFIRMED | PARTIALLY_TRUE | REFUTED | UNVERIFIABLE` — any other value is a FAIL |
| 23 | Provenance blocks | EVERY `.md` under each area's `research/`, `verify/`, `critique/`, and `author/` ends with a `<details>` provenance block containing the prompt that produced it (`docs/RESEARCH-ARCHIVE.md` §4). Run it as: `find research/0*-*/research research/0*-*/verify research/0*-*/critique research/0*-*/author -name '*.md' -print0 \| xargs -0 grep -L 'The prompt that produced this'` — any path printed is a FAIL, listed by path. (Do NOT use `research/*/{...}/**/*.md`: `**` needs `globstar`, and `research/*/` also matches `research/harvest/`, which has none of those subdirectories — bash then passes the unmatched patterns to grep literally and the per-pattern errors read like "returns nothing", i.e. a false PASS.) `_INDEX.md` is an index and correctly takes NO provenance block |

---

## Procedure

### Step 12.1 — Recover state

Read `runs/<run_tag>/manifest.json` (run_tag, gear) and `runs/<run_tag>/idea.md`. Set
round R = 1 (or resume: if `temp/design-gate-checks-round-*.json` files exist, R = max
round + 1).

### Step 12.2 — Spawn ONE `hb-gate-verifier`

**Spawn template:**
```
subagent_type: hb-gate-verifier
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md, verbatim}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 12 (design gate) of the hyperbuild
  pipeline — the Stage-A hard gate. Steps 1–11 claim to be done; you verify
  their artifacts mechanically. You NEVER fix, edit, create, or delete any
  artifact you are checking — you check, gather evidence, and report. The
  orchestrator fixes failures and re-spawns you (max 3 rounds). On your
  pass verdict the pipeline stops and waits for the user's design choice.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - gear: <standard|premier>
  - round: <R>
  - screen_inventory_source: research/product-spec.md — parse the screen
    inventory (including its mockup_feasibility column) FIRST; checks 12,
    17, 18, and 19 key off it
  - screenshots_flag: manifest `screenshots_skipped` (absent/false/true) —
    when true, checks 19 and 20 record `warn` instead of `fail`
  - visual_qa_flag: manifest `visual_qa_skipped` (absent/false/true) —
    when true, check 20 records `warn` instead of `fail`
  - visual_qa_files: runs/<run_tag>/gates/visual-qa-{a,b,c}.json — step
    8.5's records; checks 20 and 21 parse them with python3, never by eye
  - feature_index: features/00-index.md
  - output_path: runs/<run_tag>/temp/design-gate-checks-round-<R>.json
    (you have no Write tool — write it with a Bash heredoc)

  READ FIRST (in order):
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/manifest.json
  - research/product-spec.md
  - features/00-index.md

  STAGE-A CHECKLIST: <paste the full 23-row checklist table from this
  skill's "The Stage-A checklist" section here, verbatim, with the <gear>
  numbers applied>

  RESEARCH ARCHIVE: checks 4, 5, 6, 9, 10, 14, 22, and 23 all read the
  research archive, whose BINDING format contract is
  docs/RESEARCH-ARCHIVE.md — read §2 (the area layout and the FIXED area
  names), §3.2 (the closed verdict vocabulary), §4 (the provenance rule),
  and §5 (how many claims must be verified) before running them. Every
  research path is deterministic: research/<NN>-<area>/{research,verify,
  critique,author}/. A step that wrote to the OLD flat paths
  (research/competitors/, research/stack/, research/design/,
  research/stack-guide.md, ...) FAILS its check — do not "find" the file
  at a legacy path and pass the check.

  Run EVERY check with commands (ls, wc -l, grep -c, python3 for JSON and
  frontmatter validation) — never by impression. A check you cannot execute
  is FAIL with evidence "unverifiable: <reason>", not PASS. Record one
  evidence line per check: the command run + the observed value (for FAILs,
  name exactly what is missing, e.g. "designs/b/mockups has 9 of 11
  inventory screens; missing: settings.html, onboarding.html").

  OUTPUT SCHEMA (write to output_path via Bash — this is the canonical
  gate-verdict schema, identical to your agent prompt's):
  {"gate": "design", "run_tag": "<run_tag>", "round": <R>,
   "checks": [{"id": 1, "description": "Idea",
               "result": "pass" | "fail" | "warn",
               "evidence": "<command → observed value>"}],
   "overall": "pass" | "fail", "failed": <count of failing checks>}
  "warn" is legal ONLY on checks 19, 20, and 21: on 19 only when manifest
  screenshots_skipped is true; on 20 when screenshots_skipped/
  visual_qa_skipped is true, or when screens_not_viewed is non-empty and
  every entry states a reason (a screenshot in NEITHER list is still a
  FAIL); and on 21 only for criticals marked "accepted-known-issue"
  (file rounds >= 2 + a non-empty acceptance_reason) or "unverifiable"
  (source-only mode + reason) — a critical still "open" is a FAIL, never
  a warn. For a check-21 warn, list every accepted known issue's id,
  design letter, screen, and what_is_wrong in that check's evidence; the
  orchestrator prints them to the user. "overall" is "pass" ONLY when
  zero checks are "fail" — a "warn" passes the gate but MUST appear in
  the report as a WARNING. Your final message: overall verdict + failed
  check ids + output_path. Data, not prose.
```

While the verifier runs, append thoughts to `runs/<run_tag>/temp/orchestrator-notes.md`
— never bare text. If the verifier dies without writing its JSON, re-spawn it ONCE; if
it dies again, run the checklist yourself via Bash and write the JSON in the canonical
schema (the lock against fixing applies to the verifier's role, not to verification
itself).

### Step 12.3 — Write/append `runs/<run_tag>/gates/design-gate-report.md`

The orchestrator (not the verifier) owns the report. Round 1 creates it; later rounds
append a `## Round <R>` section. Format:

```markdown
---
run_tag: <run_tag>
gate: design
verdict: pass | fail | blocked
rounds: <R>
created: <ISO date>
---
# Design gate report — <run_tag>

## Round <R> — <pass|fail>
| # | Check | Status | Evidence |
|---|-------|--------|----------|
| 1 | Idea | pass | <evidence line from the JSON> |

### Failures & remedies (fail rounds only)
- Check 12 → step 8 → re-spawned hb-mockup-smith for design b, screens: settings, onboarding

### Known visual issues (step 8.5 criticals: accepted after 2 rounds, or unverifiable)
| Design | Screen | Severity | What the render shows | Why it was accepted |
|--------|--------|----------|-----------------------|---------------------|
| c | item-edit | critical | "Save item" CTA is 8px under the nav | patch round moved it; re-render still clipped |
```

Update the frontmatter `verdict`/`rounds` on every round. Status cells are
`pass` | `fail` | `warn`: a check-19 `warn` (screenshots skipped — no Chrome
binary, manifest `screenshots_skipped: true`), a check-20 `warn` (visual QA
could not run for the same reason), and a check-21 `warn` (criticals accepted
as known issues after step 8.5's two rounds) each get a `⚠ WARNING` line under
the table but do NOT make the round a fail. **A check-21 warn also requires the
`### Known visual issues` table**, one row per `accepted-known-issue` or
`unverifiable` critical, quoted verbatim from the `visual-qa-<x>.json` finding
(`design_letter`, `screen`, `what_is_wrong`, `acceptance_reason`) — the same
rows the stop message prints. **A check-20 warn caused by a non-empty
`screens_not_viewed`** adds one row per unviewed screen to the same table
(severity `unreviewed`, "what the render shows" = the reason step 8.5 recorded)
— a screen nobody could open is exactly the thing the user must be told about.
Omit the section entirely when there are none.

### Step 12.4 — On FAIL: fix the artifacts, re-run (max 3 rounds)

**The check is law.** Fix by changing artifacts; never by arguing a check is too strict,
skipping it, or editing the checklist. Map each failed check to its responsible step and
remedy — re-spawn the responsible agent ONCE per round, per that step's own spawn
contract (verbatim idea block-quoted, pipeline position, inputs, exact output path,
read-first list), with the missing/defective artifact named as its explicit required
output:

| Failed check | Responsible step | Re-spawn / remedy |
|---|---|---|
| 1–3 | 1 (intake) | bootstrap artifacts — orchestrator repairs directly (frontmatter, missing rationale) |
| 4–5 | 2 (market recon) | `hb-competitor-analyst` per missing dossier; landscape → orchestrator rebuilds the matrix from dossiers |
| 6 | 3 (social mining) | `hb-sentiment-miner` for the missing platform file; synthesis → orchestrator re-merges |
| 7 | 4 (product spec) | orchestrator patches the missing PRD section (surgical edit, never regenerate the PRD) |
| 8 | 4.5 (feature specs) | write the missing feature file(s) per the features/ contract, or patch missing sections |
| 9 | 5 (stack research) | Read `runs/<run_tag>/temp/dimensions-02.md` — the derivation record names every dimension step 5 committed to. Re-spawn `hb-stack-researcher` per dimension NAMED THERE whose `research/<dimension>.md` is missing (never for a filename this check imagined); if the derivation itself is short of the gear floor, re-enter step 5 at its DERIVE step. stack-guide → orchestrator re-authors the missing decisions from the surviving claims in `runs/<run_tag>/temp/claims-02.json` |
| 10 | 6 (design research) | `hb-design-researcher` for the missing direction |
| 11 | 7 (design systems) | `hb-design-system-author` for the affected direction |
| 12–13 | 8 (mockups) | `hb-mockup-smith` scoped to exactly the missing screens × design; gallery → orchestrator patches index.html |
| 14 | 9 (skill research) | `hb-stack-researcher` re-spawn per step 9's template |
| 15 | 10 (skill forge) | `hb-skill-smith` for the missing/invalid skill |
| 16–17 | 11 (epics) | step 11's patch procedure: orchestrator writes missing tasks or re-spawns `hb-task-author` for the gap epic; rebuild the coverage matrix from disk |
| 18–19 | 8 (mockups) | check 18: re-spawn that design's `hb-mockup-smith` with only `art_direction_screens` (or orchestrator writes the missing card from the design's design-system.md + direction research); check 19: re-run step 8's headless-Chrome render for the missing PNGs — if no Chrome binary exists anywhere, set manifest `screenshots_skipped: true` and check 19 warns instead of failing |
| 20 | 8.5 (visual QA) | a missing/invalid `visual-qa-<x>.json`, or a screenshot in NEITHER `screens_reviewed` nor `screens_not_viewed`: re-run `Skill(skill: "hyperbuild-8-5-visual-qa")` in its **SCOPED ENTRY** mode (that skill's "Scoped entry" section) with `scope_letters` = the affected direction(s) and `scope_screens` = the unjudged screens — it re-spawns `hb-design-critic` for those screens only and MERGES into the existing JSON, preserving prior rounds, statuses and acceptance_reasons. A non-empty `screens_not_viewed` whose entries all state a reason is a `warn`, not a defect to re-run: re-running produces the same unreadable PNG. NEVER hand-write a visual-QA file: a findings file nobody looked at pixels for is the exact failure this gate exists to catch |
| 21 | 8.5 (visual QA) | criticals still `"status": "open"` means the patch round never ran or never landed: re-run `Skill(skill: "hyperbuild-8-5-visual-qa")` in **SCOPED ENTRY** mode for those directions and screens (patch round → re-render → round-2 verdict, merged into the existing file). If its 2 rounds are already spent, step 8.5 flips them to `accepted-known-issue` with a reason — then this check warns instead of failing and the report + stop message carry them. Relabeling WITHOUT a spent patch round is forbidden |
| 22 | 2/3/3.5, 5, 6, or 9 — whichever area is malformed | A MISSING area, a platform-specific area name, or an empty `verify/` is a research-step failure, not a formatting nit. Wrong area name: `git mv` it to the FIXED name and fix the writing step's skill. Empty or thin `verify/`: re-enter that area's step and run the §5 claim→verify pass — extract the load-bearing H3 claims from its `research/` files and spawn ONE `hb-claim-verifier` PER CLAIM, all in parallel in one message, with the §6 prompt template verbatim. Never satisfy this check by writing verify files yourself from memory: an unchecked claim labelled CONFIRMED is worse than an unverified one |
| 23 | the step that wrote the file | Missing provenance block: re-spawn the agent that produced the file with the §4 requirement stated inside the prompt (it must reproduce its own prompt verbatim at the end of the file). Only when the producing agent cannot be re-spawned may the orchestrator append the exact spawn prompt it sent, from its own notes — never a reconstruction from the file's content |

After fixing, increment R and re-spawn `hb-gate-verifier` fresh (step 12.2 — full 23
checks again, not just the failed ones: a fix can break a neighbor — a re-mocked
screen from check 12 invalidates its visual-QA review, so check 20/21 re-run too). **Max 3 rounds
total** (≤3 both gears). Never mark the gate passed by hand — only a verifier JSON with
`"overall": "pass"` passes it.

### Step 12.5 — On PASS: set the manifest, then make THE ONE PERMITTED STOP

Order matters — the stop message ends the turn, so bookkeeping comes FIRST:

1. Update `runs/<run_tag>/manifest.json`: `steps.12 = "done"`,
   `blocked_on = "design-choice"`. `stage` stays `"PLAN"` —
   `/hyperbuild-choose` flips it to `"BUILD"`; the router and
   `hyperbuild-choose` both key the parked state off `blocked_on`.
   (Read the JSON, modify, Write it back whole.)
2. Set report frontmatter `verdict: pass`. Mark the step-12 todo complete.
3. **Write `research/README.md` — the areas index + THE REUSABILITY GUIDE.** This is
   step 12's only authored artifact, and `docs/RESEARCH-ARCHIVE.md` §8 is its binding
   format. The research the run just paid for is the most portable thing it produced;
   without this file the next checkout re-buys it. Build it FROM DISK, never from
   memory of the run:
   - The areas table — one row per area: link to its `_INDEX.md`, the `run_tag`, the
     agent count (count files under `research/`, `verify/`, `critique/`, `author/`),
     and the reusability verdict.
   - The THREE portability buckets from §8, with EVERY area — and, where an area
     splits, every file — named in exactly one of them: **Portable to ANY app** (store
     policy, privacy labels, licensing, pricing mechanics, skill-authoring craft);
     **Portable to any app on this platform (`<platform>` — from
     `decisions/platform.md`)** (architecture, project structure, the state library's
     API, testing corpus, lints, CI, performance, the platform's design-system status);
     **Specific to THIS app — context only** (domain research, the competitor set,
     audience pain points). A bucket assignment nobody can act on ("mostly reusable")
     is a defect; name files.
   - The mechanics: copy `02-engineering/`, `03-design-system/`, and/or
     `04-claude-skills/` into a new checkout's `research/` BEFORE running
     `/hyperbuild` — the FIXED area names make the copy path-compatible with zero
     edits; record the capture date and RE-VERIFY any specific version, price, or
     policy older than 90 days with the §6 verifier prompt.
   - The honest gaps: every REFUTED and PARTIALLY_TRUE verdict a downstream artifact
     rests on (read the `verify/` frontmatter), every dimension whose claims were
     never fact-checked, every unresolved critic finding, and any known bad premise
     (§6's premise trap). An honest gap beats a clean-looking index.
4. Gather the summary numbers FROM DISK: competitor count
   (`research/01-product-and-market/research/competitors/`),
   top 5 pain points (first 5 of the ranked list in
   `research/01-product-and-market/author/sentiment-synthesis.md`),
   platform + one-line rationale (`runs/<run_tag>/decisions/platform.md`), epic/task
   counts (`epics/00-overview.md` frontmatter), design names (each
   `designs/<x>/design-system.md`), mockable screen count (PRD inventory
   `full`/`partial` rows), whether manifest `screenshots_skipped` is true, and —
   from the three `gates/visual-qa-<x>.json` files — the visual-QA totals
   (screens reviewed, findings fixed) plus EVERY finding with
   `"status": "accepted-known-issue"` or `"unverifiable"` (design letter, screen,
   `what_is_wrong`).
5. Emit the stop message — bare text, user-facing, the LAST thing you output:

```markdown
## Stage A complete — pick a design to start the build

**<app name>** (run `<run_tag>`, gear <gear>) is researched, designed, and planned.

- **Market:** <N> competitors analyzed — full matrix in
  research/01-product-and-market/author/competitor-landscape.md
- **Top 5 user pain points**
  (research/01-product-and-market/author/sentiment-synthesis.md):
  1. <pain point one-liner>
  2. <...>  3. <...>  4. <...>  5. <...>
- **Platform:** <platform> — <one-sentence rationale from decisions/platform.md>
- **Backlog:** <E> epics, <T> tasks — every must/should feature covered (epics/00-overview.md)
- **Designs:** 3 complete systems, all <K> full/partial screens mocked in each:
  - **a — <design name>**: <one-line character>
  - **b — <design name>**: <one-line character>
  - **c — <design name>**: <one-line character>
- **Visual QA:** every rendered screen was reviewed against docs/DESIGN-CRAFT.md — <N> defects found, <M> fixed and re-rendered

**Known visual issues** (found by visual QA, still present after 2 fix rounds — look at these before you choose):
- **<letter> / <Screen>** — <what_is_wrong>

**Compare them side by side** — open the gallery in your browser:

    open runs/<run_tag>/designs/index.html

(macOS: `open` · Linux: `xdg-open` · Windows: `start`)

When you've picked, run `/hyperbuild-choose a|b|c`
(optionally `/hyperbuild-choose <a|b|c> <platform>` to override the platform)

Not ready to pick? Two levers, both of which change things and park the run back here:
- `/hyperbuild-revise <what to change>` — change the idea, a feature, one direction's look, or how the epics are split
- `/hyperbuild-redesign [notes]` — new design directions; say what to KEEP ("keep c, replace a and b") and what to fix
```

Drop the **Known visual issues** block entirely when every visual-QA critical
was fixed (check 21 `pass`) — never print an empty heading. When it IS printed,
one bullet per `accepted-known-issue` / `unverifiable` finding, `what_is_wrong`
quoted verbatim from the JSON: the user is choosing a design and deserves to
know which screens are still broken.

If the passing round's check 19 was `warn`, insert one line above the gallery
instructions: `- **Warning:** mockup screenshots were skipped (no Chrome binary
found) — step 15's fidelity review will lack rendered references.` If check 20
was `warn`, add: `- **Warning:** visual QA could not run without renders — no
screen in these designs has been checked for clipping, overlap, or craft.`

The message MUST end with the `/hyperbuild-choose a|b|c` line plus the two
change-of-mind lines that follow it (`/hyperbuild-revise`, `/hyperbuild-redesign`) —
`/hyperbuild-choose` is the only lever that RESUMES the pipeline, and the other two are
the only way a user who dislikes what they see learns that changing it is supported
instead of starting over. Nothing else may follow that block. Then END THE TURN.

When `/hyperbuild-revise` or `/hyperbuild-redesign` is what drove this gate run, that
skill injects its own summary lines directly ABOVE the `/hyperbuild-choose` line; the
three command lines stay in the same order regardless.

### Step 12.6 — After 3 failed rounds: BLOCKED, honestly

1. Update `runs/<run_tag>/manifest.json`: `steps.12 = "blocked"`,
   `blocked_on = "design-gate"`. Leave `stage` unchanged.
2. Set report frontmatter `verdict: blocked`; the final round section lists every
   still-failing check with its evidence and what was attempted each round.
3. Emit an honest final message: which checks still fail, verbatim evidence, what was
   tried, and what a human can do (fix the named artifacts, then re-run `/hyperbuild` —
   the router resumes at step 12). **Never soften a failing gate into a pass.** A
   blocked run that says so is a working pipeline; a passed gate over missing artifacts
   is a broken one.

---

## Artifacts

- `runs/<run_tag>/temp/design-gate-checks-round-<R>.json` — one per round (verifier-written, canonical schema above)
- `runs/<run_tag>/gates/design-gate-report.md` — frontmatter: run_tag, gate, verdict, rounds, created; per-round check tables
- `runs/<run_tag>/manifest.json` — updated: pass → `steps.12="done"`, `blocked_on="design-choice"` (stage stays `"PLAN"`); blocked → `steps.12="blocked"`, `blocked_on="design-gate"`
- `research/README.md` — REWRITTEN on pass (12.5 step 3): the areas index + the REUSABILITY GUIDE, per `docs/RESEARCH-ARCHIVE.md` §8. This step's only authored artifact.

## Exit criteria

- Final round's `design-gate-checks-round-<R>.json` exists with an `overall` verdict
- `runs/<run_tag>/gates/design-gate-report.md` exists; frontmatter verdict is `pass` or `blocked` (never silently absent)
- PASS: manifest shows `steps.12="done"` + `blocked_on="design-choice"` (stage still `"PLAN"`); step-12 todo complete; stop message emitted, ending with the `/hyperbuild-choose a|b|c` line followed by the two change-of-mind lines (`/hyperbuild-revise <what to change>`, `/hyperbuild-redesign [notes]`) and nothing else
- PASS with a check-21 `warn`: every `accepted-known-issue` critical appears BOTH as a row in the report's `### Known visual issues` table and as a bullet in the stop message — a passing gate never hides a broken screen from the person choosing the design
- PASS: `research/README.md` exists, links all four `_INDEX.md` files, and classifies every area (and every split file) into exactly one of the three portability buckets by name, with the capture date and the honest-gaps section filled in — the run's research is worthless to the next checkout without it
- BLOCKED: manifest shows `steps.12="blocked"` + `blocked_on="design-gate"`; honest failure message emitted

## Next step

There is none — **do NOT invoke any Skill()**. Stage A ends here. The pipeline resumes
when the user runs `/hyperbuild-choose <a|b|c>`, which records
`runs/<run_tag>/decisions/design-choice.md`, copies the chosen tokens to `app/design/`,
sets manifest `stage=BUILD`, and re-invokes the router to drive Stage B (steps 13–16).

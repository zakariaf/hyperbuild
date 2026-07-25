---
name: hyperbuild-1-intake
description: >
  Step 1 of the hyperbuild pipeline — persists the verbatim app idea as
  gospel (runs/<run_tag>/idea.md), mints the run_tag (slug + random 6-hex
  suffix), resolves the target platform (stated > inferred, with category
  defaults) into decisions/platform.md, detects the scale gear
  (standard | premier), initializes manifest.json and scaffold.md, and
  seeds TodoWrite with every pipeline step. Spawns no subagents. Every
  later step and every subagent re-reads what this step writes. Invoked
  by the hyperbuild router via Skill(); not run directly by users.
---

# Step 1 — Intake

You are executing step 1 (intake) of the hyperbuild pipeline. Nothing has run before you — the user just typed `/hyperbuild <idea>` and the router invoked this skill; step 2 (market recon) consumes the artifacts you write here, and EVERY subsequent step and subagent re-reads `idea.md` as gospel.

**Gear gate:** runs for both gears — this step DETECTS the gear.

**Goal:** turn one prompt into a durable run workspace: gospel idea file, run_tag, platform decision, gear, manifest, scaffold, and a seeded todo list — so that a crash at any later point resumes from disk, never from memory.

**Verify-then-create:** the router's bootstrap may have already produced some of these artifacts before invoking you. For EACH artifact below: if it already exists and is valid, verify it and move on; create it only if missing. NEVER re-mint a run_tag when `runs/` already contains a workspace for this idea with an incomplete manifest — resume that workspace instead.

---

## Inputs

- The user's idea prompt — everything after the `/hyperbuild ` command token, byte-for-byte. This is the ONLY input that exists yet.
- (If the router already bootstrapped) `runs/<run_tag>/idea.md`, `runs/<run_tag>/manifest.json`, `runs/<run_tag>/scaffold.md` — verify rather than recreate.

---

## Procedure

1. **Capture the verbatim idea FIRST.** The canonical idea is everything the user typed after `/hyperbuild `, unmodified: keep their wording, their typos, their ordering, the word "premier" if present. **IDEA IS GOSPEL — NEVER PARAPHRASE, NEVER "CLEAN UP".** Every downstream judgment (competitor relevance, PRD scope, design direction, task acceptance) is measured against this exact text. A paraphrase here silently redirects the entire pipeline.

2. **Mint the run_tag.** Distill a slug — 2–4 lowercase hyphenated words that name the app idea (e.g. `habit-coach`, `invoice-scanner`, `team-standup-bot`). Then append a random 6-hex-char suffix with a bash one-liner:

   ```bash
   echo "habit-coach-$(openssl rand -hex 3)"
   ```

   (Fallback if openssl is unavailable: `echo "habit-coach-$(xxd -l3 -p /dev/urandom)"`.) Result shape: `habit-coach-3f9a2c`. The suffix exists so two runs of similar ideas never collide. Use this run_tag EVERYWHERE — directory name, manifest, every research artifact's frontmatter.

3. **Create the workspace:**

   ```bash
   mkdir -p runs/<run_tag>/temp runs/<run_tag>/decisions runs/<run_tag>/designs runs/<run_tag>/gates
   ```

4. **Detect the gear.** `gear = "premier"` iff the word "premier" (case-insensitive) appears in the idea prompt as a scale request; otherwise `gear = "standard"`. Default is standard. **Judgment carve-out:** if "premier" is clearly domain content, not a gear request (e.g. "an app for Premier League fixtures"), record `standard` and note the judgment call in scaffold.md. The word stays in idea.md verbatim either way — detection never edits the gospel.

5. **Resolve the platform.** Two rules, in strict order:

   **Rule 1 — STATED WINS.** If the idea names a platform, language, or framework anywhere ("iOS app", "in Flutter", "a web dashboard", "CLI tool", "Chrome extension"), that statement is the decision. Quote it as evidence.

   **Rule 2 — otherwise INFER from app category**, using these defaults:

   | App category | Signal words / patterns | Default platform (slug) |
   |---|---|---|
   | Consumer mobile (personal, on-the-go) | habit, fitness, journal, tracker, photo, recipe, "an app that…" with personal daily use | Flutter, Dart — cross-platform iOS + Android (`flutter`) |
   | Apple-ecosystem-dependent | HealthKit, Apple Watch, iMessage, widgets-first, "iPhone only" | Swift + SwiftUI, native iOS (`ios-swiftui`) |
   | SaaS / dashboard / B2B / team tool | dashboard, admin, team, workspace, analytics, "web app", browser-based, collaboration | Next.js + React + TypeScript web app (`web-nextjs`) |
   | Developer tool / CLI | CLI, terminal, "command line", devtool, linter, codegen | Node.js + TypeScript CLI (`cli-node`) |
   | Desktop utility | menu bar, tray, offline desktop, "runs on my Mac/PC" | Tauri v2, TypeScript UI (`desktop-tauri`) |
   | Browser extension | extension, "in the browser on any site", overlay, clipper | WebExtension Manifest V3, TypeScript (`extension-webext`) |
   | Simple game | game, puzzle, arcade, casual | Flutter + Flame if mobile-shaped, else TypeScript + canvas web (`flutter` / `web-nextjs`) |

   When a category is genuinely ambiguous between mobile and web, default mobile-first consumer ideas to `flutter` and tool/SaaS ideas to `web-nextjs`. Record WHICH rule fired and why — step 5 (stack research) targets this decision, and `/hyperbuild-choose` can override it later, so the rationale must be reconstructable.

6. **Write `runs/<run_tag>/idea.md`** — frontmatter + the verbatim idea as the entire body:

   ```markdown
   ---
   run_tag: habit-coach-3f9a2c
   created: 2026-07-24
   platform: flutter
   ---

   <the user's idea text, byte-for-byte verbatim — nothing added, nothing removed>
   ```

7. **Write `runs/<run_tag>/decisions/platform.md`:**

   ```markdown
   ---
   run_tag: habit-coach-3f9a2c
   created: 2026-07-24
   ---

   # Platform decision

   ## Decision
   Flutter (Dart) — cross-platform iOS + Android. Platform slug: `flutter`.

   ## How it was resolved
   inferred  <!-- stated | inferred -->

   ## Evidence
   The idea says "an app that coaches me through daily habits" — personal,
   daily, on-the-go consumer use with no platform named. Category default:
   consumer mobile → Flutter.

   ## Alternatives considered
   - ios-swiftui: rejected — no Apple-only feature named; cross-platform reach wins.
   - web-nextjs: rejected — habit nudges are a pocket-device job, not a browser-tab job.

   ## Consequences
   - Step 5 (stack research) targets Flutter architecture, state management, testing.
   - Step 13 scaffolds with `flutter create`; tokens.css becomes theme.dart.
   - `/hyperbuild-choose <a|b|c> <platform>` can override; steps 5, 10, 11 then re-run.
   ```

8. **Initialize `runs/<run_tag>/manifest.json`** — the run's single source of truth for resume:

   ```json
   {
     "run_tag": "habit-coach-3f9a2c",
     "created": "2026-07-24",
     "gear": "standard",
     "stage": "PLAN",
     "platform": "flutter",
     "steps": { "1": "running" },
     "design_choice": null,
     "blocked_on": null
   }
   ```

   Step keys are added as steps run: a step sets `steps.N = "running"` on entry and `"done"` on exit; a missing key means not started. The router resumes at the first step that isn't `"done"`. `stage` is `PLAN` now; `/hyperbuild-choose` flips it to `BUILD`.

9. **Write `runs/<run_tag>/scaffold.md`** — YOUR private planning doc. It never ships and no downstream deliverable may cite it:

   ```markdown
   # Scaffold — habit-coach-3f9a2c

   PRIVATE orchestrator planning doc. Never ships.

   ## Run config
   - run_tag: habit-coach-3f9a2c
   - gear: standard
   - platform: flutter
   - created: 2026-07-24

   ## Idea digest (planning aid only — idea.md stays gospel)
   <2–4 sentences: what the app is, for whom, the core loop>

   ## Gear rationale
   <1–2 sentences: why standard/premier, incl. any "premier"-as-domain-content judgment>

   ## Platform rationale (summary — full version in decisions/platform.md)
   <1–2 sentences>

   ## Anticipated shape (guesses — step 4's PRD decides)
   - Likely audience: ...
   - 3–6 likely screens: ...
   - Competitor guesses to hand step 2's scout: ...

   ## Open questions / risks
   - ...
   ```

10. **Seed TodoWrite** — one todo per pipeline step (1 through 16, including the half-steps 3.5, 4.5 and 8.5) plus the checkpoint todo; 20 todos total, in order:

    1. Step 1 — intake (mark in_progress NOW)
    2. Step 2 — market recon
    3. Step 3 — social mining
    4. Step 3.5 — research audit
    5. Step 4 — product spec (PRD)
    6. Step 4.5 — feature specs
    7. Step 5 — stack research
    8. Step 6 — design research
    9. Step 7 — design systems
    10. Step 8 — mockups
    11. Step 8.5 — visual QA
    12. Step 9 — skill research
    13. Step 10 — skill forge
    14. Step 11 — epics & tasks
    15. Step 12 — design gate (STOP: wait for /hyperbuild-choose)
    16. Checkpoint — /hyperbuild-choose records the design choice (completed by the hyperbuild-choose skill, never by a step)
    17. Step 13 — scaffold app
    18. Step 14 — implement epics
    19. Step 15 — adversarial review
    20. Step 16 — ship gate

    If the router already seeded these, verify the list matches and move on. TodoWrite is the SECOND resume mechanism (manifest is first) — keep both true at every transition.

---

## Artifacts

| Path | Format |
|---|---|
| `runs/<run_tag>/idea.md` | frontmatter `run_tag`, `created`, `platform`; body = verbatim idea |
| `runs/<run_tag>/decisions/platform.md` | frontmatter `run_tag`, `created`; sections Decision / How it was resolved / Evidence / Alternatives considered / Consequences |
| `runs/<run_tag>/manifest.json` | exact shape in step 8 above — canonical; downstream tooling assumes it |
| `runs/<run_tag>/scaffold.md` | private planning skeleton in step 9 above |

---

## Exit criteria

- `runs/<run_tag>/idea.md` exists; its body is byte-for-byte the user's idea; frontmatter has `run_tag`, `created`, `platform`
- run_tag matches `^[a-z0-9-]+-[0-9a-f]{6}$`
- `runs/<run_tag>/decisions/platform.md` exists, names ONE platform slug, and states whether it was stated or inferred, with evidence
- `runs/<run_tag>/manifest.json` is valid JSON with `run_tag`, `created`, `gear` (`standard` | `premier`), `stage: "PLAN"`, `platform`, `steps`, `design_choice: null`, `blocked_on: null`
- `runs/<run_tag>/scaffold.md` exists with all five sections filled (no empty headings)
- TodoWrite holds one todo per pipeline step (including the half-steps 3.5, 4.5 and 8.5) plus the checkpoint todo (20 total), in order

Then update the manifest: `steps.1 = "done"`, mark the step-1 todo complete, return to the router.

---

## Next step

Return to the router (`hyperbuild`). It invokes:

```
Skill(skill: "hyperbuild-2-market-recon")
```

---
name: appbuilder-13-scaffold
description: >
  Step 13 of the appbuilder pipeline — the first step of Stage B (BUILD).
  Initializes the real project in app/ per the committed decisions in
  research/stack-guide.md and runs/<run_tag>/decisions/platform.md, git-inits
  app/ with a platform .gitignore (step 14's per-epic reviews need diffs),
  spawns ONE ab-implementer to wire lint + formatter + test harness + CI and
  translate the CHOSEN design's tokens.css into the target framework's theme
  file(s), updates the generated app-components skill with concrete theme file
  references, and verifies the empty app builds and its smoke test passes
  before making the repo's initial commit and exiting. Invoked by the
  appbuilder router via Skill(); not run directly by users.
---

# Step 13 — Scaffold (Stage B begins)

You are executing step 13 (scaffold) of the appbuilder pipeline. `/appbuilder-choose`
recorded the design choice and copied the chosen tokens to `app/design/`; step 14 (the
wave loop) will implement every feature on top of what you scaffold here.

**Stage gate:** Stage B ONLY. Requires manifest `stage: "BUILD"` and `design_choice` set.
If either is missing, this run is still waiting at the design gate — STOP, return to the
router, do not scaffold anything.

**Goal:** an empty but REAL app in `app/` — buildable, lint-clean, themed with the chosen
design's tokens, with a green smoke test — plus recorded toolchain commands so steps
14–16 never have to guess how to build, test, or lint.

## Inputs

Recover `run_tag` from disk (the `runs/*/manifest.json` whose `stage` is `"BUILD"`), never
from memory. Then read:

- `runs/<run_tag>/manifest.json` — `stage` (must be `BUILD`), `design_choice`, `platform`, `gear`
- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL.
- `runs/<run_tag>/decisions/platform.md` — chosen stack + rationale
- `research/stack-guide.md` — committed "we will do X" decisions: scaffolder, lint tool,
  formatter, test framework, CI shape, project structure. BINDING for this whole step.
- `app/design/tokens.css` + `app/design/design-system.md` — the CHOSEN design (copied by
  `/appbuilder-choose`). If missing, the checkpoint didn't finish — stop and report.
- `.claude/skills/app-components/SKILL.md` — generated in step 10; gets concrete theme
  references in step 13.7
- `runs/<run_tag>/scaffold.md` — planning doc; gets a `## Toolchain` section here

## Procedure

### 13.1 Toolchain preflight

Verify the platform SDK is actually installed before creating anything:

| Platform (per platform.md) | Check |
|---|---|
| Flutter | `flutter --version` |
| iOS native (Swift/SwiftUI) | `xcodebuild -version` (+ `xcodegen version` if stack-guide chose XcodeGen) |
| Web (React/Vue/Svelte/Next) | `node --version && npm --version` |
| React Native (Expo) | `node --version && npx expo --version` |
| CLI (`cli-node`) | `node --version && npm --version` |
| Desktop (`desktop-tauri`) | `node --version && npm --version && cargo --version` |
| Browser extension (`extension-webext`) | `node --version && npm --version` |

If a required tool is missing: set manifest `blocked_on: "toolchain: <what is missing>"`,
tell the user honestly what to install, and stop. This is a blocked run, not a checkpoint —
the design gate remains the ONE permitted stop, but a run may block when reality blocks it.

### 13.2 Run the scaffolder (orchestrator, Bash)

STACK-GUIDE.MD IS THE DECIDER. Use the exact scaffold command its decisions commit to.
Only when stack-guide names the stack but not the command, fall back to:

| Stack | Fallback scaffold command |
|---|---|
| Flutter | `flutter create --project-name <snake_name> <snake_name>` |
| iOS native | write `project.yml` per stack-guide's structure, then `xcodegen generate` |
| React (web) | `npm create vite@latest <name> -- --template react-ts` |
| Next.js | `npx create-next-app@latest <name> --typescript --eslint --app --yes` |
| React Native | `npx create-expo-app@latest <name> --template blank-typescript` |
| CLI (`cli-node`) | `mkdir <name> && cd <name> && npm init -y && npm i -D typescript @types/node && npx tsc --init` |
| Desktop (`desktop-tauri`) | `npm create tauri-app@latest <name> -- --template vanilla-ts --yes` |
| Browser extension (`extension-webext`) | `npm create vite@latest <name> -- --template vanilla-ts`, then add a Manifest V3 `manifest.json` per stack-guide |

Derive `<name>` from the run_tag slug minus its hex suffix (`habit-coach-3f9a2c` →
`habit-coach`, snake_case where the platform requires it).

`app/` is NOT empty (`app/design/` already exists) and many scaffolders refuse non-empty
targets. Stage-then-move, always:

```bash
mkdir -p runs/<run_tag>/temp/scaffold-stage
cd runs/<run_tag>/temp/scaffold-stage && <scaffold command>
```

Then move the generated project's contents INTO `app/` (e.g.
`rsync -a runs/<run_tag>/temp/scaffold-stage/<name>/ app/`), delete the stage dir, and
confirm `app/design/tokens.css` survived untouched. Never overwrite `app/design/`.

### 13.3 Git-init app/ + platform .gitignore

```bash
git -C app rev-parse --git-dir 2>/dev/null || git -C app init -b main
```

Skip the init when `app/` is already a repo (a resumed run). This is load-bearing, not
hygiene: step 14 runs ab-code-critic on each EPIC'S DIFF, and step 14's crash recovery
resets to the last commit. No repo in `app/` = no diffs = no per-epic review. `app/` gets
its OWN repo regardless of whether the harness checkout is one.

The scaffolder usually generates a `.gitignore` — keep it, but VERIFY it covers the
platform's build artifacts (Flutter: `build/`, `.dart_tool/`; node stacks:
`node_modules/`, `dist/`; iOS: `DerivedData/`, `xcuserdata/`; Tauri: `src-tauri/target/`).
Write a platform-appropriate one if absent; append the missing patterns if incomplete.

Do NOT commit yet. The INITIAL COMMIT lands in 13.8, only after the verification gate
(13.5) proves the empty app builds and its smoke test passes — the repo's very first
commit is already a green one.

### 13.4 Spawn ONE ab-implementer — tooling + theme

Theme translation targets by stack (pass the right one as `theme_output`):

| Stack | Theme file(s) |
|---|---|
| Flutter | `app/lib/theme/tokens.dart` + `app/lib/theme/theme.dart` (ThemeData light + dark) |
| iOS native | `app/<AppName>/Theme/Tokens.swift` + `app/<AppName>/Theme/Theme.swift` |
| React / Next.js | `app/src/theme/tokens.css` (wired) + `app/src/theme/theme.ts` |
| React Native | `app/src/theme/tokens.ts` (light + dark token objects) |
| CLI (`cli-node`) | `app/src/theme/tokens.ts` (the applicable subset: colors mapped to terminal-safe ANSI/hex, spacing as layout constants) |
| Desktop (`desktop-tauri`) | `app/src/theme/tokens.css` (wired) + `app/src/theme/theme.ts` |
| Browser extension (`extension-webext`) | `app/src/theme/tokens.css` (wired into popup/options/content styles) |

If the resolved platform matches none of these rows, the stack-guide's tooling
decisions MUST supply the preflight check, scaffold command, and theme target — if it
doesn't, treat it like a missing SDK: `blocked_on: "toolchain: <gap>"`, report, stop.

**Spawn template:**
```
subagent_type: ab-implementer
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 13 (scaffold) of the appbuilder pipeline.
  The orchestrator just ran the platform scaffolder into app/ and git-inited
  it (the initial commit lands only after your work verifies green). Step 14
  (the wave loop) implements every feature on top of
  what you wire here — every future ab-implementer inherits your lint config,
  test harness, and theme files. You do NOT implement features; the empty app
  shell with tooling and theme is the entire deliverable.

  YOUR INPUTS:
  - app_root: app/ (freshly scaffolded <stack> project)
  - tokens: app/design/tokens.css — the CHOSEN design's tokens, light AND dark
  - design_system: app/design/design-system.md
  - stack_guide: research/stack-guide.md — its decisions are BINDING: lint tool,
    formatter, test framework, CI shape, project structure
  - theme_output: <theme file path(s) from the table for this stack>
  - ci_output: <e.g. app/.github/workflows/ci.yml>

  CONTEXT FILES — READ FIRST, in order:
  1. runs/<run_tag>/idea.md
  2. runs/<run_tag>/decisions/platform.md
  3. research/stack-guide.md
  4. app/design/design-system.md
  5. app/design/tokens.css
  6. .claude/skills/app-code-style/SKILL.md
  7. .claude/skills/app-architecture/SKILL.md
  8. .claude/skills/app-testing/SKILL.md

  YOUR JOB (all four, in order):
  1. TOOLING — wire the stack-guide's chosen linter + formatter with config
     files; wire the chosen test framework so the test command runs; write CI
     config at ci_output that runs lint + tests + build.
  2. THEME — translate EVERY custom property in tokens.css into theme_output,
     light and dark palettes both. Keep the original token name in a comment
     next to each constant (e.g. `// --color-surface`) so mockup CSS maps 1:1
     to theme constants. Wire the theme into the app entry point.
  3. STRUCTURE — create the top-level source folders stack-guide.md's structure
     decision names (empty is fine; add a placeholder module only where the
     framework requires one to compile).
  4. SMOKE TEST — ensure at least one test exists that boots the empty app
     shell and asserts it renders (keep the scaffolder's default test if it
     does this; otherwise write one). Run the full test suite AND the build;
     both must pass before you return.

  Do NOT implement any PRD feature or screen. Do NOT touch files outside app/.
  Do NOT invent tooling the stack-guide didn't choose. Do NOT commit — the
  orchestrator commits after independent verification.

  REPORT BACK (data, not prose): theme file path(s); tokens translated (count —
  must equal the custom-property count in tokens.css); exact build / test /
  lint / format commands you verified, plus the run/launch command and — if the
  test framework emits golden/screenshot images — their output directory; CI
  config path; passing test count.
```

**CRITICAL: never emit bare text while the implementer is in flight** — a text-only
response ends the turn and kills the pipeline. Append thoughts (what you'll verify, epic
order you expect for step 14) to `runs/<run_tag>/temp/orchestrator-notes.md` instead.

### 13.5 Verification gate (orchestrator, Bash — do not take the implementer's word)

Run yourself, from the report-back's exact commands:
1. **Build** — exits 0.
2. **Test** — full suite green, ≥1 smoke test present.
3. **Lint** — clean.
4. **Theme spot-check** — pick 5 custom properties from `app/design/tokens.css` by name;
   `grep` each in the theme file(s). All 5 must appear.

Any failure: re-spawn ab-implementer with the same template plus a `FAILURE LOG:` block
containing the full command output. Max 3 fix rounds (the same ≤3 cap the gates use).
Still failing → manifest `blocked_on: "scaffold-verification"`, honest report, stop.

### 13.6 Record the toolchain

Append to `runs/<run_tag>/scaffold.md` (steps 14, 15, and 16 read these verbatim —
never re-derive build commands downstream):

```markdown
## Toolchain (written by step 13)
- build: <command>
- test: <command>
- lint: <command>
- format: <command>
- run: <command that launches the app locally — dev server / simulator / emulator / binary; `none` only when the platform has no launchable form>
- screenshot_tests: <directory where golden/screenshot-test images land, when the stack's test framework emits them; `none` otherwise>
- app_git_root: app/
- theme_files: <path(s)>
```

`run` and `screenshot_tests` are what step 15's ab-ux-critic derives its capture
method from — record them even when the honest value is `none`.

Also write `app/README.md`: five lines — what the app is (one sentence from idea.md),
then the run / build / test commands.

### 13.7 Update the generated app-components skill

Edit `.claude/skills/app-components/SKILL.md` (surgical Edit, not a rewrite): replace
the BODY of its `## Design tokens (wired by step 13)` section — step 10 guarantees that
exact H2; keep the heading verbatim. (If the heading is somehow missing, append the
section with that exact H2.) The new body must name: the concrete theme file
path(s); how token names map to theme constants (one worked example, e.g.
`--color-surface` → `AppTokens.colorSurface`); and one code snippet importing and using
the theme the way step 14 implementers should. Every step 14 ab-implementer reads this
skill — vague theme references here become hard-coded colors there.

### 13.8 Initial commit + bookkeeping

The build is verified, the suite is green, the smoke test passes — NOW make the repo's
initial commit:

```bash
git -C app add -A && git -C app commit -m "scaffold: <platform> project + theme + toolchain"
```

From this first commit onward the invariant holds: EVERY COMMIT IN app/ IS MADE ON A
GREEN SUITE. Step 14's crash recovery depends on it, and step 16's git check expects
this scaffold commit at the root of the history.

## Artifacts

- `app/` — scaffolded, buildable project in the platform's canonical layout; its own git
  repo with a platform-appropriate `.gitignore` (covers build artifacts) and the initial
  commit `scaffold: <platform> project + theme + toolchain`, HEAD green
- Theme file(s) per the 13.4 table — every tokens.css custom property, light + dark
- Lint, formatter, test-harness, and CI config files per stack-guide.md
- `app/README.md` — run/build/test quickstart
- `runs/<run_tag>/scaffold.md` — `## Toolchain` section appended
- `.claude/skills/app-components/SKILL.md` — updated with concrete theme references

## Exit criteria

- Build command exits 0 — verified mechanically THIS step, not assumed
- Full test suite green with ≥1 smoke test; lint clean
- Theme file(s) exist; 5-token spot-check passed; theme wired into the app entry point
- CI config exists at the recorded path
- `.claude/skills/app-components/SKILL.md` names the concrete theme file(s)
- `runs/<run_tag>/scaffold.md` has the `## Toolchain` section
- `app/` is a git repo; its `.gitignore` covers the platform's build artifacts; the
  initial commit `scaffold: <platform> project + theme + toolchain` exists and was made
  AFTER the build + smoke test verified green

Then update manifest: `steps."13" = "done"`, mark the step-13 todo complete, return to
the router.

## Next step

Return to the router (`appbuilder`). Invoke step 14:

```
Skill(skill: "appbuilder-14-implement")
```

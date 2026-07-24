---
name: appbuilder-choose
description: >
  Human checkpoint of the appbuilder pipeline — the user's ONE decision.
  Invoked directly by the user as /appbuilder-choose <a|b|c> [platform] after
  the Stage-A design gate (step 12) parks the run with
  blocked_on: "design-choice". Validates the run is actually at the gate,
  writes decisions/design-choice.md, copies the chosen design's tokens.css and
  design-system.md to app/design/, flips the manifest to stage: "BUILD"
  (an optional second argument overrides the platform, which marks steps 5, 10,
  and 11 for re-run), then invokes Skill(skill: "appbuilder") so the router's
  resume logic drives Stage B. This skill does NO build work.
---

# /appbuilder-choose — record the design choice, release Stage B

You are executing the human checkpoint of the appbuilder pipeline. Step 12
(design gate) stopped the run and asked the user to pick one of three designs;
the user has now answered. Your only job: validate, record, copy, flip the
manifest, and hand control back to the router. **THIS SKILL DOES NO BUILD
WORK.** Step 13 scaffolds; step 14 implements. If you find yourself about to
create project files, run a scaffolder, or write code, STOP — record the
decision and invoke the router.

## Arguments

- **arg 1 (required):** the design choice — `a`, `b`, or `c`. Case-insensitive;
  normalize to lowercase.
- **arg 2 (optional):** a platform override (e.g. `flutter`, `swiftui`,
  `react-native`, `nextjs`). Only honor it if it differs from the manifest's
  `platform`.

If arg 1 is missing or is not `a`/`b`/`c`: read the title of each
`runs/<run_tag>/designs/{a,b,c}/design-system.md`, show the user the three
letters with their design names, and stop. Record nothing. (Exception: if the
argument uniquely matches one design's NAME, accept it, note the mapping in
the decision file, and proceed with the corresponding letter.)

## Inputs

- `runs/*/manifest.json` — run_tag, stage, platform, steps, design_choice, blocked_on
- `runs/<run_tag>/designs/<choice>/design-system.md` — the chosen system (its title is the design name)
- `runs/<run_tag>/designs/<choice>/tokens.css` — the chosen tokens
- `runs/<run_tag>/designs/<choice>/mockups/` — must be non-empty (gate verified it; trust but confirm)
- `runs/<run_tag>/gates/design-gate-report.md` — proof the gate passed
- `runs/<run_tag>/decisions/platform.md` — appended to on platform override

## Procedure

1. **Locate the run.** Glob `runs/*/manifest.json`. Prefer the manifest with
   `blocked_on: "design-choice"`; if several match, take the newest by
   `created`. Failure paths — each one STOPS with the stated message and
   records nothing:
   - No manifest at all → "No appbuilder run found. Start one with
     `/appbuilder <your app idea>`."
   - `stage: "PLAN"` but `steps["12"]` is not `"done"` → "The run
     `<run_tag>` hasn't reached the design gate yet. Resume it with
     `/appbuilder` — I'll stop and ask for your choice when the three designs
     are ready."
   - `design_choice` already set (stage `"BUILD"` or `"DONE"`) → "Design
     `<design_choice>` was already chosen for `<run_tag>` and the build is
     underway/done. Changing designs after the build starts isn't supported
     by this checkpoint — that's manual surgery."
2. **Validate the gate state on disk.** All of these must exist and be
   non-empty; if any is missing, the gate report lied — STOP, name the exact
   missing path, and tell the user to re-run `/appbuilder` (the router will
   re-enter step 12):
   - `runs/<run_tag>/gates/design-gate-report.md`
   - `runs/<run_tag>/designs/<choice>/design-system.md`
   - `runs/<run_tag>/designs/<choice>/tokens.css`
   - at least one `runs/<run_tag>/designs/<choice>/mockups/*.html`
3. **Copy the chosen design into the app.**
   ```bash
   mkdir -p app/design
   cp runs/<run_tag>/designs/<choice>/tokens.css app/design/tokens.css
   cp runs/<run_tag>/designs/<choice>/design-system.md app/design/design-system.md
   ```
   `app/design/` is the build-time source of truth: step 13 scaffolds the
   project around it and translates `tokens.css` into the target framework's
   theme (e.g. `theme.dart` / `Theme.swift`). Do NOT copy the mockups — step
   14's implementers read them in place from
   `runs/<run_tag>/designs/<choice>/mockups/`.
4. **Write the decision record** to `runs/<run_tag>/decisions/design-choice.md`.
   Take `design_name` from the H1/title of the chosen `design-system.md`.
   Canonical format:
   ```markdown
   ---
   run_tag: habit-coach-3f9a2c
   choice: b
   design_name: Swiss Utility
   chosen_at: 2026-07-24T18:12:00Z
   platform_override: null
   ---

   ## Decision

   The user chose design **b** ("Swiss Utility") via `/appbuilder-choose b`.

   ## Copied artifacts

   - runs/habit-coach-3f9a2c/designs/b/tokens.css → app/design/tokens.css
   - runs/habit-coach-3f9a2c/designs/b/design-system.md → app/design/design-system.md

   ## Rejected

   - a — "Soft Focus"
   - c — "Neon Playful"
   ```
   With a platform override, `platform_override` carries the new platform
   string and the body gains a `## Platform override` section: old platform →
   new platform, plus the re-run consequence (next step).
5. **Apply the platform override (only if arg 2 differs from
   `manifest.platform`).**
   - Append a `## Overridden at checkpoint` section to
     `runs/<run_tag>/decisions/platform.md`: the old platform, the new one,
     "user override via /appbuilder-choose", timestamp.
   - In the manifest: set `platform` to the new value and set
     `steps["5"] = steps["10"] = steps["11"] = "redo"`.
   - Tell the user honestly, in the same confirmation line as step 7: stack
     research (5), the generated project skills (10), and the epic/task
     backlog (11) will be regenerated for the new platform BEFORE building;
     the three designs and all mockups carry over unchanged. The router runs
     5 → 10 → 11 first, then 13 → 16.
6. **Flip the manifest.** Edit `runs/<run_tag>/manifest.json` (adapt the
   commented lines only when an override applies):
   ```bash
   python3 - <<'PY'
   import json
   p = "runs/<run_tag>/manifest.json"
   m = json.load(open(p))
   m["design_choice"] = "<choice>"
   m["stage"] = "BUILD"
   m["blocked_on"] = None
   # Platform override only:
   # m["platform"] = "<new platform>"
   # for s in ("5", "10", "11"): m["steps"][s] = "redo"
   json.dump(m, open(p, "w"), indent=2)
   PY
   ```
7. **Mark the checkpoint todo complete** and state ONE confirmation line as
   you proceed (not a stopping message — Stage B starts now), e.g.: "Design b
   ('Swiss Utility') locked. Building now — Stage B is autonomous through the
   ship gate."

## Artifacts

- `runs/<run_tag>/decisions/design-choice.md` — frontmatter: run_tag, choice,
  design_name, chosen_at, platform_override; body: Decision, Copied artifacts,
  Rejected (+ Platform override when applicable)
- `app/design/tokens.css`, `app/design/design-system.md` — byte-identical
  copies of the chosen design's files
- Updated `runs/<run_tag>/manifest.json` — `design_choice` set,
  `stage: "BUILD"`, `blocked_on: null` (+ `platform` and the three `"redo"`
  step keys on override)
- Updated `runs/<run_tag>/decisions/platform.md` (override only)

## Exit criteria

- `runs/<run_tag>/decisions/design-choice.md` exists with valid frontmatter
  and the copied-artifact paths listed
- `app/design/tokens.css` and `app/design/design-system.md` exist and match
  their sources
- Manifest reads `design_choice: "<choice>"`, `stage: "BUILD"`,
  `blocked_on: null`; on override, `platform` is updated and steps
  `"5"`/`"10"`/`"11"` read `"redo"`
- The checkpoint todo is marked complete

Then update nothing else and return control to the router.

## Next step

Invoke the router — its resume logic reads the manifest, sees
`stage: "BUILD"` with `design_choice` set, and drives Stage B (steps
13 → 14 → 15 → 16, prefixed by 5 → 10 → 11 when marked `"redo"`):

```
Skill(skill: "appbuilder")
```

**NEVER invoke `appbuilder-13-scaffold` (or any step skill) directly from
here.** The router owns sequencing and recovery; bypassing it forfeits both.

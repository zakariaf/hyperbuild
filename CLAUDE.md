# CLAUDE.md — hyperbuild harness

This repo IS the hyperbuild harness: a Claude Code pipeline that turns one app idea
into a researched, designed, planned, and implemented application. It is not an app
codebase — the app the pipeline builds lands in `app/`.

## Entry points

- `/hyperbuild <app idea>` — runs Stage A (PLAN, steps 1–12 incl. half-steps 3.5, 4.5 and
  8.5), then stops at the design gate.
- `/hyperbuild-choose <a|b|c>` — the ONE human checkpoint. Records the design choice and
  drives Stage B (BUILD, steps 13–16) to a working app.
- `/hyperbuild-revise <plain-English change>` — at the design gate only: classifies the
  request into one of four scopes (idea | feature | design | epics) and re-runs only what
  depends on it — e.g. design scope is 7 → 8 → 8.5 → 12 for one letter — then re-parks at
  the gate. The verbatim idea body stays immutable; an idea-scope revision APPENDS a dated
  `## Revisions` entry below it.
- `/hyperbuild-redesign [notes]` — at the design gate only: regenerates the design
  directions from free-form notes — every slot by default, or only the letters not named
  in a KEEP instruction ("keep c, replace a and b"). Replaced slots are archived under
  `designs/archive/round-<N>/`; 6 → 7 → 8 → 8.5 → 12 re-run for the new letters, then it
  re-parks at the gate.

## Resume rule

When asked to continue/resume a run (or a session starts mid-run): read
`runs/*/manifest.json` FIRST, then invoke `Skill(skill: "hyperbuild")` — the router owns
all recovery (manifest → TodoWrite → artifact scan). Never re-run finished steps by hand,
and never do step work outside its step skill.

## The lock and the kill switch — read this before resuming anything

Two files in `runs/<run_tag>/` control whether a run may execute at all. A future session
that does not know about them will either deadlock on a stale lock or trample a live run.

- **`runs/<run_tag>/.lock`** — pid + host + ISO timestamp, claimed by the ROUTER before
  any step and released at every stop. **A run holding a live lock is already executing
  somewhere: do not start a second one.** If the lock's pid is dead the lock is stale —
  report it, say whose pid it was, and clear it only then. Never delete a lock to "get
  unstuck" without checking the pid first: two sessions resuming one run tag both execute,
  both write the same artifacts, and the manifest cannot tell you it happened. The lock is
  the whole reason this pipeline does not need a workflow engine.
- **`runs/<run_tag>/ABORT`** — the kill switch. Its existence stops the run cleanly at the
  next step boundary; the router records `blocked_on: "aborted-by-user"` — that exact
  string, which the Recovery ladder branches on. To stop a run from
  anywhere: `touch runs/<run_tag>/ABORT`. **To resume an aborted run you must delete the
  ABORT file first** — otherwise the router will stop again immediately and the run will
  look mysteriously stuck. Deleting it is a deliberate act; say so when you do it.

Both are owned by the router. Neither is ever committed — `runs/*/.lock` and
`runs/*/ABORT` are in `.gitignore` alongside `runs/*/temp/`, because a committed lock
carries a foreign pid+host that no other machine can safely reclaim, and a committed
ABORT halts every clone of that run.

## Enforcement — what is blocked, and what is deliberately NOT

`.claude/settings.json` wires two `PreToolUse` hooks — `scripts/hooks/guard-bash.sh` and
`scripts/hooks/guard-write.sh`. They block with `exit 2` (an `exit 1` hook does NOT block
— the action proceeds), and they cover only the unambiguously destructive or outbound:
force-push and remote branch deletion, `git reset --hard`, history rewrites, recursive
deletes OUTSIDE the repo, package publishes, `gh release` / `gh repo delete`, credential
writes, and writes outside the checkout. A plain `git push` prompts rather than blocks.
Ownership conventions are LOGGED, not enforced. **Binding rule list: `docs/GUARDRAILS.md`
— read it before touching a hook.**

If a guardrail blocks you: report it to the human and stop. Never rewrite the command to
slip past it, never edit the hook scripts or `.claude/settings.json` to disable it, and
never set `disableAllHooks`. A blocked action is a decision that was already made.

**Editing the harness is never blocked, by design.** This repo is where hyperbuild itself
is developed: `.claude/skills/hyperbuild*`, `.claude/agents/hb-*.md`, `docs/**`, root
`*.md`, `scripts/**` and `evals/**` are source, and edits to them are surfaced and logged,
never refused. If a guardrail ever starts refusing a legitimate harness edit, fix the
guardrail — do not work around it, and do not disable the hook wholesale.

Other invariants a session needs to know: steps 14 and 16 run the FROZEN gate scripts in
`runs/<run_tag>/gates/skill-scripts/` (hashed in the manifest's `frozen_gates`), never the
live `.claude/skills/app-*/scripts/*.sh` — never "helpfully" repoint them at the live
copies. Both paths become unwritable once the run's stage is `BUILD`; during Stage A they
are freely writable, which is when step 10 authors them and step 12 freezes the copies.
Stage B steps run without `WebFetch`/`WebSearch` (Rule of Two); everything they need is
already on disk. Gate checks live in `scripts/gate-*.sh` and are executed, not
interpreted. Full detail: `PIPELINE.md` → Enforcement and observability.

## Ownership

Pipeline-owned — NEVER hand-edit:
- `runs/` (run state: idea.md is gospel, manifest.json is the resume point)
- `research/`, `features/`, `epics/`, `app/` (produced by steps 2–16)
- `.claude/skills/app-*` (project-specific skills generated by step 10)

`research/` has a fixed internal structure — four AREAS, four phases each, defined by
`docs/RESEARCH-ARCHIVE.md` and written by steps 2/3/3.5 (01), 5 (02), 6 (03), 9 (04),
with `research/README.md` written last at step 12:

```
research/
├── README.md            # areas index + REUSABILITY GUIDE (step 12)
├── product-spec.md      # the PRD (step 4) — stays at ROOT: product contract, not research
├── harvest/             # shallow clones + harvest-log.md
├── 01-product-and-market/   # steps 2, 3, 3.5
├── 02-engineering/          # step 5   ← FIXED name, never platform-specific
├── 03-design-system/        # step 6
└── 04-claude-skills/        # step 9
    # every area: _INDEX.md + research/ (breadth, unverified) + verify/ (one
    # fact-checker per load-bearing claim) + critique/ (whole-corpus critics)
    # + author/ (the synthesis downstream steps read)
```

All of it is pipeline-owned: never hand-edit a `research/`, `verify/`, `critique/`, or
`author/` file, never delete a REFUTED `verify/` file, and never "clean up" a `research/`
file that a verifier contradicted — the disagreement between the two IS the record. Area
names are FIXED and never platform-specific (`02-engineering`, not
`02-flutter-engineering`) so downstream paths are deterministic and an area copies into
the next checkout unedited.

`app/` is additionally its own git repo, managed entirely by the pipeline (step 13
`git init`, per-wave/per-epic commits in steps 14–15, clean tree required at the ship
gate) — never commit into it by hand.

Harness source — editable: `.claude/skills/hyperbuild*`, `.claude/agents/hb-*.md`,
`.claude/settings.json`, `scripts/`, `evals/`, the docs.

## Map

- `README.md` — positioning, quickstart, pipeline + agent tables, scale gears.
- `PIPELINE.md` — architecture: the 11 principles, per-step contracts, gates, spawn
  contract, the enforcement and observability layer, hyperresearch lineage.
- `docs/IMPROVEMENTS.md` — the tracked backlog: what the harness is known to be missing,
  ranked, each item with its evidence and a TODO marker, plus the two things deliberately
  NOT being built. Read it before proposing a "new idea" — it may already be item 7.
- `docs/DESIGN-CRAFT.md` — the BINDING visual craft bar for steps 6, 7, 8, 8.5. Every
  design spawn prompt cites it by path; its violations are defects, not opinions.
- `docs/GUARDRAILS.md` — the enforcement layer's binding rule list: exactly what the
  `PreToolUse` hooks block, what they deliberately allow, the escape hatch, and the known
  limits. Read it before editing `.claude/settings.json` or `scripts/hooks/`.
- `docs/RESEARCH-ARCHIVE.md` — the BINDING research output contract for steps 2, 3, 3.5,
  5, 6, 9 and 12: the area layout, the claim→verify mechanism (one fact-checker per
  load-bearing claim, told to REFUTE it), the closed verdict vocabulary, the synthesis
  rule (a REFUTED claim never survives into a synthesis doc), the PROVENANCE RULE (every
  file ends with the prompt that produced it), and the reusability guide. Every research
  spawn prompt cites it by path; its violations are defects, not style disagreements.
- `runs/README.md`, `research/README.md`, `features/README.md`, `epics/README.md` —
  format contracts for each pipeline-owned directory.

# Contributing

hyperbuild is a **prompt-architecture project**: the "source code" is markdown — 23 skill
directories under `.claude/skills/` and 22 `hb-*` agent definitions under
`.claude/agents/`. A contribution here is an edit to a contract that a running pipeline
will obey literally, hours into an autonomous run, possibly after context compaction has
eaten everything except the file you touched. Edit accordingly.

Three documents anchor everything:

- **[docs/SPEC.md](docs/SPEC.md)** — the design source of truth. If a proposed change
  contradicts the spec, the change is wrong or the spec needs a PR first.
- **[PIPELINE.md](PIPELINE.md)** — the architecture reference: the 11 principles, every
  step's contract, the state layout, both gates, the spawn contract, and the lineage
  table back to [hyperresearch](https://github.com/jordan-gibbs/hyperresearch).
- **[README.md](README.md)** — the front door: pipeline tables, agent roster, gear knobs.

## How the harness is structured

- **`hyperbuild` is a thin router.** It bootstraps, sequences, and recovers — it never
  does step work. Each step is its own skill (`hyperbuild-1-intake` …
  `hyperbuild-16-ship-gate`, 19 step skills including the half-steps 3.5, 4.5 and 8.5),
  invoked via `Skill()` and loaded fresh at the moment it runs. `hyperbuild-choose` is
  the human checkpoint; `hyperbuild-revise` and `hyperbuild-redesign` are the two other
  gate-time command skills. 19 + router + 3 command skills = 23 skill directories.
- **Agents are capability contracts.** The 22 subagents in `.claude/agents/hb-*.md`
  carry tool lists that are the *enforcement mechanism*, not documentation: critics
  have no Edit/Write and physically cannot fix what they find; `hb-patcher` has no
  Write and physically cannot regenerate a file. Never "helpfully" widen an agent's
  tool list — you are removing a lock, not adding a convenience.
- **Disk is truth.** Every step writes canonical artifacts to known paths;
  `runs/<run_tag>/manifest.json` records transitions; recovery is manifest → TodoWrite
  → artifact scan. No step trusts the orchestrator's memory.
- **Two hard gates** (step 12 design gate, step 16 ship gate) verify artifacts
  mechanically, ≤3 fix rounds, then an honest blocked state.

## Editing rules

1. **Step skills stay self-contained.** A step skill is loaded fresh — possibly into a
   compacted context that remembers nothing else. It must state its own inputs (exact
   paths), its own procedure, its own spawn templates, its own exit criteria, and
   re-derive state from disk. Never make a step depend on "as established earlier" or
   on another skill being in context. Skills never chain to each other; control always
   bounces back through the router.

2. **An artifact path or name is enumerated in many places — change ALL of them or
   none.** The enumeration sites are: the step skill that writes it, the spawn
   templates that carry it as `output_path`, the consuming steps' input lists, the
   gate checklists (step 12's 21-row table, step 16's checks), the router's recovery
   artifact table (`.claude/skills/hyperbuild/SKILL.md`, "Scan disk artifacts"),
   PIPELINE.md's per-step **Artifacts:** lines, and the README tables. A path renamed
   in four of seven places produces a pipeline that writes to the new name and gates
   against the old one — a guaranteed blocked run. Grep for the old name before you
   call the change done:

   ```bash
   grep -rn "old-artifact-name" .claude/ PIPELINE.md README.md docs/
   ```

3. **The task-frontmatter key set is a single contract.** The eight keys — `id`,
   `epic`, `status`, `depends_on`, `size`, `category`, `features`, `files` — are
   defined in step 11's task schema, scheduled on by step 14 (`files:` drives wave
   disjointness; `status:` flips are the progress ledger), checked structurally by
   design-gate check 16, and walked by the ship gate's traceability chain
   (feature → tasks → `files:` → tests). Adding, renaming, or retyping a key in one
   place and not the others silently breaks wave scheduling or the ship gate. Same
   discipline applies to the manifest shape and the feature-spec frontmatter.

4. **Scale knobs live in the gear table.** The router's table is authoritative
   ("if a step skill's text and this table ever disagree on a number, this table
   wins"); the same table is mirrored in PIPELINE.md and README.md, and each step
   skill cites its own numbers inline. A knob change touches all of these. When a gear
   scales up, every knob widens together — never tune one knob in isolation.

5. **Keep the spawn contract intact.** Every spawn template carries the four pieces:
   verbatim block-quoted idea, pipeline-position statement, inputs + exact
   `output_path`, read-first file list. Templates you add or edit must keep all four.

6. **Keep the lineage honest.** PIPELINE.md's LINEAGE table credits each mechanism to
   its hyperresearch ancestor. If you add or remove a mechanism, update that table —
   the credit is part of the project, not decoration.

7. **Public-repo hygiene.** No absolute local paths, no session-specific references,
   no personal data anywhere in skills, agents, or docs.

## Testing changes

There is no unit-test suite for prompts; the test is a **shakedown run**.

1. Make a **fresh clone** (one checkout = one app — never shakedown in your working
   checkout; a run writes into `research/`, `features/`, `epics/`, `runs/`, `app/`).
2. Run `/hyperbuild <small idea>` with a deliberately small, well-known idea (e.g. a
   pomodoro timer) at the default `standard` gear.
3. **Watch the design gate.** The run should park at step 12 with
   `blocked_on: "design-choice"`. Read `runs/<run_tag>/gates/design-gate-report.md`
   check by check — a failing check names the artifact your change broke. Open
   `runs/<run_tag>/designs/index.html` if your change touches steps 6–8.
4. If your change affects Stage B, continue with `/hyperbuild-choose <a|b|c>` and read
   `runs/<run_tag>/gates/ship-report.md` the same way.
5. For crash-recovery changes, kill the run mid-step and re-invoke `/hyperbuild` — it
   must resume at the dead step, not restart.

Cheap checks before burning a shakedown run:

```bash
# Every skill dir name equals its frontmatter name
for f in .claude/skills/*/SKILL.md; do
  d=$(basename "$(dirname "$f")")
  grep -q "^name: $d$" "$f" || echo "MISMATCH: $f"
done

# No stale references after a rename (see editing rule 2)
grep -rn "<old-name>" .claude/ PIPELINE.md README.md docs/

# No local paths leaked
grep -rn "/Users/\|/private/tmp/" .claude/ .claude-plugin/ *.md docs/
```

## PR expectations

- **Surgical diffs.** Change what the PR is about and nothing else. No drive-by
  rewording, reformatting, or "improving" of prose you happened to scroll past —
  these skills are tuned; a casual rephrase can change runtime behavior.
- **One concern per PR.** A knob change, a step-skill fix, and an agent edit are three
  PRs.
- **List your enumeration sites.** If the PR renames an artifact or touches a shared
  contract (task frontmatter, manifest shape, gear table), the description names every
  file updated and shows the grep proving no stragglers.
- **Verify claims against the repo.** Counts, step names, and knob values quoted in
  docs must match the actual files — reviewers will check.
- Say whether you shakedown-ran it, and to which gate.

## License

hyperbuild is [MIT-licensed](LICENSE). By contributing you agree that your
contributions are licensed under the same MIT license.

# GUARDRAILS.md — the enforcement layer

`CLAUDE.md` ownership rules and `PIPELINE.md` step contracts are **advisory prose living
in a context window**. Compaction can delete them; prompt drift can outvote them. This
file documents the part of the harness that is not prose: two `PreToolUse` hooks, a small
set of permission rules, and the sandbox configuration that belongs at user scope.

The rule the design follows: **hard-deny only what is unambiguously destructive or
irreversible, and let everything else through.** This repository is where the hyperbuild
harness itself is developed. A guardrail that blocks editing `.claude/**`, `docs/**`,
root `*.md`, `scripts/**`, or `evals/**` would be a bug, not safety.

Layering, weakest last — each layer catches what the one below it cannot:

| Layer | Mechanism | Where |
|---|---|---|
| 1. Deterministic deny | `PreToolUse` hook, `exit 2` | `scripts/hooks/guard-bash.sh`, `scripts/hooks/guard-write.sh` |
| 2. Permission rules | `deny` (credential reads), `ask` (irreversible boundaries) | `.claude/settings.json` → `permissions` |
| 3. OS sandbox | filesystem + network confinement for Bash subprocesses | **user scope** — see [The user-scope snippet](#the-user-scope-snippet) |
| 4. Human | one prompt at each irreversible boundary | `ask` rules; the design gate |

`exit 2` blocks a tool call and feeds stderr back to the model as the reason. **`exit 1`
does not block** — it prints stderr into the transcript and the call proceeds. Both hooks
use `exit 1` deliberately, for exactly one case: the payload could not be parsed. A broken
parser must never wedge the harness.

---

## 1. `guard-bash.sh` — what it blocks

`PreToolUse`, matcher `Bash`. Reads the documented hook payload on stdin and inspects
`tool_input.command`.

| Blocked | Examples |
|---|---|
| Force push | `git push --force`, `git push -f`, `git push --force-with-lease`, `git push origin +main:main` |
| Remote branch deletion | `git push --delete origin x`, `git push origin :x` |
| Destroying local state | `git reset --hard`, `git branch -D x`, `git branch --delete --force x` |
| History rewrite | `git filter-branch`, `git filter-repo` |
| Recursive rm outside the repo | `rm -rf /`, `rm -rf ~/Documents`, `rm -rf ../other-project`, `rm -rf /etc/hosts` |
| Recursive rm with an unresolvable target | `rm -rf "$SOMEDIR"` — expand it to a literal path first |
| Package publish | `npm/pnpm/yarn/bun publish`, `cargo publish`, `gem push`, `twine upload`, `flutter pub publish` |
| GitHub destructive/outbound | `gh release create\|delete\|upload\|edit`, `gh repo delete\|archive\|rename\|transfer`, `gh secret set\|delete` |
| World-writable trees | `chmod -R 777 …` |
| Credential writes | `cp … ~/.ssh/…`, `echo … >> ~/.ssh/authorized_keys`, `tee ~/.aws/credentials`, `aws configure set …` |

**Allowed, on purpose:** `git push origin main` (non-force — it hits an `ask` rule and
prompts the human instead), `git commit`, `git init`, `rm -rf node_modules`,
`rm -rf app/build`, `rm -rf "$TMPDIR/scratch"`, `chmod +x`, every read command, and every
build/test command.

**Non-blocking warnings** (`exit 0` plus a `systemMessage`, so they appear without
stopping anything): `sudo`, `git clean -fdx`, non-recursive `chmod 777`, and
`curl … | sh` pipe-to-shell installs.

Two properties worth knowing:

- **Matching is anchored to each segment's own command name.** The command is split on
  `;`, `|`, `&`, wrappers (`sudo`, `env`, `timeout N`, `nohup`, `xargs`, leading `VAR=`)
  are stripped, and only then is the binary dispatched on. That is why
  `grep -rn "git push --force" docs/GUARDRAILS.md` is allowed and
  `timeout 30 git push --force origin main` is blocked.
- **In-repo absolute paths are fine for `rm -r`.** The check is "outside the repository",
  not "absolute": `rm -rf /Users/you/Projects/app_builder/app/build` passes,
  `rm -rf /Users/you/Documents` does not. Temp directories (`$TMPDIR`, `/tmp`,
  `/private/tmp`, `/var/folders`) are also allowed.

## 2. `guard-write.sh` — what it blocks

`PreToolUse`, matcher `Write|Edit|NotebookEdit`. Inspects `tool_input.file_path` (or
`notebook_path`), resolved against the payload's `cwd`. **Four** things block:

1. **The target is outside the repository.** `~/.zshrc`, `~/.claude/settings.json`,
   `/etc/hosts`, `../other-project/src/main.ts`. Allowed roots are the repo,
   `$CLAUDE_PROJECT_DIR`, and the temp dirs.
2. **The target is a credential file**, anywhere — `.env` and `.env.*`, `*.pem`, `*.p12`,
   `*.pfx`, `*.jks`, `*.keystore`, `id_rsa*`, `id_ed25519*`, `.npmrc`, `.netrc`,
   `.pgpass`, `.pypirc`, `credentials.json`, and anything under `.ssh/`, `.aws/`,
   `.gnupg/`. **`.env.example`, `.env.sample`, `.env.template`, `.env.dist`, and
   `.env.defaults` stay writable** — generated apps legitimately ship those.
3. **`.claude/skills/app-*/scripts/**` or `runs/<run_tag>/gates/skill-scripts/**` while
   the OWNING run is in stage `BUILD`** — the frozen oracle. Reason string: *frozen
   oracle: generated gate scripts are immutable during Stage B*. During Stage A both
   paths are freely writable — that is when step 10 authors the scripts and step 12
   freezes copies of them. Once the run enters BUILD, the build agent can execute the
   gate that grades it and can no longer edit it.

   **Which run is consulted.** Never "the newest manifest" — `runs/` holds many runs, and
   a run in BUILD would stop being protected the moment another run's manifest was
   touched more recently. A frozen copy names its run in its own path
   (`runs/<run_tag>/gates/…`) and is resolved exactly; a live `app-*/scripts/` file
   belongs to no single run, so **every** `runs/*/manifest.json` is consulted and any one
   of them in `BUILD` blocks.

   **Two carve-outs**, both for flows the pipeline itself defines while the stage is
   already `BUILD`. Without them a documented user command kills the run:

   - `steps["10"] == "redo"` → both paths writable. This is the
     `/hyperbuild-choose <a|b|c> <platform>` detour: the checkpoint sets `stage: "BUILD"`
     and marks steps 5/10/11 `"redo"` in the same manifest write, and the router then
     runs 5 → 10 → 11 before 13. Step 10 is what AUTHORS these scripts.
   - the frozen-copy path only, while `runs/<run_tag>/temp/wave-log.md` records zero
     `wave <N>:` lines → writable. This mirrors step 14.0.5's ONE LEGAL RE-FREEZE and its
     own precondition, so the hook and the skill agree by construction. It closes
     permanently the moment wave 1 is logged.

4. **`scripts/gate-*.sh` at the repo root while ANY run is in stage `BUILD`** — the
   harness gate oracle. `gate-design.sh` and `gate-ship.sh` are ordinary harness source
   and stay freely editable the rest of the time; during a build they are exactly the
   scripts grading `hb-implementer`, `hb-test-engineer` and `hb-patcher`, all of which
   hold `Edit`. A failing check is fixed in the artifact, never in the script that grades
   it. Anchored at the repo root on purpose, so a generated skill that happens to name a
   script `gate-*.sh` is rule 3's business, not this one. `Edit(/scripts/gate-*.sh)` is
   additionally on the `ask` list, which prompts a human outside a build too.

Everything else inside the repository is allowed: `.claude/skills/hyperbuild*`,
`.claude/agents/hb-*`, `.claude/settings.json`, `PIPELINE.md`, `CLAUDE.md`, `docs/**`,
`scripts/**`, `evals/**`, and every pipeline-owned directory (`runs/`, `research/`,
`features/`, `epics/`, `app/`) — the pipeline has to write those, and you have to be able
to develop the harness.

This hook is also what covers `Write` and `NotebookEdit` on credential paths at all:
per the permissions docs, a `Read` deny rule blocks the `Edit` tool on the same path but
**Write and NotebookEdit are not covered by it**. Layer 1 closes that gap.

## 3. `.claude/settings.json` — permission rules

`deny` (credential reads; these also block `Edit` on the same path):
`~/.ssh/**`, `~/.aws/**`, `~/.gnupg/**`, `~/.claude/.credentials.json`, `**/.env`,
`**/.env.local`, `**/.env.*.local`, `**/*.pem`, `**/id_rsa*`, `**/id_ed25519*`,
`**/.npmrc`, `**/.netrc`, plus `Edit(~/.claude/settings.json)` and `Edit(//etc/**)`.

`ask` (irreversible boundaries and self-modification — one human click, not a block):
`git push *`, `gh pr create *`, `gh release *`, `gh repo *`, `npm|pnpm|yarn publish *`,
`Edit(/.claude/settings.json)`, `Edit(/scripts/hooks/**)`, `Edit(/scripts/gate-design.sh)`,
`Edit(/scripts/gate-ship.sh)`.

Three deliberate choices here:

- **Bash blocking lives in the hook, not in `permissions.deny`.** A permission deny has
  no escape hatch; the hook has one the human controls. `deny` is reserved for credential
  reads, where no escape hatch should exist.
- **`ask` rules survive `--dangerously-skip-permissions`.** Per the permissions docs,
  explicit ask rules still prompt in every mode. That makes `Edit(/.claude/settings.json)`
  and `Edit(/scripts/hooks/**)` the anti-escalation property: an agent cannot silently
  weaken its own guardrails, even in bypass mode, and you keep the ability to edit them
  yourself with one click. The two `gate-*.sh` rules extend the same property to the
  oracle: outside a build an edit costs one click; during a build layer 1 refuses it.
- **`Write(path)` and `NotebookEdit(path)` rules are never matched** by Claude Code's file
  permission checks (it warns at startup if you write one). Use `Edit(path)` — it covers
  all file-editing tools — and let `guard-write.sh` handle Write/NotebookEdit.

`env` sets `CLAUDE_ASYNC_AGENT_STALL_TIMEOUT_MS=600000`, the documented bounded wait for
background subagents: if no streaming progress arrives inside the window the subagent is
aborted and the task is marked failed. (The name `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`
appears in some write-ups but is **not** in the current env-vars documentation; do not
use it.)

`sandbox.credentials` deny entries are included at project scope because deny entries only
ever narrow access and any scope may add one. They take effect **only once the sandbox is
enabled**, which is a user-scope decision — next section.

## 4. The escape hatch

```bash
HYPERBUILD_ALLOW_DESTRUCTIVE=1 claude
```

Set it in the shell that launches Claude Code. Both hooks then log the override and exit
0 for every check they would otherwise block.

Why an environment variable, and why on the launching shell: **hook handlers run with
Claude Code's environment**, not with the environment of a Bash tool call. An agent that
runs `export HYPERBUILD_ALLOW_DESTRUCTIVE=1` inside a Bash call does not change the hook's
environment — the variable is a human control by construction. The one path an agent could
take is editing `.claude/settings.json`'s `env` block, which is why that file carries an
`ask` rule and a `ConfigChange` notifier.

Narrower alternatives, preferred when they fit:

- `HYPERBUILD_EXTRA_WRITE_ROOTS=/path/one:/path/two` — additional allowed write roots for
  `guard-write.sh`, without disabling anything else.
- `HYPERBUILD_GUARDRAIL_LOG=/path/to/log` — where both hooks append their decision log.
  Default: `$TMPDIR/hyperbuild-guardrails.log`. Every ALLOW, BLOCK, WARN, OVERRIDE,
  NOTIFY, and PARSE-FAIL is one timestamped line — the poor man's audit trail until
  OpenTelemetry lands (audit change 18).

## 5. How to check that a hook actually fires

**Directly, without a session** — this is the check to run after editing either script:

```bash
cd /path/to/app_builder

# should print a BLOCKED reason and exit 2
printf '{"cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' "$PWD" \
  | ./scripts/hooks/guard-bash.sh ; echo "exit=$?"

# should be silent and exit 0
printf '{"cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"npm test"}}' "$PWD" \
  | ./scripts/hooks/guard-bash.sh ; echo "exit=$?"

# should print a BLOCKED reason and exit 2
printf '{"cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/etc/hosts"}}' "$PWD" \
  | ./scripts/hooks/guard-write.sh ; echo "exit=$?"

# should be silent and exit 0 — harness development is not restricted
printf '{"cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"%s/PIPELINE.md"}}' "$PWD" "$PWD" \
  | ./scripts/hooks/guard-write.sh ; echo "exit=$?"
```

Exit code 2 with a one-line reason on stderr means the guardrail works. Exit 1 means
neither `jq` nor `python3` is on `PATH`, or the payload was malformed — the hook did not
inspect anything and did not block.

**Inside a session:** ask Claude to run `git push --force origin main`. It should come
back blocked with the guardrail's reason, and `/hooks` (read-only browser) should list
both `PreToolUse` entries with source `Project`. Hook edits are picked up automatically by
Claude Code's file watcher, so no restart is needed after changing a script — though
changing `.claude/settings.json` itself fires the `ConfigChange` notifier, which logs and
never blocks.

**Tail the decision log** while a run is going:

```bash
tail -f "${TMPDIR:-/tmp}/hyperbuild-guardrails.log"
```

## 6. The user-scope snippet

Sandboxing is the layer that holds **regardless of what the model chose to run** — it is
OS enforcement, not a string check. It is deliberately **not** in this repository's
`.claude/settings.json`, for reasons that are properties of the settings system rather
than preference:

- `sandbox.failIfUnavailable` and `sandbox.allowUnsandboxedCommands` are boolean policy
  keys. Claude Code takes the **managed** value and ignores what a developer sets locally,
  so a value checked into a template repository is either overridden or misleading. Worse,
  `failIfUnavailable: true` shipped in a repo that others clone **blocks Claude Code from
  starting** on any machine missing `bubblewrap`/`socat` (Linux/WSL2) — a checked-in file
  must not be able to do that to someone else's machine.
- `sandbox.filesystem.disabled` and `allowAppleEvents` are explicitly **ignored** in
  project settings, and `mask` credential entries, `network.tlsTerminate`, and
  `credentials.allowPlaintextInject` are ignored there too.
- What project scope *can* carry is `sandbox.credentials` **deny** entries, because a deny
  only narrows access. Those are already in `.claude/settings.json`.

Put this in `~/.claude/settings.json` (user scope), or deliver it through managed settings
for a fleet:

```json
{
  "sandbox": {
    "enabled": true,
    "failIfUnavailable": true,
    "allowUnsandboxedCommands": false,
    "credentials": {
      "files": [
        { "path": "~/.ssh", "mode": "deny" },
        { "path": "~/.aws", "mode": "deny" },
        { "path": "~/.gnupg", "mode": "deny" },
        { "path": "~/.config/gh/hosts.yml", "mode": "deny" },
        { "path": "~/.npmrc", "mode": "deny" },
        { "path": "~/.netrc", "mode": "deny" },
        { "path": "~/.claude/.credentials.json", "mode": "deny" }
      ],
      "envVars": [
        { "name": "GITHUB_TOKEN", "mode": "deny" },
        { "name": "GH_TOKEN", "mode": "deny" },
        { "name": "NPM_TOKEN", "mode": "deny" },
        { "name": "ANTHROPIC_API_KEY", "mode": "deny" },
        { "name": "AWS_SECRET_ACCESS_KEY", "mode": "deny" }
      ]
    }
  }
}
```

Notes on that snippet:

- **The sandbox fails OPEN by default.** A missing dependency produces a warning and an
  unsandboxed agent. `failIfUnavailable: true` is what turns that into a hard failure, and
  `allowUnsandboxedCommands: false` removes the `dangerouslyDisableSandbox` retry path.
  Both are the point of enabling it at all.
- **There is no built-in credential deny list**, and the sandbox's default read policy
  covers the whole machine, `~/.aws/credentials` and `~/.ssh/` included. Only what you
  list is protected.
- `ANTHROPIC_API_KEY` and the `gh`/`npm` credential files are in the user-scope snippet
  rather than the project file on purpose: a deny entry **cannot be removed by another
  scope**, and hyperbuild can legitimately be asked to build an app whose own test suite
  needs an API key. Keep that decision with the human, not in a committed file.
- Sandboxing covers Bash subprocesses only. Read/Edit/Write go through the permission
  system, which is why layers 1 and 2 exist.
- The sandbox denies writes to `settings.json` at every scope — the single strongest
  anti-escalation property available, and another reason to turn it on.
- `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` strips Anthropic and cloud-provider credentials from
  every subprocess regardless of sandboxing. Consider it if you never build apps that call
  those providers from their tests.

## 7. Known limits — state them, don't paper over them

- **A `Stop` hook is overridden after 8 consecutive blocks.** Anything built on Stop
  blocking is soft by design. These are `PreToolUse` hooks, which do not carry that
  behavior, but any future gate built on `Stop` must account for it.
- **`disableAllHooks: true` in a higher-precedence settings file turns all of this off.**
  It is set to `false` explicitly here so that flipping it shows up in a diff.
- **Hooks are not sandboxed** and run with Claude Code's environment in the current
  directory. Read a hook script before trusting it — including these two.
- **Command inspection is string analysis, not execution.** A determined agent writing a
  shell script to a file and running it defeats `guard-bash.sh`'s pattern set. That is
  what the OS sandbox (layer 3) is for; hooks raise the cost, sandboxing sets the bound.
- **Splitting on `;`, `|`, and `&` is quote-blind.** A literal separator inside a quoted
  string can produce a synthetic segment; if that segment's first word is a watched binary,
  you get a false block. The escape hatch covers it.
- **These hooks do not cover MCP tools**, subagent spawns, or the network. Least-privilege
  per agent (audit change 2) is a separate mechanism, enforced in the agent frontmatter
  `tools:` lists.
- **This is project-scope configuration.** When hyperbuild is consumed as a *plugin*, a
  plugin's own `hooks/hooks.json` is the loading path — `.claude/settings.json` in this
  repository is not read for installs elsewhere.

---

**Sources.** Schema, event names, matcher syntax, payload fields, exit-code semantics, and
hook execution environment: <https://code.claude.com/docs/en/hooks>. Settings scope and
precedence: <https://code.claude.com/docs/en/settings>. Permission rule syntax and the
`Write(path)`-is-never-matched rule: <https://code.claude.com/docs/en/permissions>. Sandbox
keys, scope restrictions, fail-open default, and the absence of a built-in credential deny
list: <https://code.claude.com/docs/en/sandboxing>. All read 2026-07-25 against Claude Code
v2.1.220.

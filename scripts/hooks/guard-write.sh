#!/usr/bin/env bash
# guard-write.sh — hyperbuild PreToolUse deny hook over Write | Edit | NotebookEdit,
# plus a non-blocking ConfigChange notifier (invoked as `guard-write.sh --notify`).
#
# Contract (docs: https://code.claude.com/docs/en/hooks):
#   stdin  : PreToolUse JSON payload {cwd, tool_name, tool_input:{file_path|notebook_path}, ...}
#   exit 0 : allow
#   exit 2 : BLOCK the tool call; stderr is fed back to the model as the reason
#   other  : non-blocking error; stderr is shown in the transcript, the call proceeds
#
# This repo is where the hyperbuild harness itself is developed, so EVERYTHING inside
# the repository is allowed to be written — .claude/**, docs/**, root *.md, scripts/**,
# evals/**, runs/**, research/**, features/**, epics/**, app/**. Only four things block:
#
#   1. a target OUTSIDE the repository (and outside the temp dirs)
#   2. a credential-ish file (.env*, *.pem, id_rsa*, .npmrc, .netrc, .credentials.json)
#   3. .claude/skills/app-*/scripts/** or runs/<run_tag>/gates/skill-scripts/** while the
#      owning run is in stage BUILD — the frozen oracle: generated gate scripts are
#      immutable during Stage B (step 12 freezes them; steps 14/16 only execute them)
#   4. scripts/gate-*.sh while ANY run is in stage BUILD — the harness gate oracle. Outside
#      a build these are ordinary harness source and stay freely editable.
#
# The frozen-oracle block has exactly TWO carve-outs, both for flows the pipeline itself
# defines while stage is already BUILD (without them a documented command bricks the run):
#
#   a. `steps["10"] == "redo"` — the `/hyperbuild-choose <a|b|c> <platform>` detour, which
#      re-runs 5 → 10 → 11 before step 13. Step 10 AUTHORS these scripts.
#   b. the frozen-copy path only, while `temp/wave-log.md` records zero `wave <N>:` lines —
#      step 14.0.5's ONE LEGAL RE-FREEZE, whose own precondition this mirrors, so the hook
#      and the skill agree by construction. It dies the moment wave 1 is logged.
#
# Escape hatch (human, deliberate): start Claude Code with
#   HYPERBUILD_ALLOW_DESTRUCTIVE=1 claude
#
# Portability: POSIX-ish bash, must run on macOS's bash 3.2.

set -euo pipefail
set -f

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd -P)
# Symlink-unresolved twin. Tool payloads carry the path the caller typed, which on macOS
# is routinely the /var/folders (unresolved) form of a /private/var/folders (resolved)
# directory. Anchored patterns must accept both or they silently stop matching.
REPO_ROOT_LOGICAL=$(cd "$(dirname "$0")/../.." && pwd)
LOG_FILE=${HYPERBUILD_GUARDRAIL_LOG:-${TMPDIR:-/tmp}/hyperbuild-guardrails.log}
MODE=${1:-guard}

log() {
  printf '%s guard-write %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >>"$LOG_FILE" 2>/dev/null || true
}

# ---------------------------------------------------------------- payload parsing

PAYLOAD=$(cat 2>/dev/null || true)
JQ_BIN=$(command -v jq 2>/dev/null || true)
PY_BIN=$(command -v python3 2>/dev/null || true)

json_get() { # $1 = dotted path
  if [ -n "$JQ_BIN" ]; then
    printf '%s' "$PAYLOAD" |
      "$JQ_BIN" -r --arg p "$1" '(try (getpath($p | split("."))) catch null) // "" | if type == "string" then . else tostring end' 2>/dev/null ||
      printf ''
  elif [ -n "$PY_BIN" ]; then
    printf '%s' "$PAYLOAD" | "$PY_BIN" -c '
import json, sys
try:
    doc = json.load(sys.stdin)
except Exception:
    sys.exit(0)
cur = doc
for key in sys.argv[1].split("."):
    if isinstance(cur, dict) and key in cur:
        cur = cur[key]
    else:
        cur = ""
        break
sys.stdout.write(cur if isinstance(cur, str) else "")
' "$1" 2>/dev/null || printf ''
  else
    printf ''
  fi
}

# ---------------------------------------------------------------- notify mode

if [ "$MODE" = "--notify" ]; then
  # ConfigChange (and anything else wired to it): observe, never block. Blocking config
  # changes would break harness development, which is the point of this repo.
  EVENT=$(json_get hook_event_name)
  SCOPE=$(json_get scope)
  [ -n "$EVENT" ] || EVENT="unknown-event"
  log "NOTIFY ${EVENT} scope=${SCOPE:-n/a} :: $(printf '%s' "$PAYLOAD" | tr '\n' ' ' | cut -c1-400)"
  exit 0
fi

# ---------------------------------------------------------------- guard mode

TOOL_NAME=$(json_get tool_name)
if [ -z "$TOOL_NAME" ]; then
  printf 'hyperbuild guardrail: could not parse the PreToolUse payload (jq/python3 missing or malformed JSON) — this write was NOT inspected.\n' >&2
  log "PARSE-FAIL (jq=${JQ_BIN:-none} python3=${PY_BIN:-none})"
  exit 1
fi

TARGET=$(json_get tool_input.file_path)
[ -n "$TARGET" ] || TARGET=$(json_get tool_input.notebook_path)
[ -n "$TARGET" ] || exit 0

CWD_ABS=$(json_get cwd)
case "$CWD_ABS" in /*) ;; *) CWD_ABS=$REPO_ROOT ;; esac

block() { # $1 = single-line reason
  printf 'BLOCKED by hyperbuild guardrail: %s.\n' "$1" >&2
  printf 'Do not work around this by moving the file, editing the hook, or editing .claude/settings.json. If the write is genuinely required, stop and ask the human (docs/GUARDRAILS.md).\n' >&2
  log "BLOCK [$1] :: $TOOL_NAME $TARGET"
  exit 2
}

normalize_path() { # lexical realpath: resolves . and .. without touching the disk
  local p="$1" out="" part oldifs
  case "$p" in
    "~") p="$HOME" ;;
    "~/"*) p="$HOME/${p#\~/}" ;;
  esac
  case "$p" in
    /*) ;;
    *) p="$CWD_ABS/$p" ;;
  esac
  oldifs=$IFS
  IFS='/'
  # shellcheck disable=SC2086
  set -- $p
  IFS=$oldifs
  for part in "$@"; do
    case "$part" in
      '' | .) ;;
      ..) out="${out%/*}" ;;
      *) out="$out/$part" ;;
    esac
  done
  [ -n "$out" ] || out="/"
  printf '%s' "$out"
}

is_within() { # $1 = candidate, $2 = root
  case "$1" in
    "$2" | "$2"/*) return 0 ;;
  esac
  return 1
}

PATH_ABS=$(normalize_path "$TARGET")
BASE=${PATH_ABS##*/}

OVERRIDE=0
if [ "${HYPERBUILD_ALLOW_DESTRUCTIVE:-}" = "1" ]; then OVERRIDE=1; fi

# --- 1. credential-ish files -------------------------------------------------
# Deny by basename, anywhere. `.env.example` / `.sample` / `.template` are template
# files with no secrets in them and stay writable, because generated apps need them.
CRED_HIT=""
case "$BASE" in
  .env.example | .env.sample | .env.template | .env.dist | .env.defaults) ;;
  .env | .env.* | *.env) CRED_HIT="dotenv file" ;;
  *.pem | *.p12 | *.pfx | *.jks | *.keystore) CRED_HIT="private key or keystore" ;;
  id_rsa* | id_dsa* | id_ecdsa* | id_ed25519*) CRED_HIT="ssh private key" ;;
  .npmrc | .netrc | .pgpass | .pypirc) CRED_HIT="package or network credential file" ;;
  .credentials.json | credentials.json) CRED_HIT="credentials file" ;;
esac
case "$PATH_ABS" in
  */.ssh/* | */.aws/* | */.gnupg/* | */.claude/.credentials.json)
    CRED_HIT="credential directory"
    ;;
esac
if [ -n "$CRED_HIT" ]; then
  if [ "$OVERRIDE" -eq 1 ]; then
    log "OVERRIDE credential-write ($CRED_HIT) :: $PATH_ABS"
  else
    block "$TOOL_NAME targets a credential file ($CRED_HIT): $PATH_ABS. Secrets are never written by the pipeline; use .env.example for templates"
  fi
fi

# --- 2. outside the repository ----------------------------------------------
# Allowed roots: the repo itself, the project dir Claude Code reports, and temp dirs
# (agents legitimately use scratch space). Everything else — ~/.claude, ~/.zshrc,
# /etc, a sibling project — is denied.
INSIDE=0
EXTRA_ROOTS=$(printf '%s' "${HYPERBUILD_EXTRA_WRITE_ROOTS:-}" | tr ':' ' ')
# shellcheck disable=SC2086
for root in "$REPO_ROOT" "$REPO_ROOT_LOGICAL" "${CLAUDE_PROJECT_DIR:-$REPO_ROOT}" "${TMPDIR:-/tmp}" /tmp /private/tmp /var/folders $EXTRA_ROOTS; do
  [ -n "$root" ] || continue
  if is_within "$PATH_ABS" "$(normalize_path "$root")"; then
    INSIDE=1
    break
  fi
done
if [ "$INSIDE" -eq 0 ]; then
  if [ "$OVERRIDE" -eq 1 ]; then
    log "OVERRIDE outside-repo :: $PATH_ABS"
  else
    block "$TOOL_NAME targets a path outside the repository ($PATH_ABS). The harness writes only inside $REPO_ROOT (plus temp dirs)"
  fi
fi

# --- 3. frozen oracle: generated gate scripts during Stage B ------------------
# Backs the freeze-and-hash change: the build agent must not be able to edit the
# script gates that grade it once the run has entered BUILD.
#
# NEVER pick "the newest manifest" here. runs/ legitimately holds many runs, and a run
# in BUILD would stop being protected the moment any OTHER run's manifest was touched
# more recently. A frozen copy names its own run in its path, so it is resolved exactly;
# a live app-*/scripts file belongs to no single run, so EVERY run is consulted.

manifest_stage() { # $1 = manifest path
  local v=""
  if [ -n "$JQ_BIN" ]; then
    v=$("$JQ_BIN" -r '.stage // ""' "$1" 2>/dev/null || printf '')
  elif [ -n "$PY_BIN" ]; then
    v=$("$PY_BIN" -c 'import json,sys; print(json.load(open(sys.argv[1])).get("stage") or "")' "$1" 2>/dev/null || printf '')
  fi
  # Fail CLOSED: with no JSON parser available, a textual "stage": "BUILD" still protects.
  if [ -z "$v" ] && grep -qE '"stage"[[:space:]]*:[[:space:]]*"BUILD"' "$1" 2>/dev/null; then v="BUILD"; fi
  printf '%s' "$v"
}

manifest_step() { # $1 = manifest path, $2 = step key — that step's status
  local v=""
  if [ -n "$JQ_BIN" ]; then
    v=$("$JQ_BIN" -r --arg s "$2" '.steps[$s] // ""' "$1" 2>/dev/null || printf '')
  elif [ -n "$PY_BIN" ]; then
    v=$("$PY_BIN" -c 'import json,sys; print((json.load(open(sys.argv[1])).get("steps") or {}).get(sys.argv[2]) or "")' "$1" "$2" 2>/dev/null || printf '')
  fi
  # Fail OPEN on the carve-out: manifests are written with indent=2, one key per line.
  if [ -z "$v" ] && grep -qE "^[[:space:]]*\"$2\"[[:space:]]*:[[:space:]]*\"redo\"" "$1" 2>/dev/null; then v="redo"; fi
  printf '%s' "$v"
}

refreeze_window_open() { # $1 = run dir — true until step 14 logs its first wave (14.0.5)
  local wl="$1/temp/wave-log.md"
  [ -f "$wl" ] || return 0
  if grep -qiE '(^|[^a-z])wave[[:space:]]+[0-9]+[[:space:]]*:' "$wl" 2>/dev/null; then
    return 1
  fi
  return 0
}

ORACLE_BLOCK=""
ORACLE_WHY=""
case "$PATH_ABS" in
  */runs/*/gates/skill-scripts/*)
    RUN_DIR=${PATH_ABS%%/gates/skill-scripts/*}
    RUN_MANIFEST="$RUN_DIR/manifest.json"
    if [ -f "$RUN_MANIFEST" ] && [ "$(manifest_stage "$RUN_MANIFEST")" = "BUILD" ]; then
      if [ "$(manifest_step "$RUN_MANIFEST" 10)" = "redo" ]; then
        log "ALLOW frozen-oracle carve-out (step 10 = redo, platform override) :: $PATH_ABS"
      elif refreeze_window_open "$RUN_DIR"; then
        log "ALLOW frozen-oracle carve-out (pre-wave-1 re-freeze window, 14.0.5) :: $PATH_ABS"
      else
        ORACLE_BLOCK="$RUN_MANIFEST"
        ORACLE_WHY="wave 1 is already logged, so step 14.0.5's one legal re-freeze is spent"
      fi
    fi
    ;;
  */.claude/skills/app-*/scripts/*)
    if [ -d "$REPO_ROOT/runs" ]; then
      while IFS= read -r candidate; do
        [ -n "$candidate" ] || continue
        [ "$(manifest_stage "$candidate")" = "BUILD" ] || continue
        # step 10 re-running (platform override) is what AUTHORS these scripts
        [ "$(manifest_step "$candidate" 10)" = "redo" ] && continue
        ORACLE_BLOCK="$candidate"
        ORACLE_WHY="that run is in Stage B and step 10 is not re-running"
        break
      done <<EOF
$(find "$REPO_ROOT/runs" -mindepth 2 -maxdepth 2 -name manifest.json -type f 2>/dev/null || true)
EOF
    fi
    ;;
esac
if [ -n "$ORACLE_BLOCK" ]; then
  if [ "$OVERRIDE" -eq 1 ]; then
    log "OVERRIDE frozen-oracle :: $PATH_ABS"
  else
    block "frozen oracle: generated gate scripts are immutable during Stage B ($PATH_ABS; run manifest: $ORACLE_BLOCK; $ORACLE_WHY)"
  fi
fi

# --- 4. the harness gate oracle: scripts/gate-*.sh during Stage B -------------
# scripts/gate-design.sh and scripts/gate-ship.sh are the scripts that grade the build.
# This repo is where the harness is developed, so they are freely editable — EXCEPT while
# a run is in BUILD, which is exactly when hb-implementer / hb-test-engineer / hb-patcher
# are live and could edit the oracle that grades them.
# Anchored at REPO_ROOT on purpose: a generated skill that happens to name a script
# `gate-*.sh` under .claude/skills/app-*/scripts/ is rule 3's business, not this one.
case "$PATH_ABS" in
  "$REPO_ROOT"/scripts/gate-*.sh | "$REPO_ROOT_LOGICAL"/scripts/gate-*.sh)
    GATE_BLOCK=""
    if [ -d "$REPO_ROOT/runs" ]; then
      while IFS= read -r candidate; do
        [ -n "$candidate" ] || continue
        if [ "$(manifest_stage "$candidate")" = "BUILD" ]; then GATE_BLOCK="$candidate"; break; fi
      done <<EOF
$(find "$REPO_ROOT/runs" -mindepth 2 -maxdepth 2 -name manifest.json -type f 2>/dev/null || true)
EOF
    fi
    if [ -n "$GATE_BLOCK" ]; then
      if [ "$OVERRIDE" -eq 1 ]; then
        log "OVERRIDE harness-gate-script :: $PATH_ABS"
      else
        block "the harness gate oracle is immutable while a run is building: $PATH_ABS (run manifest: $GATE_BLOCK). A failing check is fixed in the artifact, never in the script that grades it"
      fi
    fi
    ;;
esac

log "ALLOW :: $TOOL_NAME $PATH_ABS"
exit 0

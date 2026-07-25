#!/usr/bin/env bash
# guard-bash.sh — hyperbuild PreToolUse deny hook over the Bash tool.
#
# Contract (docs: https://code.claude.com/docs/en/hooks):
#   stdin  : PreToolUse JSON payload {session_id, cwd, hook_event_name, tool_name,
#            tool_input:{command,...}, ...}
#   exit 0 : allow (stdout may carry a JSON object; we use {"systemMessage": ...} for warnings)
#   exit 2 : BLOCK the tool call; stderr is fed back to the model as the reason
#   other  : non-blocking error; stderr is shown in the transcript, the call proceeds
#
# Philosophy: this repo is where the hyperbuild harness itself is developed, so the
# hook hard-denies ONLY unambiguously destructive or irreversible commands. Everything
# else is allowed; a small set of ambiguous-but-notable commands produces a
# non-blocking warning. See docs/GUARDRAILS.md.
#
# Escape hatch (human, deliberate): start Claude Code with
#   HYPERBUILD_ALLOW_DESTRUCTIVE=1 claude
# Hook processes inherit Claude Code's environment, so an agent cannot set this from
# inside a Bash tool call — only the human launching the session can.
#
# Portability: POSIX-ish bash, must run on macOS's bash 3.2 (no mapfile, no assoc
# arrays, no ${var,,}).

set -euo pipefail
set -f # noglob: command arguments are inspected literally, never expanded

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd -P)
LOG_FILE=${HYPERBUILD_GUARDRAIL_LOG:-${TMPDIR:-/tmp}/hyperbuild-guardrails.log}

log() {
  printf '%s guard-bash %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >>"$LOG_FILE" 2>/dev/null || true
}

# ---------------------------------------------------------------- payload parsing

PAYLOAD=$(cat 2>/dev/null || true)
JQ_BIN=$(command -v jq 2>/dev/null || true)
PY_BIN=$(command -v python3 2>/dev/null || true)

json_get() { # $1 = dotted path, e.g. tool_input.command
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

TOOL_NAME=$(json_get tool_name)
if [ -z "$TOOL_NAME" ]; then
  # Unparseable payload, or neither jq nor python3 present. Surface it loudly but do
  # NOT block: a broken parser must not wedge the harness.
  printf 'hyperbuild guardrail: could not parse the PreToolUse payload (jq/python3 missing or malformed JSON) — this command was NOT inspected.\n' >&2
  log "PARSE-FAIL (jq=${JQ_BIN:-none} python3=${PY_BIN:-none})"
  exit 1
fi
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(json_get tool_input.command)
[ -n "$CMD" ] || exit 0

CWD_ABS=$(json_get cwd)
case "$CWD_ABS" in /*) ;; *) CWD_ABS=$REPO_ROOT ;; esac

if [ "${HYPERBUILD_ALLOW_DESTRUCTIVE:-}" = "1" ]; then
  log "OVERRIDE HYPERBUILD_ALLOW_DESTRUCTIVE=1 :: $CMD"
  exit 0
fi

# ---------------------------------------------------------------- helpers

WARNINGS=""

warn() { # $1 = single-line, quote-free reason
  WARNINGS="$WARNINGS $1;"
}

block() { # $1 = single-line reason
  printf 'BLOCKED by hyperbuild guardrail: %s.\n' "$1" >&2
  printf 'This is a capability, not a suggestion: do not rewrite the command, the hook, or .claude/settings.json to get around it. If it is genuinely required, stop and ask the human to re-run with HYPERBUILD_ALLOW_DESTRUCTIVE=1 (docs/GUARDRAILS.md).\n' >&2
  log "BLOCK [$1] :: $CMD"
  exit 2
}

m() { # regex match against the current segment ($REST, space-padded)
  printf '%s' "$REST" | grep -qE "$1"
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

# ---------------------------------------------------------------- rm inspection

check_rm() { # $1 = the rm segment (already unwrapped)
  local recursive=0 tok path resolved home_norm allowed
  # shellcheck disable=SC2086
  set -- $1
  shift # drop the `rm` word itself
  for tok in "$@"; do
    case "$tok" in
      --) ;;
      --recursive) recursive=1 ;;
      --force | --preserve-root | --no-preserve-root | -v | --verbose | -i | -I) ;;
      -*)
        case "$tok" in
          *[rR]*) recursive=1 ;;
        esac
        ;;
    esac
  done
  [ "$recursive" -eq 1 ] || return 0

  home_norm=$(normalize_path "$HOME")
  for tok in "$@"; do
    case "$tok" in
      -*) continue ;;
    esac
    path=$(printf '%s' "$tok" | tr -d "\"'")
    [ -n "$path" ] || continue
    # Expand only variables we can resolve with certainty.
    path=${path//\$\{TMPDIR\}/${TMPDIR:-/tmp}}
    path=${path//\$TMPDIR/${TMPDIR:-/tmp}}
    path=${path//\$\{HOME\}/$HOME}
    path=${path//\$HOME/$HOME}
    path=${path//\$\{PWD\}/$CWD_ABS}
    path=${path//\$PWD/$CWD_ABS}
    case "$path" in
      *'$'* | *'`'*)
        block "recursive rm whose target contains an unresolvable shell expansion ($tok) — expand it into a literal path first"
        ;;
    esac
    resolved=$(normalize_path "$path")
    case "$resolved" in
      / | /bin | /boot | /dev | /etc | /home | /lib | /opt | /private | /sbin | /System | /Applications | /usr | /var | /Users)
        block "recursive rm of a system path ($resolved)"
        ;;
    esac
    if [ "$resolved" = "$home_norm" ]; then
      block "recursive rm of the home directory ($resolved)"
    fi
    if is_within "$REPO_ROOT" "$resolved" && [ "$resolved" != "$REPO_ROOT" ]; then
      block "recursive rm of a parent of the repository ($resolved)"
    fi
    if is_within "$resolved" "$REPO_ROOT"; then
      continue # inside the repo: allowed (build dirs, node_modules, harvest clones)
    fi
    for allowed in "${TMPDIR:-/tmp}" /tmp /private/tmp /var/folders; do
      if is_within "$resolved" "$(normalize_path "$allowed")"; then
        continue 2
      fi
    done
    block "recursive rm of a path outside the repository ($resolved)"
  done
}

# ---------------------------------------------------------------- per-segment checks

check_segment() {
  local raw seg first bin guard timeout_seen
  raw=$(printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  [ -n "$raw" ] || return 0
  seg="$raw"

  # Strip leading env assignments and process wrappers so `sudo env X=1 git push -f`
  # is inspected as `git push -f`.
  guard=0
  timeout_seen=0
  while [ "$guard" -lt 12 ]; do
    guard=$((guard + 1))
    first=${seg%%[[:space:]]*}
    case "$first" in
      sudo | doas)
        warn "elevated privileges ($first)"
        ;;
      env | nohup | time | nice | stdbuf | command | builtin | xargs | caffeinate) ;;
      timeout) timeout_seen=1 ;;
      *=*) ;;
      [0-9]*)
        if [ "$timeout_seen" -eq 1 ]; then
          timeout_seen=0
        else
          break
        fi
        ;;
      *) break ;;
    esac
    case "$seg" in
      *[[:space:]]*)
        seg=${seg#*[[:space:]]}
        seg=$(printf '%s' "$seg" | sed -e 's/^[[:space:]]*//')
        ;;
      *) seg="" ;;
    esac
    [ -n "$seg" ] || return 0
  done

  first=${seg%%[[:space:]]*}
  bin=${first##*/}
  bin=$(printf '%s' "$bin" | tr -d "\"'")
  REST=" $seg "

  # --- credential-directory writes (any binary) --------------------------------
  if printf '%s' "$REST" | grep -qE '(~|\$HOME|\$\{HOME\}|/Users/[^/ ]+|/home/[^/ ]+)/(\.ssh|\.aws|\.claude/\.credentials\.json)'; then
    case "$bin" in
      cp | mv | tee | dd | install | truncate | chown | chmod | rm | shred | ln | sed | ssh-keygen | ssh-add | openssl | security | aws | rsync | curl | wget)
        block "write to a credential directory (~/.ssh, ~/.aws, ~/.claude/.credentials.json)"
        ;;
    esac
    if printf '%s' "$REST" | grep -qE '>>?[[:space:]]*[\"'\'']?(~|\$HOME|\$\{HOME\}|/Users/[^/ ]+|/home/[^/ ]+)/(\.ssh|\.aws|\.claude)'; then
      block "shell redirect into a credential directory (~/.ssh, ~/.aws, ~/.claude)"
    fi
  fi

  case "$bin" in
    git)
      if m '(^| )push( |$)'; then
        if m '(^| )(-f|--force|--force-with-lease(=[^ ]*)?|--force-if-includes)( |$)'; then
          block "force push (git push --force / -f / --force-with-lease) rewrites published history"
        fi
        if m '(^| )(--delete|-d)( |$)'; then
          block "remote branch deletion (git push --delete)"
        fi
        if m '(^| )\+[^ ]*:[^ ]*( |$)'; then
          block "force push via a + refspec (git push origin +branch)"
        fi
        if m '(^| ):[A-Za-z0-9_./-]+( |$)'; then
          block "remote branch deletion via a colon refspec (git push origin :branch)"
        fi
      fi
      if m '(^| )reset( |$)' && m '(^| )--hard( |$)'; then
        block "git reset --hard discards committed and working-tree state irreversibly"
      fi
      if m '(^| )branch( |$)'; then
        if m '(^| )-[a-zA-Z]*D[a-zA-Z]*( |$)'; then
          block "force branch deletion (git branch -D)"
        fi
        if m '(^| )--delete( |$)' && m '(^| )(--force|-f)( |$)'; then
          block "force branch deletion (git branch --delete --force)"
        fi
      fi
      if m '(^| )clean( |$)' && m '(^| )-[a-zA-Z]*[fx][a-zA-Z]*( |$)'; then
        warn "git clean removes untracked files"
      fi
      if m '(^| )filter-branch( |$)' || m '(^| )filter-repo( |$)'; then
        block "history rewrite (git filter-branch / filter-repo)"
      fi
      ;;
    rm)
      check_rm "$seg"
      ;;
    npm | pnpm | yarn | bun)
      if m '(^| )publish( |$)'; then
        block "package publish ($bin publish) is an irreversible outbound action"
      fi
      ;;
    cargo | gem | pod | melos)
      if m '(^| )(publish|push)( |$)'; then
        block "package publish ($bin) is an irreversible outbound action"
      fi
      ;;
    twine)
      if m '(^| )upload( |$)'; then
        block "package publish (twine upload) is an irreversible outbound action"
      fi
      ;;
    flutter | dart)
      if m '(^| )pub( |$)' && m '(^| )publish( |$)'; then
        block "package publish ($bin pub publish) is an irreversible outbound action"
      fi
      ;;
    gh)
      if m '(^| )repo( |$)' && m '(^| )(delete|archive|rename|transfer)( |$)'; then
        block "destructive GitHub repository operation (gh repo delete/archive/rename/transfer)"
      fi
      if m '(^| )release( |$)' && m '(^| )(create|delete|upload|edit)( |$)'; then
        block "GitHub release publish/modify (gh release create/delete/upload/edit) is an irreversible outbound action"
      fi
      if m '(^| )secret( |$)' && m '(^| )(set|delete)( |$)'; then
        block "GitHub secret write (gh secret set/delete)"
      fi
      ;;
    aws)
      # writes ~/.aws/credentials without ever naming the path
      if m '(^| )configure( |$)' && m '(^| )set( |$)'; then
        block "aws configure set writes credentials into ~/.aws"
      fi
      ;;
    chmod)
      if m '(^| )(-R|-r|--recursive)( |$)' && m '(^| )0?777( |$)'; then
        block "chmod -R 777 makes a tree world-writable"
      fi
      if m '(^| )0?777( |$)'; then
        warn "chmod 777 makes a path world-writable"
      fi
      ;;
  esac
}

# ---------------------------------------------------------------- drive

# Split on shell separators. Anchoring every check to a segment's own command name
# is what keeps `grep "git push --force" docs/GUARDRAILS.md` from being blocked.
SEGMENTS=$(printf '%s' "$CMD" | tr ';|&' '\n\n\n')
while IFS= read -r SEG; do
  [ -n "$SEG" ] || continue
  check_segment "$SEG"
done <<EOF
$SEGMENTS
EOF

# Whole-command heuristics (non-blocking).
if printf '%s' "$CMD" | grep -qE '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|k|d)?sh( |$)'; then
  warn "pipe-to-shell install (curl or wget piped into a shell)"
fi

if [ -n "$WARNINGS" ]; then
  log "WARN [$WARNINGS] :: $CMD"
  printf '{"systemMessage":"hyperbuild guardrail (allowed, noted):%s"}\n' "$WARNINGS"
  exit 0
fi

log "ALLOW :: $CMD"
exit 0

#!/usr/bin/env bash
#
# gate-ship.sh — hyperbuild Gate 2 (step 16), the DETERMINISTIC half.
#
# Runs ONLY Tier-0 checks: artifact state, referential integrity, git facts,
# credential patterns, dependency resolution. It deliberately does NOT run the
# test suite, the linter, the build, or the generated-skill script gates — those
# need the platform commands step 13 recorded in scaffold.md, and hb-gate-verifier
# executes them with their exit codes as evidence. Everything else that used to
# be a model reading a prose checklist is decided here, in code the build agents
# cannot edit.
#
# THIS FILE IS THE ORACLE. It lives in scripts/ at the repo root, OUTSIDE every
# agent's write path: no pipeline step, no subagent, and no generated skill may
# write to scripts/**. A build agent that can edit its own gate has no gate.
#
# Usage:
#   scripts/gate-ship.sh <run_tag> [--root <repo_root>]
#                                  [--app <app_dir>]        (default: app)
#                                  [--json-out <path>]
#
# Output: one PASS/WARN/FAIL/SKIP line per check on stdout (sorted by check id),
#         then the marker ===JSON=== followed by a machine-readable summary in
#         the canonical gate-verdict schema.
#
# Exit:   0 = every HARD check passed (warns allowed)
#         1 = at least one HARD check FAILED
#         2 = usage error / run_tag not found / no python3
#
# Severity policy — deliberate, and mirrored in hyperbuild-16-ship-gate:
#   FAIL  a task not done; a dangling path in a task's files:; a frozen gate
#         script whose hash no longer matches the manifest; a dirty working
#         tree; a missing wave/epic commit; a high-confidence credential; a
#         tracked .env; a declared dependency absent from the lockfile; any
#         break in the feature -> task -> files -> tests chain.
#   WARN  heuristic secret hits (the FP-prone generic patterns), a missing
#         lockfile, an unrecorded freeze (the freeze mechanism has not run for
#         this run), an unrecognised platform manifest. A WARN never blocks; it
#         is printed in the ship report.
#
# Nothing in this script writes to any pipeline-owned path, and every git
# command it runs is read-only. It is safe to run at any time.

set -euo pipefail

GATE="ship"
# Absolute BEFORE any cd: this script cd's to --root, and a relative $0 would
# dangle from there. A dangling $0 used to kill the gate silently (shasum fails
# -> pipefail -> set -e), producing zero output and exit 1 — indistinguishable
# from a real gate failure. Resolve it once, here.
SCRIPT_PATH="$0"
case "$SCRIPT_PATH" in
  /*) ;;
  *)  SCRIPT_PATH="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd)/$(basename "$0")" ;;
esac
RUN_TAG=""
ROOT=""
APP_DIR="app"
JSON_OUT=""

usage() {
  sed -n '3,46p' "$SCRIPT_PATH" | sed 's/^# \{0,1\}//'
  exit 2
}

# ---------------------------------------------------------------- args -------
[ $# -ge 1 ] || usage
RUN_TAG="${1:-}"
case "$RUN_TAG" in -*|"") usage ;; esac
shift
while [ $# -gt 0 ]; do
  case "$1" in
    --root)     ROOT="${2:-}"; shift 2 ;;
    --app)      APP_DIR="${2:-}"; shift 2 ;;
    --json-out) JSON_OUT="${2:-}"; shift 2 ;;
    -h|--help)  usage ;;
    *) printf 'gate-ship.sh: unknown argument: %s\n' "$1" >&2; usage ;;
  esac
done

if [ -z "$ROOT" ]; then
  ROOT="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
else
  ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || {
    printf 'gate-ship.sh: --root does not exist\n' >&2; exit 2; }
fi

command -v python3 >/dev/null 2>&1 || {
  printf 'FAIL  env-python3            python3 is required to run this gate\n' >&2
  exit 2; }

cd "$ROOT"

RUN_DIR="runs/$RUN_TAG"
if [ ! -d "$RUN_DIR" ]; then
  printf 'gate-ship.sh: no such run: %s (looked in %s/runs/)\n' "$RUN_TAG" "$ROOT" >&2
  exit 2
fi

TMPD="$(mktemp -d "${TMPDIR:-/tmp}/hb-gate-ship.XXXXXX")"
trap 'rm -rf "$TMPD"' EXIT INT TERM
RESULTS="$TMPD/results"
: > "$RESULTS"

FAILED=0
WARNED=0
SKIPPED=0
US=$'\037'

# Results are buffered and rendered in check-id order at the end, so the ship
# report is deterministic regardless of the order the checks ran in.
record() { # record <id> <result> <description> <evidence>
  local id="$1" res="$2" desc="$3" ev="$4"
  ev="$(printf '%s' "$ev" | tr '\n\r\t\037' '    ')"
  printf '%s\n%s\n%s\n%s\n' "$id" "$res" "$desc" "$ev" >> "$RESULTS"
  case "$res" in
    pass) ;;
    warn) WARNED=$((WARNED+1)) ;;
    skip) SKIPPED=$((SKIPPED+1)) ;;
    *)    FAILED=$((FAILED+1)) ;;
  esac
}

# Never allowed to fail the script: the gate's own hash is evidence, not a check.
# Every branch ends in `|| true` so a missing binary or an unreadable file
# degrades to "unavailable" instead of tripping set -e / pipefail.
sha256_of() {
  local out=""
  if command -v shasum >/dev/null 2>&1; then
    out="$(shasum -a 256 "$1" 2>/dev/null | awk '{print $1}' || true)"
  elif command -v sha256sum >/dev/null 2>&1; then
    out="$(sha256sum "$1" 2>/dev/null | awk '{print $1}' || true)"
  fi
  [ -n "$out" ] || out="unavailable"
  printf '%s' "$out"
}

trim() { printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'; }

# =============================================================================
# S01–S04 — git facts about app/. Read-only commands only.
# =============================================================================
IS_REPO=0
if [ ! -d "$APP_DIR" ]; then
  record S01 fail "app/ exists and is a git repo" "$APP_DIR/ does not exist — nothing was built"
elif ! command -v git >/dev/null 2>&1; then
  record S01 fail "app/ exists and is a git repo" "git is not installed; principle 9's audit trail cannot be verified"
elif git -C "$APP_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ncommits="$(git -C "$APP_DIR" rev-list --count HEAD 2>/dev/null || echo 0)"
  IS_REPO=1
  record S01 pass "app/ exists and is a git repo" "$APP_DIR is a git work tree with $ncommits commit(s)"
else
  record S01 fail "app/ exists and is a git repo" "$APP_DIR/ is not a git repository — step 13 never ran git init"
fi

if [ "$IS_REPO" -eq 1 ]; then
  porcelain="$(git -C "$APP_DIR" status --porcelain 2>/dev/null || true)"
  if [ -z "$porcelain" ]; then
    record S02 pass "app/ working tree clean" "git -C $APP_DIR status --porcelain -> empty"
  else
    dirty_n="$(printf '%s\n' "$porcelain" | grep -c . || true)"
    record S02 fail "app/ working tree clean" "git -C $APP_DIR status --porcelain -> $dirty_n dirty path(s): $(printf '%s' "$porcelain" | head -8 | tr '\n' ' ')"
  fi

  git -C "$APP_DIR" log --oneline > "$TMPD/gitlog.txt" 2>/dev/null || : > "$TMPD/gitlog.txt"
  logn="$(grep -c . "$TMPD/gitlog.txt" || true)"
  if grep -qi 'scaffold' "$TMPD/gitlog.txt"; then
    record S03 pass "scaffold commit present" "git log shows a scaffold commit ($logn commits total)"
  elif [ "${logn:-0}" -gt 0 ]; then
    record S03 warn "scaffold commit present" "no commit message matches /scaffold/i; $logn commits exist — step 13's initial commit may be worded differently"
  else
    record S03 fail "scaffold commit present" "git -C $APP_DIR log is empty — no commit history at all"
  fi

  # Expected commit shapes: one `wave <N>:` commit per live wave-log entry, and
  # one `epic <NN>: critic pass` commit per epic whose patch log applied hunks.
  wave_missing=""; wave_expected=0
  WAVE_LOG="$RUN_DIR/temp/wave-log.md"
  if [ -f "$WAVE_LOG" ]; then
    while IFS= read -r line; do
      case "$line" in
        wave\ *|"- wave "*|"* wave "*) ;;
        *) continue ;;
      esac
      printf '%s' "$line" | grep -qi 'DEAD' && continue
      wn="$(printf '%s' "$line" | sed -n 's/^[^0-9]*wave[[:space:]]*\([0-9][0-9]*\).*$/\1/p')"
      [ -n "$wn" ] || continue
      wave_expected=$((wave_expected+1))
      grep -q "wave $wn:" "$TMPD/gitlog.txt" || wave_missing="$wave_missing wave-$wn"
    done < "$WAVE_LOG"
  fi
  epic_missing=""; epic_expected=0
  for pl in "$RUN_DIR"/temp/epic-*-patch-log.json; do
    [ -f "$pl" ] || continue
    en="$(basename "$pl" | sed -n 's/^epic-\([0-9][0-9]*\)-patch-log\.json$/\1/p')"
    [ -n "$en" ] || continue
    applied="$(python3 - "$pl" <<'PY' 2>/dev/null || echo 0
import json,sys
try:
    d = json.load(open(sys.argv[1]))
    print(len(d.get("applied") or []))
except Exception:
    print(0)
PY
)"
    [ "${applied:-0}" -gt 0 ] || continue
    epic_expected=$((epic_expected+1))
    grep -qi "epic $en: critic pass" "$TMPD/gitlog.txt" || epic_missing="$epic_missing epic-$en"
  done
  if [ -n "$wave_missing$epic_missing" ]; then
    record S04 fail "wave/epic commit shapes" "missing commits:$wave_missing$epic_missing (expected $wave_expected wave commit(s), $epic_expected epic critic-pass commit(s))"
  elif [ "$wave_expected" -eq 0 ] && [ ! -f "$WAVE_LOG" ]; then
    record S04 warn "wave/epic commit shapes" "$WAVE_LOG absent — step 14's wave ledger is the crash-resume mechanism and should exist"
  else
    record S04 pass "wave/epic commit shapes" "$wave_expected live wave commit(s) + $epic_expected epic critic-pass commit(s) all present in git log"
  fi
else
  record S02 fail "app/ working tree clean" "not a git repo — cannot check"
  record S03 fail "scaffold commit present" "not a git repo — cannot check"
  record S04 fail "wave/epic commit shapes" "not a git repo — cannot check"
fi

# S15 — the calibrated-uncertainty section of the ship report.
# Same ordering caveat as gate-design.sh's D27: this script runs at step 16 item 2 and the
# report is written at item 9, so round 1 records `skip`. From round 2 on, and on any
# re-run of a finished gate, the check is hard. PIPELINE.md Gate 2 is the binding rule.
SHIP_REPORT="$RUN_DIR/gates/ship-report.md"
if [ -f "$SHIP_REPORT" ]; then
  if grep -q '^## What I am least confident about[[:space:]]*$' "$SHIP_REPORT"; then
    lc_entries=$(awk '
      /^## What I am least confident about[[:space:]]*$/ { f=1; next }
      f && /^## / { f=0 }
      f && /^[[:space:]]*[-*][[:space:]]+[^[:space:]]/ { n++ }
      END { print n+0 }' "$SHIP_REPORT")
    if [ "$lc_entries" -ge 3 ]; then
      record S15 pass "calibrated uncertainty section" "ship-report.md '## What I am least confident about': $lc_entries entries"
    elif [ "$lc_entries" -gt 0 ]; then
      record S15 fail "calibrated uncertainty section" "ship-report.md '## What I am least confident about' has only $lc_entries entr(y|ies); the contract is 3-6, each naming a file, test or check"
    else
      record S15 fail "calibrated uncertainty section" "ship-report.md '## What I am least confident about' is present but EMPTY — a heading with no entries is worse than no heading"
    fi
  else
    record S15 fail "calibrated uncertainty section" "ship-report.md exists but carries no '## What I am least confident about' section (mandatory on PASSED AND BLOCKED — PIPELINE.md Gate 2)"
  fi
else
  record S15 skip "calibrated uncertainty section" "no ship-report.md yet — this script runs at step 16 item 2, the report at item 9; enforced on every later round and by step 16's exit criteria"
fi

# =============================================================================
# S10/S11 — credential scan over app/. Tracked files only when app/ is a repo
# (an untracked local .env is the developer's business; a committed one is not).
# =============================================================================
: > "$TMPD/scanfiles.txt"
if [ -d "$APP_DIR" ]; then
  if [ "$IS_REPO" -eq 1 ]; then
    git -C "$APP_DIR" ls-files -z 2>/dev/null | tr '\0' '\n' | sed "s|^|$APP_DIR/|" > "$TMPD/scanfiles.txt" || true
  else
    find "$APP_DIR" -type d \( -name node_modules -o -name .git -o -name build -o -name .dart_tool \
      -o -name Pods -o -name .venv -o -name dist -o -name target \) -prune -o -type f -print \
      > "$TMPD/scanfiles.txt" 2>/dev/null || true
  fi
fi
scan_n="$(grep -c . "$TMPD/scanfiles.txt" || true)"

STRONG_PAT='(AKIA|ASIA)[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{28,}|xox[abprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|sk_live_[0-9a-zA-Z]{16,}|glpat-[0-9A-Za-z_-]{20,}'
HEUR_PAT='(api[_-]?key|secret|passwd|password|access[_-]?token|private[_-]?key|client[_-]?secret)["'"'"' ]*[:=][ ]*["'"'"'][^"'"'"']{12,}["'"'"']'

if [ "${scan_n:-0}" -eq 0 ]; then
  record S10 fail "secret scan (high confidence)" "no files to scan under $APP_DIR/ — the app is empty or untracked"
  record S11 skip "secret scan (heuristic)" "no files to scan"
else
  : > "$TMPD/strong.txt"; : > "$TMPD/heur.txt"
  # Batched through xargs rather than one grep per file: the ship gate re-runs
  # every fix round, and 2 process spawns per tracked file costs seconds on a
  # real app for nothing. -H forces the filename prefix even on a single-file
  # chunk, so the output shape is file:line:text either way; -I skips binaries.
  # xargs exits 123 when a chunk's grep matched nothing — never a scan failure.
  tr '\n' '\0' < "$TMPD/scanfiles.txt" \
    | xargs -0 grep -IHnE "$STRONG_PAT" 2>/dev/null > "$TMPD/strong.txt" || true
  tr '\n' '\0' < "$TMPD/scanfiles.txt" \
    | xargs -0 grep -IHnE "$HEUR_PAT" 2>/dev/null > "$TMPD/heur.txt" || true
  strong_n="$(grep -c . "$TMPD/strong.txt" || true)"
  heur_n="$(grep -c . "$TMPD/heur.txt" || true)"
  if [ "${strong_n:-0}" -gt 0 ]; then
    record S10 fail "secret scan (high confidence)" "$strong_n credential-shaped hit(s) in $scan_n scanned files: $(head -4 "$TMPD/strong.txt" | cut -c1-160 | tr '\n' ' ')"
  else
    record S10 pass "secret scan (high confidence)" "$scan_n files scanned; zero AWS keys, private-key headers, GitHub/Slack/Google/Stripe/GitLab tokens"
  fi
  if [ "${heur_n:-0}" -gt 0 ]; then
    record S11 warn "secret scan (heuristic)" "$heur_n assignment-shaped hit(s) — review, most are fixtures/config keys: $(head -4 "$TMPD/heur.txt" | cut -c1-140 | tr '\n' ' ')"
  else
    record S11 pass "secret scan (heuristic)" "$scan_n files scanned; no <secret-ish name> = <long literal> assignments"
  fi
fi

# .env committed
env_hits="$(grep -E '(^|/)\.env(\.|$)' "$TMPD/scanfiles.txt" 2>/dev/null | grep -vE '\.env\.(example|sample|template|dist)$' || true)"
if [ "${scan_n:-0}" -eq 0 ]; then
  record S12 skip "no .env committed" "no files to scan"
elif [ -n "$env_hits" ]; then
  record S12 fail "no .env committed" "environment file(s) committed to $APP_DIR: $(printf '%s' "$env_hits" | head -5 | tr '\n' ' ')"
else
  record S12 pass "no .env committed" "no tracked .env file (only .env.example-style templates are allowed)"
fi

# =============================================================================
# Structural checks in python3: task state, files: integrity, the frozen-oracle
# hashes, the traceability chain, epic acceptance, and dependency resolution.
# =============================================================================
PY_OUT="$TMPD/py.out"
PY_ERR="$TMPD/py.err"
set +e
python3 - "$ROOT" "$RUN_TAG" "$APP_DIR" > "$PY_OUT" 2> "$PY_ERR" <<'PYEOF'
import hashlib, json, os, re, sys

ROOT, RUN_TAG, APP = sys.argv[1], sys.argv[2], sys.argv[3]
US = "\x1f"
RUN = os.path.join("runs", RUN_TAG)
OUT = []


def rec(cid, result, desc, evidence):
    ev = str(evidence).replace("\n", " ").replace("\r", " ").replace(US, " ")
    OUT.append(US.join([cid, result, desc, ev]))


def run(cid, desc, fn):
    try:
        fn(cid, desc)
    except Exception as exc:
        rec(cid, "fail", desc, "checker error: %s: %s" % (type(exc).__name__, exc))


def read(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            return fh.read()
    except OSError:
        return None


def listdir(path, suffix=None):
    try:
        names = sorted(os.listdir(path))
    except OSError:
        return []
    if suffix:
        names = [n for n in names if n.endswith(suffix)]
    return names


def frontmatter(path):
    txt = read(path)
    if txt is None:
        return None
    lines = txt.split("\n")
    if not lines or lines[0].strip() != "---":
        return None
    fm, key, closed = {}, None, False
    for line in lines[1:]:
        if line.strip() == "---":
            closed = True
            break
        m = re.match(r"^([A-Za-z0-9_.-]+):\s*(.*)$", line)
        if m:
            key = m.group(1)
            val = m.group(2).strip()
            fm[key] = [] if val == "" else val
            continue
        m = re.match(r"^\s*-\s+(.*)$", line)
        if m and key is not None:
            if not isinstance(fm.get(key), list):
                fm[key] = []
            fm[key].append(m.group(1).strip())
    return fm if closed else None


def as_list(value):
    if value is None:
        return []
    if isinstance(value, list):
        items = value
    else:
        s = value.strip()
        if s in ("[]", "", "-", "none", "None", "null"):
            return []
        if s.startswith("[") and s.endswith("]"):
            s = s[1:-1]
        items = s.split(",")
    out = []
    for it in items:
        it = str(it).strip().strip('"').strip("'").strip()
        if it:
            out.append(it)
    return out


def scalar(value):
    if isinstance(value, list):
        return ""
    return (value or "").strip().strip('"').strip("'")


def sample(items, n=6):
    items = list(items)
    return ", ".join(items[:n]) + ("" if len(items) <= n else " (+%d more)" % (len(items) - n))


MOSCOW_MS = ("must", "should")
TEST_HINTS = ("/test/", "/tests/", "_test.", ".test.", ".spec.", "test_", "Tests.swift", "Test.kt", "Spec.")


def epic_dirs():
    out = []
    for name in listdir("epics"):
        d = os.path.join("epics", name)
        if os.path.isdir(d) and re.match(r"^\d+-", name):
            out.append(d)
    return out


def task_paths():
    out = []
    for d in epic_dirs():
        for name in listdir(d, ".md"):
            if name.startswith("task-"):
                out.append(os.path.join(d, name))
    return out


TASKS = dict((p, frontmatter(p)) for p in task_paths())


def feature_files():
    out = []
    for name in listdir("features", ".md"):
        if name in ("00-index.md", "README.md"):
            continue
        if re.match(r"^\d+-", name):
            out.append(os.path.join("features", name))
    return out


def feature_index_rows():
    txt = read(os.path.join("features", "00-index.md")) or ""
    rows = []
    for line in txt.split("\n"):
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not cells:
            continue
        m = re.match(r"^(F-\d+)$", cells[0].strip("` "))
        if not m:
            continue
        moscow = ""
        for c in cells[1:]:
            if c.strip().lower() in ("must", "should", "could", "wont", "won't"):
                moscow = c.strip().lower()
                break
        rows.append((m.group(1), moscow))
    return rows


# ------------------------------------------------------------------ S05 ------
def c_tasks_done(cid, desc):
    if not TASKS:
        rec(cid, "fail", desc, "no epics/*/task-*.md files found — there is no backlog to ship")
        return
    bad = []
    for p, fm in sorted(TASKS.items()):
        st = scalar((fm or {}).get("status")).lower()
        if st != "done":
            bad.append("%s (%s)" % (p, st or "<no frontmatter>"))
    if bad:
        rec(cid, "fail", desc, "%d of %d tasks are not status: done: %s" % (len(bad), len(TASKS), sample(bad, 8)))
    else:
        rec(cid, "pass", desc, "all %d task files are status: done" % len(TASKS))


# ------------------------------------------------------------------ S06 ------
def c_task_files_exist(cid, desc):
    if not TASKS:
        rec(cid, "fail", desc, "no task files found")
        return
    dangling, empty, outside, total = [], [], [], 0
    app_prefix = os.path.normpath(APP) + os.sep
    for p, fm in sorted(TASKS.items()):
        paths = as_list((fm or {}).get("files"))
        if not paths:
            empty.append(p)
            continue
        tid = scalar((fm or {}).get("id")) or p
        for rel in paths:
            total += 1
            if not os.path.exists(rel):
                dangling.append("%s -> %s" % (tid, rel))
            elif not os.path.normpath(rel).startswith(app_prefix):
                # A build task's files: should land in the app. Some legitimately
                # do not (step 13 updates .claude/skills/app-components/SKILL.md),
                # so this is reported, never blocking — see the severity policy.
                outside.append("%s -> %s" % (tid, rel))
    problems = []
    if empty:
        problems.append("%d task(s) declare an empty files: list: %s" % (len(empty), sample(empty, 4)))
    if dangling:
        problems.append("%d declared path(s) do not exist on disk: %s" % (len(dangling), sample(dangling, 8)))
    if problems:
        rec(cid, "fail", desc, "; ".join(problems))
    elif outside:
        rec(cid, "warn", desc, "all %d declared paths exist, but %d resolve OUTSIDE %s/ — confirm each is a "
                               "deliberate harness edit and not a task that never touched the app: %s"
            % (total, len(outside), os.path.normpath(APP), sample(outside, 6)))
    else:
        rec(cid, "pass", desc, "all %d paths declared across %d tasks exist on disk under %s/"
            % (total, len(TASKS), os.path.normpath(APP)))


# ------------------------------------------------------------------ S07 ------
def c_epic_acceptance(cid, desc):
    dirs = epic_dirs()
    if not dirs:
        rec(cid, "fail", desc, "no epic directories found")
        return
    unchecked, total = [], 0
    for d in dirs:
        p = os.path.join(d, "epic.md")
        txt = read(p)
        if txt is None:
            unchecked.append("%s missing" % p)
            continue
        in_ac = False
        for line in txt.split("\n"):
            if re.match(r"^##\s+", line):
                in_ac = bool(re.match(r"^##\s+acceptance criteria", line.strip(), re.I))
                continue
            if not in_ac:
                continue
            m = re.match(r"^\s*[-*]\s+\[( |x|X)\]\s*(.*)$", line)
            if m:
                total += 1
                if m.group(1) == " ":
                    unchecked.append("%s: %s" % (p, m.group(2)[:60]))
    if total == 0:
        rec(cid, "fail", desc, "no acceptance-criteria checkboxes found under any epic's '## Acceptance criteria'")
    elif unchecked:
        rec(cid, "fail", desc, "%d of %d acceptance criteria are unchecked: %s" % (len(unchecked), total, sample(unchecked, 6)))
    else:
        rec(cid, "pass", desc, "all %d acceptance criteria across %d epics are checked off" % (total, len(dirs)))


# ------------------------------------------------------------------ S08 ------
def c_feature_status(cid, desc):
    rows = feature_index_rows()
    if not rows:
        rec(cid, "fail", desc, "features/00-index.md has no parseable feature rows")
        return
    by_id = {}
    for path in feature_files():
        fm = frontmatter(path) or {}
        fid = scalar(fm.get("id"))
        if fid:
            by_id[fid] = (path, scalar(fm.get("status")).lower())
    bad = []
    ms = [fid for fid, mo in rows if mo in MOSCOW_MS]
    for fid in ms:
        if fid not in by_id:
            bad.append("%s has no spec file" % fid)
        elif by_id[fid][1] != "implemented":
            bad.append("%s is status: %s" % (fid, by_id[fid][1] or "<absent>"))
    if bad:
        rec(cid, "fail", desc, "%d of %d must/should features are not implemented: %s" % (len(bad), len(ms), sample(bad, 8)))
    else:
        rec(cid, "pass", desc, "all %d must/should features are status: implemented" % len(ms))


# ------------------------------------------------------------------ S09 ------
def c_traceability(cid, desc):
    rows = feature_index_rows()
    if not rows:
        rec(cid, "fail", desc, "features/00-index.md has no parseable feature rows — the chain has no starting set")
        return
    specs = {}
    for path in feature_files():
        fm = frontmatter(path) or {}
        fid = scalar(fm.get("id"))
        if fid:
            specs[fid] = path
    citing = {}
    for p, fm in TASKS.items():
        for fid in as_list((fm or {}).get("features")):
            citing.setdefault(fid, []).append(p)
    breaks, intact = [], 0
    ms = [fid for fid, mo in rows if mo in MOSCOW_MS]
    for fid in ms:
        if fid not in specs:
            breaks.append("%s: no features/NN-*.md" % fid)
            continue
        tasks = citing.get(fid) or []
        if not tasks:
            breaks.append("%s: no task cites it" % fid)
            continue
        not_done = [p for p in tasks if scalar((TASKS.get(p) or {}).get("status")).lower() != "done"]
        if not_done:
            breaks.append("%s: citing task not done (%s)" % (fid, sample(not_done, 2)))
            continue
        missing_paths, test_paths = [], []
        for p in tasks:
            for rel in as_list((TASKS.get(p) or {}).get("files")):
                if not os.path.exists(rel):
                    missing_paths.append(rel)
                if any(h in rel for h in TEST_HINTS):
                    test_paths.append(rel)
        if missing_paths:
            breaks.append("%s: files: path missing from disk (%s)" % (fid, sample(missing_paths, 2)))
            continue
        if not test_paths:
            breaks.append("%s: no test file among its tasks' files: lists" % fid)
            continue
        missing_tests = [t for t in test_paths if not os.path.exists(t)]
        if missing_tests:
            breaks.append("%s: declared test missing (%s)" % (fid, sample(missing_tests, 2)))
            continue
        intact += 1
    if breaks:
        rec(cid, "fail", desc, "%d/%d chains intact; breaks: %s" % (intact, len(ms), sample(breaks, 6)))
    else:
        rec(cid, "pass", desc, "%d/%d must/should chains walk feature -> spec -> done task(s) -> files on disk -> test file" % (intact, len(ms)))


# ------------------------------------------------------------------ S13 ------
def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        while True:
            chunk = fh.read(65536)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def c_frozen_scripts(cid, desc):
    """The oracle-freeze check. Step 12.1b copies every generated skill's
    scripts/*.sh to runs/<tag>/gates/skill-scripts/<skill>/<script>.sh and
    records freeze-root-relative key -> SHA-256 in manifest `frozen_gates`.
    Steps 14/16 execute ONLY the frozen copies. This is the script-side
    confirmation of the same three-set walk the ship gate's check 10 runs: the
    frozen set, the manifest record, and the live originals must agree.
    A hash that moved means the build side edited the gate that grades it."""
    manifest_path = os.path.join(RUN, "manifest.json")
    try:
        manifest = json.load(open(manifest_path, encoding="utf-8"))
    except Exception as exc:
        rec(cid, "fail", desc, "%s unreadable: %s" % (manifest_path, exc))
        return
    hashes = None
    for key in ("frozen_gates", "frozen_skill_scripts", "skill_script_hashes", "gate_script_hashes"):
        v = manifest.get(key)
        if isinstance(v, dict) and v:
            hashes = dict(v)
            break
        if isinstance(v, list) and v:
            built = {}
            for item in v:
                if isinstance(item, dict) and item.get("path"):
                    built[item["path"]] = item.get("sha256") or item.get("hash") or ""
            if built:
                hashes = built
                break
    frozen_root = os.path.join(RUN, "gates", "skill-scripts")
    # live set, keyed exactly like the freeze: "<skill>/<script>.sh"
    live = {}
    for name in listdir(os.path.join(".claude", "skills")):
        sdir = os.path.join(".claude", "skills", name, "scripts")
        if name.startswith("app-") and os.path.isdir(sdir):
            for s in listdir(sdir, ".sh"):
                live["%s/%s" % (name, s)] = os.path.join(sdir, s)
    # frozen set on disk
    frozen = {}
    for dirpath, _d, filenames in os.walk(frozen_root):
        for f in sorted(filenames):
            if f.endswith(".sh"):
                p = os.path.join(dirpath, f)
                frozen[os.path.relpath(p, frozen_root)] = p
    if not hashes:
        note = "%d live generated-skill script(s), %d frozen copies on disk" % (len(live), len(frozen))
        rec(cid, "warn", desc, "manifest records no frozen-gate hashes — step 12.1b's freeze has not run for this run, "
                               "so the generated skill gates are still agent-authored AND agent-editable (%s)" % note)
        return
    # a logged, deliberate change to a gate script is legal; a silent one is not
    changelog = read(os.path.join(RUN, "decisions", "gate-changes.md")) or ""

    def logged(key):
        return os.path.basename(key) in changelog or key in changelog

    tamper, diverge, ok = [], [], 0
    for key in sorted(hashes):
        want = str(hashes[key] or "").strip().lower()
        fp = frozen.get(key) or os.path.join(frozen_root, key)
        if not os.path.isfile(fp):
            tamper.append("MISSING %s — frozen copy is gone" % key)
        elif not want:
            tamper.append("UNRECORDED-SHA %s — manifest entry has no sha256" % key)
        elif sha256_file(fp) != want:
            tamper.append("TAMPERED %s — frozen copy no longer matches its recorded sha" % key)
        else:
            ok += 1
    for key in sorted(set(frozen) - set(hashes)):
        tamper.append("UNRECORDED %s — frozen file with no manifest entry" % key)
    for key in sorted(set(live) - set(hashes)):
        diverge.append("LIVE-ADDED %s" % key)
    for key in sorted(set(hashes) - set(live)):
        diverge.append("LIVE-DELETED %s" % key)
    for key in sorted(set(live) & set(hashes)):
        want = str(hashes[key] or "").strip().lower()
        if want and sha256_file(live[key]) != want:
            diverge.append("LIVE-EDITED %s" % key)
    unlogged = [d for d in diverge if not logged(d.split(" ", 1)[1])]
    if tamper:
        rec(cid, "fail", desc, "the frozen oracle was altered: %s" % sample(tamper, 6))
    elif unlogged:
        rec(cid, "fail", desc, "live gate scripts diverged from the freeze with no entry in "
                               "%s/decisions/gate-changes.md: %s" % (RUN, sample(unlogged, 6)))
    elif diverge:
        rec(cid, "warn", desc, "%d live/freeze divergence(s), each accounted for in gate-changes.md: %s"
            % (len(diverge), sample(diverge, 6)))
    else:
        rec(cid, "pass", desc, "%d frozen gate script hash(es) match the manifest AND their live originals" % ok)


# ------------------------------------------------------------------ S14 ------
def c_dependencies(cid, desc):
    """Every declared dependency resolves — i.e. the platform's own manifest
    parses AND every package it declares is pinned in the platform's lockfile.
    A hallucinated package name that was never installed shows up here."""
    checks, problems, warns = [], [], []

    pubspec = os.path.join(APP, "pubspec.yaml")
    if os.path.isfile(pubspec):
        txt = read(pubspec) or ""
        deps, section = [], None
        for line in txt.split("\n"):
            m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*$", line)
            if m:
                section = m.group(1)
                continue
            if section in ("dependencies", "dev_dependencies"):
                m = re.match(r"^  ([A-Za-z_][A-Za-z0-9_]*):", line)
                if m and m.group(1) not in ("sdk", "flutter_test", "flutter"):
                    deps.append(m.group(1))
            elif re.match(r"^\S", line):
                section = None
        if not deps and "dependencies" not in txt:
            problems.append("%s has no dependencies: block — unparseable as a pub manifest" % pubspec)
        lock = os.path.join(APP, "pubspec.lock")
        if not os.path.isfile(lock):
            warns.append("%s exists but %s does not — dependencies were never resolved" % (pubspec, lock))
        else:
            locktxt = read(lock) or ""
            missing = [d for d in deps if not re.search(r"^\s{2}%s:\s*$" % re.escape(d), locktxt, re.M)]
            if missing:
                problems.append("declared in pubspec.yaml but absent from pubspec.lock: %s" % sample(missing, 8))
        checks.append("pubspec.yaml (%d deps)" % len(deps))

    pkg = os.path.join(APP, "package.json")
    if os.path.isfile(pkg):
        try:
            data = json.load(open(pkg, encoding="utf-8"))
        except Exception as exc:
            problems.append("%s is not valid JSON: %s" % (pkg, exc))
            data = None
        if data is not None:
            deps = sorted(list((data.get("dependencies") or {}).keys())
                          + list((data.get("devDependencies") or {}).keys()))
            locks = [os.path.join(APP, n) for n in ("package-lock.json", "yarn.lock", "pnpm-lock.yaml")]
            lock = next((l for l in locks if os.path.isfile(l)), None)
            if not lock:
                warns.append("%s exists but no package-lock.json / yarn.lock / pnpm-lock.yaml" % pkg)
            else:
                locktxt = read(lock) or ""
                missing = [d for d in deps if d not in locktxt]
                if missing:
                    problems.append("declared in package.json but absent from %s: %s"
                                    % (os.path.basename(lock), sample(missing, 8)))
            checks.append("package.json (%d deps)" % len(deps))

    cargo = os.path.join(APP, "Cargo.toml")
    if os.path.isfile(cargo):
        txt = read(cargo) or ""
        deps, section = [], None
        for line in txt.split("\n"):
            m = re.match(r"^\[([^\]]+)\]\s*$", line)
            if m:
                section = m.group(1)
                continue
            if section and "dependencies" in section:
                m = re.match(r"^([A-Za-z0-9_-]+)\s*=", line)
                if m:
                    deps.append(m.group(1))
        lock = os.path.join(APP, "Cargo.lock")
        if not os.path.isfile(lock):
            warns.append("%s exists but Cargo.lock does not" % cargo)
        else:
            locktxt = read(lock) or ""
            missing = [d for d in deps if ('name = "%s"' % d) not in locktxt]
            if missing:
                problems.append("declared in Cargo.toml but absent from Cargo.lock: %s" % sample(missing, 8))
        checks.append("Cargo.toml (%d deps)" % len(deps))

    podfile = os.path.join(APP, "Podfile")
    if os.path.isfile(podfile):
        pods = re.findall(r"^\s*pod\s+['\"]([^'\"]+)['\"]", read(podfile) or "", re.M)
        lock = os.path.join(APP, "Podfile.lock")
        if not os.path.isfile(lock):
            warns.append("Podfile exists but Podfile.lock does not")
        else:
            locktxt = read(lock) or ""
            missing = [p for p in pods if p.split("/")[0] not in locktxt]
            if missing:
                problems.append("declared in Podfile but absent from Podfile.lock: %s" % sample(missing, 6))
        checks.append("Podfile (%d pods)" % len(pods))

    if not checks:
        rec(cid, "skip", desc, "no parseable platform manifest under %s/ (pubspec.yaml, package.json, Cargo.toml, Podfile) — nothing to resolve" % APP)
    elif problems:
        rec(cid, "fail", desc, "; ".join(problems[:6]) + " [%s]" % ", ".join(checks))
    elif warns:
        rec(cid, "warn", desc, "; ".join(warns[:4]) + " [%s]" % ", ".join(checks))
    else:
        rec(cid, "pass", desc, "every declared dependency is pinned in its lockfile: %s" % ", ".join(checks))


run("S05", "every task status: done", c_tasks_done)
run("S06", "no dangling paths in task files:", c_task_files_exist)
run("S07", "epic acceptance criteria checked", c_epic_acceptance)
run("S08", "must/should features implemented", c_feature_status)
run("S09", "traceability chain feature->task->files->tests", c_traceability)
run("S13", "frozen gate script hashes match manifest", c_frozen_scripts)
run("S14", "declared dependencies resolve", c_dependencies)

sys.stdout.write("\n".join(OUT) + ("\n" if OUT else ""))
PYEOF
PY_STATUS=$?
set -e

if [ "$PY_STATUS" -ne 0 ]; then
  record "S00" fail "structural checker" "python3 checker exited $PY_STATUS: $(tail -3 "$PY_ERR" 2>/dev/null | tr '\n' ' ')"
fi

while IFS="$US" read -r cid cres cdesc cev; do
  [ -n "${cid:-}" ] || continue
  record "$cid" "$cres" "$cdesc" "$cev"
done < "$PY_OUT"

# --------------------------------------------------------------- summary -----
OVERALL="pass"
[ "$FAILED" -eq 0 ] || OVERALL="fail"
SELF_SHA="$(sha256_of "$SCRIPT_PATH")"

python3 - "$RESULTS" "$GATE" "$RUN_TAG" "" "$SELF_SHA" "$OVERALL" "$FAILED" "$WARNED" "$SKIPPED" "${JSON_OUT:-}" <<'PY'
import json, sys, os, time
results, gate, run_tag, gear, sha, overall, failed, warned, skipped, out_path = sys.argv[1:11]
checks = []
with open(results, encoding="utf-8") as fh:
    lines = fh.read().split("\n")
for i in range(0, len(lines) - 3, 4):
    cid, res, desc, ev = lines[i], lines[i + 1], lines[i + 2], lines[i + 3]
    if not cid:
        continue
    checks.append({"id": cid, "description": desc, "result": res, "evidence": ev})
checks.sort(key=lambda c: c["id"])
for c in checks:
    label = {"pass": "PASS", "warn": "WARN", "skip": "SKIP"}.get(c["result"], "FAIL")
    line = "%-5s %-6s %s" % (label, c["id"], c["description"])
    if c["result"] != "pass" and c["evidence"]:
        line += " — " + c["evidence"]
    print(line)
print("")
print("gate-%s: %s — %s failed, %s warned, %s skipped" % (gate, overall, failed, warned, skipped))
print("===JSON===")
doc = {
    "gate": gate,
    "run_tag": run_tag,
    "source": "scripts/gate-%s.sh" % gate,
    "script_sha256": sha,
    "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "tier": "0",
    "checks": checks,
    "overall": overall,
    "failed": int(failed),
    "warned": int(warned),
    "skipped": int(skipped),
}
text = json.dumps(doc, indent=2)
print(text)
if out_path:
    d = os.path.dirname(out_path)
    if d:
        try:
            os.makedirs(d)
        except OSError:
            pass
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write(text + "\n")
PY

[ "$FAILED" -eq 0 ] || exit 1
exit 0

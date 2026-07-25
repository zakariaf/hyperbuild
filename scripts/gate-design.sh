#!/usr/bin/env bash
#
# gate-design.sh — hyperbuild Gate 1 (step 12), the DETERMINISTIC half.
#
# Runs ONLY Tier-0 checks: facts about bytes on disk that no model has to read.
# Judgment stays with hb-gate-verifier, which runs AFTER this script and merges
# its verdicts into the same report: does the stack-guide hold real committed
# decisions, is every REFUTED claim traced to its correction, do the three
# directions read as three products. A gate executed by a model reading prose is
# a Tier-2 gate wearing Tier-0 clothes; everything code can decide is decided
# here instead.
#
# THIS FILE IS THE ORACLE. It lives in scripts/ at the repo root, OUTSIDE every
# agent's write path: no pipeline step, no subagent, and no generated skill may
# write to scripts/**. A build agent that can edit its own gate has no gate.
#
# Usage:
#   scripts/gate-design.sh <run_tag> [--root <repo_root>]
#                                    [--gear standard|premier]
#                                    [--json-out <path>]
#
# Output: one PASS/WARN/FAIL/SKIP line per check on stdout, then the marker
#         ===JSON=== followed by a machine-readable summary (canonical gate
#         verdict schema: gate, run_tag, checks[id,description,result,evidence],
#         overall, failed).
#
# Exit:   0 = every HARD check passed (warns allowed)
#         1 = at least one HARD check FAILED
#         2 = usage error / run_tag not found / no python3
#
# Severity policy — deliberate, and mirrored in hyperbuild-12-design-gate:
#   FAIL  missing or empty required artifact; frontmatter schema violation;
#         closed-vocabulary violation; missing provenance block; referential
#         integrity break (DAG cycle, dangling depends_on, uncovered must/should
#         feature, mockable screen with no mockup, empty files: list); an
#         unresolved step-8.5 critical.
#   WARN  gear-range and cap deviations (scale knobs, not integrity) and
#         anything the manifest itself flags as skipped (screenshots_skipped,
#         visual_qa_skipped). A WARN never blocks; it is printed in the report.
#
# Nothing in this script writes to any pipeline-owned path. It is read-only
# apart from its own --json-out file.

set -euo pipefail

GATE="design"
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
GEAR=""
JSON_OUT=""

usage() {
  sed -n '3,40p' "$SCRIPT_PATH" | sed 's/^# \{0,1\}//'
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
    --gear)     GEAR="${2:-}"; shift 2 ;;
    --json-out) JSON_OUT="${2:-}"; shift 2 ;;
    -h|--help)  usage ;;
    *) printf 'gate-design.sh: unknown argument: %s\n' "$1" >&2; usage ;;
  esac
done

if [ -z "$ROOT" ]; then
  ROOT="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
else
  ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || {
    printf 'gate-design.sh: --root does not exist\n' >&2; exit 2; }
fi

command -v python3 >/dev/null 2>&1 || {
  printf 'FAIL  env-python3            python3 is required to run this gate\n' >&2
  exit 2; }

cd "$ROOT"

RUN_DIR="runs/$RUN_TAG"
if [ ! -d "$RUN_DIR" ]; then
  printf 'gate-design.sh: no such run: %s (looked in %s/runs/)\n' "$RUN_TAG" "$ROOT" >&2
  exit 2
fi

if [ -z "$GEAR" ]; then
  GEAR="$(python3 - "$RUN_DIR/manifest.json" <<'PY' 2>/dev/null || true
import json,sys
try:
    print((json.load(open(sys.argv[1])).get("gear") or "standard"))
except Exception:
    print("standard")
PY
)"
fi
[ -n "$GEAR" ] || GEAR="standard"
case "$GEAR" in standard|premier) ;; *) GEAR="standard" ;; esac

TMPD="$(mktemp -d "${TMPDIR:-/tmp}/hb-gate-design.XXXXXX")"
trap 'rm -rf "$TMPD"' EXIT INT TERM
RESULTS="$TMPD/results"
: > "$RESULTS"

FAILED=0
WARNED=0
SKIPPED=0
US=$'\037'

# ------------------------------------------------------------- helpers -------
# Results are buffered and rendered in check-id order at the end, so the report
# a human (or the orchestrator) reads is deterministic regardless of the order
# the checks happened to run in.
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

nonempty_file() { [ -f "$1" ] && [ -s "$1" ]; }

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

# =============================================================================
# Bash-side checks: existence, non-emptiness, and the two documented greps.
# =============================================================================

# D01 — idea.md
if nonempty_file "$RUN_DIR/idea.md"; then
  missing=""
  for k in run_tag created platform; do
    head -30 "$RUN_DIR/idea.md" | grep -q "^${k}:" || missing="$missing $k"
  done
  body_lines="$(sed -n '/^---$/,$p' "$RUN_DIR/idea.md" | sed '1,/^---$/d' | grep -c '[^[:space:]]' || true)"
  if [ -n "$missing" ]; then
    record D01 fail "idea.md + frontmatter" "$RUN_DIR/idea.md missing frontmatter keys:$missing"
  elif [ "${body_lines:-0}" -lt 1 ]; then
    record D01 fail "idea.md + frontmatter" "$RUN_DIR/idea.md body is empty below the frontmatter"
  else
    record D01 pass "idea.md + frontmatter" "$RUN_DIR/idea.md: run_tag/created/platform present, ${body_lines} body lines"
  fi
else
  record D01 fail "idea.md + frontmatter" "$RUN_DIR/idea.md missing or empty"
fi

# D03 — platform decision
if nonempty_file "$RUN_DIR/decisions/platform.md"; then
  record D03 pass "platform decision" "$RUN_DIR/decisions/platform.md present ($(wc -c < "$RUN_DIR/decisions/platform.md" | tr -d ' ') bytes)"
else
  record D03 fail "platform decision" "$RUN_DIR/decisions/platform.md missing or empty"
fi

# D11 — provenance blocks in every research-phase file.
# Path-filtered find, never a `**` glob: `**` needs globstar and
# research/*/ also matches research/harvest/, whose unmatched patterns get
# passed to grep literally and read like a false PASS.
find research -type d -name harvest -prune -o -type f -name '*.md' -print 2>/dev/null \
  | grep -E '^research/0[0-9]-[^/]+/(research|verify|critique|author)/' \
  > "$TMPD/phase-files.txt" || true
prov_total=0; prov_missing=0; prov_list=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  prov_total=$((prov_total+1))
  if ! grep -q 'The prompt that produced this' "$f"; then
    prov_missing=$((prov_missing+1))
    [ "$prov_missing" -le 8 ] && prov_list="$prov_list $f"
  fi
done < "$TMPD/phase-files.txt"
if [ "$prov_total" -eq 0 ]; then
  record D11 fail "provenance blocks" "no files found under research/0N-*/{research,verify,critique,author}/ — the vault is empty"
elif [ "$prov_missing" -eq 0 ]; then
  record D11 pass "provenance blocks" "$prov_total/$prov_total phase files carry 'The prompt that produced this'"
else
  extra=""
  [ "$prov_missing" -gt 8 ] && extra=" (+$((prov_missing-8)) more)"
  record D11 fail "provenance blocks" "$prov_missing of $prov_total phase files have no provenance block:$prov_list$extra"
fi

# D23 — gallery
if nonempty_file "$RUN_DIR/designs/index.html"; then
  gal_missing=""
  for x in a b c; do
    grep -q "$x/mockups/" "$RUN_DIR/designs/index.html" || \
      grep -q "designs/$x" "$RUN_DIR/designs/index.html" || gal_missing="$gal_missing $x"
  done
  if [ -n "$gal_missing" ]; then
    record D23 fail "design gallery" "$RUN_DIR/designs/index.html does not reference design(s):$gal_missing"
  else
    record D23 pass "design gallery" "$RUN_DIR/designs/index.html references a, b and c"
  fi
else
  record D23 fail "design gallery" "$RUN_DIR/designs/index.html missing or empty"
fi

# D27 — the calibrated-uncertainty section of the gate report.
# ORDERING, stated because it changes what this check can promise: this script runs at
# step 12.1c and the report is written at 12.3, so on round 1 there is nothing to read
# and the check records `skip`. From round 2 on — and on any re-run of a finished gate —
# the previous round's report IS on disk and the check is hard. Step 12.5/12.6 re-verify
# the section with one grep after writing the report, which is what covers a clean
# single-round pass. Gate 1's checklist is the binding requirement either way.
DG_REPORT="$RUN_DIR/gates/design-gate-report.md"
if [ -f "$DG_REPORT" ]; then
  if grep -q '^## What I am least confident about[[:space:]]*$' "$DG_REPORT"; then
    lc_entries=$(awk '
      /^## What I am least confident about[[:space:]]*$/ { f=1; next }
      f && /^## / { f=0 }
      f && /^[[:space:]]*[-*][[:space:]]+[^[:space:]]/ { n++ }
      END { print n+0 }' "$DG_REPORT")
    if [ "$lc_entries" -ge 3 ]; then
      record D27 pass "calibrated uncertainty section" "design-gate-report.md '## What I am least confident about': $lc_entries entries"
    elif [ "$lc_entries" -gt 0 ]; then
      record D27 fail "calibrated uncertainty section" "design-gate-report.md '## What I am least confident about' has only $lc_entries entr(y|ies); the contract is 3-6, each citing an artifact by path"
    else
      record D27 fail "calibrated uncertainty section" "design-gate-report.md '## What I am least confident about' is present but EMPTY — a heading with no entries is worse than no heading"
    fi
  else
    record D27 fail "calibrated uncertainty section" "design-gate-report.md exists but carries no '## What I am least confident about' section (mandatory on pass AND blocked — PIPELINE.md Gate 1)"
  fi
else
  record D27 skip "calibrated uncertainty section" "no design-gate-report.md yet — this script runs at 12.1c, the report at 12.3; enforced on every later round and by step 12's exit criteria"
fi

# =============================================================================
# Structural checks — frontmatter schemas, closed vocabularies, referential
# integrity, set coverage. One python3 pass; every check is wrapped so a
# malformed or absent artifact records a FAIL instead of crashing the gate.
# =============================================================================
PY_OUT="$TMPD/py.out"
PY_ERR="$TMPD/py.err"
set +e
python3 - "$ROOT" "$RUN_TAG" "$GEAR" > "$PY_OUT" 2> "$PY_ERR" <<'PYEOF'
import json, os, re, sys

ROOT, RUN_TAG, GEAR = sys.argv[1], sys.argv[2], sys.argv[3]
PREMIER = (GEAR == "premier")
US = "\x1f"
RUN = os.path.join("runs", RUN_TAG)
OUT = []


def rec(cid, result, desc, evidence):
    ev = str(evidence).replace("\n", " ").replace("\r", " ").replace(US, " ")
    OUT.append(US.join([cid, result, desc, ev]))


def run(cid, desc, fn):
    try:
        fn(cid, desc)
    except Exception as exc:  # a checker never crashes the gate
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
    """Naive but strict YAML-frontmatter reader. Returns None when the block is
    absent or unterminated (both are schema failures, not parse excuses)."""
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
        items = [p for p in s.split(",")]
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
    head = ", ".join(items[:n])
    return head + ("" if len(items) <= n else " (+%d more)" % (len(items) - n))


def body_sections(path):
    txt = read(path) or ""
    out = []
    for line in txt.split("\n"):
        m = re.match(r"^##\s+(.*?)\s*$", line)
        if m:
            norm = m.group(1).lower().replace("&", "and")
            norm = re.sub(r"[^a-z0-9]+", " ", norm).strip()
            out.append(norm)
    return out


AREAS = ["01-product-and-market", "02-engineering", "03-design-system", "04-claude-skills"]
CRITIC_MIN = {"01-product-and-market": (2, 3), "02-engineering": (3, 5),
              "03-design-system": (2, 3), "04-claude-skills": (2, 3)}
PHASES = ["research", "verify", "critique", "author"]
VERDICTS = ["CONFIRMED", "PARTIALLY_TRUE", "REFUTED", "UNVERIFIABLE"]
MOSCOW = ["must", "should", "could", "wont", "won't"]
FEATURE_STATUS = ["specced", "designed", "implemented"]
TASK_STATUS = ["todo", "in-progress", "done"]
TASK_SIZE = ["XS", "S", "M", "L", "XL"]
FEATURE_SECTIONS = ["overview", "user stories", "ux flow", "states and edge cases",
                    "data touchpoints", "acceptance criteria", "evidence", "open questions"]


def phase_files(area, phase):
    """Every .md under research/<area>/<phase>/, at any depth (area 01 nests
    competitors/ and sentiment/ one level down)."""
    base = os.path.join("research", area, phase)
    found = []
    for dirpath, _dirnames, filenames in os.walk(base):
        for name in sorted(filenames):
            if name.endswith(".md") and name != "_INDEX.md":
                found.append(os.path.join(dirpath, name))
    return sorted(found)


MANIFEST = {}
try:
    MANIFEST = json.load(open(os.path.join(RUN, "manifest.json"), encoding="utf-8"))
except Exception:
    MANIFEST = {}
SHOTS_SKIPPED = bool(MANIFEST.get("screenshots_skipped"))
VQA_SKIPPED = bool(MANIFEST.get("visual_qa_skipped"))


# ------------------------------------------------------------------ D02 ------
def c_manifest(cid, desc):
    path = os.path.join(RUN, "manifest.json")
    if not os.path.isfile(path):
        rec(cid, "fail", desc, "%s missing" % path)
        return
    try:
        data = json.load(open(path, encoding="utf-8"))
    except Exception as exc:
        rec(cid, "fail", desc, "%s is not valid JSON: %s" % (path, exc))
        return
    required_steps = ["1", "2", "3", "3.5", "4", "4.5", "5", "6", "7", "8", "8.5", "9", "10", "11"]
    steps = data.get("steps") or {}
    bad = [s for s in required_steps if steps.get(s) != "done"]
    if bad:
        rec(cid, "fail", desc, "steps not done: %s" % sample(bad, 20))
    else:
        rec(cid, "pass", desc, "valid JSON; steps 1-11 (incl 3.5/4.5/8.5) all done; gear=%s" % GEAR)


# ------------------------------------------------------------------ D04 ------
def c_prd(cid, desc):
    path = os.path.join("research", "product-spec.md")
    if not os.path.isfile(path) or os.path.getsize(path) == 0:
        rec(cid, "fail", desc, "%s missing or empty" % path)
        return
    txt = read(path) or ""
    low = txt.lower()
    missing = []
    if "moscow" not in low and not re.search(r"\|\s*must\s*\|", low):
        missing.append("MoSCoW feature list")
    if "screen inventory" not in low:
        missing.append("screen inventory")
    if "mockup_feasibility" not in low:
        missing.append("mockup_feasibility column")
    if missing:
        rec(cid, "fail", desc, "%s is missing: %s" % (path, ", ".join(missing)))
    else:
        rec(cid, "pass", desc, "%s: MoSCoW list + screen inventory + mockup_feasibility present" % path)


# ------------------------------------------------------------------ D05 ------
def c_feature_index(cid, desc):
    path = os.path.join("features", "00-index.md")
    if not os.path.isfile(path) or os.path.getsize(path) == 0:
        rec(cid, "fail", desc, "%s missing or empty" % path)
        return
    fm = frontmatter(path) or {}
    missing = [k for k in ("run_tag", "created", "features") if not scalar(fm.get(k))]
    rows = feature_index_rows()
    if missing:
        rec(cid, "fail", desc, "%s frontmatter missing: %s" % (path, ", ".join(missing)))
    elif not rows:
        rec(cid, "fail", desc, "%s has no parseable | F-NN | rows" % path)
    else:
        rec(cid, "pass", desc, "%s: %d feature rows" % (path, len(rows)))


def feature_index_rows():
    """[(id, moscow)] parsed from the features/00-index.md table."""
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
            if c.strip().lower() in MOSCOW:
                moscow = c.strip().lower()
                break
        rows.append((m.group(1), moscow))
    return rows


# ------------------------------------------------------------------ D06 ------
def c_epic_overview(cid, desc):
    path = os.path.join("epics", "00-overview.md")
    if not os.path.isfile(path) or os.path.getsize(path) == 0:
        rec(cid, "fail", desc, "%s missing or empty" % path)
        return
    txt = (read(path) or "").lower()
    if "coverage matrix" not in txt:
        rec(cid, "fail", desc, "%s has no '## PRD coverage matrix' section" % path)
        return
    fm = frontmatter(path) or {}
    missing = [k for k in ("run_tag", "created", "epics", "tasks") if not scalar(fm.get(k))]
    if missing:
        rec(cid, "fail", desc, "%s frontmatter missing: %s" % (path, ", ".join(missing)))
    else:
        rec(cid, "pass", desc, "%s: coverage matrix + frontmatter (%s epics, %s tasks)"
            % (path, scalar(fm.get("epics")), scalar(fm.get("tasks"))))


# ------------------------------------------------------------------ D07 ------
def c_area_shape(cid, desc):
    problems = []
    for area in AREAS:
        base = os.path.join("research", area)
        if not os.path.isdir(base):
            problems.append("%s/ missing" % base)
            continue
        idx = os.path.join(base, "_INDEX.md")
        if not os.path.isfile(idx) or os.path.getsize(idx) == 0:
            problems.append("%s missing or empty" % idx)
        for phase in PHASES:
            if not phase_files(area, phase):
                problems.append("%s/%s/ empty" % (base, phase))
    # a platform-specific area name is a FAIL, not a variant (RESEARCH-ARCHIVE §2)
    for name in listdir("research"):
        if re.match(r"^0[0-9]-", name) and name not in AREAS:
            problems.append("non-canonical area directory research/%s/" % name)
    if problems:
        rec(cid, "fail", desc, "; ".join(problems[:10])
            + ("" if len(problems) <= 10 else " (+%d more)" % (len(problems) - 10)))
    else:
        rec(cid, "pass", desc, "4 fixed-name areas, each with _INDEX.md + non-empty research/verify/critique/author")


# ------------------------------------------------------------------ D08 ------
def c_author_docs(cid, desc):
    required = [
        "research/01-product-and-market/author/competitor-landscape.md",
        "research/01-product-and-market/author/sentiment-synthesis.md",
        "research/02-engineering/author/stack-guide.md",
        "research/03-design-system/author/design-directions.md",
        "research/04-claude-skills/author/skill-authoring-guide.md",
        "research/01-product-and-market/research/sentiment/reddit.md",
        "research/01-product-and-market/research/sentiment/hn-forums.md",
        "research/01-product-and-market/research/sentiment/appstore-reviews.md",
        "research/01-product-and-market/research/sentiment/linkedin-x.md",
    ]
    missing = [p for p in required if not (os.path.isfile(p) and os.path.getsize(p) > 0)]
    if missing:
        rec(cid, "fail", desc, "missing or empty: %s" % sample(missing, 9))
    else:
        rec(cid, "pass", desc, "all 5 author syntheses + 4 sentiment dimension files present and non-empty")


# ------------------------------------------------------------------ D09 ------
def c_research_frontmatter(cid, desc):
    bad, total = [], 0
    for area in AREAS:
        for phase in PHASES:
            for path in phase_files(area, phase):
                total += 1
                fm = frontmatter(path)
                if fm is None:
                    bad.append("%s (no closed frontmatter block)" % path)
                    continue
                miss = [k for k in ("run_tag", "created", "area", "phase") if not scalar(fm.get(k))]
                if miss:
                    bad.append("%s (missing %s)" % (path, "/".join(miss)))
                    continue
                if scalar(fm.get("area")) != area:
                    bad.append("%s (area: %s != %s)" % (path, scalar(fm.get("area")), area))
                elif scalar(fm.get("phase")) != phase:
                    bad.append("%s (phase: %s != %s)" % (path, scalar(fm.get("phase")), phase))
                elif phase == "verify" and not scalar(fm.get("claim")):
                    bad.append("%s (verify file with no claim:)" % path)
                elif phase == "critique" and not scalar(fm.get("critic")):
                    bad.append("%s (critique file with no critic:)" % path)
    if total == 0:
        rec(cid, "fail", desc, "no research-phase files found at all")
    elif bad:
        rec(cid, "fail", desc, "%d of %d files violate the RESEARCH-ARCHIVE §3 frontmatter schema: %s"
            % (len(bad), total, sample(bad, 5)))
    else:
        rec(cid, "pass", desc, "%d research-phase files carry run_tag/created/area/phase, area+phase matching their path" % total)


# ------------------------------------------------------------------ D10 ------
def c_verdicts(cid, desc):
    bad, total = [], 0
    for area in AREAS:
        for path in phase_files(area, "verify"):
            total += 1
            fm = frontmatter(path) or {}
            v = scalar(fm.get("verdict"))
            if v not in VERDICTS:
                bad.append("%s (verdict: %s)" % (path, v or "<absent>"))
    if total == 0:
        rec(cid, "fail", desc, "zero verify/ files across all four areas — no claim was ever fact-checked")
    elif bad:
        rec(cid, "fail", desc, "%d of %d verify files carry no closed-vocabulary verdict: %s"
            % (len(bad), total, sample(bad, 6)))
    else:
        rec(cid, "pass", desc, "%d/%d verify files carry a verdict from CONFIRMED|PARTIALLY_TRUE|REFUTED|UNVERIFIABLE" % (total, total))


# ------------------------------------------------------------------ D12 ------
def c_verify_coverage(cid, desc):
    floor = 6 if PREMIER else 3
    short, counts = [], []
    for area in AREAS:
        n = len(phase_files(area, "verify"))
        counts.append("%s=%d" % (area.split("-")[0], n))
        if n < floor:
            short.append("%s has %d verify file(s), floor is %d" % (area, n, floor))
    # per-file coverage: every research/ file with a selected claim needs >=1 verify file
    dangling = []
    for idx, area in enumerate(AREAS, start=1):
        reg = os.path.join(RUN, "temp", "claims-%02d.json" % idx)
        if not os.path.isfile(reg):
            continue
        try:
            claims = json.load(open(reg, encoding="utf-8"))
        except Exception:
            dangling.append("%s is not valid JSON" % reg)
            continue
        items = claims if isinstance(claims, list) else (claims.get("claims") or [])
        dims = set()
        for c in items:
            if isinstance(c, dict) and c.get("selected"):
                d = c.get("dimension") or c.get("source_file") or ""
                d = os.path.basename(str(d)).replace(".md", "")
                if d:
                    dims.add(d)
        have = set()
        for path in phase_files(area, "verify"):
            have.add(os.path.basename(path).split("--")[0])
        for d in sorted(dims - have):
            dangling.append("%s: dimension '%s' has selected claims but no verify/%s--*.md" % (area, d, d))
    if dangling:
        rec(cid, "fail", desc, "; ".join(dangling[:6]) + (" [counts %s]" % ", ".join(counts)))
    elif short:
        rec(cid, "warn", desc, "; ".join(short) + " [counts %s]" % ", ".join(counts))
    else:
        rec(cid, "pass", desc, "verify files per area: %s (floor %d at %s)" % (", ".join(counts), floor, GEAR))


# ------------------------------------------------------------------ D13 ------
def c_dimension_counts(cid, desc):
    notes, fails, warns = [], [], []

    comps = [p for p in phase_files("01-product-and-market", "research")
             if os.sep + "competitors" + os.sep in p]
    comp_floor = 12 if PREMIER else 6
    notes.append("area 01 competitors=%d" % len(comps))
    if len(comps) == 0:
        fails.append("area 01 has zero competitor dossiers")
    elif len(comps) < comp_floor:
        warns.append("area 01 has %d competitor dossiers, gear floor is %d" % (len(comps), comp_floor))

    eng = [p for p in phase_files("02-engineering", "research")]
    lo, hi = (10, 14) if PREMIER else (6, 8)
    notes.append("area 02 dimensions=%d" % len(eng))
    if len(eng) == 0:
        fails.append("area 02 has zero research dimensions")
    elif not (lo <= len(eng) <= hi):
        warns.append("area 02 has %d research dimensions, gear range is %d-%d" % (len(eng), lo, hi))

    dirs = 0
    for path in phase_files("03-design-system", "research"):
        fm = frontmatter(path) or {}
        if scalar(fm.get("direction")) and scalar(fm.get("letter")):
            dirs += 1
    notes.append("area 03 directions=%d" % dirs)
    if dirs != 3:
        fails.append("area 03 has %d files carrying BOTH direction: and letter: frontmatter — exactly 3 are required "
                     "(count by frontmatter; step 6.3a's shared platform dimensions are expected extras)" % dirs)

    for area in AREAS:
        n = len(phase_files(area, "critique"))
        lo_c, hi_c = CRITIC_MIN[area]
        floor = hi_c if PREMIER else lo_c
        if n == 0:
            fails.append("%s has zero critique/ files" % area)
        elif n < floor:
            warns.append("%s has %d critique file(s), floor is %d at %s" % (area, n, floor, GEAR))

    if fails:
        rec(cid, "fail", desc, "; ".join(fails) + " [%s]" % ", ".join(notes))
    elif warns:
        rec(cid, "warn", desc, "; ".join(warns) + " [%s]" % ", ".join(notes))
    else:
        rec(cid, "pass", desc, ", ".join(notes) + " — all within the %s range" % GEAR)


# ------------------------------------------------------------------ D14 ------
def feature_files():
    out = []
    for name in listdir("features", ".md"):
        if name in ("00-index.md", "README.md"):
            continue
        if re.match(r"^\d+-", name):
            out.append(os.path.join("features", name))
    return out


def c_feature_frontmatter(cid, desc):
    files = feature_files()
    if not files:
        rec(cid, "fail", desc, "no features/NN-<slug>.md files found")
        return
    bad = []
    for path in files:
        fm = frontmatter(path)
        if fm is None:
            bad.append("%s (no closed frontmatter block)" % path)
            continue
        fid = scalar(fm.get("id"))
        if not re.match(r"^F-\d+$", fid):
            bad.append("%s (id: %s)" % (path, fid or "<absent>"))
            continue
        prefix = os.path.basename(path).split("-")[0]
        if fid != "F-%s" % prefix:
            bad.append("%s (id %s does not match filename prefix %s)" % (path, fid, prefix))
            continue
        if not scalar(fm.get("name")):
            bad.append("%s (no name:)" % path)
            continue
        mo = scalar(fm.get("moscow")).lower()
        if mo not in MOSCOW:
            bad.append("%s (moscow: %s not in must|should|could|wont)" % (path, mo or "<absent>"))
            continue
        st = scalar(fm.get("status")).lower()
        if st not in FEATURE_STATUS:
            bad.append("%s (status: %s not in specced|designed|implemented)" % (path, st or "<absent>"))
            continue
        if not as_list(fm.get("screens")):
            bad.append("%s (screens: is empty)" % path)
            continue
        have = body_sections(path)
        miss = [s for s in FEATURE_SECTIONS if s not in have]
        if miss:
            bad.append("%s (missing sections: %s)" % (path, "/".join(miss)))
    cap = 25 if PREMIER else 15
    if bad:
        rec(cid, "fail", desc, "%d of %d feature files fail the features/README.md contract: %s"
            % (len(bad), len(files), sample(bad, 5)))
    elif len(files) > cap:
        rec(cid, "warn", desc, "%d feature files exceed the %s cap of %d (schema otherwise clean)" % (len(files), GEAR, cap))
    else:
        rec(cid, "pass", desc, "%d feature files: id/name/moscow/status/screens valid, all 8 body sections present" % len(files))


# ------------------------------------------------------------- tasks/epics ---
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


def load_tasks():
    tasks = {}
    for path in task_paths():
        fm = frontmatter(path)
        tasks[path] = fm
    return tasks


def c_task_frontmatter(cid, desc):
    tasks = load_tasks()
    if not tasks:
        rec(cid, "fail", desc, "no epics/*/task-*.md files found")
        return
    bad = []
    taxonomy = (read(os.path.join("research", "02-engineering", "author", "stack-guide.md")) or "").lower()
    for path, fm in sorted(tasks.items()):
        if fm is None:
            bad.append("%s (no closed frontmatter block)" % path)
            continue
        tid = scalar(fm.get("id"))
        if not re.match(r"^T-\d+-\d+$", tid):
            bad.append("%s (id: %s)" % (path, tid or "<absent>"))
            continue
        if not re.match(r"^E-\d+$", scalar(fm.get("epic"))):
            bad.append("%s (epic: %s)" % (path, scalar(fm.get("epic")) or "<absent>"))
            continue
        st = scalar(fm.get("status")).lower()
        if st not in TASK_STATUS:
            bad.append("%s (status: %s not in todo|in-progress|done)" % (path, st or "<absent>"))
            continue
        if "depends_on" not in fm:
            bad.append("%s (no depends_on:)" % path)
            continue
        size = scalar(fm.get("size")).upper()
        if size not in TASK_SIZE:
            bad.append("%s (size: %s not in XS|S|M|L|XL)" % (path, size or "<absent>"))
            continue
        if not scalar(fm.get("category")):
            bad.append("%s (no category:)" % path)
            continue
        if "features" not in fm:
            bad.append("%s (no features: key)" % path)
            continue
        if "files" not in fm:
            bad.append("%s (no files: key)" % path)
    # epic.md schema rides along
    for d in epic_dirs():
        p = os.path.join(d, "epic.md")
        if not os.path.isfile(p):
            bad.append("%s missing" % p)
            continue
        fm = frontmatter(p)
        if fm is None:
            bad.append("%s (no closed frontmatter block)" % p)
        elif not re.match(r"^E-\d+$", scalar(fm.get("id"))):
            bad.append("%s (id: %s)" % (p, scalar(fm.get("id")) or "<absent>"))
        elif not scalar(fm.get("name")):
            bad.append("%s (no name:)" % p)
        elif "depends_on" not in fm:
            bad.append("%s (no depends_on:)" % p)
    if bad:
        rec(cid, "fail", desc, "%d schema violations under epics/: %s" % (len(bad), sample(bad, 5)))
    else:
        rec(cid, "pass", desc, "%d task files + %d epic.md files carry the epics/README.md frontmatter schema"
            % (len(tasks), len(epic_dirs())))


def c_task_status_todo(cid, desc):
    tasks = load_tasks()
    if not tasks:
        rec(cid, "fail", desc, "no task files found")
        return
    bad = ["%s (%s)" % (p, scalar((fm or {}).get("status")) or "<absent>")
           for p, fm in sorted(tasks.items())
           if scalar((fm or {}).get("status")).lower() != "todo"]
    if bad:
        rec(cid, "fail", desc, "%d task(s) are not status: todo at the design gate: %s" % (len(bad), sample(bad, 6)))
    else:
        rec(cid, "pass", desc, "all %d task files are status: todo" % len(tasks))


def c_task_files_nonempty(cid, desc):
    tasks = load_tasks()
    if not tasks:
        rec(cid, "fail", desc, "no task files found")
        return
    bad = [p for p, fm in sorted(tasks.items()) if not as_list((fm or {}).get("files"))]
    if bad:
        rec(cid, "fail", desc, "%d task(s) have an empty files: list — step 14's wave-disjointness key: %s"
            % (len(bad), sample(bad, 6)))
    else:
        total = sum(len(as_list((fm or {}).get("files"))) for fm in tasks.values())
        rec(cid, "pass", desc, "all %d tasks declare a non-empty files: list (%d planned paths)" % (len(tasks), total))


def c_dag(cid, desc):
    tasks = load_tasks()
    epics = {}
    for d in epic_dirs():
        fm = frontmatter(os.path.join(d, "epic.md"))
        if fm:
            eid = scalar(fm.get("id"))
            if eid:
                epics[eid] = as_list(fm.get("depends_on"))
    task_ids, task_deps, task_epic = {}, {}, {}
    for path, fm in tasks.items():
        if not fm:
            continue
        tid = scalar(fm.get("id"))
        if not tid:
            continue
        task_ids[tid] = path
        task_deps[tid] = as_list(fm.get("depends_on"))
        task_epic[tid] = scalar(fm.get("epic"))

    problems, warns = [], []
    for eid, deps in sorted(epics.items()):
        for dep in deps:
            if dep not in epics:
                problems.append("epic %s depends_on %s which does not exist" % (eid, dep))
            elif dep >= eid:
                warns.append("epic %s depends_on %s (forward/self reference — epics/README.md requires lower-numbered)" % (eid, dep))
    for tid, deps in sorted(task_deps.items()):
        for dep in deps:
            if dep not in task_ids:
                problems.append("task %s depends_on %s which does not exist" % (tid, dep))
    for tid, eid in sorted(task_epic.items()):
        if eid and epics and eid not in epics:
            problems.append("task %s names epic %s which has no epics/*/epic.md" % (tid, eid))

    def cycles(graph):
        WHITE, GREY, BLACK = 0, 1, 2
        color = dict((n, WHITE) for n in graph)
        found = []

        def visit(node, stack):
            color[node] = GREY
            for nxt in graph.get(node, []):
                if nxt not in color:
                    continue
                if color[nxt] == GREY:
                    found.append(" -> ".join(stack + [nxt]))
                elif color[nxt] == WHITE:
                    visit(nxt, stack + [nxt])
            color[node] = BLACK

        for n in sorted(graph):
            if color[n] == WHITE:
                visit(n, [n])
        return found

    ecyc = cycles(epics)
    tcyc = cycles(task_deps)
    if ecyc:
        problems.append("EPIC DAG HAS A CYCLE: %s" % sample(ecyc, 3))
    if tcyc:
        problems.append("TASK DAG HAS A CYCLE: %s" % sample(tcyc, 3))

    if not epics and not task_ids:
        rec(cid, "fail", desc, "no epics or tasks to walk")
    elif problems:
        rec(cid, "fail", desc, "; ".join(problems[:6]) + ("" if len(problems) <= 6 else " (+%d more)" % (len(problems) - 6)))
    elif warns:
        rec(cid, "warn", desc, "; ".join(warns[:6]))
    else:
        rec(cid, "pass", desc, "%d epics + %d tasks: acyclic, every depends_on target exists" % (len(epics), len(task_ids)))


def c_feature_coverage(cid, desc):
    rows = feature_index_rows()
    if not rows:
        rec(cid, "fail", desc, "features/00-index.md has no parseable feature rows")
        return
    tasks = load_tasks()
    cited = {}
    for path, fm in tasks.items():
        for fid in as_list((fm or {}).get("features")):
            cited.setdefault(fid, []).append(path)
    on_disk = {}
    for path in feature_files():
        fm = frontmatter(path) or {}
        fid = scalar(fm.get("id"))
        if fid:
            on_disk[fid] = path
    must_should = [fid for fid, mo in rows if mo in ("must", "should")]
    uncovered = [fid for fid in must_should if fid not in cited]
    unknown = sorted(set(cited) - set(on_disk))
    no_spec = [fid for fid, _mo in rows if fid not in on_disk]
    problems = []
    if uncovered:
        problems.append("must/should features with ZERO covering task: %s" % sample(uncovered, 8))
    if unknown:
        problems.append("tasks cite feature ids with no features/NN-*.md: %s" % sample(unknown, 8))
    if no_spec:
        problems.append("index rows with no spec file: %s" % sample(no_spec, 8))
    if problems:
        rec(cid, "fail", desc, "; ".join(problems))
    else:
        rec(cid, "pass", desc, "%d must/should features all covered by >=1 task; every cited id resolves to a spec file"
            % len(must_should))


# ------------------------------------------------------------- designs -------
def screen_inventory():
    """[(slug, feasibility)] from the PRD's canonical screen-inventory table."""
    txt = read(os.path.join("research", "product-spec.md")) or ""
    lines = txt.split("\n")
    start = None
    for i, line in enumerate(lines):
        if re.match(r"^#{2,3}\s+.*screen inventory", line.strip(), re.I):
            start = i
            break
    if start is None:
        return []
    header, idx_slug, idx_feas = None, None, None
    rows = []
    for line in lines[start + 1:]:
        s = line.strip()
        if s.startswith("#") and header is not None:
            break
        if not s.startswith("|"):
            if header is not None and not s:
                continue
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        low = [c.lower() for c in cells]
        if header is None:
            if "slug" in low and any("feasib" in c for c in low):
                header = cells
                idx_slug = low.index("slug")
                idx_feas = [i for i, c in enumerate(low) if "feasib" in c][0]
            continue
        if set("".join(cells).replace(" ", "")) <= set("-:"):
            continue
        if idx_slug is None or len(cells) <= max(idx_slug, idx_feas):
            continue
        slug = cells[idx_slug].strip("` ").strip()
        feas_raw = cells[idx_feas].strip().lower()
        feas = "unknown"
        for cand in ("full", "partial", "none"):
            if re.match(r"^%s\b" % cand, feas_raw):
                feas = cand
                break
        if slug and not slug.startswith("-"):
            rows.append((slug, feas))
    return rows


def c_design_systems(cid, desc):
    missing = []
    for x in ("a", "b", "c"):
        for f in ("design-system.md", "tokens.css"):
            p = os.path.join(RUN, "designs", x, f)
            if not (os.path.isfile(p) and os.path.getsize(p) > 0):
                missing.append(p)
    if missing:
        rec(cid, "fail", desc, "missing or empty: %s" % sample(missing, 6))
    else:
        rec(cid, "pass", desc, "designs a, b, c each have a non-empty design-system.md + tokens.css")


def c_mockup_coverage(cid, desc):
    inv = screen_inventory()
    if not inv:
        rec(cid, "fail", desc, "could not parse a screen inventory table (slug + mockup_feasibility columns) from research/product-spec.md")
        return
    mockable = [s for s, f in inv if f in ("full", "partial")]
    none_screens = [s for s, f in inv if f == "none"]
    unknown = [s for s, f in inv if f == "unknown"]
    cap = 20 if PREMIER else 12
    problems, warns, sets = [], [], {}
    if unknown:
        warns.append("inventory rows with an unparseable mockup_feasibility: %s" % sample(unknown, 5))
    for x in ("a", "b", "c"):
        d = os.path.join(RUN, "designs", x, "mockups")
        present = [n[:-5] for n in listdir(d, ".html")]
        sets[x] = set(present)
        missing = [s for s in mockable if s not in sets[x]]
        illegal = [s for s in none_screens if s in sets[x]]
        stray = sorted(sets[x] - set(mockable) - set(none_screens))
        if missing:
            (warns if len(mockable) > cap else problems).append(
                "design %s missing mockups for: %s" % (x, sample(missing, 8)))
        if illegal:
            problems.append("design %s has mockups for 'none' screens: %s" % (x, sample(illegal, 5)))
        if stray:
            problems.append("design %s has mockups not in the PRD inventory: %s" % (x, sample(stray, 5)))
    if sets.get("a") is not None and not (sets.get("a") == sets.get("b") == sets.get("c")):
        diff = []
        allk = set().union(*[sets[x] for x in ("a", "b", "c")])
        for s in sorted(allk):
            here = [x for x in ("a", "b", "c") if s in sets[x]]
            if len(here) != 3:
                diff.append("%s only in %s" % (s, "/".join(here) or "none"))
        problems.append("the three designs do not mock the SAME screen set: %s" % sample(diff, 6))
    if len(mockable) > cap:
        warns.append("%d full/partial screens exceed the %s cap of %d" % (len(mockable), GEAR, cap))
    if problems:
        rec(cid, "fail", desc, "; ".join(problems[:6]))
    elif warns:
        rec(cid, "warn", desc, "; ".join(warns[:6]))
    else:
        rec(cid, "pass", desc, "%d full/partial screens mocked in all 3 designs; %d 'none' screens correctly unmocked"
            % (len(mockable), len(none_screens)))


def c_screenshot_parity(cid, desc):
    problems, counts = [], []
    total_mocks = 0
    for x in ("a", "b", "c"):
        mdir = os.path.join(RUN, "designs", x, "mockups")
        sdir = os.path.join(RUN, "designs", x, "screenshots")
        mocks = [n[:-5] for n in listdir(mdir, ".html")]
        total_mocks += len(mocks)
        missing, empty = [], []
        for m in mocks:
            png = os.path.join(sdir, m + ".png")
            if not os.path.isfile(png):
                missing.append(m + ".png")
            elif os.path.getsize(png) == 0:
                empty.append(m + ".png")
        stray = [n for n in listdir(sdir, ".png") if n[:-4] not in mocks]
        counts.append("%s=%d/%d" % (x, len(mocks) - len(missing) - len(empty), len(mocks)))
        if missing:
            problems.append("design %s missing renders: %s" % (x, sample(missing, 6)))
        if empty:
            problems.append("design %s zero-byte renders: %s" % (x, sample(empty, 6)))
        if stray:
            problems.append("design %s has screenshots with no mockup: %s" % (x, sample(stray, 6)))
    if total_mocks == 0:
        rec(cid, "fail", desc, "no mockups exist in any design — nothing to render, so parity is vacuous (see D21)")
    elif problems and SHOTS_SKIPPED:
        rec(cid, "warn", desc, "manifest screenshots_skipped=true — %s [%s]" % ("; ".join(problems[:4]), ", ".join(counts)))
    elif problems:
        rec(cid, "fail", desc, "; ".join(problems[:6]) + " [%s]" % ", ".join(counts))
    else:
        rec(cid, "pass", desc, "every mockup has a non-empty screenshot (%s)" % ", ".join(counts))


def c_generated_skills(cid, desc):
    names = ["app-code-style", "app-architecture", "app-testing", "app-components", "app-review-checklist"]
    bad = []
    for n in names:
        p = os.path.join(".claude", "skills", n, "SKILL.md")
        if not (os.path.isfile(p) and os.path.getsize(p) > 0):
            bad.append("%s missing or empty" % p)
            continue
        fm = frontmatter(p)
        if fm is None:
            bad.append("%s has no closed frontmatter block" % p)
        elif not scalar(fm.get("name")):
            bad.append("%s frontmatter has no name:" % p)
        elif not scalar(fm.get("description")) and not isinstance(fm.get("description"), list):
            bad.append("%s frontmatter has no description:" % p)
    if bad:
        rec(cid, "fail", desc, "; ".join(bad[:5]))
    else:
        rec(cid, "pass", desc, "all 5 generated app-* skills present with valid frontmatter")


# ---------------------------------------------------------- visual QA --------
def load_vqa(x):
    p = os.path.join(RUN, "gates", "visual-qa-%s.json" % x)
    if not os.path.isfile(p):
        return p, None, "missing"
    try:
        return p, json.load(open(p, encoding="utf-8")), None
    except Exception as exc:
        return p, None, "invalid JSON: %s" % exc


def c_vqa_files(cid, desc):
    problems, warns, notes = [], [], []
    for x in ("a", "b", "c"):
        p, data, err = load_vqa(x)
        if err:
            problems.append("%s %s" % (p, err))
            continue
        try:
            rounds = int(data.get("rounds") or 0)
        except Exception:
            rounds = 0
        if rounds < 1:
            problems.append("%s has rounds=%s (<1)" % (p, data.get("rounds")))
        reviewed = set()
        for key in ("screens_reviewed", "screens_not_viewed"):
            v = data.get(key) or []
            for item in v:
                if isinstance(item, dict):
                    s = item.get("screen") or item.get("screenshot") or ""
                else:
                    s = str(item)
                s = os.path.basename(str(s))
                if s.endswith(".png"):
                    s = s[:-4]
                if s:
                    reviewed.add(s)
        not_viewed = data.get("screens_not_viewed") or []
        shots = [n[:-4] for n in listdir(os.path.join(RUN, "designs", x, "screenshots"), ".png")]
        unaccounted = [s for s in shots if s not in reviewed]
        notes.append("%s: %d shots, %d accounted" % (x, len(shots), len(shots) - len(unaccounted)))
        if unaccounted:
            problems.append("design %s: rendered screenshots in NEITHER screens_reviewed nor screens_not_viewed: %s"
                            % (x, sample(unaccounted, 6)))
        if not_viewed:
            no_reason = []
            for item in not_viewed:
                if isinstance(item, dict) and str(item.get("reason") or "").strip():
                    continue
                no_reason.append(str(item)[:40])
            if no_reason:
                problems.append("design %s: screens_not_viewed entries with no reason: %s" % (x, sample(no_reason, 5)))
            else:
                warns.append("design %s lists %d screen(s) as not viewed, each with a reason" % (x, len(not_viewed)))
    if problems and (SHOTS_SKIPPED or VQA_SKIPPED):
        rec(cid, "warn", desc, "manifest screenshots_skipped/visual_qa_skipped set — %s" % "; ".join(problems[:4]))
    elif problems:
        rec(cid, "fail", desc, "; ".join(problems[:6]))
    elif warns:
        rec(cid, "warn", desc, "; ".join(warns) + " [%s]" % ", ".join(notes))
    else:
        rec(cid, "pass", desc, "3 visual-QA files, every rendered screenshot accounted for (%s)" % ", ".join(notes))


def c_vqa_criticals(cid, desc):
    open_crit, accepted, bad_accept = [], [], []
    any_file = False
    for x in ("a", "b", "c"):
        p, data, err = load_vqa(x)
        if err:
            continue
        any_file = True
        try:
            rounds = int(data.get("rounds") or 0)
        except Exception:
            rounds = 0
        for f in (data.get("findings") or []):
            if not isinstance(f, dict):
                continue
            if str(f.get("severity", "")).lower() != "critical":
                continue
            st = str(f.get("status", "")).lower()
            ident = "%s/%s#%s" % (x, f.get("screen", "?"), f.get("id", "?"))
            if st == "open":
                open_crit.append(ident)
            elif st == "accepted-known-issue":
                if rounds < 2 or not str(f.get("acceptance_reason") or "").strip():
                    bad_accept.append("%s (rounds=%d, reason=%s)" % (ident, rounds, "yes" if f.get("acceptance_reason") else "NO"))
                else:
                    accepted.append(ident)
            elif st == "unverifiable":
                if not VQA_SKIPPED or not str(f.get("acceptance_reason") or f.get("reason") or "").strip():
                    bad_accept.append("%s (unverifiable outside source-only mode or with no reason)" % ident)
                else:
                    accepted.append(ident)
    if not any_file:
        rec(cid, "fail", desc, "no readable visual-qa-{a,b,c}.json — step 8.5's findings cannot be checked")
    elif open_crit or bad_accept:
        parts = []
        if open_crit:
            parts.append("criticals still open: %s" % sample(open_crit, 8))
        if bad_accept:
            parts.append("illegally relabelled criticals: %s" % sample(bad_accept, 5))
        rec(cid, "fail", desc, "; ".join(parts))
    elif accepted:
        rec(cid, "warn", desc, "%d critical(s) accepted as known issues after 2 rounds — MUST be printed in the report "
                               "and the stop message: %s" % (len(accepted), sample(accepted, 8)))
    else:
        rec(cid, "pass", desc, "zero unresolved step-8.5 critical findings")


# ------------------------------------------------------------------ run ------
run("D02", "manifest valid + steps 1-11 done", c_manifest)
run("D04", "PRD: MoSCoW + screen inventory", c_prd)
run("D05", "feature index", c_feature_index)
run("D06", "epic overview + coverage matrix", c_epic_overview)
run("D07", "research area shape (4 fixed names)", c_area_shape)
run("D08", "author syntheses + sentiment files", c_author_docs)
run("D09", "research frontmatter schema", c_research_frontmatter)
run("D10", "verify verdict vocabulary", c_verdicts)
run("D12", "verify coverage per area", c_verify_coverage)
run("D13", "research dimension counts", c_dimension_counts)
run("D14", "feature spec schema + sections", c_feature_frontmatter)
run("D15", "task/epic frontmatter schema", c_task_frontmatter)
run("D16", "every task status: todo", c_task_status_todo)
run("D17", "every task files: non-empty", c_task_files_nonempty)
run("D18", "epic+task DAG acyclic, deps exist", c_dag)
run("D19", "feature<->task coverage both ways", c_feature_coverage)
run("D20", "3 design systems + tokens", c_design_systems)
run("D21", "mockup coverage vs screen inventory", c_mockup_coverage)
run("D22", "mockup<->screenshot parity", c_screenshot_parity)
run("D24", "5 generated app-* skills", c_generated_skills)
run("D25", "visual-QA files account for every render", c_vqa_files)
run("D26", "zero unresolved visual criticals", c_vqa_criticals)

sys.stdout.write("\n".join(OUT) + ("\n" if OUT else ""))
PYEOF
PY_STATUS=$?
set -e

if [ "$PY_STATUS" -ne 0 ]; then
  record "D00" fail "structural checker" "python3 checker exited $PY_STATUS: $(tail -3 "$PY_ERR" 2>/dev/null | tr '\n' ' ')"
fi

while IFS="$US" read -r cid cres cdesc cev; do
  [ -n "${cid:-}" ] || continue
  record "$cid" "$cres" "$cdesc" "$cev"
done < "$PY_OUT"

# --------------------------------------------------------------- summary -----
OVERALL="pass"
[ "$FAILED" -eq 0 ] || OVERALL="fail"
SELF_SHA="$(sha256_of "$SCRIPT_PATH")"

python3 - "$RESULTS" "$GATE" "$RUN_TAG" "$GEAR" "$SELF_SHA" "$OVERALL" "$FAILED" "$WARNED" "$SKIPPED" "${JSON_OUT:-}" <<'PY'
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
    "gear": gear,
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

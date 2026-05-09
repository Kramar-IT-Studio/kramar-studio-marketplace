#!/usr/bin/env bash
# product — artifact integrity hook.
#
# Runs after Edit/Write/MultiEdit. Reads the tool input JSON from stdin,
# extracts the file path, and surfaces soft warnings if the artifact violates
# the format contract (front-matter requirements, mandatory sections, size
# budgets). NEVER blocks — exits 0 always.
#
# Checks performed (matching plugin design):
#   - market-scan.md: ≤200 lines; non-empty Gaps section.
#   - PRD: success_metric front-matter or section, non-empty.
#   - PRD: linked SCAN exists and is ≤90 days old (warn if stale or missing).
#   - SPEC: ≥3 acceptance criteria.

set -u

# Read stdin payload (Claude Code passes a JSON document).
PAYLOAD=$(cat 2>/dev/null || true)
[ -z "$PAYLOAD" ] && exit 0

# Extract file_path. Try jq first; fall back to grep/sed for portability.
FILE_PATH=""
if command -v jq >/dev/null 2>&1; then
  FILE_PATH=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
fi
if [ -z "$FILE_PATH" ]; then
  FILE_PATH=$(printf '%s' "$PAYLOAD" \
    | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]+"' \
    | head -n1 \
    | sed -E 's/.*"file_path"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
fi

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Only operate on artifacts under docs/product/.
case "$FILE_PATH" in
  */docs/product/*) ;;
  *) exit 0 ;;
esac

# Derive repo root (best-effort; not strictly required for these checks).
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
else
  REPO_ROOT=""
fi

LINES=$(wc -l < "$FILE_PATH" 2>/dev/null | tr -d ' ')

# --- Helpers -----------------------------------------------------------------

# Print contents of a section (text between "## <name>" and the next "## " or EOF).
section_body() {
  local file="$1" name="$2"
  awk -v target="## $name" '
    $0 == target { capture=1; next }
    capture && /^## / { capture=0 }
    capture { print }
  ' "$file"
}

# True if a section exists and has at least one non-empty, non-whitespace line.
section_nonempty() {
  local body
  body=$(section_body "$1" "$2")
  printf '%s' "$body" | grep -qE '[^[:space:]]'
}

# Read a value from YAML front-matter (only the first '---'…'---' block at top).
front_matter_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    NR==1 && $0=="---" { in_fm=1; next }
    in_fm && $0=="---" { exit }
    in_fm {
      n=index($0, ":")
      if (n>0) {
        k=substr($0,1,n-1); v=substr($0,n+1)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
        if (k==key) { print v; exit }
      }
    }
  ' "$file"
}

# Extract referenced SCAN-IDs from links_to in front-matter.
front_matter_links_scans() {
  awk '
    NR==1 && $0=="---" { in_fm=1; next }
    in_fm && $0=="---" { exit }
    in_fm
  ' "$1" | grep -oE 'SCAN-[0-9]+' | sort -u
}

emit() {
  printf '[product] %s\n' "$1" >&2
}

# --- Per-type checks ---------------------------------------------------------

case "$FILE_PATH" in

  *market-scan.md)
    if [ "${LINES:-0}" -gt 200 ]; then
      emit "${FILE_PATH##*/}: ${LINES} lines (>200). Market-scan should be bounded — 3-7 competitors, 1-3 gaps, one positioning paragraph. Trim before saving as final."
    fi
    if ! section_nonempty "$FILE_PATH" "Gaps"; then
      emit "${FILE_PATH##*/}: Gaps section is empty. Either name 1-3 concrete gaps or abort the scan with an explicit 'no gap surfaced' note. An empty Gaps section is the failure mode this command guards against."
    fi
    ;;

  */docs/product/prds/*.md)
    metric_fm=$(front_matter_value "$FILE_PATH" "success_metric")
    if [ -z "$metric_fm" ] && ! section_nonempty "$FILE_PATH" "Success metric"; then
      emit "${FILE_PATH##*/}: no success_metric (front-matter or '## Success metric' section). A PRD without a primary metric is a wishlist. Add baseline → target → window → counter-metric."
    fi

    if [ -n "$REPO_ROOT" ]; then
      linked_scans=$(front_matter_links_scans "$FILE_PATH")
      if [ -z "$linked_scans" ]; then
        # No SCAN linked. Warn unless there's a recent scan in any area (then ambiguous).
        recent=$(find "$REPO_ROOT/docs/product/research" -maxdepth 1 -type f -name '*-market-scan.md' -mtime -90 2>/dev/null | head -n1)
        if [ -z "$recent" ]; then
          emit "${FILE_PATH##*/}: no SCAN-NNNN in links_to and no market-scan in last 90 days. PRDs for new areas should be anchored by a market-scan — run /product:market-scan first, or add an explicit note why this PRD doesn't need one."
        fi
      else
        # SCAN linked — check freshness.
        for scan_id in $linked_scans; do
          n=$(printf '%s' "$scan_id" | sed -E 's/SCAN-0*([0-9]+)/\1/')
          scan_file=$(grep -lE "^id:[[:space:]]*$scan_id$" "$REPO_ROOT/docs/product/research"/*.md 2>/dev/null | head -n1)
          if [ -z "$scan_file" ]; then
            emit "${FILE_PATH##*/}: links_to includes ${scan_id} but no matching file in docs/product/research/. Broken cross-reference."
          else
            if find "$scan_file" -mtime +90 2>/dev/null | grep -q .; then
              emit "${FILE_PATH##*/}: linked ${scan_id} is older than 90 days. Consider refreshing the scan before committing to this PRD."
            fi
          fi
        done
      fi
    fi
    ;;

  */docs/product/specs/*-spec.md)
    body=$(section_body "$FILE_PATH" "Acceptance criteria")
    # Count list items: lines starting with "- ", "* ", or "1.", "2.", etc.
    count=$(printf '%s' "$body" | grep -cE '^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]+' || true)
    if [ "${count:-0}" -lt 3 ]; then
      emit "${FILE_PATH##*/}: Acceptance criteria has ${count} item(s) (<3). A spec with fewer than 3 testable criteria is hand-waving. Expand or split the feature."
    fi
    ;;

esac

exit 0

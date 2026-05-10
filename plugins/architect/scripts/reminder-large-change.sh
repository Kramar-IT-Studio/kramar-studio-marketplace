#!/usr/bin/env bash
# archforge — soft architectural reminder hook.
#
# This script runs after Edit/Write/MultiEdit tool calls. It NEVER blocks —
# exits 0 always. Its only job is to surface gentle reminders when changes
# look architecturally consequential.
#
# Triggers:
#   - Many files modified in the current session (>= 10) without a recent
#     ADR change.
#   - A new top-level directory appears in the working tree.
#   - A package manifest (package.json, pyproject.toml, Cargo.toml, go.mod)
#     was changed (suggests a new dependency).

set -u

# Bail silently if not in a git repo — we use git for change detection.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
cd "$REPO_ROOT" 2>/dev/null || exit 0

# --- 1. Large changeset reminder ---------------------------------------------

CHANGED_COUNT=$(git diff --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')
ADR_CHANGED=$(git diff --name-only HEAD 2>/dev/null | grep -c "docs/architecture/decisions/" || true)

if [ "${CHANGED_COUNT:-0}" -ge 10 ] && [ "${ADR_CHANGED:-0}" -eq 0 ]; then
  cat <<EOF >&2
[archforge] Reminder: ${CHANGED_COUNT} files changed in this session and no ADR has been touched.
            If this represents an architectural decision (new module, pattern, dependency, structural shift),
            consider running /archforge:adr to capture it. Implicit decisions become tomorrow's tech debt.
EOF
fi

# --- 2. Manifest changes (new dependency suspect) ----------------------------

MANIFEST_CHANGED=""
for manifest in package.json pyproject.toml Cargo.toml go.mod composer.json Gemfile pom.xml build.gradle build.gradle.kts; do
  if git diff --name-only HEAD 2>/dev/null | grep -qx "$manifest"; then
    MANIFEST_CHANGED="$manifest"
    break
  fi
done

if [ -n "$MANIFEST_CHANGED" ]; then
  cat <<EOF >&2
[archforge] Reminder: \`$MANIFEST_CHANGED\` was modified — possibly a new dependency.
            New dependencies are architectural decisions. If this is non-trivial (a runtime, a framework,
            a security-sensitive lib), run /archforge:adr to record why this dep was chosen over alternatives.
EOF
fi

# --- 3. New top-level directory ---------------------------------------------

NEW_TOP_DIRS=$(git status --porcelain 2>/dev/null \
  | awk '$1 ~ /^\?\?$/ {print $2}' \
  | awk -F/ 'NF >= 2 && $1 != "" {print $1}' \
  | sort -u)

if [ -n "$NEW_TOP_DIRS" ]; then
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    # Ignore obvious noise (build artifacts, IDE files, deps).
    case "$dir" in
      node_modules|.next|.nuxt|.output|dist|build|target|.venv|__pycache__|.idea|.vscode|.cache|coverage|.git)
        continue
        ;;
    esac
    cat <<EOF >&2
[archforge] Reminder: new top-level directory \`$dir/\` detected.
            If this represents a new module/component in the system, consider updating ARCHITECTURE.md
            (high-level structure, decision index) and possibly the C4 container diagram.
EOF
  done <<< "$NEW_TOP_DIRS"
fi

# --- 4. Many modules touched — suggest observe -------------------------------

MODULES_TOUCHED=$(git diff --name-only HEAD 2>/dev/null \
  | awk -F/ '{print $1}' \
  | sort -u \
  | grep -v -E '^(node_modules|\.next|\.nuxt|\.output|dist|build|target|\.venv|__pycache__|\.idea|\.vscode|\.cache|coverage|\.git|docs)$' \
  | wc -l | tr -d ' ')

# Last-observe marker prevents nagging on every commit.
LAST_OBSERVE_FILE="docs/architecture/.last-observe"
SHOULD_NUDGE_OBSERVE=0

if [ "${MODULES_TOUCHED:-0}" -ge 4 ]; then
  if [ ! -f "$LAST_OBSERVE_FILE" ]; then
    SHOULD_NUDGE_OBSERVE=1
  else
    # Only nudge if observe was last run more than 14 days ago.
    if find "$LAST_OBSERVE_FILE" -mtime +14 2>/dev/null | grep -q .; then
      SHOULD_NUDGE_OBSERVE=1
    fi
  fi
fi

if [ "$SHOULD_NUDGE_OBSERVE" -eq 1 ]; then
  cat <<EOF >&2
[archforge] Reminder: ${MODULES_TOUCHED} modules touched in this session, and architectural observation hasn't run recently.
            Consider \`/archforge:observe\` to surface implicit decisions, stale deferrals, or strategy-without-architecture gaps.
EOF
fi

# Always succeed — these are nudges, not gates.
exit 0

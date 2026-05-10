#!/usr/bin/env bash
# archforge — session start hook.
#
# Surfaces ARCHITECTURE.md and the ADR index at session start so Claude is
# primed with architectural context. Never blocks; always exits 0.

set -u

# Bail silently if not in a git repo (avoids noise outside projects).
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
cd "$REPO_ROOT" 2>/dev/null || exit 0

ARCH_FILE="$REPO_ROOT/ARCHITECTURE.md"
ADR_DIR="$REPO_ROOT/docs/architecture/decisions"

if [ -f "$ARCH_FILE" ]; then
  cat <<EOF >&2
[archforge] ARCHITECTURE.md found at repo root. The architect skill treats it as binding context.
EOF
  if [ -d "$ADR_DIR" ]; then
    ADR_COUNT=$(find "$ADR_DIR" -maxdepth 1 -type f -name '[0-9]*.md' 2>/dev/null | wc -l | tr -d ' ')
    if [ "${ADR_COUNT:-0}" -gt 0 ]; then
      echo "[archforge] ${ADR_COUNT} ADR(s) in docs/architecture/decisions/." >&2
    fi
  fi
else
  # ARCHITECTURE.md missing. Suggest /archforge:init only if the repo looks
  # non-trivial (more than 20 tracked files).
  TRACKED=$(git ls-files 2>/dev/null | wc -l | tr -d ' ')
  if [ "${TRACKED:-0}" -ge 20 ]; then
    cat <<EOF >&2
[archforge] No ARCHITECTURE.md detected in this project. For architectural work, run /archforge:init
            to bootstrap a living architecture document and docs/architecture/ skeleton.
EOF
  fi
fi

exit 0

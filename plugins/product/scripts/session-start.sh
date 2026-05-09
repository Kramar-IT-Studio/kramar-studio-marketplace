#!/usr/bin/env bash
# product — session start hook.
#
# Surfaces PRODUCT.md and product artifact state at session start so Claude is
# primed with product context. Never blocks; always exits 0.

set -u

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
cd "$REPO_ROOT" 2>/dev/null || exit 0

PRODUCT_FILE="$REPO_ROOT/PRODUCT.md"
PRODUCT_DIR="$REPO_ROOT/docs/product"
VERSION_FILE="$REPO_ROOT/.product-version"

if [ -f "$PRODUCT_FILE" ]; then
  cat <<EOF >&2
[product] PRODUCT.md found at repo root. The product-cycle skill treats it as binding context.
EOF

  if [ -d "$PRODUCT_DIR" ]; then
    HYP_COUNT=$(find "$PRODUCT_DIR/discoveries" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    PRD_COUNT=$(find "$PRODUCT_DIR/prds" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    SPEC_COUNT=$(find "$PRODUCT_DIR/specs" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    VAL_COUNT=$(find "$PRODUCT_DIR/validations" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    SCAN_COUNT=$(find "$PRODUCT_DIR/research" -maxdepth 1 -type f -name '*-market-scan.md' 2>/dev/null | wc -l | tr -d ' ')

    TOTAL=$((HYP_COUNT + PRD_COUNT + SPEC_COUNT + VAL_COUNT + SCAN_COUNT))
    if [ "$TOTAL" -gt 0 ]; then
      echo "[product] Artifacts: ${SCAN_COUNT} SCAN, ${HYP_COUNT} HYP, ${PRD_COUNT} PRD, ${SPEC_COUNT} SPEC, ${VAL_COUNT} VAL." >&2
    fi
  fi

  # Stale market-scan check (>90 days, any area).
  if [ -d "$PRODUCT_DIR/research" ]; then
    STALE_SCANS=$(find "$PRODUCT_DIR/research" -maxdepth 1 -type f -name '*-market-scan.md' -mtime +90 2>/dev/null | wc -l | tr -d ' ')
    if [ "${STALE_SCANS:-0}" -gt 0 ]; then
      cat <<EOF >&2
[product] ${STALE_SCANS} market-scan(s) older than 90 days. Consider /product:market-scan to refresh before starting new work in those areas.
EOF
    fi
  fi

  # Version drift check.
  if [ -f "$VERSION_FILE" ]; then
    PROJECT_VERSION=$(head -n1 "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]')
    PLUGIN_VERSION=$(grep -E '"version"' "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" 2>/dev/null \
      | head -n1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    if [ -n "$PROJECT_VERSION" ] && [ -n "$PLUGIN_VERSION" ] && [ "$PROJECT_VERSION" != "$PLUGIN_VERSION" ]; then
      cat <<EOF >&2
[product] .product-version (${PROJECT_VERSION}) differs from installed plugin (${PLUGIN_VERSION}). Run /product:upgrade.
EOF
    fi
  fi

else
  # PRODUCT.md missing. Suggest /product:init only if the repo looks non-trivial.
  TRACKED=$(git ls-files 2>/dev/null | wc -l | tr -d ' ')
  if [ "${TRACKED:-0}" -ge 20 ]; then
    cat <<EOF >&2
[product] No PRODUCT.md detected in this project. For product work, run /product:init
          to bootstrap PRODUCT.md and the docs/product/ skeleton.
EOF
  fi
fi

exit 0

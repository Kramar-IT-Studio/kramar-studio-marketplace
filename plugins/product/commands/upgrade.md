---
description: Migrate the project's product artifacts to the currently installed plugin version.
argument-hint: "(no arguments)"
---

# /product:upgrade

Migrate `docs/product/`, `PRODUCT.md`, and `.product-version` from the version recorded in `.product-version` to the version of the currently installed `product` plugin.

## Steps

1. **Read the current plugin version** from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.

2. **Read `.product-version`** at the repository root.
   - If missing → refuse. Tell the user to run `/product:init` first.
   - If equal to the plugin version → tell the user there's nothing to do.
   - Otherwise → run migrations.

3. **Run migrations sequentially** from `${CLAUDE_PLUGIN_ROOT}/migrations/` (one migration file per version step, named `NNNN-from-X.Y.Z-to-A.B.C.md`).

   Each migration file describes:
   - What changes structurally (file moves, renamed sections, new front-matter fields).
   - What to leave alone.
   - How to handle conflicts.

   In v0.1 there are no migrations yet — this command is a stub that reports "no migrations to run; updating `.product-version`".

4. **Update `.product-version`** to the current plugin version after all migrations succeed.

5. **Report**:
   - Versions migrated through.
   - Files touched.
   - Anything that needs the user's manual attention.

## Discipline

- **Never delete artifacts.** Migrations transform; they don't drop. If a category is removed from the layout, the artifacts move to `docs/product/archive/` with a status transition to `archived`.
- **Never re-number IDs.** ID prefixes (HYP/PRD/SPEC/VAL/SCAN) are stable across versions.
- **Show the migration plan before applying** when migrating ≥2 versions. Ask the user to confirm.
- **Refuse on a dirty working tree.** Migrations touch many files; the user needs a clean baseline to inspect the diff. Tell them to commit or stash first.

## When to abort

If `.product-version` records a version newer than the installed plugin (downgrade), refuse and tell the user to install a newer plugin version. Don't downgrade artifacts silently.

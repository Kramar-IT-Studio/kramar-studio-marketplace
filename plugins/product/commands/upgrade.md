---
description: Migrate the project's product artifacts to the currently installed plugin version.
argument-hint: "(no arguments)"
---

# /product:upgrade

Migrate this project's product artifacts to the currently installed version of the
`product` plugin. This command updates **the project** (artifacts under `docs/product/`,
`PRODUCT.md`, the `.product-version` marker) — it does **not** update the plugin code
itself (that's `/plugin marketplace update` + `/plugin install`).

Migrations are separate files under `${CLAUDE_PLUGIN_ROOT}/migrations/`, named
`NNNN-from-X.Y.Z-to-A.B.C.md`. This command is the runner. The migration file format is
documented in README §7 and `product-conventions`; see ADR-0003 for the rationale.

## Steps

### 1. Read the installed plugin version

Read `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` → `version`. If you can't read it,
abort: "Couldn't determine the installed plugin version. Is the plugin installed correctly?"

### 2. Read the project marker

Read `.product-version` at the **repository root** (single-line SemVer string).

- **Missing** → recovery flow, do **not** crash: tell the user the marker is absent and
  offer (a) re-run `/product:init`, or (b) specify the last-known version manually so the
  runner can proceed. (ADR-0002 rule 3.)
- **`docs/product/` itself absent** → the project isn't initialized: "Run `/product:init`
  first." Stop.

### 3. Determine the migration path

List `${CLAUDE_PLUGIN_ROOT}/migrations/*.md`, ignore `_TEMPLATE.md`, parse each file's
`from` / `to` front-matter. Select migrations with `from ≥ marker` and `to ≤ installed`,
ordered by `migration` (NNNN).

- `installed == marker` → no-op: "Already at product `<version>`. Nothing to migrate."
- `installed < marker` (downgrade) → refuse: the marker is ahead of the installed plugin.
  Do not downgrade artifacts.

### 4. Refuse on a dirty working tree

Run `git status --porcelain`. If non-empty, refuse: "Commit or stash first — migrations
touch files and a clean baseline is your rollback." `git` is the primary rollback path.

### 5. Show the changelog summary

Read `${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md`; surface, in one block, what each version step
between marker and installed does at a high level. Informational — no files touched yet.

### 6. Confirm before mutating

Summarize what each migration will change (files created/edited, structural changes).
**Mandatory when ≥2 migrations** will run. Wait for confirmation.

### 7. Run migrations in order

For each selected migration, in `NNNN` order:

1. Check its `## Preconditions`. If unmet, stop and report — do not partially apply.
2. If front-matter `mutates_frontmatter: true`, copy every file the `## Transform` will
   touch into `docs/product/.upgrade-backup/<from>-to-<to>/` before changing anything.
3. Apply the `## Transform` steps exactly.
4. Run the `## Verification` checks. If any fails, stop and report; leave the marker at the
   previous step's value.
5. **Write `.product-version` = this migration's `to`** (per-step atomicity).
6. Log to chat: "Applied <from> → <to>."

### 8. Report

- Versions migrated through.
- Files touched (created / edited / no-op), and any backup directory written.
- Breaking changes from the CHANGELOG, surfaced individually.
- Recommended next steps the migrations didn't auto-apply.

## Discipline

- **Never delete artifacts.** Migrations transform; they don't drop. A removed category
  moves to `docs/product/archive/` with a status transition to `archived`.
- **Never re-number IDs.** Prefixes (HYP/PRD/SPEC/VAL/SCAN) are stable across versions.
- **Per-step atomicity.** The marker advances only after a migration's Verification passes.
  A mid-run failure leaves the marker at the last completed step; the next run resumes.
- **Refuse on a dirty working tree.** Stated above.
- **Idempotent.** Re-running on an already-current project is a no-op.

## When to abort

- Marker newer than installed plugin (downgrade) → refuse.
- Plugin version unreadable → abort with a clear message.
- `docs/product/` missing → route to `/product:init`.

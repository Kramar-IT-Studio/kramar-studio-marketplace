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
documented in README §7, `product-conventions`, and `migrations/_TEMPLATE.md`; see ADR-0003
for the rationale.

## Steps

### 1. Read the installed plugin version

Read `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` → `version`. If you can't read it,
abort: "Couldn't determine the installed plugin version. Is the plugin installed correctly?"

### 2. Read the project marker

Read `.product-version` at the **repository root** (single-line SemVer string).

- **Missing or not a valid SemVer string** → recovery flow, do **not** crash: tell the user
  the marker is absent/unreadable and offer (a) re-run `/product:init`, (b) specify the
  last-known version manually, or (c) treat the project as `0.0.0` and apply all migrations.
  Confirm before proceeding under (b)/(c). (ADR-0002 rule 3.)
- **`docs/product/` itself absent** → the project isn't initialized: "Run `/product:init`
  first." Stop.

### 3. Determine the migration path

- `installed == marker` → no-op: "Already at product `<version>`. Nothing to migrate." Stop.
- `installed < marker` (downgrade) → refuse: the marker is ahead of the installed plugin.
  Do not downgrade artifacts. Stop.

Otherwise (`installed > marker`): list `${CLAUDE_PLUGIN_ROOT}/migrations/*.md`, ignore
`_TEMPLATE.md`, parse each file's `from` / `to`. Select migrations with `to > marker` **and**
`to ≤ installed`, ordered ascending by `to` (equivalently by `migration` NNNN). Migrations
are **sparse**: most version steps have no migration file, and an absent migration for a
step is a legitimate no-op — not an error. Compare versions by SemVer precedence (a
pre-release like `0.4.0-rc1` sorts before `0.4.0`).

### 4. Refuse on a dirty working tree

Run `git status --porcelain`. If non-empty, refuse: "Commit or stash first — migrations
touch files and a clean baseline is your rollback." `git` is the primary rollback path.

### 5. Show the changelog summary

Read `${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md`; surface, in one block, what each version step
between marker and installed does at a high level. Informational — no files touched yet.

### 6. Confirm before mutating

Summarize what each migration will change (files created/edited, structural changes), then
**wait for confirmation before mutating any files**. A migration whose `## Transform` is a
declared no-op (no file changes) may proceed without waiting.

### 7. Run migrations in order

For each selected migration, in ascending `to` order:

1. Check its `## Preconditions`. If unmet, stop and report — do not partially apply.
2. If front-matter `mutates_frontmatter: true`, copy every file the `## Transform` will
   touch into `docs/product/.upgrade-backup/<from>-to-<to>/` before changing anything.
3. Apply the `## Transform` steps exactly.
4. Run the `## Verification` checks. If any fails, stop and report; leave the marker at the
   previous step's value.
5. **Write `.product-version` = this migration's `to`** (per-step atomicity).
6. Log to chat: "Applied <from> → <to>."

After the last selected migration — or immediately, if the selected set was empty but
`installed > marker` — **write `.product-version` = `installed`** to reconcile the tail of
no-migration version steps. After a successful run the marker always equals the installed
version (ADR-0002 rule 3).

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

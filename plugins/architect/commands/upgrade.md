---
description: Migrate the project's architect artifacts to the latest plugin version. Updates AGENTS.md integration block, refreshes templates, adds new structural sections to ARCHITECTURE.md if needed, and surfaces breaking changes from the changelog. Does NOT update the plugin itself — that's a Claude Code action; this command makes the project ready for the new version.
argument-hint: "(no arguments)"
---

# /architect:upgrade

Migrate this project's architect artifacts to the currently installed version of the
plugin. This command updates **the project** (artifacts under `docs/architecture/`,
`AGENTS.md`, `ARCHITECTURE.md`) — it does **not** update the plugin code itself (that's
`/plugin marketplace update` + `/plugin install`).

Migrations are separate files under `${CLAUDE_PLUGIN_ROOT}/migrations/`, named
`NNNN-from-X.Y.Z-to-A.B.C.md`. This command is the runner. The migration file format is
documented in README §7 and `adr-writing` / `role`; see ADR-0003 for the rationale.

## Steps

### 1. Read the installed plugin version

Read `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` → `version`. If you can't read it,
abort: "Couldn't determine the installed plugin version. Is the plugin installed correctly?"

### 2. Read the project marker

Read `docs/architecture/.architect-version` (single-line SemVer string).

- **Missing** → check for legacy markers in this order: `.archforge-version` (pre-rename,
  ADR-0001), then `.krait-arch-version` (plugin versions 0.4.0-rc1/rc2 when named
  `krait_arch`). If a legacy marker is found, ask the user to confirm migrating it: read its
  contents, write `docs/architecture/.architect-version` with the same string, and delete
  the legacy marker. Tell the user which legacy marker was detected and renamed.
- **No marker and no legacy marker, but `docs/architecture/` exists** → treat as `0.0.0`
  (all migrations apply); confirm with the user first, since for a long-lived project this
  may be a non-trivial set of changes.
- **`docs/architecture/` itself absent** → "This project hasn't been initialized for
  architect. Run `/architect:init` first." Stop.

### 3. Determine the migration path

List `${CLAUDE_PLUGIN_ROOT}/migrations/*.md`, ignore `_TEMPLATE.md`, parse each file's
`from` / `to`. Select migrations with `from ≥ marker` and `to ≤ installed`, ordered by
`migration` (NNNN).

- `installed == marker` → no-op: "Already at architect `<version>`. Nothing to migrate."
- `installed < marker` (downgrade) → refuse: the marker is ahead of the installed plugin.

### 4. Refuse on a dirty working tree

Run `git status --porcelain`. If non-empty, refuse: "Commit or stash first — migrations
touch files and a clean baseline is your rollback."

### 5. Show the changelog summary

Read `${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md`; surface what each version step between marker and
installed does. Informational — no files touched yet.

### 6. Confirm before mutating

Summarize what each migration will change. **Mandatory when ≥2 migrations** will run.
Preserve user customizations: if a migration wants to refresh a section the user edited,
diff it and ask before overwriting. Wait for confirmation.

### 7. Run migrations in order

For each selected migration, in `NNNN` order:

1. Check its `## Preconditions`. If unmet, stop and report.
2. If front-matter `mutates_frontmatter: true`, copy every file the `## Transform` will
   touch into `docs/architecture/.upgrade-backup/<from>-to-<to>/` first.
3. Apply the `## Transform` steps. Migrations are additions or in-place section updates;
   they never delete user-authored content.
4. Run the `## Verification` checks. On failure, stop; leave the marker at the previous
   step's value.
5. **Write `docs/architecture/.architect-version` = this migration's `to`** (per-step
   atomicity); one-line file, trailing newline.
6. Log to chat: "Applied <from> → <to>."

### 8. Report

- Versions migrated through.
- Files touched (created / edited / no-op), and any backup directory written.
- Breaking changes from the CHANGELOG ("BREAKING:" entries), surfaced individually.
- Recommended next steps the migrations didn't auto-apply.

## Discipline

- **Idempotent.** Re-running on an already-current project is a no-op.
- **Per-step atomicity.** The marker advances only after a migration's Verification passes;
  a mid-run failure leaves it at the last completed step and the next run resumes.
- **No destructive changes without explicit confirmation.**
- **Don't pretend to update the plugin code itself.** State this when relevant.
- **Don't edit files outside `docs/architecture/`, `AGENTS.md`, `CLAUDE.md`,
  `ARCHITECTURE.md`, `STRATEGY.md`.**
- **Preserve user customizations.** Diff and ask before overwriting edited sections.

## When to abort

- Marker newer than installed plugin (downgrade) → refuse.
- Plugin version unreadable → abort with a clear message.
- `docs/architecture/` missing → route to `/architect:init`.

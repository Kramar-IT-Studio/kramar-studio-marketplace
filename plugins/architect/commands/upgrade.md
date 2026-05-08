---
description: Migrate the project's archforge artifacts to the latest plugin version. Updates AGENTS.md integration block, refreshes templates, adds new structural sections to ARCHITECTURE.md if needed, and surfaces breaking changes from the changelog. Does NOT update the plugin itself — that's a Claude Code action; this command makes the project ready for the new version.
argument-hint: "(no arguments)"
---

# /archforge:upgrade

Migrate this project's archforge artifacts to the currently installed version of the plugin.

**Important framing**: this command does not update the plugin code itself. Plugin code lives in `~/.claude/plugins/` and is updated through Claude Code's plugin commands (`/plugin marketplace update`, `/plugin install`). This command updates **the project** to take advantage of features and conventions in the new plugin version.

Run this command after `/plugin marketplace update archforge-marketplace` and `/plugin install archforge@archforge-marketplace` have brought your installed plugin to a new version, especially across minor versions (0.2 → 0.3, etc.).

## What it does

1. Reads the **installed plugin version** from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.
2. Reads the **project's last upgrade marker** from `docs/architecture/.archforge-version` (a single-line file with a version string). If the file is missing, treats the project as last touched by 0.0.0.
3. Reads `${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md` and identifies entries between the project's last version and the installed version.
4. For each version step, runs the migrations associated with that step (see migration list below).
5. Updates `docs/architecture/.archforge-version` to the installed version.
6. Surfaces breaking changes and required follow-up actions.

This command is **idempotent**: running it twice in a row is safe; the second run is a no-op.

## Migrations by version

These are the project-side changes per version. Each migration only runs once per project — gated by the version marker.

### 0.2 → 0.3

- **Refresh integration block in `AGENTS.md`** if present. The 0.3 block includes the `Research` phase in the workflow diagram and adds language-detection support. Run the equivalent of `/archforge:remember-compound-integration` and let it replace the block in place. Detect the project's working language; the new block is written in that language.
- **Add `decision-map.md` skeleton if missing**, but only if there are ≥3 open architectural questions in `ARCHITECTURE.md` or ≥2 ADRs already exist. Otherwise leave a note in chat suggesting `/archforge:map` as an optional next step.
- **Add `Status` section to existing review files** in `docs/architecture/reviews/` if they don't have one. Default to `Status: Open` unless a closeout block already exists.
- **Surface to user**: terminology pass for Russian artifacts is now mandatory (was advisory in 0.2). If the project has Russian artifacts, suggest re-running `/archforge:review` on key ADRs to apply the terminology pass.
- **No file deletions, no destructive changes.**

### 0.3 → 0.4 (placeholder)

When 0.4 lands, this section gets the migration steps. The structure is fixed; the content evolves.

## Inputs

- Project files: `docs/architecture/` directory, `AGENTS.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `STRATEGY.md`.
- Plugin files (read-only): `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`, `${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md`, `${CLAUDE_PLUGIN_ROOT}/templates/*`.

## Steps

### 1. Read the installed plugin version

```
${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json → "version"
```

If you can't read it for any reason, abort with a message: "Couldn't determine the installed plugin version. Is the plugin installed correctly?"

### 2. Read the project's last upgrade marker

```
./docs/architecture/.archforge-version
```

If the file doesn't exist, check for the legacy marker `.krait-arch-version` (used in plugin versions 0.4.0-rc1 and rc2 when the plugin was named `krait_arch`). If found, read its contents and rename it to `.archforge-version` as part of the migration. Tell the user: "Detected legacy marker `.krait-arch-version` from pre-rename plugin versions. Renamed to `.archforge-version`."

If neither marker exists, the project was last touched by an unknown earlier version. Treat as 0.0.0 — all migrations apply (this is the same effect as a fresh init plus all migrations).

If `docs/architecture/` itself doesn't exist, the project hasn't been initialized for archforge. Tell the user: "This project hasn't been initialized for archforge. Run `/archforge:init` first."

### 3. Determine the migration path

Compute the list of migrations to run (each migration is gated by `from_version`).

If the installed version equals the marker version, no-op: tell the user "Already at version X. No migration needed."

If the installed version is older than the marker (downgrade detected), refuse: tell the user the marker is ahead of the installed plugin and abort. Do not attempt to "downgrade" the project — that risks data loss.

### 4. Read the changelog

Identify the entries between marker and installed version. Tell the user, in one block, what each version did at a high level. This is informational — the user sees what's changing before any files are touched.

### 5. Confirm with the user before mutating files

Before running migrations, summarize what will change: which files will be edited, which will be created, what the structural changes are. Wait for the user's confirmation. Do not make destructive changes silently.

### 6. Run the migrations in order

For each version step from marker to installed, run that step's migration block. Migrations are pure additions or in-place section updates; they never delete user-authored content.

After each migration block, log to chat: "Applied 0.X → 0.Y migration."

### 7. Update the marker

Write the installed version to `docs/architecture/.archforge-version`. This is a one-line file with just the version string and a trailing newline.

### 8. Output to chat

- The version migrated from and to.
- The list of files touched (created, edited, no-op).
- Any **breaking changes** the user must handle manually — the changelog "BREAKING:" entries, surfaced individually.
- Any **recommended next steps** the migrations didn't auto-apply (e.g., "we suggest running `/archforge:roast` on ADR-0001 since deep-cycle roast is new in 0.3").

## Discipline

- **Idempotent.** Re-running on an already-current project is a no-op.
- **No destructive changes without explicit confirmation.** Even if a migration logically wants to delete or rewrite a file, ask first.
- **Don't pretend to update the plugin code itself.** That's outside the command's scope. State this explicitly when relevant.
- **Don't edit files outside `docs/architecture/`, `AGENTS.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `STRATEGY.md`.** Other files are out of bounds.
- **Preserve user customizations.** If a user has edited a section of `ARCHITECTURE.md` that a migration wants to refresh, diff it and ask before overwriting.

## Failure modes

- **Plugin not installed**: abort with clear message.
- **Project not initialized**: route to `/archforge:init`.
- **Marker present but unreadable**: treat as 0.0.0 and proceed (with confirmation).
- **Migration fails midway**: leave the marker at the last successful version. The next run picks up from there.

## When the user is on the latest version

If the marker equals the installed version: "Project is already at archforge <version>. Nothing to migrate. Run `/archforge:upgrade` again after updating the plugin."

## When the marker is missing but `docs/architecture/` exists

Most likely an existing project from before 0.3 (when this command was added). Treat as 0.0.0 and run all migrations from the beginning. Confirm with the user first — for a long-lived project this might be a non-trivial set of changes.

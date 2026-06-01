# Design: Migration mechanism for Kramar Studio Suite (ADR-0002 B1)

- **Date:** 2026-06-01
- **Track:** STRATEGY Track A (product maturity) ∩ Track C / B1 (migration format & procedure)
- **Upstream decision:** [ADR-0002 — multi-level versioning contract](../../architecture/decisions/0002-multi-level-versioning-contract.md)
- **Status:** approved (brainstorm complete; ready for implementation plan)

## Problem

The migration mechanism promised across the repo is empty **and** specified in two
incompatible ways:

- **Model B (declared, binding docs):** `CLAUDE.md`, ADR-0002, and `product/upgrade.md`
  all prescribe separate files `plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md`
  run sequentially, with marker atomicity and backup-before-mutation.
- **Model A (actual, reference plugin):** `architect/upgrade.md` carries migrations
  *inline* as version-gated prose blocks (`### 0.2 → 0.3`); there is no `migrations/`
  directory anywhere in the repo.

Neither plugin can actually run a migration today. `architect` (the reference
implementation) diverges from its own binding contract — per `CLAUDE.md`'s own rule
("diverging is a bug in the plugin, not a precedent") this is drift in `architect`,
not a precedent.

## Decisions (locked during brainstorm)

1. **Model B is binding** for the whole suite — separate files in `migrations/`.
   This *executes* ADR-0002 (no edit to the Accepted ADR); `architect` is reconciled
   to it.
2. **Scope = product + architect reconciliation** (not product-only).
3. **product gets the symbolic 1.0.0 bump** (ADR-0002 rule 5) with a real first
   migration that is a maturity-transition no-op (no artifact transform exists yet).
4. **architect bump = 1.1.0 (minor)** — behavior-preserving refactor + new
   `.archforge-version` recovery path; not breaking per ADR-0002 rule 4.
5. **A short ADR-0003 records B1** (format & procedure), since ADR-0002 slated B1 as
   its own cycle and the per-step atomicity refinement deserves a record.

## Non-goals

- Normalizing marker locations. `product` writes `.product-version` at repo root;
  `architect` uses `docs/architecture/.architect-version`. ADR-0002 rule 3 does not pin
  location. Normalizing would itself break existing users and require a migration.
  **Kept per-plugin; documented as "marker location is declared in the plugin's
  conventions."**
- Real frontmatter transformation. No such migration is due yet; the format supports it,
  the first migration does not exercise it.
- Version-checking tooling / CI (explicitly out of scope in ADR-0002).

## 1. Migration file format (the contract)

Path: `plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md`

Front-matter:

```yaml
---
migration: NNNN              # zero-padded, monotonic
from: X.Y.Z                  # marker value at which this migration applies
to: A.B.C                    # marker value after success
mutates_frontmatter: false   # true → runner takes a backup before mutating
scope: project-docs | artifacts | both
---
```

Body sections (fixed):

- `## Summary` — one line: what changes in the user's project.
- `## Preconditions` — what must hold; the runner verifies.
- `## Transform` — ordered imperative steps (file moves, section adds, optional
  front-matter field additions). Prose, like architect's current blocks.
- `## Backup` — meaningful only when `mutates_frontmatter: true`.
- `## Verification` — post-conditions checked before the marker is written.
- `## Rollback note` — usually "git; the tree is clean by precondition."
- `## Never` — invariants: never delete artifacts, never renumber IDs.

A copy-paste `migrations/_TEMPLATE.md` ships in each plugin. The runner ignores any file
not matching `NNNN-from-X.Y.Z-to-A.B.C.md` (so `_TEMPLATE.md` is never executed).

## 2. The upgrade runner (shared procedure, both plugins)

`upgrade.md` becomes a thin runner with identical shape across plugins:

1. Read the installed plugin version from `plugin.json`.
2. Read the marker (location is plugin-specific). Missing → recovery flow (re-init or
   manual version); **do not crash** (rule 3). Docs directory absent → route to `init`.
3. Build the migration path: files with `from ≥ marker` and `to ≤ installed`, ordered by
   `NNNN`. `installed == marker` → no-op. `installed < marker` → refuse (downgrade).
4. **Refuse on a dirty working tree** (git is the primary rollback).
5. Show a CHANGELOG summary between marker and installed.
6. Confirm before mutating (mandatory when ≥2 steps).
7. For each migration, in order:
   1. Check preconditions.
   2. If `mutates_frontmatter: true` → copy affected files to
      `docs/<role>/.upgrade-backup/<from>-to-<to>/`.
   3. Apply `## Transform` steps.
   4. Run `## Verification`.
   5. **Write the marker = this migration's `to`** (per-step atomicity).
   6. Log "Applied X→Y".
8. Report: versions, files touched, manual follow-ups, breaking changes from CHANGELOG.

**Atomicity (per-step).** The marker is written after each successful step; a mid-run
failure leaves the marker at the last completed step. This refines ADR-0002 rule 3
("atomic with the last migration") to per-step granularity and matches what
`architect/upgrade.md` already declares ("leave the marker at the last successful
version"). Treated as an implementation detail within rule 3's intent — **not** an edit to
the Accepted ADR; recorded in ADR-0003.

**Backup.** Primary rollback is git (the dirty-tree refusal guarantees a clean baseline).
An explicit backup directory is taken **only** when `mutates_frontmatter: true`, satisfying
ADR-0002's C-3 compliance requirement (regulated/PII content). The report names the backup
path; the user may delete it after verifying.

## 3. product → symbolic 1.0.0

Plugin-side (edits in this repo):

- `plugins/product/.claude-plugin/plugin.json`: `0.1.0 → 1.0.0`.
- Root `README.md` table row: `🟡 scaffolded / 0.1.0` → `🟢 active / 1.0.0`.
- New `plugins/product/CHANGELOG.md` (Keep-a-Changelog): a retrospective `[0.1.0]`
  initial-scaffold entry + a `[1.0.0]` entry whose top line is exactly
  `No breaking API changes — version reflects maturity transition (scaffolded → active)`
  (rule 5).
- `marketplace.json` is untouched (it carries no per-plugin version; rule 2).
- Remove the "in v0.1 there are no migrations yet — stub" text from `product/upgrade.md`.

Project-side: `plugins/product/migrations/0001-from-0.1.0-to-1.0.0.md`,
`mutates_frontmatter: false`, empty `## Transform` — an honest maturity-transition no-op
that doubles as the simplest worked example of the format and exercises the runner
end-to-end.

## 4. architect reconciliation

- `plugins/architect/migrations/0001-from-0.2.0-to-0.3.0.md` — the current `0.2 → 0.3`
  inline block re-expressed in the new format.
- `architect/upgrade.md` → the shared thin runner. Keep architect specifics: marker in
  `docs/architecture/`, legacy `.krait-arch-version` handling. **Add** the
  `.archforge-version → .architect-version` transition path (ADR-0002 rule 3, "at first
  convenience").
- Drop the inline `0.3 → 0.4 (placeholder)` (future migrations are just new files).
- Version: `1.0.0 → 1.1.0` (minor). CHANGELOG entry + README table version.
- `migrations/_TEMPLATE.md` added.

## 5. Documentation

- Root `README.md` "Kramar Studio Plugin Conventions": expand the existing migration
  bullet into the full format spec (canonical home of the meta-form). Mirror a condensed
  version in `CLAUDE.md`.
- `plugins/product/skills/product-conventions/SKILL.md`: document the `.product-version`
  marker location (currently undocumented) + a pointer to the migration format.
- `docs/architecture/decision-map.md`: B1 → `decided` / in-progress with a reference to
  ADR-0003.
- New `docs/architecture/decisions/0003-migration-format-and-procedure.md` (short ADR):
  records Model B execution, per-step atomicity, backup posture, marker-location-per-plugin.
  Update `ARCHITECTURE.md` decision index.

## Risks

- **Marker in two locations** stays a latent confusion for future `ops`/`security`.
  Mitigation: pin "marker location = a field in the plugin's conventions."
- **architect minor bump with no external behavior change** may surprise a downstream
  auditor. Mitigation: explicit CHANGELOG wording.
- **A no-op first migration** may read as pointless. Mitigation: `## Summary` states the
  maturity-transition intent explicitly.

## File-by-file change list

New:
- `plugins/product/migrations/_TEMPLATE.md`
- `plugins/product/migrations/0001-from-0.1.0-to-1.0.0.md`
- `plugins/product/CHANGELOG.md`
- `plugins/architect/migrations/_TEMPLATE.md`
- `plugins/architect/migrations/0001-from-0.2.0-to-0.3.0.md`
- `docs/architecture/decisions/0003-migration-format-and-procedure.md`

Edited:
- `plugins/product/commands/upgrade.md` (runner; drop stub)
- `plugins/product/.claude-plugin/plugin.json` (1.0.0)
- `plugins/product/skills/product-conventions/SKILL.md` (marker location + format pointer)
- `plugins/architect/commands/upgrade.md` (runner; move inline block out; add
  `.archforge-version` path)
- `plugins/architect/.claude-plugin/plugin.json` (1.1.0)
- `plugins/architect/CHANGELOG.md` (1.1.0 entry)
- `README.md` (conventions expansion + product/architect table rows)
- `CLAUDE.md` (condensed mirror of the format)
- `ARCHITECTURE.md` (ADR-0003 in decision index)
- `docs/architecture/decision-map.md` (B1 → decided)

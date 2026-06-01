# Migration Mechanism Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the suite's promised migration mechanism real and consistent — separate `migrations/` files run by a thin `upgrade` runner — then apply it to `product` (symbolic 1.0.0) and reconcile `architect` to it.

**Architecture:** Migrations are markdown files `plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md` with typed front-matter and fixed sections. `/<role>:upgrade` is an LLM-executed runner that reads them in order, applies the prose `Transform` steps, and writes the `.<plugin>-version` marker per-step (atomicity). This *executes* ADR-0002 (Model B); the inline-migration drift in `architect` is reconciled to it.

**Tech Stack:** Markdown command/skill files + a small amount of bash in the runner prose. No build/test runner exists (per `CLAUDE.md`), so "verification" steps are concrete file/consistency checks plus one manual end-to-end exercise via `/reload-plugins`.

**Spec:** [`docs/superpowers/specs/2026-06-01-product-migration-mechanism-design.md`](../specs/2026-06-01-product-migration-mechanism-design.md)

---

## Conventions for every commit in this plan

- Commit messages follow the repo's conventional-commit style (`feat(scope): …`, `docs(scope): …`, `chore(scope): …`).
- End each commit message with the trailer:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- Do not push; committing happens per-task, pushing is a separate user-initiated action.

---

## Task 1: Migration file format (the contract)

**Files:**
- Create: `plugins/product/migrations/_TEMPLATE.md`
- Create: `plugins/architect/migrations/_TEMPLATE.md`
- Modify: `README.md` (§7 Versioning contract, after line 202)
- Modify: `CLAUDE.md` ("Common operations" — the migration sentence)

- [ ] **Step 1: Create the shared template for `product`**

Create `plugins/product/migrations/_TEMPLATE.md` with exactly this content:

````markdown
---
migration: NNNN
from: X.Y.Z
to: A.B.C
mutates_frontmatter: false
scope: project-docs
---

# Migration NNNN: X.Y.Z → A.B.C

## Summary

<One line: what changes in the user's project at this version step.>

## Preconditions

- `docs/product/` exists (project initialized for this role).
- <other invariants the Transform assumes>

## Transform

<Ordered, imperative steps the runner executes. Examples:>
1. <move / rename a file>
2. <add a section to an existing doc>
3. <add an OPTIONAL front-matter field to artifacts of type X>

If there are no structural changes, write exactly: `No structural changes. Marker bump only.`

## Backup

Not applicable — no front-matter mutation.
<When mutates_frontmatter: true, instead describe which files are copied to
`docs/product/.upgrade-backup/<from>-to-<to>/` before mutation.>

## Verification

- <post-condition the runner checks before writing the marker>

## Rollback note

The runner refuses on a dirty working tree, so `git` is the rollback: inspect the diff,
`git restore` / `git checkout` to revert. When `mutates_frontmatter: true`, a copy of the
affected files is also written to `docs/product/.upgrade-backup/<from>-to-<to>/`.

## Never

- Never delete artifacts; transition status instead.
- Never renumber IDs (HYP/PRD/SPEC/VAL/SCAN, ADR).
````

- [ ] **Step 2: Create the shared template for `architect`**

Create `plugins/architect/migrations/_TEMPLATE.md` with the same content as Step 1, except replace every `docs/product/` with `docs/architecture/` and the ID list line with:
`- Never renumber IDs (ADR-NNNN).`

- [ ] **Step 3: Expand README §7 with the migration format**

In `README.md`, immediately after the line (currently line 202):

```markdown
- **CHANGELOG** is mandatory for every plugin and every bump.
```

insert this new bullet block:

```markdown
- **Migrations** are separate files `plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md`, run sequentially by `/<role>:upgrade`. Each file carries `migration / from / to / mutates_frontmatter / scope` front-matter and fixed body sections (`Summary`, `Preconditions`, `Transform`, `Backup`, `Verification`, `Rollback note`, `Never`). The runner writes the `.<plugin>-version` marker after each successful step (per-step atomicity); a mid-run failure leaves the marker at the last completed step. A backup is taken before any front-matter mutation. The marker's location is plugin-specific and declared in the plugin's `<role>-conventions` skill (`product`: repo-root `.product-version`; `architect`: `docs/architecture/.architect-version`). See [ADR-0003](./docs/architecture/decisions/0003-migration-format-and-procedure.md).
```

- [ ] **Step 4: Mirror the format into CLAUDE.md**

In `CLAUDE.md`, find this sentence in the "Common operations" section:

```markdown
To bump a plugin version: edit `plugins/<role>/.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` if the marketplace-level metadata changes. Add a migration file under `plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md` whenever artifact structure changes (the `upgrade` command runs them sequentially).
```

Replace the second sentence so the block reads:

```markdown
To bump a plugin version: edit `plugins/<role>/.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` if the marketplace-level metadata changes. Add a migration file under `plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md` whenever a version step needs project-side changes — front-matter (`migration / from / to / mutates_frontmatter / scope`) plus fixed sections (`Summary` / `Preconditions` / `Transform` / `Backup` / `Verification` / `Rollback note` / `Never`); copy `migrations/_TEMPLATE.md`. `/<role>:upgrade` runs them in order and writes the `.<role>-version` marker per successful step. See ADR-0003 and README §7.
```

- [ ] **Step 5: Verify the format is internally consistent**

Run:
```bash
cd /home/ikramar/Work/Self/kramar-studio-marketplace
for f in plugins/product/migrations/_TEMPLATE.md plugins/architect/migrations/_TEMPLATE.md; do
  echo "== $f =="
  grep -c '^## \(Summary\|Preconditions\|Transform\|Backup\|Verification\|Rollback note\|Never\)$' "$f"
done
grep -n 'migrations/NNNN-from-X.Y.Z-to-A.B.C.md' README.md CLAUDE.md
grep -n '0003-migration-format-and-procedure' README.md
```
Expected: each template reports `7` section headers; README and CLAUDE.md both reference the migration path; README references ADR-0003.

- [ ] **Step 6: Commit**

```bash
git add plugins/product/migrations/_TEMPLATE.md plugins/architect/migrations/_TEMPLATE.md README.md CLAUDE.md
git commit -m "feat(migrations): define migration file format and templates

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: product upgrade runner

**Files:**
- Modify (full rewrite): `plugins/product/commands/upgrade.md`

- [ ] **Step 1: Rewrite `plugins/product/commands/upgrade.md`**

Replace the entire file with:

````markdown
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
````

- [ ] **Step 2: Verify the runner references real paths and the format**

Run:
```bash
cd /home/ikramar/Work/Self/kramar-studio-marketplace
grep -n 'migrations/' plugins/product/commands/upgrade.md
grep -n '\.product-version' plugins/product/commands/upgrade.md
grep -n 'per-step atomicity\|dirty working tree\|downgrade\|_TEMPLATE.md' plugins/product/commands/upgrade.md
grep -ci 'no migrations to run; updating' plugins/product/commands/upgrade.md
```
Expected: migrations path and `.product-version` referenced; atomicity/dirty-tree/downgrade/_TEMPLATE all present; the old stub phrase "no migrations to run; updating" count is `0`.

- [ ] **Step 3: Commit**

```bash
git add plugins/product/commands/upgrade.md
git commit -m "feat(product): rewrite upgrade.md from stub into a migration runner

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: product symbolic 1.0.0 + first migration

**Files:**
- Modify: `plugins/product/.claude-plugin/plugin.json` (version)
- Create: `plugins/product/CHANGELOG.md`
- Create: `plugins/product/migrations/0001-from-0.1.0-to-1.0.0.md`
- Modify: `README.md` (plugins table row for `product`, line 26; roadmap line 265)
- Modify: `plugins/product/skills/product-conventions/SKILL.md` (marker location + format pointer)

- [ ] **Step 1: Bump the plugin version**

In `plugins/product/.claude-plugin/plugin.json`, change:
```json
  "version": "0.1.0",
```
to:
```json
  "version": "1.0.0",
```

- [ ] **Step 2: Create `plugins/product/CHANGELOG.md`**

Create the file with exactly:

````markdown
# Changelog

All notable changes to the `product` plugin are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-06-01

No breaking API changes — version reflects maturity transition (scaffolded → active).

### Added

- Migration mechanism: `migrations/` directory, `_TEMPLATE.md`, and the first migration
  `0001-from-0.1.0-to-1.0.0.md` (maturity transition, no artifact changes).
- `plugins/product/CHANGELOG.md` (this file), per ADR-0002 rule 8.

### Changed

- `commands/upgrade.md` rewritten from a stub into a real migration runner (sequential
  migrations, per-step marker atomicity, dirty-tree refusal, downgrade refusal,
  backup-before-mutation when a migration mutates front-matter).
- `skills/product-conventions/SKILL.md` documents the `.product-version` marker location
  and the migration format.

## [0.1.0] — 2026-05-10

### Added

- Initial scaffold: per-feature cycle (`discover` → `define` → `spec` → `validate`),
  `market-scan`, `prioritize`, service commands (`init`, `status`, `upgrade`), two skills
  (`product-conventions`, `product-cycle`), soft hooks, templates.
````

- [ ] **Step 3: Create the first migration**

Create `plugins/product/migrations/0001-from-0.1.0-to-1.0.0.md` with exactly:

````markdown
---
migration: 0001
from: 0.1.0
to: 1.0.0
mutates_frontmatter: false
scope: project-docs
---

# Migration 0001: 0.1.0 → 1.0.0

## Summary

`product` reaches 1.0.0 (status `active`). This is a maturity transition — there are no
structural changes to your artifacts.

## Preconditions

- `docs/product/` exists.
- `.product-version` reads `0.1.0` (or is treated as such by the runner).

## Transform

No structural changes. Marker bump only.

## Backup

Not applicable — no front-matter mutation.

## Verification

- `docs/product/` and `PRODUCT.md` are present and unchanged.

## Rollback note

The runner refuses on a dirty working tree, so `git` is the rollback.

## Never

- Never delete artifacts; transition status instead.
- Never renumber IDs (HYP/PRD/SPEC/VAL/SCAN, ADR).
````

- [ ] **Step 4: Update the README plugins table row**

In `README.md` line 26, replace:
```markdown
| **`product`** | 🟡 scaffolded | `0.1.0` | Market-scan (quarterly anchor) + per-feature cycle Discover → Define → Spec → Validate, plus `prioritize` over a backlog. Artifacts: HYP/PRD/SPEC/VAL/SCAN, cross-linked to ADRs from `architect`. |
```
with:
```markdown
| **`product`** | 🟢 active | `1.0.0` | Market-scan (quarterly anchor) + per-feature cycle Discover → Define → Spec → Validate, plus `prioritize` over a backlog. Artifacts: HYP/PRD/SPEC/VAL/SCAN, cross-linked to ADRs from `architect`. |
```

- [ ] **Step 5: Update the README roadmap line**

In `README.md` line 265, replace:
```markdown
- 🚧 **v0.2** — `product` content fill (real templates with examples, integration patterns with `architect`); migration format (B1)
```
with:
```markdown
- ✅ **product 1.0** — migration mechanism (B1) + symbolic 1.0.0 (scaffolded → active); see ADR-0003
- 🚧 **next** — `product` content fill for non-cycle commands (`market-scan`, `prioritize`); `ops` scaffold (v0.3)
```

- [ ] **Step 6: Document the marker location in product-conventions**

In `plugins/product/skills/product-conventions/SKILL.md`, find the file-layout block listing
`.last-prioritize` and `.last-market-scan`. Immediately after that fenced block (before
"`PRODUCT.md` lives at the **repository root**"), add this paragraph:

```markdown
**Version marker.** `.product-version` is a single-line SemVer string at the **repository
root** (not under `docs/product/`). It is written by `/product:init` and by each successful
step of `/product:upgrade`, and mirrors `plugin.json.version` at that moment (ADR-0002 rule
3). Migrations live in the plugin under `migrations/NNNN-from-X.Y.Z-to-A.B.C.md`; the
format is in README §7 and ADR-0003.
```

- [ ] **Step 7: Verify version sync across the three places**

Run:
```bash
cd /home/ikramar/Work/Self/kramar-studio-marketplace
echo "plugin.json: $(grep '"version"' plugins/product/.claude-plugin/plugin.json)"
echo "README row:  $(grep -E '\*\*`product`\*\*' README.md)"
echo "CHANGELOG:   $(grep -m1 '^## \[' plugins/product/CHANGELOG.md)"
echo "migration to: $(grep '^to:' plugins/product/migrations/0001-from-0.1.0-to-1.0.0.md)"
grep -q 'No breaking API changes — version reflects maturity transition' plugins/product/CHANGELOG.md && echo "rule-5 line: OK" || echo "rule-5 line: MISSING"
```
Expected: plugin.json `1.0.0`, README row shows `1.0.0` + `🟢 active`, CHANGELOG top entry `[1.0.0]`, migration `to: 1.0.0`, rule-5 line OK.

- [ ] **Step 8: Commit**

```bash
git add plugins/product/.claude-plugin/plugin.json plugins/product/CHANGELOG.md \
        plugins/product/migrations/0001-from-0.1.0-to-1.0.0.md \
        plugins/product/skills/product-conventions/SKILL.md README.md
git commit -m "feat(product): symbolic 1.0.0 (scaffolded → active) with first migration

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: architect reconciliation

**Files:**
- Create: `plugins/architect/migrations/0001-from-0.2.0-to-0.3.0.md`
- Modify (full rewrite): `plugins/architect/commands/upgrade.md`
- Modify: `plugins/architect/.claude-plugin/plugin.json` (version → 1.1.0)
- Modify: `plugins/architect/CHANGELOG.md` (new 1.1.0 entry)
- Modify: `README.md` (plugins table row for `architect`, line 25)

- [ ] **Step 1: Create the architect 0.2 → 0.3 migration file**

Create `plugins/architect/migrations/0001-from-0.2.0-to-0.3.0.md` with exactly:

````markdown
---
migration: 0001
from: 0.2.0
to: 0.3.0
mutates_frontmatter: false
scope: project-docs
---

# Migration 0001: 0.2.0 → 0.3.0

## Summary

Refresh the `AGENTS.md` integration block, optionally scaffold `decision-map.md`, and add a
`Status` section to existing review files.

## Preconditions

- `docs/architecture/` exists.

## Transform

1. **Refresh the integration block in `AGENTS.md`** if present. The 0.3 block includes the
   `Research` phase in the workflow diagram and adds language-detection support. Run the
   equivalent of `/architect:remember-compound-integration` and let it replace the block in
   place. Detect the project's working language; write the new block in that language.
2. **Add a `decision-map.md` skeleton if missing**, but only if there are ≥3 open
   architectural questions in `ARCHITECTURE.md` or ≥2 ADRs already exist. Otherwise leave a
   note in chat suggesting `/architect:map` as an optional next step.
3. **Add a `Status` section to existing review files** in `docs/architecture/reviews/` if
   they don't have one. Default to `Status: Open` unless a closeout block already exists.
4. **Surface to user (no file change):** the terminology pass for Russian artifacts is now
   mandatory (was advisory in 0.2). If the project has Russian artifacts, suggest
   re-running `/architect:review` on key ADRs to apply the terminology pass.

## Backup

Not applicable — no front-matter mutation. Section refreshes are additive / in-place.

## Verification

- `AGENTS.md` integration block, if present, references the `Research` phase.
- No review file lost its existing content.

## Rollback note

The runner refuses on a dirty working tree, so `git` is the rollback.

## Never

- No file deletions, no destructive changes.
- Never renumber ADR IDs.
````

- [ ] **Step 2: Rewrite `plugins/architect/commands/upgrade.md` as the runner**

Replace the entire file with:

````markdown
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
````

- [ ] **Step 3: Bump the architect plugin version**

In `plugins/architect/.claude-plugin/plugin.json`, change `"version": "1.0.0",` to
`"version": "1.1.0",`.

- [ ] **Step 4: Add the CHANGELOG entry**

In `plugins/architect/CHANGELOG.md`, insert a new entry **above** the current top entry
(the `## [1.0.0] — 2026-05-10 — Absorbed …` heading). The file's heading style is
`## [version] — date — short title`:

```markdown
## [1.1.0] — 2026-06-01 — File-based migrations (suite alignment)

### Changed

- `commands/upgrade.md` reworked into a thin migration runner. The 0.2 → 0.3 migration that
  was inline is now `migrations/0001-from-0.2.0-to-0.3.0.md`. External upgrade behavior is
  unchanged; this aligns `architect` with the suite migration format (ADR-0002 / ADR-0003).

### Added

- `migrations/` directory with `_TEMPLATE.md` and `0001-from-0.2.0-to-0.3.0.md`.
- Recovery path: `/architect:upgrade` detects a legacy `.archforge-version` marker and, on
  confirmation, renames it to `.architect-version` (ADR-0002 rule 3).
```

> If `plugins/architect/migrations/_TEMPLATE.md` was not created in Task 1, create it now per
> Task 1 Step 2 before committing.

- [ ] **Step 5: Update the README plugins table row for architect**

In `README.md` line 25, change the version cell from `` `1.0.0` `` to `` `1.1.0` `` (leave
the `🟢 active` status and description text unchanged).

- [ ] **Step 6: Verify architect consistency**

Run:
```bash
cd /home/ikramar/Work/Self/kramar-studio-marketplace
echo "plugin.json: $(grep '"version"' plugins/architect/.claude-plugin/plugin.json)"
echo "README row:  $(grep -E '\*\*`architect`\*\*' README.md)"
echo "CHANGELOG:   $(grep -m1 '^## \[' plugins/architect/CHANGELOG.md)"
grep -ci 'Migrations by version' plugins/architect/commands/upgrade.md
grep -n 'archforge-version' plugins/architect/commands/upgrade.md
ls plugins/architect/migrations/
```
Expected: plugin.json `1.1.0`; README row `1.1.0`; CHANGELOG top `[1.1.0]`; the old inline
"Migrations by version" count is `0`; `.archforge-version` recovery referenced; migrations
dir lists `_TEMPLATE.md` and `0001-from-0.2.0-to-0.3.0.md`.

- [ ] **Step 7: Commit**

```bash
git add plugins/architect/migrations/ plugins/architect/commands/upgrade.md \
        plugins/architect/.claude-plugin/plugin.json plugins/architect/CHANGELOG.md README.md
git commit -m "feat(architect): reconcile to file-based migrations; v1.1.0

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: ADR-0003 + architecture index

**Files:**
- Create: `docs/architecture/decisions/0003-migration-format-and-procedure.md`
- Modify: `ARCHITECTURE.md` (§5 decision index row; §6 close the migrations open question)
- Modify: `docs/architecture/decision-map.md` (B1 → decided)

- [ ] **Step 1: Write ADR-0003**

Create `docs/architecture/decisions/0003-migration-format-and-procedure.md` with:

````markdown
# ADR-0003: Формат и процедура миграций (B1)

- **Date**: 2026-06-01
- **Status**: Accepted
- **Authors**: Igor Kramar
- **Upstream**: [ADR-0002](./0002-multi-level-versioning-contract.md) — versioning контракт; B1 был помечен как отдельный цикл.

## Context

ADR-0002 зафиксировал semver-контракт и анонсировал B1 (формат миграций) как отдельный
цикл. До этого ADR механизм миграций существовал в двух несовместимых видах: декларированном
(`CLAUDE.md`, ADR-0002, `product/upgrade.md` — отдельные файлы `migrations/NNNN-from-X.Y.Z-to-A.B.C.md`)
и фактическом (`architect/upgrade.md` — инлайн version-gated блоки). Ни один плагин не мог
реально выполнить миграцию.

## Decision

1. **Model B — binding.** Миграции — отдельные файлы
   `plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md`, прогоняются последовательно
   `/<role>:upgrade`. Это исполнение ADR-0002, не его правка.
2. **Формат файла.** Front-matter `migration / from / to / mutates_frontmatter / scope`;
   фиксированные секции `Summary` / `Preconditions` / `Transform` / `Backup` /
   `Verification` / `Rollback note` / `Never`. Эталон — `migrations/_TEMPLATE.md` в каждом
   плагине. Runner игнорирует файлы, не подходящие под шаблон имени.
3. **Per-step atomicity.** Маркер `.<plugin>-version` пишется после каждого успешного шага
   (после прохождения его `Verification`); падение в середине оставляет маркер на последнем
   завершённом шаге. Это уточнение rule 3 ADR-0002 («атомарно с последней миграцией») до
   per-step гранулярности; совпадает с уже декларированным поведением `architect`.
4. **Backup-posture.** Основной откат — git (runner отказывает на грязном дереве). Явный
   backup в `docs/<role>/.upgrade-backup/<from>-to-<to>/` берётся только при
   `mutates_frontmatter: true` (закрывает C-3 из roast ADR-0002 — regulated/PII content).
5. **Marker location — per-plugin.** ADR-0002 rule 3 место маркера не фиксирует.
   `product` — корень репозитория (`.product-version`); `architect` —
   `docs/architecture/.architect-version`. Нормализация не делается: она сама сломала бы
   существующих пользователей и потребовала бы миграции. Место объявляется в
   `<role>-conventions` плагина.

## Consequences

### Easier
- `/<role>:upgrade` стал тонким runner'ом; новые миграции — просто новые файлы, upgrade.md
  не растёт.
- `architect` реконсилирован: инлайн-блок 0.2→0.3 вынесен в файл; добавлен
  `.archforge-version` recovery path (ADR-0002 rule 3 «at first convenience»).
- `product` получил символический 1.0.0 (scaffolded → active) с первой миграцией-no-op.

### Harder
- Honor system без enforcement сохраняется (как в ADR-0002): корректность формата и
  atomicity держатся ручной дисциплиной + verification-грепами в плане, не CI.
- Маркер в двух местах остаётся латентной путаницей для будущих `ops`/`security`;
  mitigation — место маркера всегда объявляется в conventions.

### Risks accepted
- LLM-исполнение `Transform` недетерминировано (миграция — промпт, не скрипт). Mitigation:
  отказ на грязном дереве + git-откат + явный backup при мутации frontmatter.

## Связанные артефакты
- [ADR-0002](./0002-multi-level-versioning-contract.md) — versioning контракт (upstream).
- README §7 — каноничный формат миграций (мета-форма).
- Spec/plan: `docs/superpowers/specs/2026-06-01-product-migration-mechanism-design.md`.
````

- [ ] **Step 2: Add ADR-0003 to the ARCHITECTURE.md decision index**

In `ARCHITECTURE.md` §5, insert a new row **above** the ADR-0002 row (line 117):
```markdown
| [0003](./docs/architecture/decisions/0003-migration-format-and-procedure.md) | 2026-06-01 | Accepted | Формат и процедура миграций (B1): file-based Model B, per-step atomicity, backup при мутации frontmatter, marker-location per-plugin |
```

- [ ] **Step 3: Close the migrations open question in §6**

In `ARCHITECTURE.md` §6, replace the "**Стратегия миграций артефактов.**" bullet (line 128)
with a closed (strikethrough) version matching the section's existing style:
```markdown
- ~~**Стратегия миграций артефактов.**~~ **Закрыт через [ADR-0003](./docs/architecture/decisions/0003-migration-format-and-procedure.md):** file-based формат `migrations/NNNN-from-X.Y.Z-to-A.B.C.md`, тонкий runner в `/<role>:upgrade`, per-step atomicity, git-откат + backup при мутации frontmatter. `architect` реконсилирован, `product` → 1.0.0 с первой миграцией.
```

- [ ] **Step 4: Update decision-map.md (B1 → decided)**

In `docs/architecture/decision-map.md`, immediately after the B1 header line:
```markdown
### B1. Migration format and procedure _(unblocked after ADR-0002)_
```
insert a status line (mirroring A2's format on line 29):
```markdown
- _Status:_ **decided → [ADR-0003](./decisions/0003-migration-format-and-procedure.md)** (2026-06-01). Решение: file-based Model B, формат `_TEMPLATE.md`, per-step atomicity, backup при `mutates_frontmatter: true`, marker-location per-plugin. `architect` реконсилирован (инлайн 0.2→0.3 → файл; `.archforge-version` recovery path добавлен), `product` → символический 1.0.0.
```
Then, in the "Suggested order" table, replace the B1 row (line 86):
```markdown
| После A2 | **B1** Migration format and procedure | Hard-зависим от A2. Формат миграции описывается тривиально, когда семантика версий зафиксирована. До этого — спекуляция. |
```
with:
```markdown
| ~~После A2~~ ✅ | ~~**B1** Migration format and procedure~~ → [ADR-0003](./decisions/0003-migration-format-and-procedure.md) | Done 2026-06-01. File-based runner + первая миграция product + реконсиляция architect. |
```
And in the single-thread / parallel summary lines (90 and 92), strike `B1`:
- line 90 `**B3 → D4 → B1 → B2 → C1**` → `**B3 → D4 → ~~B1~~ ✅ → B2 → C1**`
- line 92 `потом B1 и B2 (можно параллельно — оба unblocked)` → `~~B1~~ ✅ done; B2 (unblocked)`

- [ ] **Step 5: Verify references resolve**

Run:
```bash
cd /home/ikramar/Work/Self/kramar-studio-marketplace
test -f docs/architecture/decisions/0003-migration-format-and-procedure.md && echo "ADR file: OK"
grep -c '0003-migration-format-and-procedure' ARCHITECTURE.md README.md docs/architecture/decision-map.md
grep -n '~~\*\*Стратегия миграций' ARCHITECTURE.md
```
Expected: ADR file OK; each of the three files references ADR-0003 at least once; the
migrations open question now shows the strikethrough form.

- [ ] **Step 6: Commit**

```bash
git add docs/architecture/decisions/0003-migration-format-and-procedure.md \
        ARCHITECTURE.md docs/architecture/decision-map.md
git commit -m "docs(architecture): ADR-0003 migration format and procedure (B1)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: End-to-end manual verification

There is no automated test runner. Exercise the mechanism once, by hand, in a scratch
project.

- [ ] **Step 1: Reload the plugins in a Claude Code session**

Run `/reload-plugins` (or restart Claude Code) so the rewritten commands load.

- [ ] **Step 2: Dry-run the product runner against a scratch project**

In a throwaway project with the marketplace installed:
```text
/product:init
```
Then hand-edit `.product-version` to `0.1.0`, commit, and run:
```text
/product:upgrade
```
Expected: the runner reads `0.1.0`, finds `0001-from-0.1.0-to-1.0.0.md`, shows the CHANGELOG
summary, applies the no-op transform, and writes `.product-version` = `1.0.0`. Re-running
`/product:upgrade` reports "Already at product 1.0.0."

- [ ] **Step 3: Confirm the downgrade and dirty-tree guards**

- With `.product-version` set to `2.0.0`, run `/product:upgrade` → expect a downgrade
  refusal.
- With an uncommitted change in the tree, run `/product:upgrade` → expect a dirty-tree
  refusal.

- [ ] **Step 4: Record the result**

Note in chat whether each guard behaved as specified. If anything diverges, file it as a
follow-up rather than patching silently mid-verification.

---

## Self-review notes (filled by the author of this plan)

- **Spec coverage:** format §2→Task 1; runner §2→Task 2; product 1.0.0 §3→Task 3; architect
  §4→Task 4; docs + ADR-0003 §5→Task 5; "no test runner" reality→Task 6. All spec sections
  map to a task.
- **No automated tests** in this repo by design (`CLAUDE.md`); TDD steps are replaced by
  concrete consistency greps + one manual exercise — the closest honest analog.
- **Type/name consistency:** marker file names (`.product-version` at root,
  `docs/architecture/.architect-version`), section headers (`Summary`/`Preconditions`/…),
  and front-matter keys (`migration/from/to/mutates_frontmatter/scope`) are identical across
  Tasks 1–5.

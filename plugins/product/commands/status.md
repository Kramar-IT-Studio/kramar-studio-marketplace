---
description: Read-only report on what's in flight in product work, what's stale, what cross-references are broken.
argument-hint: "(no arguments)"
---

# /product:status

Produce a one-screen status report of the project's product state. Read-only — never edits files. The first thing to run when reopening a project after a long pause.

## Inputs

- `PRODUCT.md` at repository root.
- `docs/product/` tree.
- `.product-version`.
- `ARCHITECTURE.md` and `docs/architecture/decisions/` if they exist (for cross-link validation).

## What to report

### 1. Plugin and project version

- Installed plugin version (from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`).
- Project version (from `.product-version`).
- If they differ → flag and suggest `/product:upgrade`.

### 2. Active artifacts

For each category (HYP, PRD, SPEC, VAL):
- Count by status (`draft`, `active`, `accepted`, `superseded`, `archived`).
- Names of artifacts in `draft` or `active` — these are what's in flight.

### 3. Market-scan freshness

For each `docs/product/research/*-market-scan.md`:
- Area covered.
- Date.
- Age. **Warn if older than 90 days.**

### 4. Cycle integrity

For each in-flight feature (HYP in `active`, PRD in `draft`/`active`, etc.):
- Trace the chain HYP → PRD → SPEC → VAL.
- Flag if a phase is missing or out of order.
- Flag if a PRD has no `success_metric` field in front-matter or section.
- Flag if a SPEC has no `acceptance_criteria` section.

### 5. Cross-reference integrity

- `links_to` entries pointing to non-existent IDs.
- ADRs referenced from product artifacts that don't exist in `docs/architecture/decisions/`.
- Product artifacts in `docs/product/` whose body mentions an ADR but `links_to` is empty.

### 6. Backlog snapshot

From `docs/product/backlog.md`:
- Number of candidates.
- Last `/product:prioritize` run date (from `.last-prioritize` if present).

## Output

Markdown to chat. No file writes. Group by sections above. End with a one-line **Suggested next step** (e.g. "two PRDs in `active`, no SPEC yet — run `/product:spec` for PRD-0003" or "no anomalies — pick the next item from backlog").

## Discipline

- **Read-only.** Never touch files.
- **No prose preamble.** Lead with the data; let it speak.
- **Honest about silence.** If nothing is in flight, say so plainly. Don't pad the report.

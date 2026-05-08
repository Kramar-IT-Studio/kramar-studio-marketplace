---
description: Phase 4 of the Architecture Cycle — write the ADR, update ARCHITECTURE.md, refresh diagrams.
argument-hint: "<problem statement>"
---

# /archforge:document

Phase 4 of the Architecture Cycle. Persist the decision so the team and future agents can find it.

## Inputs

- Problem statement: $ARGUMENTS
- Decision summary: read the most recent file in `docs/architecture/research/` matching the problem (`-decision.md`).
- Project context: `./ARCHITECTURE.md`, existing ADRs in `./docs/architecture/decisions/`.

If no decision summary exists, refuse and ask the user to run `/archforge:decide` first.

## What to produce

### 1. The ADR

Use the `adr-writing` skill. Default template is Nygard.

Steps:
- Find the next ADR number by listing `docs/architecture/decisions/`.
- Generate file `docs/architecture/decisions/NNNN-<slug>.md`.
- Fill in Context, Decision, Consequences, and Alternatives considered.
- Status: `Accepted` (unless the user explicitly says `Proposed`).
- Date: today.

### 2. Update `docs/architecture/decisions/README.md`

Add an entry at the top of the index with the new ADR number, date, status, and one-line summary.

### 3. Update `ARCHITECTURE.md`

For each section that the decision affects:
- **Decision index** — always: add a row.
- **System summary** — only if the decision changes what the system *does*.
- **Quality attributes** — if the decision shifts a non-functional posture (e.g., we accepted higher write latency to gain availability).
- **High-level structure** — if the decision changes topology, update the C4 diagram.
- **Constraints** — if a new constraint is now formally adopted.
- **Open questions** — resolve or remove the now-answered ones; add new ones the decision creates.
- **Anti-patterns** — if the decision excludes an approach, list it explicitly so future contributors don't propose it again.

### 4. Update or generate diagrams

If the decision changes structure, regenerate the affected C4 diagrams in `docs/architecture/diagrams/` using the `c4-diagrams` skill.

### 5. Supersede previous ADRs if applicable

If this decision overrides a prior ADR:
- Mark the prior ADR's status as `Superseded by ADR-NNNN` (edit only the status header, never the substance).
- Note this in the new ADR's Context.

## Discipline

- **Never edit the substance of an accepted ADR.** Add new ADRs that supersede.
- **Don't pad ARCHITECTURE.md.** Update only sections that genuinely changed.
- **Update the diagram when topology changes.** Stale diagrams are worse than no diagrams.
- **Numbers are immutable.** ADR-0007 is always ADR-0007, even if it's deprecated.

## Output to chat

Tell the user:
- The new ADR number and file path.
- Which sections of `ARCHITECTURE.md` were updated.
- Which diagrams were touched.
- Suggestion: "Once this is implemented, run `/archforge:review` against the changed code."

Don't commit — leave that to the user.

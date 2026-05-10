---
description: Phase 5 of the Architecture Cycle — architectural code review of changed files or a path.
argument-hint: "[path or git ref] (optional; defaults to staged + last commit)"
---

# /archforge:review

Phase 5 of the Architecture Cycle. Architectural review of code, with the project's ADRs and `ARCHITECTURE.md` as binding context.

## Inputs

- Target: `$ARGUMENTS` if provided. Interpret as either:
  - A file path (review that file/directory).
  - A git ref or PR description (review the changes in that ref).
  - Empty → review staged changes plus the last commit on the current branch.
- Project context: `./ARCHITECTURE.md`, all ADRs in `./docs/architecture/decisions/`.

## What to produce

Use the `code-review-architectural` skill. Output structure (mandatory):

```
## Status
**Open** — written YYYY-MM-DD by /archforge:review.
(When findings are addressed, this header is updated to "Applied YYYY-MM-DD" with a closeout block at the end.)

## Summary
2–3 sentences: what the changes are doing and the main architectural risk or concern.

## Conformance with ADRs
For each relevant ADR (by number), state whether the change:
- Conforms.
- Conflicts (and how — this is a blocker unless a new ADR supersedes).
- Is silent (the ADR doesn't speak to this change).

## Blocking issues
Things that should be fixed before merge. For each:
- Identifier (B-1, B-2, ...).
- Pointer to specific code location.
- Why it's a blocker (architectural reason, not stylistic).
- Suggested fix.

## Non-blocking suggestions
"nit:" or "suggestion:" prefix, prioritized.

## Questions
Where context wasn't sufficient to evaluate.

## Praise
What's good in this change. Reinforce.
```

## Closeout — when blockers are addressed

A review is not done when it's written. It's done when its findings are either applied or explicitly accepted as risk. When you (or a follow-up `/archforge:review` invocation) confirm that blockers have been addressed, **update the same review file** by:

1. Changing the `## Status` line from "Open" to "Applied YYYY-MM-DD" (or "Partially applied" if some items remain).
2. Appending a `## Closeout` section at the end of the file with this structure:

```markdown
## Closeout — YYYY-MM-DD

For each blocker (B-1, B-2, ...): how it was resolved.
- **B-1**: <one-line description> → <resolution: applied as ADR rule N, accepted as risk, deferred to V2 with new ADR-NNNN>.
- **B-2**: ...

For non-blocking suggestions that were taken: list them similarly. Suggestions that were declined are noted with reason ("not pursued — out of scope for this change").
```

This makes the review document self-contained: future readers see both what was found and what came of it. The cycle compounds: the next review cites prior reviews when the same architectural seams resurface.

## Where to save

Save the review as `docs/architecture/reviews/YYYY-MM-DD-<short-summary>.md`. Also output to chat.

## Discipline

- **Don't lint.** Style and formatting are out of scope.
- **L2–L4 only.** Local correctness goes in a normal code review, not here.
- **Conformance to ADRs is the first thing.** A change that violates an accepted ADR without a superseding ADR is a blocking issue by default.
- **Favor a few high-leverage comments over a long list.** Architectural noise drowns out signal.
- **If the change is architecturally wrong at its core**, don't pile nitpicks. Write one detailed diagnosis in `Blocking issues` and suggest moving the discussion synchronous.

## When to recommend a new ADR

If the changes contain an implicit decision that isn't recorded — new dependency, new module, new pattern — flag it and suggest running `/archforge:adr` to capture it. Implicit decisions are how architectural debt accumulates.

## Output to chat

The structured review, plus the path of the saved file.

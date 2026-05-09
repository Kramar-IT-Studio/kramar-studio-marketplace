---
description: Phase 3 of the product cycle — implementation spec with explicit acceptance criteria.
argument-hint: "<feature slug or PRD-NNNN>"
---

# /product:spec

Phase 3 of the per-feature product cycle. Take a PRD and produce an implementation spec engineering can build from. The spec is **the product/engineering contract** — what behaviors qualify as "done", what edge cases are explicitly handled, what's intentionally deferred.

## Inputs

- Feature slug or PRD ID: `$ARGUMENTS`
- The matching `docs/product/prds/*.md` (PRD-NNNN). **Required.** If missing, abort and tell the user to run `/product:define` first.
- `ARCHITECTURE.md` and relevant ADRs — the spec must conform to them.
- `CLAUDE.md` for codebase conventions.

## What to produce

A spec covering:

1. **Header** — feature, source PRD, target architecture (which ADRs apply).

2. **Behavior contract** — the user-facing behaviors from the PRD's acceptance section, expanded into precise specifications. Each behavior is:
   - Trigger.
   - Pre-conditions.
   - Action.
   - Post-conditions.
   - Visible side-effects (UI, events, analytics).

3. **Acceptance criteria** — **MANDATORY.** A numbered list of testable statements. Each criterion is:
   - Phrased as `Given/When/Then` or as a precise assertion.
   - Independent (can be checked in isolation).
   - Tied to one or more PRD success-metric components or PRD acceptance items.

   The hook will flag if this section is missing or has fewer than 3 criteria.

4. **Edge cases and error states** — list the failure modes. For each: expected behavior, user-facing message (if any), recovery path. "Not sure" is a valid entry, but it's also an open question.

5. **Out of scope (explicit)** — what this spec does *not* cover. "Phase 2" features, deferred edge cases, intentionally weak fallbacks.

6. **Analytics / observability** — what we instrument to actually measure the success metric. Event names, properties, where they fire. **A spec where the success metric isn't measurable is broken.**

7. **Open questions for engineering** — implementation choices the spec doesn't pin down because they're judgment calls (library, exact data type, etc.). These are *not* product questions; they're for the engineer (or the architect via `/archforge:cycle`).

8. **Cross-references** — `links_to`:
   - Source PRD-NNNN.
   - All ADRs the spec relies on or triggers.

## Output location

Save to `docs/product/specs/YYYY-MM-DD-<feature-slug>-spec.md`.

Front-matter:
```yaml
---
id: SPEC-NNNN
status: draft
created_at: YYYY-MM-DD
role: product
links_to:
  - PRD-NNNN          # always
  - ADR-NNNN          # all ADRs the spec depends on
acceptance_count: <n>  # mirrors section 3 length
---
```

Allocate `SPEC-NNNN` sequentially.

Update the source PRD's status: `draft` → `active` when its SPEC enters draft.

## Discipline

- **Acceptance criteria must be testable, not aspirational.** "The system is fast" is not a criterion. "p95 round-trip < 200ms under 100 RPS" is.
- **At least 3 acceptance criteria.** Below this, you're not specifying — you're hand-waving. The hook flags this.
- **Out-of-scope must be explicit.** "We won't handle network partitions in v1" is a valid line. Silently not handling them is a bug.
- **Analytics is part of the spec.** If you skip section 6, the success metric in the PRD is unmeasurable, which means the PRD was broken too.
- **If the spec contradicts an existing ADR, stop.** Surface the conflict: "this spec implies a deviation from ADR-NNNN. Resolve via `/archforge:cycle` (new ADR superseding the old) before continuing." Do not silently override architecture from product side.

## Review pass

After drafting, run a self-review pass for:
- Every PRD acceptance item maps to ≥1 SPEC acceptance criterion.
- Every SPEC acceptance criterion can be tested by an engineer without asking you a clarifying question.
- Every `success_metric` component in the PRD has a corresponding analytics event in section 6.

Append the result of the pass as Section 9: "Self-review notes" (1–3 lines).

## After the spec

Tell the user:
- Where the spec was saved.
- The acceptance count.
- Any unresolved engineering questions.
- **Suggested next step:** implement, then `/product:validate "<feature>"` post-launch.

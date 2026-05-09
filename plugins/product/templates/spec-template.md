---
id: SPEC-NNNN
status: draft
created_at: YYYY-MM-DD
role: product
links_to:
  - PRD-NNNN
acceptance_count: 0
---

# Spec: <feature name>

- **Source PRD**: PRD-NNNN
- **Architecture**: ADR-NNNN, ADR-NNNN (if applicable)

## Behavior contract

<!--
The PRD's acceptance items expanded to precise behaviors:
- Trigger
- Pre-conditions
- Action
- Post-conditions
- Visible side-effects (UI, events, analytics)

### Behavior: <name>
- Trigger: …
- Pre-conditions: …
- Action: …
- Post-conditions: …
- Side-effects: …
-->

## Acceptance criteria

<!--
MANDATORY. ≥3 testable, independent statements.
Format: numbered list using Given/When/Then or precise assertions.

1. Given <state>, when <action>, then <observable result>.
2. <assertion>.
3. <assertion>.
-->

## Edge cases and error states

<!--
Failure modes. For each: expected behavior, user-facing message, recovery
path. "Not sure" is valid but is an open question.
-->

## Out of scope (explicit)

<!--
What this spec does NOT cover. Phase 2 features, deferred edge cases,
intentionally weak fallbacks.
-->

## Analytics / observability

<!--
What we instrument to actually measure the PRD's success metric.
- Event name, properties, where it fires.
- Counter-metric measurement.
-->

## Open questions for engineering

<!--
Implementation choices the spec doesn't pin down. Library, exact data type,
etc. NOT product questions.
-->

## Self-review notes

<!--
Filled by /product:spec after the review pass:
- PRD acceptance items mapped to SPEC criteria? Yes/No.
- Every criterion testable without clarifying questions? Yes/No.
- Every success_metric component instrumented? Yes/No.
-->

## Cross-references

- PRD-NNNN — source PRD
- ADR-NNNN — architectural decisions this spec relies on

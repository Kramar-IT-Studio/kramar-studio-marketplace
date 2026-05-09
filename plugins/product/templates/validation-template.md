---
id: VAL-NNNN
status: active
created_at: YYYY-MM-DD
role: product
verdict: confirmed | refuted | mixed | inconclusive
links_to:
  - PRD-NNNN
  - HYP-NNNN
---

# Validation: <feature name>

- **Source PRD**: PRD-NNNN
- **Source HYP**: HYP-NNNN
- **Source SPEC**: SPEC-NNNN (if applicable)
- **Launch date**: YYYY-MM-DD
- **Validation window**: YYYY-MM-DD → YYYY-MM-DD

## Verdict

<!--
ONE of: confirmed | refuted | mixed | inconclusive.
ONE paragraph of justification. Verdict goes FIRST. No leading-up-to.
-->

## Metric snapshot

| Metric | Baseline | Measured | Delta | Target |
|---|---|---|---|---|
| Primary: <name> | | | | |
| Counter: <name> | | | | |

- **Sample size**: <n>
- **Time window**: <YYYY-MM-DD → YYYY-MM-DD>

## What the data showed

<!--
Real movement, segment-level surprises (metric moved for cohort A but not B,
etc.). Surprising findings get their own line.
-->

## What we got wrong / right about the hypothesis

<!--
Reference HYP-NNNN. Be specific: which assumption broke, which held.
-->

## What we learned about the user

<!--
The durable part — survives the feature. This is the compounding asset.
-->

## Implications

### For the product

<!-- Stay (active) / pivot / roll back. One line. -->

### For the backlog

<!-- Re-prioritize? Which candidates does this validation move? -->

### For architecture

<!-- Any ADRs whose justification is reinforced or weakened? -->

## Cross-references

- PRD-NNNN — source PRD
- HYP-NNNN — the hypothesis we were testing
- ADR-NNNN — architectural decisions affected (if any)

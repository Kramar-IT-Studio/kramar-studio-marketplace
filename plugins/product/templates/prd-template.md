---
id: PRD-NNNN
status: draft
created_at: YYYY-MM-DD
role: product
links_to:
  - HYP-NNNN
success_metric: "<short metric description>"
---

# PRD: <feature name>

- **Owner**: <name or handle>
- **Target window**: <week/month, not exact date>
- **Source HYP**: HYP-NNNN

## Problem and hypothesis

<!--
Copy-down from HYP-NNNN. Don't re-derive; reference.
-->

## Scope

### In

<!-- 3-7 bullet points of what this PRD covers. -->

### Out

<!-- What's intentionally not in scope. As important as the In list. -->

## User stories

<!--
3-7 stories. Format: "As a <role>, I want <action> so that <outcome>".
More than 7? Split the feature.
-->

## Success metric

<!-- MANDATORY. Without this, the PRD is broken. -->

- **Primary metric**: <what we measure>
- **Baseline**: <current value or "no data">
- **Target**: <what change qualifies as success>
- **Window**: <1 week / 30 days / 1 quarter post-launch>
- **Counter-metric**: <what should NOT degrade>

## Acceptance (product level)

<!--
User-visible behaviors as a checklist. NOT implementation details.
- [ ] User can <do thing> within <constraint>
- [ ] When <state>, system shows <message>
-->

## Risks

<!--
2-4 risks ranked by severity. For each: detection + mitigation.

### Risk 1: <name>
- **Severity**: high | medium | low
- **Detection**: how we'd notice it
- **Mitigation**: how we'd respond
-->

## Open questions for engineering

<!--
Things to defer to the SPEC phase. Don't pretend to answer them here.
-->

## Cross-references

- HYP-NNNN — source hypothesis
- SCAN-NNNN — market-scan for the area (if applicable)
- ADR-NNNN — architectural decisions this PRD depends on or triggers

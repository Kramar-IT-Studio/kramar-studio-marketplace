---
description: Phase 4 of the product cycle — post-launch validation against the PRD success metric. Honest verdict.
argument-hint: "<feature slug or PRD-NNNN>"
---

# /product:validate

Phase 4 of the per-feature product cycle. The feature has shipped (or has been live long enough to read the data). This command produces a validation document with an **honest verdict**: did the success metric move as predicted, did the counter-metric hold, what did we learn?

The default of this phase is **not** "celebrate the launch". It's "audit our prediction".

## Inputs

- Feature slug or PRD ID: `$ARGUMENTS`
- The matching `docs/product/prds/*.md` (PRD-NNNN). **Required.**
- The matching SPEC if it exists (for context on what shipped vs what was specified).
- The actual data — analytics dashboards, user feedback, support tickets. The user provides this; you don't fabricate it. If they haven't given you data, ask.

## What to produce

A validation document covering:

1. **Header** — feature, source PRD, source SPEC, launch date, validation window.

2. **Verdict** — one of:
   - **Confirmed.** Success metric moved per prediction; counter-metric held. The hypothesis was right.
   - **Refuted.** Success metric didn't move (or moved the wrong way). The hypothesis was wrong.
   - **Mixed.** Some movement but ambiguous, or success metric moved but counter-metric also degraded.
   - **Inconclusive.** Insufficient data — describe why and what window you'd need.

   The verdict goes **first**, with one paragraph of justification. No leading-up-to.

3. **Metric snapshot**:
   - Primary metric: baseline → measured → delta.
   - Counter-metric: baseline → measured → delta.
   - Sample size and time window.

4. **What the data actually showed** — the real movement and any segment-level surprises (the metric moved for cohort A but not B, etc.).

5. **What we got wrong / right about the hypothesis** — referencing HYP-NNNN. Be specific: which assumption broke, which held.

6. **What we learned about the user** — the part of the discovery that's now durably true. This is the compounding asset; it survives the feature.

7. **Implications**:
   - **For the product:** does this feature stay (active), pivot, or get rolled back?
   - **For the backlog:** what does this validation imply about other candidates? Re-prioritize?
   - **For architecture:** any decisions that should be revisited (e.g. ADR-NNNN was bet on this hypothesis being true)?

8. **Cross-references** — `links_to`:
   - Source PRD.
   - Source HYP (the hypothesis we were testing).
   - Any ADRs whose justification depended on this validation.

## Output location

Save to `docs/product/validations/YYYY-MM-DD-<feature-slug>-validation.md`.

Front-matter:
```yaml
---
id: VAL-NNNN
status: active        # validations don't enter draft; you commit to a verdict
created_at: YYYY-MM-DD
role: product
verdict: confirmed | refuted | mixed | inconclusive
links_to:
  - PRD-NNNN
  - HYP-NNNN
  - ADR-NNNN          # if any
---
```

Allocate `VAL-NNNN` sequentially.

After validation:
- If `verdict: confirmed` → update PRD status to `accepted`, HYP status to `accepted`.
- If `verdict: refuted` → update PRD status to `archived`, HYP status to `archived` with `links_to: [VAL-NNNN]`. Discuss with user whether to roll back the feature or accept it as-is despite refutation.
- If `verdict: mixed` or `inconclusive` → leave PRD/HYP in `active`; propose a follow-up window or a focused experiment.

## Discipline

- **Verdict first.** No prose that softens the call. If the hypothesis was wrong, say so on line 1.
- **No "directionally correct" hand-waving.** Either the metric crossed the target or it didn't. If the target was unrealistic, that's a learning about *us*, not about the feature.
- **Counter-metric movement is a finding.** Don't bury it. A feature that grew engagement and tanked retention is not a win.
- **No fabricated data.** If the user can't produce numbers, say so and stop. An inconclusive validation is honest; a confirmed-by-vibe one is fraud.
- **Push back if the user argues for "confirmed" against ambiguous data.** The whole point of having a success metric was so we could be honest now.

## After validation

Tell the user:
- Where the validation was saved.
- The verdict and one-line justification.
- The status transitions you applied.
- **Suggested next step**:
  - If `confirmed` → next feature: `/product:prioritize` or `/product:discover`.
  - If `refuted` → discuss rollback; then `/product:discover` for the next attempt with the new learning.
  - If `mixed` / `inconclusive` → propose a focused follow-up.

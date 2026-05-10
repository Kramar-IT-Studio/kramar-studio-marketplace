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

## Worked examples

### Good: VAL-confirmed for "undo on accidental delete" (continues SPEC-0005)

```yaml
---
id: VAL-0004
status: active
created_at: 2026-05-18
role: product
verdict: confirmed
links_to:
  - PRD-0005
  - HYP-0007
  - ADR-0011
---
```

**Verdict.** **Confirmed.** Support tickets tagged `restore document` for the cohort dropped from 11/week (baseline) to 3.2/week (–71%) over the 4-week window — past the 60% target. WAU for the same cohort moved +1.4% (counter-metric held). The hypothesis was right on direction, magnitude, and segment.

**Metric snapshot.**

| Metric | Baseline | Measured | Delta | Target |
|---|---|---|---|---|
| Primary: support tickets `restore document` per week | 11 | 3.2 | –71% | ≤4.4 (–60%) |
| Counter: WAU among cohort (paying, <90 days) | 1,840 | 1,866 | +1.4% | ≥–2% |

- **Sample size.** 1,866 WAU; 13 tickets logged across the 4 weeks among this cohort.
- **Time window.** 2026-04-21 → 2026-05-18 (4 weeks post-launch).

**What the data showed.** Distribution of `time_to_undo_ms` (from the analytics event in SPEC-0005#6) clustered at 1.2–2.8s — most users undo within 3 seconds, well inside the 5s window. Tickets that *did* land in the period were almost all from users on the keyboard-shortcut path who didn't see the toast (one segment-level surprise — see Implications).

**What we got wrong / right about the hypothesis.** Got right: assumption that <90-day users are the affected cohort (older users either didn't have the problem or had built workarounds). Got partly wrong: assumed all delete paths were equivalent — keyboard-shortcut users have a meaningfully worse experience because their hands are already off the mouse when the toast appears.

**What we learned about the user.** Users who delete via keyboard expect to *resolve via keyboard*. The toast was reachable only by mouse; that's why a residual ticket cluster remained. Durable: any reversible action triggered by keyboard should have a keyboard-reachable undo affordance.

**Implications.**

- **Product.** Stay (PRD → `accepted`, HYP → `accepted`). One follow-up: `Cmd+Z` should bind to the undo affordance for 5 seconds after the toast appears. Spawn a new HYP for that — it's a separate small bet.
- **Backlog.** Re-prioritize: the `bulk-delete-undo` candidate that was deferred should re-enter the ICE list. We have stronger confidence now (the underlying mechanic works).
- **Architecture.** ADR-0011 (10s server-side soft-delete window) is reinforced — the 1.2–2.8s undo distribution sits comfortably inside the 10s GC budget.

**Why this is good.** Verdict is on line 1 with the magnitude and the cohort. Counter-metric is reported, not buried. The "what we learned" section produces a *durable* user insight (keyboard users expect keyboard undo) that survives this feature and seeds the next bet. ADR is reinforced explicitly.

### Bad: VAL that protects the launch

```yaml
---
id: VAL-0005
status: active
created_at: 2026-05-18
role: product
verdict: confirmed
links_to:
  - PRD-0006
  - HYP-0008
---
```

**Verdict.** **Confirmed.** Users seem happier with onboarding. Activation didn't move much numerically but qualitatively the team feels good about the launch. Directionally correct.

**Metric snapshot.**

| Metric | Baseline | Measured | Delta | Target |
|---|---|---|---|---|
| Primary: activation rate D7 | 28% | 28.5% | +0.5pp | +5pp |

**Why this is bad — line by line.**

- **"Confirmed" is fraud, given the data shown.** The target was +5pp (28% → 33%). The result is +0.5pp, well inside random noise for that sample size. This is a **refuted** verdict, possibly **inconclusive** if the sample is small. Marking it confirmed protects the launch and burns the whole feedback loop the cycle exists for.
- **"Directionally correct"** is a phrase invented to make missed targets sound like progress. Either the metric crossed the target or it didn't. If +0.5pp is the new target, restate the target *before* the launch and own that you weren't aiming as high. Post-hoc target adjustment is the most expensive form of self-deception.
- **"The team feels good about the launch"** is not data. It's a feeling. Validation reads data.
- **No counter-metric reported.** The PRD had `success_metric: "Improved user satisfaction"` (which we already established was broken — see define.md examples). The VAL inherits the brokenness and doesn't fix it.
- **No "what we learned about the user" section.** A confirmed-by-vibe verdict produces no learning. The next discovery starts from the same shaky priors.

The push-back move: refuse the verdict. Tell the user: "this is **refuted** or at minimum **inconclusive**. Mark it honestly. The point of the metric was to allow being wrong — accept the wrong, capture the learning. The roll-back conversation is separate."

## Anti-patterns to refuse

- **Verdict in section 5, not section 2.** Burying the verdict behind metric tables and prose lets the reader infer it from numbers — and inference produces the most generous interpretation. Verdict goes first; data comes after to support it.
- **Adjusting the target post-hoc.** Either the original target was unrealistic (a learning about *us*) or the launch missed (a learning about *the bet*). Both are findings. Re-writing the target to match the result destroys the learning on either axis.
- **"Inconclusive" as the safety verdict.** Reaching for inconclusive whenever data is uncomfortable defeats the cycle. Inconclusive is valid only when sample size or window genuinely can't decide; if the sample is sufficient and the result is unfavorable, that's *refuted*, not inconclusive.
- **No segment cuts when the metric is mixed.** A primary metric that moved at the population level but masks a cohort difference (worked for cohort A, hurt cohort B) is a finding. Reporting only the average obscures this and produces a wrong "stay" decision.
- **Leaving status transitions undone.** A confirmed verdict that doesn't move PRD → `accepted` and HYP → `accepted` leaves the artifacts in `active` forever. `/product:status` will keep flagging them as in-flight. Apply the transitions; that's part of the validation, not housekeeping.
- **No ADR cross-link when the architecture was justified by the hypothesis.** If ADR-NNNN was bet on this validation being confirmed (or refuted), the VAL must surface that — `links_to` + an "Implications for architecture" line. Silent VALs let stale ADR justifications rot.

## After validation

Tell the user:
- Where the validation was saved.
- The verdict and one-line justification.
- The status transitions you applied.
- **Suggested next step**:
  - If `confirmed` → next feature: `/product:prioritize` or `/product:discover`.
  - If `refuted` → discuss rollback; then `/product:discover` for the next attempt with the new learning.
  - If `mixed` / `inconclusive` → propose a focused follow-up.

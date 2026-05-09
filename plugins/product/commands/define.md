---
description: Phase 2 of the product cycle — write the PRD with explicit success metric.
argument-hint: "<feature slug or HYP-NNNN>"
---

# /product:define

Phase 2 of the per-feature product cycle. Take a discovery (HYP) and turn it into a Product Requirements Document. The PRD is what engineering reads to build, what design reads to flow, what analytics reads to instrument. **A PRD without a success metric is not a PRD — it's a wishlist.**

## Inputs

- Feature slug or HYP ID: `$ARGUMENTS`
- The matching `docs/product/discoveries/*.md` (HYP-NNNN). **Required.** If missing, abort and tell the user to run `/product:discover` first.
- The market-scan covering this feature's area (if recent). **The hook will warn** if no market-scan exists or if it's >90 days old.
- `ARCHITECTURE.md` and prior ADRs if they exist — for cross-references.

## What to produce

A PRD covering:

1. **Header** — feature name, owner, target launch window (rough — week/month, not date), source HYP.

2. **Problem and hypothesis** — copy-down from the discovery. Don't re-derive; reference HYP-NNNN.

3. **Scope** — what's in, what's out. The "out" list is as important as the "in" list.

4. **User stories** — 3–7 stories in `As a <role>, I want <action> so that <outcome>` form. **No more than 7.** If you have 12, split the feature.

5. **Success metric** — **MANDATORY.** A single primary metric with:
   - Baseline (current value or "no data").
   - Target (what change qualifies as success).
   - Measurement window (1 week / 30 days / 1 quarter post-launch).
   - Counter-metric (what should *not* degrade).

   The hook will flag if this section is missing or empty.

6. **Acceptance, at the product level** — checklist of behaviors. Not implementation details (that's the spec). E.g. "user can undo within 5 seconds", not "we use a 5-second debounce".

7. **Risks** — 2–4 risks ranked by severity. For each: how we'd detect it, how we'd mitigate.

8. **Open questions for engineering** — things you'll defer to the SPEC phase. Don't pretend to answer them here.

9. **Cross-references** — `links_to` block listing:
   - Source HYP.
   - Relevant ADRs (architectural decisions this PRD depends on or triggers).
   - Relevant market-scan SCAN-NNNN if applicable.

## Output location

Save to `docs/product/prds/YYYY-MM-DD-<feature-slug>.md`.

Front-matter:
```yaml
---
id: PRD-NNNN
status: draft
created_at: YYYY-MM-DD
role: product
links_to:
  - HYP-NNNN          # always
  - SCAN-NNNN         # if applicable
  - ADR-NNNN          # if applicable
success_metric: "<short metric description>"   # mirrors section 5
---
```

Allocate `PRD-NNNN` sequentially.

Update the source HYP's status: `draft` → `active` (a HYP becomes active when the PRD enters draft).

## Discipline

- **Success metric is non-negotiable.** Without it, you've written a feature description, not a PRD.
- **Counter-metric must be different from the primary.** "Engagement up, latency not worse" is valid. "Engagement up, engagement not down" is the same metric and doesn't catch regressions.
- **No solution proposals beyond user-visible behavior.** Don't pick libraries, don't draw schemas. The SPEC phase does that.
- **If the discovery's hypothesis was vague, the PRD will inherit the vagueness.** Push back: "HYP-NNNN's hypothesis is unmeasurable; refine it before continuing." Don't paper over.
- **If the feature requires a new architectural decision** (new external service, new schema, new protocol), surface it: "this PRD requires ADR work — run `/archforge:cycle` first or in parallel." Don't pretend the architecture is free.

## After the PRD

Tell the user:
- Where the PRD was saved.
- The success metric sentence.
- Any architectural ADRs that are required and don't yet exist.
- **Suggested next step:** `/product:spec "<feature>"` to write the implementation spec.

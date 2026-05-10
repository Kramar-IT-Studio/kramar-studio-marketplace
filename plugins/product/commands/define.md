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

## Worked examples

### Good: PRD for "undo on accidental delete" (continues HYP-0007)

```yaml
---
id: PRD-0005
status: draft
created_at: 2026-04-15
role: product
links_to:
  - HYP-0007
  - SCAN-0002
  - ADR-0011
success_metric: "Support tickets tagged 'restore document' down 60% for paying users <90 days, weekly window."
---
```

**Scope. In:** undo toast appears for 5 seconds after single-document delete; one click restores the document with its original metadata; toast is keyboard-dismissable. **Out:** undo for bulk delete (≥5 items — separate PRD), undo across sessions, undo for permanent-delete-from-trash.

**Success metric.**
- **Primary metric.** Support tickets tagged `restore document` per week.
- **Baseline.** 47 tickets / 30 days = ~11 / week (Linear export, 2026-03-12 → 2026-04-11).
- **Target.** ≤4.4 / week (60% reduction) for the user cohort defined in HYP-0007.
- **Window.** 4 weeks post-launch.
- **Counter-metric.** Weekly active users among the same cohort. Must not drop more than 2% (we're not selling outcomes by tanking engagement).

**Acceptance (product level).**
- [ ] After deleting a single document, a toast appears for 5 seconds with "Undo" and a close affordance.
- [ ] Clicking "Undo" within 5 seconds restores the document, its title, and its location in the tree.
- [ ] After 5 seconds, the toast dismisses; the document is in trash and recoverable through the existing trash UI.
- [ ] If another collaborator on the same document loaded the post-delete state, the restored document re-appears for them on next sync (no manual reload required).

**Risks.**
- **High: undo race vs. backend GC.** Mitigation: deletion is soft for ≥10s server-side regardless of toast state; ADR-0011 sets the GC window.
- **Medium: 5s is wrong.** Mitigation: track time-to-undo distribution as instrumentation; revisit at 4 weeks.

**Open questions for engineering.** Toast positioning during simultaneous bulk-delete (deferred to bulk-delete PRD). Mobile breakpoint behavior.

**Why this is good.** Success metric has all four parts (baseline, target, window, counter). Counter-metric is genuinely different from primary (ticket volume vs. WAU). Scope-out list is as long as scope-in. Each acceptance item is observable. Architectural dependency (ADR-0011 for GC window) is explicit, not hand-waved.

### Bad: PRD with broken success metric

```yaml
---
id: PRD-0006
status: draft
created_at: 2026-04-15
role: product
links_to:
  - HYP-0008
success_metric: "Improved user satisfaction"
---
```

**Success metric.**
- **Primary.** User satisfaction.
- **Baseline.** N/A.
- **Target.** Better.
- **Counter-metric.** User satisfaction must not decrease.

**Why this is bad — line by line.**

- **"User satisfaction" is not a metric, it's a category.** Until you name the instrument (CSAT survey? NPS? in-app rating?) and the question, you can't measure anything. The hook will flag this; even if it didn't, the field is empty in spirit.
- **Baseline `N/A` is a confession, not an exemption.** If you don't have a baseline, the action is to collect one before launch, not to declare it doesn't matter. Without baseline, "the metric moved" is unprovable.
- **Target "better" is unfalsifiable.** Better than what, by how much, in what window? A target that admits any positive number is a target that can never be missed.
- **Counter-metric == primary metric.** "User satisfaction up; user satisfaction not down" doesn't catch regressions. The counter-metric exists to surface side effects on a *different* dimension. If you can't name a different dimension, the feature has no plausible failure mode in your model — which is itself a finding.

The push-back move: refuse to save. Tell the user one of two things:
1. "Replace the metric with a measurable signal — a specific survey question with a baseline number, or pick a behavioral proxy (return rate, completion rate)."
2. "If you genuinely don't know what success looks like, the PRD is premature — go back to discovery, that's an open question."

## Anti-patterns to refuse

- **Acceptance items that are implementation choices.** "We use a 5-second debounce" is implementation. "Undo is available within 5 seconds of delete" is product behavior. The first belongs in the SPEC; in the PRD it constrains engineering before the SPEC phase has weighed alternatives.
- **User stories as features.** "As a user, I want a notification system." That's not a story, that's a feature name with a comma in it. A real story names the *role*, the *action*, and the *outcome the user gets*. If the outcome is missing, the story isn't a story — it's a wishlist item.
- **>7 user stories.** If you have 12, the feature is two features. Split. Forcing one PRD to cover both produces a SPEC that everyone reads as "everything in scope" and a launch that's late on both halves.
- **Risks without detection.** "Risk: it might not work." Without a way to *notice* the risk materializing, it's not a risk you've planned for, it's a worry you've voiced. Each risk needs detection (specific signal, specific threshold) and mitigation (specific action).
- **No `links_to` despite obvious architectural dependencies.** Body says "we'll need a queue" → `links_to` is empty → ADR doesn't exist. Either run `/archforge:cycle` first (or in parallel), or write the dependency in `links_to` as `ADR-TBD-<topic>` and surface it as a blocker. Don't pretend the architecture is free.
- **Counter-metric == primary metric, in disguise.** "Engagement up; bounce rate not up" — if engagement and bounce are derived from the same denominator, they're the same metric. Pick a counter-metric on a *different axis* (cost, latency, support volume, retention).

## After the PRD

Tell the user:
- Where the PRD was saved.
- The success metric sentence.
- Any architectural ADRs that are required and don't yet exist.
- **Suggested next step:** `/product:spec "<feature>"` to write the implementation spec.

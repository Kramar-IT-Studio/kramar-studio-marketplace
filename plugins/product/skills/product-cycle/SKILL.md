---
name: product-cycle
description: Activate this skill whenever the user is doing product work — defining a feature, writing a PRD, validating a launch, scanning a market, prioritizing a backlog. The skill carries the methodology: what each phase produces, when to skip a phase, when to abort, how the per-feature cycle relates to market-scan and prioritize (which are NOT in the cycle), and how product work interleaves with architect architecture work. Use proactively when the user discusses product strategy, feature definition, launch metrics, user discovery, or asks "what's next" / "should we build this" — even without a /product slash command.
---

# product-cycle

This skill carries the **methodology** for the `product` plugin. The format rules — front-matter, IDs, file layout — live in `product-conventions`. This file is about **why this cycle, in this order, with these guardrails**.

## The shape

```
                    ┌───────────────────┐
                    │   MARKET-SCAN     │  rare — quarterly or new area
                    │   (per area)      │  bounded: 3-7 competitors,
                    └────────┬──────────┘  1-3 gaps, ≤200 lines
                             │
                             ▼ informs
                    ┌───────────────────┐         ┌──────────────┐
                    │   PER-FEATURE     │ ◄────── │  PRIORITIZE  │
                    │   CYCLE           │ next    │  (over       │
                    │                   │ pick    │  backlog)    │
                    └─────────┬─────────┘         └──────────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │  1. DISCOVER      │  hypothesis + segment + JTBD
                    └─────────┬─────────┘
                              ▼
                    ┌───────────────────┐
                    │  2. DEFINE        │  PRD with success metric
                    └─────────┬─────────┘
                              ▼
                    ┌───────────────────┐
                    │  3. SPEC          │  acceptance criteria + analytics
                    └─────────┬─────────┘
                              ▼
                    ┌───────────────────┐
                    │  4. VALIDATE      │  honest verdict against the metric
                    └─────────┬─────────┘
                              │
                              └─► feeds back into PRIORITIZE (re-rank)
                                  and DISCOVER (next feature)
```

Three things to internalize about this shape:

1. **Market-scan is not the first step of the cycle.** It's an **anchor for an area**. The cycle runs many times per market-scan. Treating market-scan as per-feature kills you with research overhead.

2. **Prioritize is not a step at all.** It's an operation **over the backlog**. Run when ≥2 candidates compete for the next slot. Solo work with one feature in flight: skip it.

3. **The cycle is per-feature, not per-product.** A product has many cycles in flight at different phases. `PRODUCT.md` carries the cross-feature view; the cycle artifacts carry the per-feature view.

## Why these phases, in this order

- **Discover before Define.** A PRD without a hypothesis is a wishlist. The hypothesis is what makes the validation later possible.

- **Define before Spec.** Engineering has to know what behavior they're contracting to before they specify how. PRDs that mix product behavior with implementation choices are unreviewable on either axis.

- **Spec before build.** A spec that's written *during* implementation is a debug log, not a spec. It exists to make acceptance testable.

- **Validate after launch.** Without validation, the feature was a guess that we promoted to a fact silently. The hypothesis was made for this moment.

- **Validate before prioritizing the next thing.** Validation recalibrates the confidence column on every other backlog candidate. Skip validation, and your priorities drift on stale priors.

## When to skip a phase

Skipping is allowed but **visible** — `/product:status` will flag the gap.

| Phase | Skip when | Don't skip when |
|---|---|---|
| `market-scan` | Working in an area scanned in the last 90 days, or in a new area where speed-to-test outweighs anchor (early prototype). | Entering a new area you'll commit serious work to; >90 days since last scan; pricing/positioning under question. |
| `discover` | The feature is mechanical (tooling improvement, refactor with no user-visible behavior change). Even then, write a one-paragraph note as `HYP-NNNN` for the trace. | Anything user-visible. Anything where a measurable signal exists. |
| `define` | The feature is so small a 3-line description is the whole story. Even then, the success metric must be named or the work shouldn't ship. | Almost always run it. The PRD is cheap; lacking one later is expensive. |
| `spec` | Building solo, the feature is a few hours of work, and the PRD's acceptance items are already testable. | Multi-engineer work, novel architecture, anything touching paying users. |
| `validate` | Never. Even if no metric moved, validate to capture the learning. Reading the data after every launch is the discipline that compounds. | Always run. |
| `prioritize` | Solo work with one candidate. | ≥2 candidates competing, or major recalibration after a refuted validation. |

## Common failure modes of the cycle

The cycle's failures are not random — they cluster. Watch for these:

### 1. Research-paralysis at market-scan

Symptom: scan grows past 300 lines, lists 12 competitors, no positioning paragraph.

Fix: hard cut to 5 most relevant competitors. Drop everything that doesn't sharpen the gap analysis. The 200-line hook exists for this.

### 2. Solution-leakage in discovery

Symptom: HYP-NNNN proposes "we'll add a button to do X" before establishing whether the user has the underlying pain.

Fix: rewrite. Discovery is **problem space**, not solution space. If the discovery already names the solution, the hypothesis can't be tested — the team will rationalize the solution they already chose.

### 3. PRD without a real success metric

Symptom: success metric is "users will love it" or "engagement will improve".

Fix: refuse. Either name a numeric target with a window and a counter-metric, or admit the metric is unknown and add it as the top open question. The hook flags missing metrics; this is for the cosmetic-but-empty case.

### 4. Spec that re-derives the PRD

Symptom: the spec's acceptance criteria are the PRD's acceptance items, copy-pasted.

Fix: the spec must **expand** product acceptance into testable behaviors with edge cases, error states, analytics events. If the spec adds nothing, you didn't need a spec phase — but more often you did, and the spec is broken.

### 5. Validation that protects the launch

Symptom: the metric didn't move; the validation argues "directionally correct" and marks `confirmed`.

Fix: refute. The point of the metric was to allow being wrong. If we adjust the metric post-hoc to make the launch succeed, we lose the only feedback loop the cycle has.

### 6. Prioritization without recent validations

Symptom: every candidate scored at high-confidence; no validation has run in months.

Fix: cap confidence column. Without recent validations, the confidence number is a fiction — surface that explicitly.

## Interleaving with `architect`

Most non-trivial features touch architecture. The cycles are different but they meet:

- **A PRD that requires a new service, schema, or external dependency** triggers a parallel `/architect:cycle`. The PRD blocks on the ADR; the SPEC links to the resulting `ADR-NNNN`. Don't pretend the architecture is free.

- **An ADR justified by a product hypothesis** (e.g. "we picked Postgres because we believe transactional consistency matters for use case X") should `links_to` the `HYP-NNNN`. When that hypothesis is later validated or refuted, the ADR's justification is reinforced or weakened — and that's worth tracking.

- **Validation that refutes the hypothesis** the architecture was built on is a signal to revisit the ADR. Run `/architect:observe` after a refuted validation.

## When the cycle does **not** apply

If the request is a bug fix, a copy change, or a minor UX tweak that doesn't carry a hypothesis — don't force the cycle. Say so plainly: "this isn't product cycle territory, it's a tweak." Mark it in the changelog or commit and move on. The cycle is for **decisions**, not for keystrokes.

## Worked example: one full pass

A connected example showing how the artifacts interlock. Same case as the per-command examples in `discover.md` / `define.md` / `spec.md` / `validate.md`, but here as a *narrative* — the call each phase made and what would have broken if the cycle had been short-circuited.

### Setting

Solo studio, B2B docs product. Support tag `restore document` is climbing — 47 tickets in 30 days, ~80% from accounts <90 days old. The trigger to start a cycle is the support data, not a feature request.

### Phase 0: market-scan (already on file)

The `onboarding-and-recovery` area has a fresh scan from the last quarter (`SCAN-0002`). Key finding from the scan: the gap is not "missing undo" — every comparable product has *some* form of recovery. The gap is **time-to-recovery without contacting support**. Notion: 10s toast. Linear: immediate-then-trash. Our product: trash-only, ~30 minutes of human work to restore.

This anchors the discovery. Without `SCAN-0002`, the cycle would start without context for "5s vs 10s vs immediate" — just our guess.

### Phase 1: discover → HYP-0007

The discovery establishes:
- The problem is *recovery latency*, not *information loss* — restored documents come back fine, it's just slow.
- The cohort is paying users in their first 90 days.
- The hypothesis is one sentence with a number: *"5-second undo toast → 60% reduction in restore tickets, weekly window."*
- Open questions include the specific "5 vs 10 seconds" call.
- The anti-hypothesis names what would refute the bet: *if support data shows redeletes by the same user, the deletes were intentional and undo is decoration*.

**What would have broken without discovery.** Going straight to a PRD would have produced "let's add an undo button" with no hypothesis, no measurable signal, and no anti-hypothesis. We'd have shipped, looked at "tickets went down a bit", felt good, and missed the keyboard-undo blind spot that surfaced in the validation. Discovery is what makes the validation later mean something.

### Phase 2: define → PRD-0005

The define phase produces the PRD. The load-bearing call is the **success metric**:

| | Value |
|---|---|
| Primary | Support tickets tagged `restore document` per week |
| Baseline | 11 / week (computed from Linear export) |
| Target | ≤4.4 / week (60% reduction) |
| Window | 4 weeks post-launch |
| Counter | WAU among the same cohort, must not drop >2% |

The PRD also surfaces the **architectural dependency**: the soft-delete window. We can't safely promise undo if the backend GCs deletes immediately. This triggers a parallel `/architect:cycle` → `ADR-0011` (10-second server-side soft-delete window). The PRD's `links_to` carries `[HYP-0007, SCAN-0002, ADR-0011]`.

**What would have broken without define.** Skipping straight from HYP to SPEC would have left the success metric unstated. The team would have built the toast, eyeballed the ticket trend, and declared victory. With no baseline, no target, no counter-metric, the validation later would have nothing to compare against.

The other failure mode — fake success metric ("improved user satisfaction") — is shown as the bad example in `define.md`. Same crash, slower.

### Phase 3: spec → SPEC-0005

The spec expands the PRD's product-level acceptance into testable criteria. Key calls:

1. Each PRD acceptance item maps to ≥1 SPEC criterion. Trace shown in the self-review block.
2. Edge cases get explicit behavior — network failure has its own acceptance criterion (#6), not buried in prose.
3. **Analytics is part of the spec**: events `document.deleted` and `document.undeleted` with `time_to_undo_ms` are named. Without this, the success metric in the PRD is unmeasurable. The hook only checks acceptance count; the analytics-coverage check is methodology, lives here.
4. Out-of-scope is explicit: bulk delete is its own PRD; mobile breakpoint is its own design pass.

`acceptance_count` lands at 6 — past the floor of 3, comfortable for the scope.

**What would have broken without spec.** The team builds, ships, and the success metric is the *support tag count* (already instrumented). But the question "is 5s the right window" can't be answered without `time_to_undo_ms` — and that event was named in the SPEC. Without the SPEC, we'd ship a feature with a measurable headline metric but no way to revisit the calibration.

### Phase 4: validate → VAL-0004

Four weeks after launch. The validation reads the data and lands a verdict on line 1:

> **Confirmed.** Tickets dropped 71% (vs 60% target). WAU +1.4% (counter held). Hypothesis right on direction, magnitude, and segment.

But the validation doesn't stop at "confirmed". The `time_to_undo_ms` distribution shows clustering at 1.2–2.8s — much faster than the 5s budget. And the residual tickets cluster on keyboard-shortcut users who didn't see the toast.

**The durable learning** isn't "undo works". It's "**users who delete via keyboard expect to resolve via keyboard**". That generalizes — every reversible keyboard action should have a keyboard-reachable undo. This insight outlives the feature; it seeds the next bet (HYP for `Cmd+Z` undo binding).

The validation also reinforces **ADR-0011** (the 10s soft-delete window): the 1.2–2.8s undo distribution sits inside the 10s GC budget with margin. The ADR's justification holds.

**What would have broken without validate.** If we'd shipped and moved on, the keyboard-undo insight would have stayed buried. The next discovery would have started from the same priors as HYP-0007. The whole point of the cycle is the loop — without validate, the loop isn't closed and the studio's product memory doesn't compound.

The other failure mode — *protecting the launch* by marking +0.5pp as "directionally correct" — is shown as the bad example in `validate.md`. That kills the loop just as effectively as skipping the phase.

### What the example shows in aggregate

- **Each phase pays the next.** Discovery's anti-hypothesis informed what to instrument; PRD's metric defined what the SPEC analytics had to cover; SPEC's `time_to_undo_ms` event made the validation's keyboard-undo insight visible. Skip one and the chain breaks downstream.
- **Cross-role linkage is structural.** ADR-0011 wasn't decorative — without the 10s server-side window, the 5s client toast couldn't make a safe promise. The PRD surfaced the dependency; `architect` produced the decision; SPEC and VAL referenced it.
- **The verdict is the start of the next cycle, not the end.** Confirmed VAL → backlog re-shuffles (bulk-delete-undo gains confidence), new HYP spawned (keyboard-undo binding). The VAL is feedback into prioritize, not a closing ceremony.

If a real cycle in your project doesn't produce this kind of trail, the cycle isn't doing the work. Look for which phase got skipped or gestured at, and put the missing artifact in.

## Tone

- **Push back, don't acquiesce.** A weak hypothesis, a missing metric, a vague segment — these are the failures the cycle exists to catch. Soft pushback that folds wastes the cycle.
- **Why before how.** Every output starts with the why (problem, hypothesis, evidence) before the how (PRD scope, spec criteria).
- **Honest about uncertainty.** "We don't know" is a valid output if it's accompanied by what you'd need to know.

## Pre-output checklist

Before sending a phase artifact, mentally verify:

- [ ] The artifact's required front-matter fields are present (see `product-conventions`).
- [ ] The phase's mandatory section (success_metric / acceptance / verdict) is real, not theatrical.
- [ ] Cross-references to prior phases (`links_to`) are filled.
- [ ] If architecture is implied, an ADR is named or an open question is logged.
- [ ] No solution-leakage in problem-space artifacts (HYP); no problem-leakage in solution-space artifacts (SPEC).
- [ ] Language pass applied per `architect`'s Language section if the artifact is in Russian.

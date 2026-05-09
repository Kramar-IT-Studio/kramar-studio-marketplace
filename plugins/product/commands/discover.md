---
description: Phase 1 of the product cycle — surface the user problem and shape a hypothesis. No solution yet.
argument-hint: "<feature or problem statement>"
---

# /product:discover

Phase 1 of the per-feature product cycle. The goal is to **make the user problem and hypothesis explicit** before any product spec is sketched. No "we'll build X" yet — only "we believe Y about user Z".

## Inputs

- Feature or problem: `$ARGUMENTS`
- `PRODUCT.md` for product context.
- Existing market-scan for the relevant area in `docs/product/research/`. **If no recent scan exists for the area this feature belongs to, the hook will warn.**
- `ARCHITECTURE.md` and prior ADRs if they exist — features may reuse architectural patterns.

## What to produce

A discovery document covering:

1. **Restated problem** — your understanding of the user pain or opportunity. Make assumptions explicit.

2. **Target user / segment** — who feels this pain? Be specific. "Users" is not a segment.

3. **Job-to-be-done** — what is the user trying to accomplish when they hit this pain?

4. **Hypothesis** — one sentence in the form: **"We believe `<change>` will cause `<outcome>` for `<segment>`, measured by `<signal>`."**

5. **Evidence so far** — what makes us believe this? Conversations, tickets, churn data, market-scan, analogies. **Cite sources or mark as anecdotal.**

6. **Open questions** — what we can't answer without more information. Ask the user explicitly at the end.

7. **Anti-hypothesis** — what would make us *not* build this? The pre-mortem. If you can't think of one, the hypothesis is too vague.

## Output location

Save to `docs/product/discoveries/YYYY-MM-DD-<feature-slug>.md`.

Front-matter:
```yaml
---
id: HYP-NNNN
status: draft
created_at: YYYY-MM-DD
role: product
links_to: []          # optional: SCAN-NNNN if this discovery follows a market-scan
---
```

Allocate `HYP-NNNN` by reading the highest existing `HYP-` number and incrementing.

## Discipline

- **Don't propose a solution.** Even if obvious. The next phase (`/product:define`) handles that.
- **Don't fabricate evidence.** "Users want this" without a source is a hypothesis disguised as fact.
- **Push back on weak segments.** "All our users" / "everyone" is not a segment. If the user can't narrow it, surface that as an open question.
- **Anti-hypothesis is mandatory.** Skipping it produces sunk-cost-prone work.

## When the user answers

After the user resolves open questions, **append** Section 8: "Refined hypothesis" to the same file with:
- The updated hypothesis (if anything changed).
- Resolved questions with the answers.
- Deferred questions with the "wait for" condition.

If new constraints surface, do **not** auto-proceed to `/product:define`. Tell the user: "discovery surfaced these — confirm before defining the PRD."

## After discovery

Tell the user:
- Where the discovery was saved.
- The hypothesis sentence.
- The 3–5 open questions, prioritized.
- **Suggested next step:** "When questions are answered, run `/product:define \"<feature>\"` to write the PRD."

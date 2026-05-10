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

## Worked examples

### Good: solo-dev "undo on accidental delete"

```yaml
---
id: HYP-0007
status: draft
created_at: 2026-04-12
role: product
links_to:
  - SCAN-0002
---
```

**Restated problem.** Users delete documents and ask support to recover them. Restore-from-backup takes ~30 minutes of human work and produces angry threads. Underlying assumption: most deletes are accidental, not intentional.

**Target user / segment.** Paying users on the team plan (5+ seats), within their first 90 days. Low-tenure users haven't built habits around our trash flow yet.

**Job-to-be-done.** Recover a document I deleted by mistake without writing to support.

**Hypothesis.** *We believe that adding a 5-second undo toast after deletion will reduce support tickets tagged "restore document" by 60% for users in days 0–90, measured weekly.*

**Evidence so far.** 47 support threads tagged "restore document" in the last 30 days (Linear export, attached). Of those, 38 (81%) were on accounts <90 days old. No formal user research yet — anecdotal from the support tag.

**Open questions** (in priority order):
1. Is 5 seconds the right window? Competitor scan says Notion uses 10s, Linear uses immediate-then-trash.
2. Should undo also apply to bulk-delete (≥5 items)? More risk of regret, but undo at 5s for 50 items is heavier UX.
3. What happens if the document was shared and another user already loaded the post-delete state?

**Anti-hypothesis.** If support data shows the deletes are intentional (user is cleaning up old work, not panicking), undo is decoration. We'd see a spike in same-user redeletes — check that before building.

**Why this is good.** Hypothesis is one sentence with a measurable signal (60% reduction, weekly window). Segment is concrete (paying, 5+ seats, <90 days). Evidence is cited with a count. Anti-hypothesis names the failure mode in falsifiable terms.

### Bad: vague "improve onboarding"

```yaml
---
id: HYP-0008
status: draft
created_at: 2026-04-12
role: product
links_to: []
---
```

**Restated problem.** Onboarding feels rough.

**Target user / segment.** New users.

**Hypothesis.** Better onboarding will increase activation.

**Evidence so far.** Anecdotal — Igor saw a tweet about it.

**Anti-hypothesis.** *(empty)*

**Why this is bad — line by line.**

- "Onboarding feels rough" is not a problem statement. *Whose* onboarding? *Which step?* *Compared to what baseline?* No assumption is made explicit, so nothing can be tested.
- "New users" is not a segment. New users on which plan? In which language? On which device?
- "Better onboarding will increase activation" defines neither variable. What change? What outcome? What measurement? This sentence cannot be wrong, which means it cannot be useful.
- One anecdotal source is fine as a trigger. As the *only* evidence, it's not enough to start a cycle. At minimum, pull a number from your own analytics.
- An empty anti-hypothesis means you haven't thought about what would refute the bet. You will rationalize whatever you build.

The push-back move on this draft: refuse to save. Tell the user "this is too vague to test — drop it back to one of: a specific friction point, a specific segment, a specific signal." Make them narrow before continuing.

## Anti-patterns to refuse

If a draft hits any of these, push back, don't save:

- **Solution-leakage.** "We'll add a button that does X" appears anywhere in the discovery. Discovery is *problem space*. The button is a hypothesis about the solution; the discovery's job is to verify the underlying user pain first. If the user insists the solution is obvious — even more reason to write the hypothesis cleanly so the validation later means something.
- **"All our users" segment.** No real segment is "everyone". If the user can't narrow, ask: "which cohort would notice this *first*?" That cohort is the real segment. If they say "everyone", surface it as an open question and refuse to proceed without a concrete cut.
- **Unfalsifiable hypothesis.** "Users will love it" / "engagement will improve" can't be measured against a specific target, so they can't be wrong. Demand a numeric signal with a window. If the user can't name one, that's the discovery's *primary* open question — make it Q1.
- **Anti-hypothesis copy-paste.** If the anti-hypothesis is just "if it doesn't work" — that's not a pre-mortem, that's a tautology. The anti-hypothesis names the *specific evidence* that would invalidate the bet. "If support data shows redeletes by the same user, undo is decoration."
- **Evidence without sources.** "Users want this" with no link, no count, no quote. Either cite (ticket IDs, dashboard query, NPS comments by ID) or mark explicitly as anecdotal. The validation later compares against this baseline; if the baseline is a vibe, the validation is theatre.

## After discovery

Tell the user:
- Where the discovery was saved.
- The hypothesis sentence.
- The 3–5 open questions, prioritized.
- **Suggested next step:** "When questions are answered, run `/product:define \"<feature>\"` to write the PRD."

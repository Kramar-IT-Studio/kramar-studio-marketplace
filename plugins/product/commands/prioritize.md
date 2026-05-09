---
description: Operate over the backlog — produce a prioritized order of candidates with explicit criteria. Not a step in the per-feature cycle.
argument-hint: "[criteria=<criteria>]"
---

# /product:prioritize

Backlog operation. Read all `draft` HYPs and PRDs, plus `docs/product/backlog.md`, and produce a prioritized order with explicit reasoning. **This is not a step in the per-feature cycle** — it runs whenever there are ≥2 candidates competing for the next slot. For solo work with one item in flight, this command is a no-op and will say so.

## Inputs

- Optional criteria flag: `$ARGUMENTS`. Default criteria: `impact / confidence / effort` (ICE). Other supported: `RICE`, `value-vs-effort`, or a free-form list (e.g. `criteria=strategic-fit,revenue-near-term,reversibility`).
- All `docs/product/discoveries/*.md` with `status: draft` or `status: active`.
- All `docs/product/prds/*.md` with `status: draft`.
- `docs/product/backlog.md` — the rolling list of candidates.
- Recent validations — they recalibrate confidence.
- Recent market-scans — they shift impact.

## What to produce

### 1. Candidate set

A list of all current candidates with:
- ID (HYP-NNNN, PRD-NNNN, or unallocated backlog entry).
- Title.
- Source (discovery / direct backlog entry / from a prior validation's follow-up).

### 2. Per-candidate scoring

For each candidate, score on the chosen criteria. Show the math; don't hide it. Example for ICE:

| ID | Title | Impact (1-10) | Confidence (0-1) | Effort (weeks) | ICE = I×C/E |
|---|---|---|---|---|---|

**Justify each score in one line below the table.** Numbers without reasoning are theatre.

### 3. Ordered ranking

Highest-priority first. State which candidate is **next** (singular).

### 4. The "do not pick" list

Candidates that look attractive but you're recommending against. For each, the one-line reason. This list is as important as the ranking — it's where you push back.

### 5. Open questions affecting priority

What you can't score because you lack information. Ask the user.

## Output location

Save to `docs/product/backlog.md` (overwrite — this is a snapshot, not a versioned artifact). Append a dated history block at the bottom (`## History` section), preserving prior runs as one-line summaries (date + top pick).

Touch `docs/product/.last-prioritize` (empty file or timestamp). The hook reads this to detect long pauses without prioritization.

## Discipline

- **Criteria must be explicit.** "Gut feel" is not a criterion. If you used gut feel, name it and say so.
- **Push back on user-supplied weights.** If the user says "always optimize for revenue", surface the trade-off: "this deprioritizes HYP-007 indefinitely; that hypothesis was high-conviction in the last discovery — sure?"
- **No prioritization without recent context.** If the most recent market-scan is >180 days old or there are no validations on file, surface that as a confidence cap on every score.
- **Solo-mode handling.** If there's exactly one candidate in `draft`, don't perform the full ritual. Say: "one candidate, prioritization unnecessary — proceed to `/product:define`." Don't fabricate competition.

## When to abort

If there are no candidates: tell the user and suggest `/product:discover`. Don't produce an empty backlog snapshot.

If the candidates are at incompatible stages (one HYP, one already-shipped feature pending validation), tell the user the comparison is malformed and ask which subset to compare.

## After prioritization

Tell the user:
- Top pick and the one-line reason.
- The "do not pick" list (if any).
- Open questions to resolve before the top pick is fully picked.
- **Suggested next step:** `/product:define` for the top pick if it's a HYP, or `/product:spec` if it's a PRD.

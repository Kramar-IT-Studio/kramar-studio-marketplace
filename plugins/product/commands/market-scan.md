---
description: Bounded market scan for a product area — competitors, gaps, price anchors, positioning. Quarterly cadence, not per-feature.
argument-hint: "<area name>"
---

# /product:market-scan

Produce a market scan for an **area** of the product (not a feature). Market-scan runs **rarely** — when a new area is being entered, or roughly quarterly to refresh existing areas. It is **not** a step in the per-feature cycle; per-feature work uses `/product:discover` and `/product:define`.

The scan is **deliberately bounded** — it exists to anchor positioning, not to fund a research project. The hooks will warn if the output exceeds 200 lines.

## Inputs

- Area name: `$ARGUMENTS`
- `PRODUCT.md` for prior context on this area.
- Existing `docs/product/research/*-market-scan.md` for the same area (if any) → this is a **refresh**, not a fresh scan.

## What to produce

A market scan with **hard limits** (these are not aspirational — exceeding them is the failure mode this command guards against):

### 1. Competitors (3–7, max)

A short table:

| Name | Positioning (one line) | Notable strength | Notable weakness |
|---|---|---|---|

If you find more than 7 candidates, **filter** — keep the most relevant. Listing 15 competitors is research-paralysis, not a scan.

### 2. Gaps (1–3, max)

What is **underserved** in this area? One paragraph per gap. A gap must be:
- Concrete (not "better UX").
- Tied to a user job-to-be-done.
- Not just "X is missing in competitor Y" — a real category-level gap.

If you can't name 1–3 gaps, the scan failed — say so explicitly. **Empty gap section is an automatic flag for the hook.**

### 3. Price anchors

What do reasonable competitors charge for analogous value? Short list:
- Free / open-source tier.
- Mid-tier ($X–$Y range, what you get).
- Premium / enterprise ($Z+, what unlocks).

If pricing is opaque (common in B2B), say so. Don't fabricate.

### 4. Positioning paragraph (1, max)

**One paragraph.** Where would *our* product sit in this market, given the gaps we found? This is the load-bearing output — everything above feeds into it.

## Output location

Save to `docs/product/research/YYYY-MM-DD-<area-slug>-market-scan.md`.

Front-matter:
```yaml
---
id: SCAN-NNNN
status: active
created_at: YYYY-MM-DD
role: product
area: <area-name>
links_to: []
---
```

Allocate `SCAN-NNNN` by reading the highest existing `SCAN-` number in `docs/product/research/` and incrementing.

## Hard rules

- **3–7 competitors.** Not "I found 12 and listed them all".
- **1–3 gaps.** Not zero, not eight.
- **One positioning paragraph.** Not three sections of speculation.
- **≤200 lines total.** This is enforced softly via hook; aiming for 100–150 is healthy.
- **Use `web_search` for anything version-sensitive** (pricing, recent launches, market events). Pretrained knowledge of "what tools exist in space X" is months stale.

## When to refresh vs new scan

- **Refresh** (same area, existing scan): supersede the old scan (`status: superseded`, `links_to: [SCAN-NNNN-new]`) and create a new `SCAN-NNNN+1`. Keep the old file. Track movement in the new scan's intro.
- **New scan**: a different area entirely.

## After the scan

Tell the user:
- Where the scan was saved.
- The 1–3 gaps you found.
- The positioning paragraph.
- **Suggested next step:** if the user has a specific feature in mind that lives in this area, run `/product:discover "<feature>"` next. If not, the scan stands alone as a quarterly reference.

## When to abort

If you can't name **any** gap after 3–7 competitors, abort. Tell the user: "no gap surfaced — either the area is saturated, or our differentiation is non-existent here, or this isn't the right area to enter." Don't fabricate a gap to fill the section.

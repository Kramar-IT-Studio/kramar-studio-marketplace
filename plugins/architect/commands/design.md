---
description: Phase 2 of the Architecture Cycle — generate 2–3 alternatives with explicit trade-offs.
argument-hint: "<problem statement>"
---

# /archforge:design

Phase 2 of the Architecture Cycle. The goal is to **propose alternatives, not pick one**. Decision is the next phase.

## Inputs

- Problem statement: $ARGUMENTS
- Discovery output: read the most recent file in `docs/architecture/research/` that matches the problem, if it exists.
- Project context: `./ARCHITECTURE.md` and prior ADRs.

If no discovery document exists, briefly walk the discovery questions inline before designing — but flag this and suggest running `/archforge:discover` first for non-trivial problems.

## What to produce

A design document with:

1. **Problem and forces (1 paragraph)** — refer to discovery, summarize.

2. **Alternative 1** — name and one-line summary.
   - **Sketch** — diagram (Mermaid via `c4-diagrams` skill where structure helps), or a short structural description.
   - **How it satisfies the forces** — point by point.
   - **What gets easier.**
   - **What gets harder.**
   - **Estimated effort** — rough order of magnitude (days / weeks / months).
   - **Where it breaks** — boundary conditions, when this stops being a good fit.

3. **Alternative 2** — same structure.

4. **Alternative 3** — same structure. **Always include "do nothing / keep status quo"** as one of the alternatives unless the problem statement makes it impossible. Status quo is a real option and explicitly comparing to it sharpens the others.

5. **Comparison matrix** — alternatives × the top 3–5 forces, with one-word scoring (good / fair / poor / N/A).

6. **What we explicitly do NOT consider — and why.** Architectural research and discovery often surface options that look reasonable on the surface but are wrong for this specific situation. Capturing them with one-line dismissals prevents the next person (or the user, six months later) from re-litigating the same dead ends. List 2–6 such options with one-line reasons:
   - "MongoDB — not considered: Postgres covers all our access patterns; introducing a second engine without need is operational debt."
   - "Microservices split — not considered: single team, single product, premature."
   - "Self-hosted Kafka — not considered: managed Pub/Sub is cheaper at our scale and we have no replay requirements."
   This section is **not** the alternatives list — these never made it to alternatives because forces ruled them out fast.

7. **What you'd need to know to decide** — the missing inputs that, once known, would tip the choice. This bridges to phase 3.

## Output location

Save to `docs/architecture/research/YYYY-MM-DD-<slug>-design.md`.

## Discipline

- **Three alternatives is the target**, not one. Two minimum. If you genuinely can't generate three, name what you tried and rejected and why.
- **Trade-offs, not just upsides.** Every alternative has downsides; if you can't see them, you haven't thought enough.
- **No premature recommendation.** Keep the bias out of phase 2.
- **Consult `system-design`, `frontend-architecture`, `backend-architecture`, or `ai-agents-architecture` skills** as appropriate.
- **Reference ADRs by number** when an alternative aligns or conflicts with an existing decision.

## Output to chat

Summarize the alternatives and the comparison matrix. Tell the user where the doc is. Suggest: "When you're ready, run `/archforge:decide \"<problem>\"` to commit."

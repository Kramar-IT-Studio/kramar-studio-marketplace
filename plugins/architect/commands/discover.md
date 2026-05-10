---
description: Phase 1 of the Architecture Cycle — gather constraints, forces, prior art, and requirements for a problem.
argument-hint: "<problem statement>"
---

# /archforge:discover

Phase 1 of the Architecture Cycle. The goal is to **make the problem space explicit** before any solution is sketched. No alternatives are proposed in this phase.

## Inputs

- Problem statement: $ARGUMENTS
- Project context: read `./ARCHITECTURE.md` and `./docs/architecture/decisions/` if they exist.

## What to produce

A discovery document covering:

1. **Restated problem** — your understanding of what's being asked, in your own words. Make assumptions explicit.

2. **Functional requirements** — what the system must do. 3–5 user/operational scenarios.

3. **Quality attributes (non-functional)** — fill in or flag missing:
   - Scale: DAU/MAU, peak RPS, data volume.
   - Latency targets: p50, p95, p99 for critical operations.
   - Availability target: e.g., 99.9%.
   - Consistency requirements: strong / eventual / per-operation.
   - Durability requirements: what must never be lost.
   - Geographic distribution.

4. **Constraints** — fixed forces:
   - Team: size, expertise, on-call posture.
   - Operational: existing infra, deployment model, budget.
   - Compliance / regulatory.
   - Time budget.

5. **Prior art and existing decisions**:
   - Relevant prior ADRs in `docs/architecture/decisions/`.
   - Relevant external precedents (with `architecture-research` if needed).
   - Existing components or modules in the repo that touch this problem (use file search).

6. **Forces that will shape any solution** — the load-bearing constraints. Things like CAP, latency budget, organizational reality, regulatory requirements.

7. **Open questions** — what you can't answer without more information from the user. Ask them explicitly at the end.

## Output location

Save the discovery document to `docs/architecture/research/YYYY-MM-DD-<slug>.md`. Slug is derived from the problem statement.

## Discipline

- **Don't propose solutions.** Even if the answer seems obvious. Keep this phase pure.
- **If you don't know, ask.** Don't fabricate the user's constraints.
- **Use `architecture-research` for any version-sensitive claim.**
- **If existing ADRs apply, name them by number** and explain how.

## When the user answers — second round of discover

After the user answers the open questions, **do not jump straight to design**. Run a second pass through the discovery document with the new information, looking for:

1. **Push-back opportunities.** Did the user answer something that contradicts the forces you identified? Did they ask for capability X when their stated constraints (team size, budget, time) make X unrealistic? If yes — push back explicitly. Quote the contradiction and propose a deferral or a scope reduction. Do not soft-cave: if the architecture skill considers an answer weak, argue for the alternative until the user provides a real counter-argument.

2. **Constraints surfaced by answers.** Sometimes answers reveal a constraint that wasn't visible in round 1. ("We can only deploy to <region>" → re-evaluate provider availability; "The product must work offline" → re-evaluate the entire async strategy.) Add the new constraint to the document explicitly.

3. **Questions resolved vs deferred.** Mark each open question as resolved (with the resolution) or deferred (with a "wait for" condition). A question silently dropped is a hidden assumption.

Append this as **Section 7: Second round of discover** to the same document, dated. Do not overwrite Section 6 — the trail of how the problem was understood matters.

If round 2 produces material new constraints or push-backs, **do not auto-proceed to design**. Tell the user: "second round surfaced these gaps — confirm before proceeding to design."

## Output to chat

Tell the user:
- Where the document was saved.
- The 3–7 open questions, prioritized.
- A suggestion (path A): "When you've answered these, I'll run a second-round pass and push back on anything that doesn't fit. Then run `/archforge:design \"<problem>\"` (or `/archforge:research` first if any answers depend on current info)."

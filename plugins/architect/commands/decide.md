---
description: Phase 3 of the Architecture Cycle — pick one alternative with explicit reasoning and boundaries.
argument-hint: "<problem statement>"
---

# /archforge:decide

Phase 3 of the Architecture Cycle. The goal is to **commit to one alternative** with reasoning that survives a year of hindsight.

## Inputs

- Problem statement: $ARGUMENTS
- Design output: read the most recent design doc in `docs/architecture/research/` matching the problem.
- Project context: `./ARCHITECTURE.md` and prior ADRs.

If no design doc exists, run `/archforge:design` first. Don't decide on a vacuum.

## What to produce

A decision summary (this is **not yet the ADR** — that's phase 4):

1. **Chosen alternative** — name it.

2. **Why this one** — 3–6 bullets tying the choice to the forces from discovery. The reasoning must be *contextual*, not generic. "We chose X because in our specific situation Y, Z mattered more than the trade-off W."

3. **What we are giving up** — explicit list of the downsides we're accepting. This is the test of whether we made the decision honestly.

4. **Boundary conditions** — under what conditions would this decision need to be revisited? Examples:
   - Scale crosses N RPS.
   - Team grows beyond M people.
   - A new compliance requirement emerges.
   - The cost crosses some threshold.

5. **Operational implications** — what concrete things will change once this lands. Deploy model, monitoring needs, on-call posture, runbook updates.

6. **Migration path** — if this replaces something existing, the rough plan to get from the current state to the new one. Phases, dependencies, risk points.

7. **Definition of done** — what evidence will tell us the decision is implemented and working?

## Discipline

- **Argue if the user picks weakly.** If the user names an alternative you consider clearly worse for the stated forces, say so. State your reasoning. Don't agree just because they asked. Hold position until they show a real counter-argument.
- **One decision, not three.** If multiple decisions are entangled, separate them and decide one at a time.
- **No "we'll see how it goes".** A decision is a commitment. If you can't commit, you're still in design.
- **No new alternatives in this phase.** If the design phase missed something, go back to design — don't smuggle a new option in here.

## Output to chat

Show the decision summary inline. Save it to `docs/architecture/research/YYYY-MM-DD-<slug>-decision.md`.

Suggest: "Run `/archforge:document \"<problem>\"` to write the ADR and update ARCHITECTURE.md."

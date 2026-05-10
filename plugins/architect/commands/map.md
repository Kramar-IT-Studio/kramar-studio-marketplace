---
description: Build or update a decision map — groups of architectural decisions, their dependencies, and the order in which to take them. Use at project start or when ≥3 architectural questions are open simultaneously.
argument-hint: "(no arguments — reads ARCHITECTURE.md and existing ADRs)"
---

# /archforge:map

Construct a **decision map** — a meta-document that groups open architectural questions into logical clusters, makes dependencies between them explicit, and proposes a sensible order in which to run cycles.

## Why this exists

When a project has more than two open architectural questions at once, cycles trip over each other. You start a cycle on "agent architecture" and discover it depends on a database choice you haven't made. You start "database choice" and discover it depends on "data residency posture" which depends on "target market". Without a map, you make the same forces explicit three times in three different cycles and the documents diverge.

The decision map is the antidote. It's not a roadmap (no dates), it's not a backlog (no estimates). It's a **dependency graph of decisions**.

## When to run

- **First-time architectural work on a project**, after `/archforge:init`, when the discovery surface is wide.
- **Whenever `ARCHITECTURE.md` lists ≥3 open questions** that look related.
- **Before starting a sequence of related cycles** (e.g., "AI agent layer", "RAG layer", "billing layer", "tenant isolation" — these are clearly entangled).

The router skill `architect` should also propose `/archforge:map` proactively when it sees a user about to start a cycle that obviously depends on other unmade decisions.

## Inputs

- `./ARCHITECTURE.md` — open questions section, key constraints section.
- `./docs/architecture/decisions/` — existing ADRs, especially their boundary conditions.
- `./docs/architecture/research/` — discovery documents in flight.
- `./STRATEGY.md` if present — product/business context.

## Steps

1. **Read all the inputs.** This is a synthesis command, not a generation-from-scratch command.

2. **Identify open architectural decisions.** Sources, in priority order:
   - Open questions in `ARCHITECTURE.md`.
   - Decisions explicitly deferred in existing ADRs ("V2: see ADR-0007").
   - Decisions implied by `STRATEGY.md` constraints that don't yet have an ADR.
   - Architectural seams visible in the codebase but undocumented.

3. **Group them into clusters.** Three suggested cluster types:
   - **Group A — Principal stakes.** Decisions that constrain everything below them. Stack, language, runtime, hosting region, regulatory posture. Few in number, made first.
   - **Group B — Stack and components.** Database, queue, cache, auth model, observability stack. Made after Group A.
   - **Group C — Domain and feature shape.** How the agent layer is organized, how billing works, how tenants are isolated. Made after Group B, often per-feature.
   - Other groupings are fine. The point is hierarchy, not these exact labels.

4. **Map dependencies.** For each decision:
   - **Hard dependencies**: cannot start until X is decided. Example: "tool registry shape" depends on "AI agent architecture".
   - **Soft dependencies**: easier if X is decided first, but not blocking.
   - **Mutual constraints**: two decisions that constrain each other; usually a sign they should be made together as a single bundled decision.

5. **Propose order.** A topological sort respecting hard dependencies. Where multiple decisions are unblocked at once, prioritize by:
   - **Reversibility**: less reversible first.
   - **Blast radius**: bigger blast radius first.
   - **Information value**: decisions whose answer unlocks several others first.

6. **Identify decisions that should NOT be made now.** Some decisions look open but should be deferred — premature, missing prerequisite information, dependent on a market signal not yet present. Mark these explicitly with a "wait for" condition.

## Output structure

Save as `docs/architecture/decision-map.md`. If it exists, replace in place — it's a living document, not append-only.

```markdown
# Decision Map

> Living document. Updated whenever a cycle completes or a new architectural question is identified.
> Last updated: YYYY-MM-DD

## Group A — Principal stakes

**A1. <decision name>**
- *Forces*: <one line>
- *Status*: open / in-discovery / in-design / deciding / decided (link to ADR-NNNN)
- *Blocks*: A2, B1, B3
- *Blocked by*: —

**A2. <decision name>**
- ...

## Group B — Stack and components

**B1. <decision name>**
- *Forces*: ...
- *Status*: ...
- *Blocks*: C2
- *Blocked by*: A1

...

## Group C — Domain and feature shape

...

## Suggested order

Next up (unblocked): A1, A2

After A1 decided: B1, B3

After B1 decided: C2

## Deferred (do not run yet)

- **C5. Multi-region deployment** — wait for: ≥1000 active users in a second geographic cluster, or compliance requirement.
- **B7. Microservice extraction of <module>** — wait for: monolith pain measurable; team size ≥6 with separate ownership.

## Notes

<free-form notes about the map: assumptions, things to watch, items to revisit>
```

## Discipline

- **Decisions, not tasks.** Implementing a feature is not on the map. Choosing the architecture for a feature is.
- **Hierarchy by force, not by date.** Group A items are above Group B items because they constrain Group B, not because they're "earlier in the roadmap".
- **Be honest about deferral.** A "deferred" decision with no "wait for" condition is just hiding from the decision. Force the condition.
- **Don't fabricate decisions.** If `ARCHITECTURE.md` only has two open questions and one ADR, the map will be small. That's fine.
- **Update on every cycle close.** When `/archforge:document` lands an ADR, the map should also be updated — that decision moves to "decided" with a link, and any decisions it unblocks are marked.

## Sources of new map entries

The map is updated from several sources:

- **Manual addition by the architect** — most common.
- **Cycle outputs** — when an ADR lands, the map's index updates.
- **`/archforge:observe`** — when run, observe surfaces architectural gaps (implicit decisions, stale deferrals, strategy-without-architecture, drifted ADRs) and offers to add them to the map. This is the recommended way to keep the map honest about the project's actual state.
- **External signals** — incidents, customer requests, regulatory changes can each produce a new map entry.

## Output to chat

- The path of the saved/updated map.
- A summary: how many open decisions, how many groups, what's at the top of "next up".
- A suggestion: "Run `/archforge:cycle \"<top item>\"` to take the first decision."

## When the map says "you're not ready to decide"

If the map identifies that the top-priority decision is blocked by a missing prerequisite (e.g., business model not yet defined, target market not chosen, key dependency not evaluated), state this directly. Don't manufacture a cycle on top of a missing prerequisite — that's how architectural fiction gets written.

The right next step in that case is often outside the plugin's scope: a strategy conversation, a market validation, a spike. Say so.

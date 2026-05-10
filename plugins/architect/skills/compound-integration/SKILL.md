---
name: compound-integration
description: Use this skill whenever the user wants to integrate archforge with the EveryInc Compound Engineering plugin (`compound-engineering`), or whenever both plugins are detected in the same project and an architectural task is being run. The skill defines exactly where the architecture cycle (Discover → Design → Decide → Document) plugs into the CE workflow (Brainstorm → Plan → Work → Review → Compound), how archforge artifacts (ADRs, ARCHITECTURE.md) coexist with CE artifacts (`docs/solutions/`, `docs/plans/`, `docs/brainstorms/`), and which hand-offs happen between the two plugins. Triggered by `/archforge:remember-compound-integration` and used as reference when CE commands are observed in a project alongside archforge commands.
---

# compound-integration

Defines how `archforge` and the EveryInc `compound-engineering` plugin work together inside a single project, without duplicating each other's work.

## Why integrate at all

The two plugins solve **adjacent but different** problems:

| Concern | CE answers | archforge answers |
|---|---|---|
| What feature should we build next? | yes (`/ce-ideate`) | no |
| What does this feature need to do? | yes (`/ce-brainstorm`) | partially — only the architectural slice |
| **What's the architectural shape of the system?** | no — assumed | **yes — explicit cycle** |
| **Why this architectural choice and not that one?** | no | **yes — ADR with alternatives** |
| How do we plan a specific feature implementation? | yes (`/ce-plan`) | no |
| How do we execute the plan? | yes (`/ce-work`) | no |
| How do we review the code? | yes (`/ce-code-review`) | partially — architectural lens only |
| **Does the change conform to our architecture?** | weakly (`ce-architecture-strategist` agent) | **yes — explicit ADR conformance** |
| What did we learn from this task? | yes (`/ce-compound`) | no |
| **What architectural patterns/anti-patterns does this project hold?** | no | **yes — ARCHITECTURE.md, ADRs** |

CE is about **getting work done well**. archforge is about **knowing why the system is shaped the way it is**. Both compound, but on different axes — features compound through `docs/solutions/`, architectural knowledge compounds through `ARCHITECTURE.md` and the ADR archive.

## The combined workflow

For an architecturally significant task, the combined cycle:

```
            ┌────────────────────┐
            │  /ce-ideate (opt.) │  pick what to work on
            └─────────┬──────────┘
                      ▼
            ┌────────────────────┐
            │   /ce-brainstorm   │  explore the requirement
            └─────────┬──────────┘
                      │
       is the task architecturally significant?
                      │
        ┌─────────────┴──────────────┐
        │                            │
    NO  ▼                            ▼  YES
        │                  ┌─────────────────────┐
        │                  │ /archforge:cycle   │
        │                  │  ├─ discover         │
        │                  │  ├─ design           │
        │                  │  ├─ decide           │
        │                  │  └─ document         │  ── ADR lands
        │                  └─────────┬───────────┘
        │                            │
        └────────────┬───────────────┘
                     ▼
            ┌────────────────────┐
            │     /ce-plan       │  ADR + brainstorm doc → detailed plan
            └─────────┬──────────┘
                      ▼
            ┌────────────────────┐
            │     /ce-work       │  execute the plan
            └─────────┬──────────┘
                      ▼
            ┌────────────────────┐
            │  /ce-code-review   │  multi-agent code review (CE)
            └─────────┬──────────┘
                      ▼
            ┌────────────────────┐
            │ /archforge:review │  ADR-conformance review (archforge)
            └─────────┬──────────┘                          │
                      ▼                                      │
            ┌────────────────────┐                           │
            │    /ce-compound    │ ── docs/solutions/ entry  │
            └─────────┬──────────┘                           │
                      │                                      │
              new architectural pattern emerged?             │
                      │                                      │
                      └──── YES ──── /archforge:adr ────────┘
```

The two cycles are **interleaved**, not parallel — at each point only one is driving. archforge runs *inside* the planning gate, archforge runs *after* CE's code review, archforge runs again *if* the work surfaced a new architectural pattern.

## When the task is **not** architecturally significant

Most tasks aren't. For these, run pure CE — archforge stays silent.

**Triggers that mean archforge *should* engage:**

- New module / new top-level directory in the project.
- New runtime dependency in a package manifest (lib that becomes part of the architecture).
- New external service (DB, queue, cache, third-party API).
- New protocol (introducing gRPC, WebSocket, SSE where there wasn't before).
- Change in data model that breaks existing consumers.
- Change in deployment topology (new service, new region, edge migration).
- A pattern decision the team hasn't made before (auth model, error model, retry model, caching strategy).
- The user explicitly says "this is architectural" or "this affects the architecture".

**Triggers that mean archforge *should not* engage:**

- Bug fix.
- New endpoint following an established pattern.
- New page/component following the existing structure.
- Test additions.
- Refactor strictly within an existing module's boundary.
- Style and formatting.
- Documentation updates that don't touch ARCHITECTURE.md.

When unsure — ask the user, briefly: "this looks architecturally relevant — run a archforge cycle, or skip and go to `/ce-plan`?"

## Artifact split — who owns what

| Artifact | Owner | Purpose |
|---|---|---|
| `ARCHITECTURE.md` (root) | archforge | Living architectural state |
| `docs/architecture/decisions/NNNN-*.md` | archforge | ADRs |
| `docs/architecture/diagrams/*.md` | archforge | C4 diagrams |
| `docs/architecture/research/*.md` | archforge | Discovery + design notes |
| `docs/architecture/reviews/*.md` | archforge | ADR-conformance reviews |
| `AGENTS.md` (root) | shared (CE primary) | Process: how the team works with agents |
| `CLAUDE.md` (root) | shared (CE primary) | Codebase context: stack, conventions |
| `docs/brainstorms/*.md` | CE | Output of `/ce-brainstorm` |
| `docs/plans/*.md` | CE | Output of `/ce-plan` |
| `docs/solutions/*.md` | CE | Output of `/ce-compound` — task-level learnings |
| `todos/*.md` | CE | Triage and review findings |

**No file is written by both plugins.** This is the rule that keeps them from stepping on each other.

## Cross-references between artifacts

To keep the knowledge graph navigable:

- **CE plan documents** that touch architecture **must reference the relevant ADRs by number** — e.g., "Per ADR-0007, all inter-service communication is gRPC; this plan uses gRPC for the new endpoint." Without this reference, the plan and the architecture drift apart.
- **ADRs** that are produced **as part of a CE-driven task** **should reference the brainstorm doc and/or plan** in their Context section. This shows where the decision came from.
- **Compound learnings** (`docs/solutions/`) **may reference ADRs** when the learning affects an architectural choice. They never *replace* an ADR — if a compound learning is architectural, file an ADR too.

## Hand-offs — concrete steps

### Hand-off 1: `/ce-brainstorm` → `/archforge:cycle` (when architectural)

After `/ce-brainstorm` produces a requirements document, if the task is architecturally significant:

1. The user (or Claude, if it spots architectural triggers in the brainstorm output) invokes `/archforge:cycle "<problem>"`.
2. `/archforge:discover` reads the brainstorm doc as input alongside `ARCHITECTURE.md` and ADRs.
3. The cycle runs through Discover → Design → Decide → Document.
4. The resulting ADR is filed in `docs/architecture/decisions/`.
5. The user proceeds to `/ce-plan` — archforge's recommendation is now an input to planning.

### Hand-off 2: `/archforge:cycle` → `/ce-plan`

After archforge produces an ADR:

1. The user invokes `/ce-plan "<feature>"`.
2. CE reads the brainstorm doc *and* the new ADR.
3. The plan must reference the ADR by number when it touches the decided concern.

### Hand-off 3: `/ce-code-review` → `/archforge:review`

After CE's multi-agent code review finishes:

1. The user invokes `/archforge:review` on the same target (PR, branch, files).
2. archforge checks **conformance with ADRs**, not the things CE already covered (correctness, security, perf).
3. If archforge blocks a change for ADR conflict, the resolution is one of:
   - The change is amended to conform.
   - A new ADR is filed that supersedes the old one (archforge's blocking review explicitly suggests this path).
4. archforge's review is saved to `docs/architecture/reviews/` alongside CE's findings.

### Hand-off 4: `/ce-compound` → `/archforge:adr` (sometimes)

After `/ce-compound` documents a task-level learning:

1. The user (or Claude) checks: did this task surface a **reusable architectural pattern** (or anti-pattern)?
2. If yes — invoke `/archforge:adr "<pattern>"` to capture it as an ADR.
3. The ADR's Context section references the compound learning that surfaced it.
4. The compound learning gets a one-line link back to the ADR.

This is the rare case — most compound learnings are task-level, not architectural. But missing this hand-off is how teams accumulate undocumented architectural conventions.

## Avoiding double work

A few discipline rules to prevent overlap:

1. **Don't run `/ce-code-review` and `/archforge:review` on the same lens.** CE reviews correctness, security, perf, maintainability, testing. archforge reviews ADR conformance and structural smells. If CE's `ce-architecture-strategist` agent flags an ADR conflict, archforge's review can confirm and elaborate, but doesn't restart from scratch.

2. **Don't write a `docs/solutions/` entry that is actually an ADR.** If the learning is "we now do X for all services because Y", that's an ADR. File it as an ADR. The compound entry can reference it.

3. **Don't run `/archforge:cycle` for non-architectural changes.** It costs time and produces an ADR for noise. The triggers list above is the gate.

4. **Don't duplicate the brainstorm.** archforge's discover phase reads the CE brainstorm and treats it as input — it doesn't re-elicit requirements from scratch.

## Materializing the integration

The plugin command `/archforge:remember-compound-integration` writes a project-level integration block to `AGENTS.md` (or `CLAUDE.md` on user choice) so the rules above are loaded at every session start, automatically. The block points at this skill for the long version.

## When to refresh the integration

Re-run `/archforge:remember-compound-integration` if:

- CE is upgraded and adds/renames commands (the integration block references them by name).
- The team's process changes (e.g., you stop using `/ce-ideate`, you add a custom command).
- A new ADR establishes a different artifact split.

The block should not be edited by hand for the substance — re-run the command. Stylistic edits are fine.

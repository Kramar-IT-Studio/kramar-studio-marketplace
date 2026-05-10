---
name: adr-writing
description: Use this skill whenever an architectural decision is being made, captured, or revised — when the user says "write an ADR", "let's document this decision", "we decided to use X", "deprecate decision Y", or when the conversation has just produced a non-trivial choice (database, framework, protocol, structural pattern) that should be persisted. Also use proactively after the `/archforge:decide` phase. Outputs an ADR file in `docs/architecture/decisions/` using the project's template, with proper numbering and an updated index.
---

# ADR writing

An ADR (Architecture Decision Record) is a short document capturing **one** architectural decision, its context, and consequences. Not a design doc. Not an RFC. It's the record a future engineer reads to understand "why X, not Y" when no one in the room remembers.

## When to write an ADR

- The decision is **irreversible or expensive to undo** (database, language, framework, inter-service protocol).
- The decision is **counter-intuitive** or contradicts common practice — explaining why saves future arguments.
- The decision is **critical for onboarding** new team members.
- The decision **changes a public contract** (API, schema, event format).

**Don't write ADRs for:**
- Trivial library picks ("axios vs fetch for one request").
- Decisions easily reversed in an hour.
- Stylistic preferences (those go in a style guide, not an ADR).

## When to write it: in the moment

Write the ADR **at the time of the decision**, not after. Retroactive ADRs become rationalization, not records.

## File location and naming

```
docs/architecture/decisions/
├── 0001-use-postgres-as-primary-store.md
├── 0002-introduce-job-queue-for-async-work.md
├── 0003-adopt-grpc-for-internal-services.md
└── README.md            ← index of ADRs (auto-maintained)
```

Naming: `NNNN-imperative-decision-summary.md`. Zero-padded numbers, kebab-case. The number is allocated sequentially by the `architect` skill or the `/archforge:document` command.

## Templates

Two are supported. Default to **Nygard** unless the user asks for MADR or the team already uses it.

### Nygard (default — concise, conversational)

```markdown
# ADR-NNNN: <Decision summary in imperative mood>

- **Date**: YYYY-MM-DD
- **Status**: Proposed | Accepted | Deprecated | Superseded by ADR-NNNN
- **Authors**: <names or handles>

## Context

What forced this decision? Technical, organizational, political, economic forces.
What constraints are fixed? Which alternatives are on the table?

This section is the most important one. If the decision later looks strange, the
reader must be able to see that **at the time, it was reasonable given this
context**.

## Decision

What was decided. Active voice, imperative: "We will use X", "We will adopt Y",
"We will stop doing Z".

This section is the *what*, not the *why*. Keep it to one or two paragraphs;
the why is in Context.

## Consequences

What gets **easier** because of this decision? What gets **harder**? What risks
are accepted? Which future paths are foreclosed?

This section is honest. If the decision has downsides (and every decision
does), they are listed here. An ADR with no downsides is marketing copy, not
an ADR.

## Alternatives considered

What else was on the table and why it was rejected. Minimum two alternatives
including "do nothing / keep status quo".

Each: 2–4 lines describing the option, its strengths, its weaknesses, and
why it lost.
```

### MADR (when more structure is needed)

```markdown
# ADR-NNNN: <Decision summary>

- **Status**: Accepted
- **Date**: YYYY-MM-DD
- **Deciders**: <names>
- **Consulted**: <names>
- **Informed**: <stakeholders>

## Context and Problem Statement

Two-sentence problem statement, ideally as a question:
"How should we organize state in a server-rendered application with dozens of
pages and a shared session?"

## Decision Drivers

- Driver 1
- Driver 2
- Driver 3

## Considered Options

1. Option A
2. Option B
3. Option C

## Decision Outcome

**Chosen option: A**, because [primary reasons].

### Positive Consequences
- ...

### Negative Consequences
- ...

## Pros and Cons of the Options

### Option A
- ✅ ...
- ❌ ...

### Option B
- ✅ ...
- ❌ ...

[etc.]

## Links
- Reference 1
- Related ADR-NNNN
```

## Lifecycle

```
Proposed ─── discussion ───> Accepted ─── in force ───> Superseded by ADR-NNNN
                                  │
                                  └── decision outlived its time ──> Deprecated
```

**Never edit an accepted ADR to change the decision.** Write a new ADR that supersedes the old one. The old ADR is marked `Superseded by ADR-NNNN`. This preserves the trail of the team's evolving thinking.

Typo fixes and clarifications in an accepted ADR are fine — but never the substance of the decision.

## What makes an ADR good

1. **Short.** One to two pages. If it grows, it's becoming a design doc — extract that, link from here.
2. **Honest about trade-offs.** Consequences with real downsides are mandatory.
3. **Time-bound.** Date, context, constraints of the moment. A reader in 2030 can see what was true in 2026.
4. **Concrete, not theoretical.** Not "an overview of state management options" — "why we chose Pinia *here*".
5. **One decision per ADR.** Three decisions = three ADRs.

## Anti-patterns

- **ADRs written years after the fact.** Limited value: you're rationalizing, not recording.
- **ADRs without alternatives.** Without alternatives, it's a declaration, not a decision.
- **ADRs for trivia.** Pollutes the archive, devalues the format.
- **ADR as a substitute for discussion.** ADR is the artifact of discussion, not its replacement.
- **Corporate-speak.** "Leveraging synergies for stakeholder alignment" — not an ADR. Write to a peer over coffee.

## ADR + ARCHITECTURE.md interplay

When an ADR lands, also update `ARCHITECTURE.md` if the decision changes:
- The decision index (always — add a new entry with status and one-line summary).
- High-level structure / containers (if topology changed).
- Quality attributes (if non-functional posture shifted).
- Open questions (resolve or revise).
- Anti-patterns (if a new one is being added or removed).

If none of those changed, just add to the index. Don't pad.

## Example: short Nygard ADR

```markdown
# ADR-0003: Adopt SSR via Nuxt for the public storefront

- **Date**: 2026-04-15
- **Status**: Accepted
- **Authors**: @owner

## Context

The storefront requires SEO indexing (Google + regional engines) and fast FCP
on mobile 3G. A pure SPA leaves an empty `<div id="app">` for crawlers and a
slow first paint. Team is one developer; infra budget is minimal.

Alternatives: Vue + Vite SPA with prerender, Nuxt SSR, Astro with Vue islands,
hosted storefront builder.

## Decision

Use **Nuxt 4 in SSR mode**, deployed to a CDN with edge functions.

## Consequences

Easier:
- Out-of-the-box SEO, OpenGraph, sitemap.
- File-based routing and auto-imports cut boilerplate.
- SSR + edge yields ~80ms TTFB on the storefront.

Harder:
- Hydration nuances when integrating third-party scripts and global state.
- Lock-in to edge-runtime semantics for some primitives.
- Cold-start on edge for rarely-hit pages.

## Alternatives considered

1. **Vue + Vite SPA + prerender** — would work, but the dynamic catalog forces
   constant regeneration; harder than it looks.
2. **Astro + Vue islands** — excellent perf profile, but team has zero Astro
   experience and existing Nuxt familiarity; learning curve not justified for
   one project.
3. **Hosted storefront builder** — covers 80% of needs in an hour, but blocks
   custom checkout logic and bespoke order flow.
```

## Process integration

When called via `/archforge:document` or `/archforge:adr`:

1. Find the next available ADR number by listing `docs/architecture/decisions/`.
2. Use the project's template (or Nygard default).
3. Write the file.
4. Update `docs/architecture/decisions/README.md` index.
5. If applicable, update `ARCHITECTURE.md` decision index and any sections affected.
6. Tell the user the ADR number and file path.

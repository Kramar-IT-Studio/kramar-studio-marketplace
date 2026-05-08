---
name: code-review-architectural
description: Use this skill when reviewing code with an architectural lens — boundaries between modules, coupling and cohesion, conformance to ADRs, evolvability, operational concerns. Triggers on phrases like "review this PR architecturally", "what architectural issues does this introduce", "is this respecting our ADRs", "is this the right place for this code". Distinct from stylistic review (linters do that) and from local correctness review (typical PR review). Output is structured: blocking issues, non-blocking suggestions, questions, and praise.
---

# code-review-architectural

Architectural review ≠ style review. Linters do style. This skill looks at:

- **Boundaries and dependencies** between modules.
- **Coupling and cohesion**.
- **Conformance to ADRs** in the repo.
- **Operational concerns** (logs, metrics, errors, perf).
- **Evolvability** — how easy will this be to change in six months?

Don't lint here. Don't catch missing semicolons. The expensive comments are about structure.

## Levels of review

| Level | What | When |
|---|---|---|
| **L0: Syntax / style** | Formatting, naming | Linter's job. If you're catching it manually, fix the process. |
| **L1: Local correctness** | Function logic, edge cases, tests | Any normal review. |
| **L2: Module design** | Module's boundary, public API, responsibilities | Any non-trivial review. |
| **L3: Cross-module** | Inter-module dependencies, contracts, compat | Public API changes, new features. |
| **L4: Architecture** | ADR conformance, patterns, evolution | Big PRs, new modules, refactors. |

This skill operates at L2–L4. L0 and L1 belong to other tools and reviews.

## Checklist by level

### L2: Module / component

- [ ] **Single responsibility.** If the description has "and", it's two modules.
- [ ] **Public API is minimal.** Only what's needed externally is exported.
- [ ] **Dependencies are explicit.** What the module needs is passed in (params, constructor, props), not pulled from globals.
- [ ] **Internal types don't leak.** If `class FooImpl` is internal, `interface Foo` is what's exported.
- [ ] **Errors are part of the contract.** What's returned on failure is typed or documented.
- [ ] **Side effects are visible** in signatures or explicit calls.
- [ ] **Testable** without standing up the whole system.

### L3: Cross-module

- [ ] **Dependency direction is right.** Features don't depend on each other directly (only via shared / events). No cycles.
- [ ] **Contracts between modules are stable** or explicitly versioned.
- [ ] **No duplicated business logic** in multiple places. If duplicated, it's deliberate.
- [ ] **Layering rules respected** (UI doesn't reach into DB directly, etc.).
- [ ] **Changes are backward-compatible** for public APIs, or there's a migration plan.

### L4: Architecture

- [ ] **Conforms to existing ADRs.** If it contradicts, the review explicitly raises this.
- [ ] **No new abstraction where YAGNI applies.**
- [ ] **No duplicate of existing abstractions** under a different name.
- [ ] **Performance budget respected.** Bundle size, query count, latency.
- [ ] **Operational concerns present**: metrics, logs, error tracking.
- [ ] **Security**: input validation, authz checks, no secrets in code.
- [ ] **Failure mode readiness**: timeouts, retries, graceful degradation as appropriate.

---

## Architectural smells to catch

### Structural

- **God object / God module** — knows about everything. Symptoms: huge import block, name like "Manager" / "Helper" / "Service" without specificity, > 500 lines. Fix: decompose by responsibility.
- **Feature envy** — module A constantly reaches into module B's data. Symptom: chains like `b.x.y.z`. Fix: move logic into B, or extract a third module.
- **Inappropriate intimacy** — two modules know too much about each other. Fix: explicit interface or event-based communication.
- **Shotgun surgery** — one feature change requires edits in 8 files. Fix: cohesion — gather related code into one module.
- **Divergent change** — one module changes for many unrelated reasons. Fix: SRP — split it.

### Dependencies

- **Cyclic dependencies** — usually a sign the boundary is in the wrong place. Fix: extract shared into a third module, or invert with an interface.
- **Concept dependencies you don't need** — pulling in a huge library for one function. Fix: tree-shake or write the 5-line version.
- **Direct dependency on external service in business logic** — cloud SDK in a use case. Fix: ports and adapters — domain talks to an interface; the concrete impl is injected at the edge.

### Behavior

- **Magic** — code that works "because it does". Fix: explicit names, types, in-code documentation.
- **Implicit state mutation** — function changes things not obvious from its signature. Fix: explicit returns, immutability where reasonable.
- **Hidden coupling via global state** — modules talk through a shared store with no contract. Fix: explicit events or narrow store API.

### Performance / scale

- **N+1 queries** — loop with a query inside. Common in ORM code, GraphQL without DataLoader, `.map(async ...)`.
- **Premature scaling** — sharding / CDN / microservice without real load. Remove until needed.
- **Resource leaks** — unclosed connections, unsubscribed events, uncleared timers. Fix: cleanup in `finally` / `defer` / lifecycle hooks.
- **Unbounded everything** — list without pagination, queue without limit, cache without TTL/eviction. Fix: limits at every input.

### Backend-specific

- **Implicit transactions** — operation should be atomic but no transaction is opened. Risks rotten data on partial failure.
- **Distributed transaction in code** — attempted 2PC across services. Almost always wrong. Fix: outbox, sagas, eventual consistency.
- **Hot path with blocking I/O** — synchronous slow operation in request handler. Fix: push to a queue.
- **Missing pagination** on list endpoints — eventual DoS.
- **Cache without invalidation** — stale data forever.

### Frontend-specific

- **Prop drilling** — props through 4+ component levels. Fix: provide/inject, local store, or composition with slots.
- **Giant component** — a single component file at 1000+ lines. Fix: decompose + extract logic into hooks/composables.
- **Logic in templates** — `v-if="user.role === 'admin' && user.permissions.includes('edit') && !item.locked"`. Fix: a named computed/derived value.
- **Reactivity in the wrong place** — refs around arrays that never change wholesale; forgotten `.value`; mutated props.
- **SSR-specific**: `window`/`document` in setup, `Date.now()` in templates, server/client divergence → hydration mismatch.

---

## Review output format

Always structure architectural reviews like this:

```
## Summary
2–3 sentences: what the PR is doing and the main architectural risk or concern.

## Blocking issues
Things that must be fixed before merge. Each item:
- Link to the specific location.
- Explanation of why it's a blocker.
- Suggested fix or alternative if possible.

## Non-blocking suggestions
Improvements that aren't blockers. Prefix each with "nit:" or "suggestion:" so
priority is unambiguous.

## Questions
Places where context was insufficient to evaluate. These are *questions*, not
guesses. "Why X and not Y?" "What happens if Z?"

## Praise
What's good in this PR. Reinforcing good practice is part of the job.
```

---

## Process principles

1. **Review the code, not the person.** "This method is hard to test" — not "you wrote it badly".
2. **Explain "why".** "This is bad" is useless. "This is bad because under partition X, behavior Y" is valuable.
3. **Suggest alternatives** for blocking issues when possible.
4. **Don't litigate taste.** If it's a taste call, suggest and yield.
5. **Big PR = bad PR.** A 2000-line PR's first comment is "can this be split?". Big PRs get reviewed superficially.
6. **The most valuable comments are at design time, not at implementation.** If the architectural problem should have been caught in design review, learn to see it earlier and ask for design discussion before the PR is written.

## When to say "no"

Sometimes the PR is **architecturally wrong at its core** — not "rename this variable", but "this shouldn't exist in this form". When that happens:

1. Don't pile on 50 nitpicks — they drown.
2. One detailed comment with the diagnosis: what's wrong with the approach, what alternatives exist, what next step is needed (design discussion, redo, abandon).
3. Move it to a synchronous channel (call, design review). Text resolves these 5× slower.

This is hard. But merging an architecturally broken commit costs the team years of debt. An uncomfortable conversation now beats that.

## What this review is *not*

- A design session — that belongs in a separate doc, not the PR thread.
- A performance evaluation of the author — that's a 1:1, not a PR comment.
- A patience exercise — the goal is improving the code and the system, not winning.

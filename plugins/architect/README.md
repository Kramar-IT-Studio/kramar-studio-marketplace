# archforge

**English** | [Русский](./README.ru.md)

Architecture toolkit for Claude Code. A staff/principal-grade architect on tap, structured around a repeatable cycle and a set of narrow specialist skills.

> **Philosophy.** Architecture is not a document — it's a *cycle of decisions* and the *trail those decisions leave*. This plugin makes the cycle first-class and the trail durable.

> **Эта версия — на английском (универсально). Русские заметки идут параллельно курсивом, где это полезно.**
>
> *Этот плагин — про архитектурный цикл и его документирование. Маршрутизирующий скилл `architect` активирует архитектурный режим, узкие скиллы дают глубину под конкретный выход (диаграмма, ADR, ревью), команды запускают этапы цикла, агенты делают долгие автономные задачи.*

---

## The Architecture Cycle

```
            ┌──────────────┐
            │  1. DISCOVER │  Constraints, forces, prior art, requirements
            └──────┬───────┘
                   ▼
            ┌──────────────┐
            │  2. DESIGN   │  2–3 alternatives, each with trade-offs
            └──────┬───────┘
                   ▼
            ┌──────────────┐
            │  3. DECIDE   │  Pick one. State why. State when it breaks.
            └──────┬───────┘
                   ▼
            ┌──────────────┐
            │  4. DOCUMENT │  ADR + update ARCHITECTURE.md + diagrams
            └──────┬───────┘
                   ▼
            ┌──────────────┐
            │  5. REVIEW   │  Architectural code review against ADRs
            └──────┬───────┘
                   │
                   └──── feeds back into DISCOVER for next change
```

Each phase has a slash command. You can also run the whole cycle for a single problem with `/archforge:cycle "<problem statement>"`.

*Цикл повторяется. Каждый проход обогащает `docs/architecture/` — это и есть «компаунд»: следующее решение опирается на предыдущие, а не изобретается заново.*

---

## Components at a glance

### Slash commands (`/archforge:*`)

| Command | Purpose |
|---|---|
| `/archforge:init` | Bootstrap project with `ARCHITECTURE.md` and `docs/architecture/` |
| `/archforge:upgrade` | Migrate the project's artifacts to the currently installed plugin version |
| `/archforge:map` | Build or update the decision map (groups of open decisions, dependencies, suggested order) |
| `/archforge:observe` | Find architectural gaps — implicit decisions in code, stale deferrals, strategy-without-architecture |
| `/archforge:discover <topic>` | Phase 1 — gather context |
| `/archforge:research <topic>` | Phase 1.5 — gather current information from the web |
| `/archforge:design <topic>` | Phase 2 — generate alternatives |
| `/archforge:decide <topic>` | Phase 3 — choose with justification |
| `/archforge:document <topic>` | Phase 4 — emit ADR + update root doc |
| `/archforge:review [path]` | Phase 5 — architectural code review (with closeout tracking) |
| `/archforge:roast <ADR-NNNN\|path> [--roles=...]` | Adversarial multi-perspective review (5 roles) |
| `/archforge:meta-review <target>` | Plugin-conformance check — does this artifact match the templates and rules the plugin promised? Catches identifier-translation, template drift, missing language pass, broken cross-references |
| `/archforge:cycle <topic> [--scale=light\|standard\|deep]` | Run the full cycle end-to-end with detail scaled to complexity (auto-roast + auto-meta-review at deep) |
| `/archforge:adr <topic>` | Shortcut: jump straight to ADR drafting |
| `/archforge:diagram <type> <subject>` | Generate a diagram: `c4-context\|c4-container\|c4-component\|sequence\|state\|er\|deployment` |
| `/archforge:c4 <level> <subject>` | Alias for `/archforge:diagram c4-<level>` (kept for compatibility) |
| `/archforge:remember-compound-integration [--lang=en\|ru\|auto]` | Materialize integration with the EveryInc `compound-engineering` plugin |

All commands respect the project's `ARCHITECTURE.md` and prior ADRs as primary context.

### Skills

The router:

- **`architect`** — entry point. Activates the architect persona, decides which specialist skills to consult, enforces the cycle when relevant. Triggers automatically on architectural intent (any mention of "architecture", "design", "scaling", "stack choice", "trade-offs", "review architecture", etc.) even without a slash command.

The specialists (loaded by router or directly):

- **`architectural-diagrams`** — five diagram types in Mermaid: C4 (context/container/component), sequence, state, entity-relationship, deployment. (Was `c4-diagrams` in earlier versions, expanded in 0.4.)
- **`adr-writing`** — Architecture Decision Records (Nygard + MADR templates), lifecycle, anti-patterns.
- **`system-design`** — distributed systems, scaling, databases, queues, caching, CAP/PACELC, latency budgets, microservices vs monolith, FAANG-style design walkthrough.
- **`frontend-architecture`** — render strategies (CSR/SSR/SSG/ISR/RSC/Islands), state management matrix, module structure, performance, edge.
- **`backend-architecture`** — service decomposition, API design, transactions, async patterns, observability, reliability.
- **`ai-agents-architecture`** — agent design, tool-use, memory, evaluation, latency/cost budgets, prompt-injection threat model.
- **`code-review-architectural`** — review with structural lens (boundaries, coupling, cohesion, ADR conformance), not stylistic.
- **`architecture-research`** — protocol for getting current information when claims depend on versions, releases, benchmarks, or current best practices.
- **`compound-integration`** — defines how `archforge` interleaves with the EveryInc `compound-engineering` plugin: which phase plugs in where, who owns which artifact, how to avoid double work.

### Sub-agents

Three structural roles for long-running tasks:

- **`architect`** — long-running architectural reasoning, returns a structured proposal.
- **`reviewer`** — autonomous architectural review of a directory or PR.
- **`researcher`** — gathers up-to-date information from the web on a focused topic, returns a digest.

Five roast roles for adversarial multi-perspective review (invoked via `/archforge:roast`):

- **`devil-advocate`** — adversarial pressure-test. Failure modes, hidden assumptions, edge cases, concurrency bugs.
- **`pragmatist`** — operational realism. On-call burden, real cost, skills/bus factor, deployment risk.
- **`junior-engineer`** — clarity check from a fresh reader six months later. Undefined terms, unfollowable steps, broken cross-references.
- **`compliance-officer`** — regulatory and security exposure. PII flows, jurisdiction, audit, incident response.
- **`futurist`** — 1-3 year horizon. Structural drift, technology lifecycle, hiring, regulatory drift.

One conformance role (invoked via `/archforge:meta-review`):

- **`meta-reviewer`** — plugin-conformance QA. Reads artifacts produced by `archforge` and verifies they match the plugin's own templates and rules: required sections present and verbatim, identifiers (agent names, command names, finding IDs) untranslated, language pass applied per `architect/SKILL.md`, cross-references resolved, lifecycle states valid. Catches the plugin failing to follow its own rules.

Sub-agents are useful for tasks that would otherwise pollute the main thread with research or large reviews.

### Hooks (soft warnings)

The plugin ships **non-blocking** hooks (`PostToolUse`) that emit reminders when:

- A large number of files is modified without a recent ADR change (suggests an architectural decision is happening implicitly).
- A new top-level module/directory is created (suggests `ARCHITECTURE.md` may need an update).
- A new dependency is added in a package manifest (suggests an ADR may be warranted).

The hooks **never block** — they nudge. Architecture is a discipline, not a gate.

### Templates

- `templates/ARCHITECTURE.md` — the root architecture document. Living doc, updated as the system evolves.
- `templates/adr-template.md` — ADR boilerplate.
- `templates/docs-architecture-readme.md` — index for `docs/architecture/`.

---

## How `ARCHITECTURE.md` works

Per [Compound Engineering's split](https://wotai.co/blog/compound-engineering-agents-md), this plugin treats project-level memory as two files:

- **`CLAUDE.md`** (you already have it or will) — codebase context, conventions, dependencies, file layout. *What* the code looks like.
- **`ARCHITECTURE.md`** (this plugin) — architectural state of the system. *Why* the code looks like that.

`ARCHITECTURE.md` is the living spine. It contains:

1. **System summary** — what the system does, who uses it, what it integrates with.
2. **Quality attributes** — non-functional requirements that drive design (latency, availability, consistency, scale).
3. **High-level structure** — C4 L1+L2 inline (Mermaid) or links to `docs/architecture/diagrams/`.
4. **Key constraints** — organizational, operational, compliance, budget. Things that bound the design space.
5. **Decision index** — links to all ADRs in `docs/architecture/decisions/` with status and one-line summary.
6. **Open questions** — known unknowns. Architectural questions deferred to future cycles.
7. **Anti-patterns to avoid** — project-specific traps the team has agreed to steer clear of.

Claude reads `ARCHITECTURE.md` at session start (via the `architect` skill's protocol) and treats it as binding context. Every ADR update should also touch `ARCHITECTURE.md` if it changes anything in sections 1–6.

---

## Recommended directory layout in your project

After `/archforge:init` you'll have:

```
your-project/
├── ARCHITECTURE.md                    ← root architecture document
├── CLAUDE.md                          ← (your existing project memory)
└── docs/
    └── architecture/
        ├── README.md                  ← index of this directory
        ├── decisions/                 ← ADRs (numbered, never deleted)
        │   ├── 0001-use-postgres-as-primary-store.md
        │   └── 0002-introduce-job-queue.md
        ├── diagrams/                  ← C4 diagrams as .md (Mermaid) or images
        │   ├── context.md
        │   └── container.md
        ├── research/                  ← research digests from /archforge:discover
        └── reviews/                   ← architectural code-review notes
```

You don't have to follow this layout — every command accepts a `--root` style override — but defaults are wired for it.

---

## Tone and posture

`archforge` is opinionated. The router skill `architect` instructs Claude to:

- Push back on weak proposals; argue position until presented with a real counter-argument.
- Refuse to give technology recommendations without first establishing constraints and quality attributes.
- Always offer 2–3 alternatives before recommending one.
- State explicitly when a recommendation breaks (its boundary conditions).
- Verify version-sensitive claims against the current web before committing them to an ADR.

This is intentional. Soft, agreeable architectural advice is the most expensive kind — it sounds helpful and quietly costs years of refactoring.

*Скилл намеренно «токсичный» в хорошем смысле — настойчивый, аргументирующий, не складывающийся при первом возражении. Это и отличает архитектурный диалог от вкусовой беседы.*

---

## Updating the plugin

After editing files, run `/reload-plugins` in Claude Code to pick up changes without restart.

## License

MIT.

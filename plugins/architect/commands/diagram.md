---
description: Generate an architectural diagram in Mermaid. Supports C4 (context/container/component), sequence, state, entity-relationship, and deployment diagrams. Picks the right type by inference if not specified, but it's better to be explicit.
argument-hint: "<type> <subject>   types: c4-context|c4-container|c4-component|sequence|state|er|deployment"
---

# /archforge:diagram

Generate one architectural diagram. Single command, multiple types — the type is the first argument.

## Inputs

- `$ARGUMENTS` — first token is the type, the rest is the subject.
- Project context: `./ARCHITECTURE.md`, repo structure, key config files.

### Types

| Type token | What it produces | When to use |
|---|---|---|
| `c4-context` | C4 L1 — system in the world | Project start, exec-level overview |
| `c4-container` | C4 L2 — deployable units inside the system | Architectural overview |
| `c4-component` | C4 L3 — internals of one container | Designing or refactoring a service |
| `sequence` | Message flow over time | Tool-use loops, distributed transactions, error flows |
| `state` | State machine for one entity | Session, agent, workflow, retry logic |
| `er` | Entity-relationship for the data model | Schema design, persistence decisions |
| `deployment` | Infrastructure topology | Deployment, region, network, security zones |

If type is missing or unrecognized, ask the user once, with the table above.

## Steps

### 1. Resolve the type

Parse the first argument. If it's not in the supported list, show the table and ask. Don't guess.

### 2. Load the `architectural-diagrams` skill

This skill is the source of truth for notation, rules, common mistakes, and templates. Use it for every diagram type.

### 3. Inspect the project as needed for the type

Different types want different inputs:

- **c4-context**: README, `STRATEGY.md`, `ARCHITECTURE.md` system summary.
- **c4-container**: `package.json` / `Cargo.toml` / `pyproject.toml`, `docker-compose.yml`, `kubernetes/`, top-level directories.
- **c4-component**: directory structure of the targeted service / module.
- **sequence**: ADRs and code paths for the scenario being diagrammed; trace through actual call sites if available.
- **state**: ADRs and code where the state machine is implemented or planned; existing types/enums.
- **er**: schema migrations, model files (`models/`, `schema.sql`, `prisma/schema.prisma`, `entity/`), referenced columns in code.
- **deployment**: `Dockerfile`s, `docker-compose.yml`, `kubernetes/`, `terraform/`, deployment ADRs.

If the relevant inputs are sparse (project too young, file not present), proceed with what's available and **explicitly note in the output** what's inferred vs. what's grounded in the repo.

### 4. Generate the diagram

Follow the rules and templates from the `architectural-diagrams` skill. Diagrams must:

- Have all arrows labeled.
- Have all boxes labeled with technology where applicable.
- Have a single level / single subject (don't mix C4 levels, don't mix entities in one state diagram).
- Use Mermaid syntax that renders inline in markdown.
- Be ≤ ~15 elements at top level. If more, render a partial view with explicit note.

### 5. Save the file

Path: `docs/architecture/diagrams/<type>-<slug>.md`. Examples:

- `docs/architecture/diagrams/c4-container.md`
- `docs/architecture/diagrams/sequence-tool-use-loop.md`
- `docs/architecture/diagrams/state-agent-session.md`
- `docs/architecture/diagrams/er-billing.md`
- `docs/architecture/diagrams/deployment-eu-primary.md`

If a file with that name exists, ask before overwriting and offer to save with a date suffix instead. **Don't silently destroy existing diagrams** — they're often referenced from ADRs.

### 6. Update `ARCHITECTURE.md` if it references the high-level structure

If the diagram is a `c4-context`, `c4-container`, or `deployment` view at the system level, also update `ARCHITECTURE.md`'s "High-level structure" section to embed or link the new diagram.

For component-level, sequence, state, ER — the diagram lives in `docs/architecture/diagrams/` and is referenced from the relevant ADR, not from `ARCHITECTURE.md`.

### 7. Output to chat

- The Mermaid code block (so the user can render in chat).
- The path it was saved to.
- A note about what's inferred vs grounded — usually you've inferred from the repo, and the user will know things you don't (external systems, future containers, regulatory boundaries).
- Suggestions for adjacent diagrams when relevant: "this container view doesn't show the deployment topology — try `/archforge:diagram deployment <subject>` for that."

## Discipline

- **Don't invent components.** If the repo doesn't show it and the user didn't tell you, leave it out. Note what's missing.
- **Don't render multiple types in one shot** unless explicitly asked. The point of one diagram is to answer one question well.
- **Don't render more than 15 elements** at the top level. If the system is bigger, render a partial view and say which subset.
- **No bidirectional arrows** in C4 / deployment. Pick the initiator side.
- **No emojis in diagrams**. Mermaid renders them inconsistently and they don't add information.
- **Refuse the wrong type** politely. If the user asks for a state diagram of the system topology, say so and propose `c4-container`.

## Backward compatibility

The legacy `/archforge:c4 <level> <subject>` command still works. It is now an alias for `/archforge:diagram c4-<level> <subject>`. New work should use `/archforge:diagram` directly.

## When to skip the file save

If the user explicitly asks for a one-off diagram in chat ("just show me a quick sequence diagram of X"), it's fine to render in chat without saving to disk. Default behavior is to save — diagrams that exist only in chat scrollback don't compound.

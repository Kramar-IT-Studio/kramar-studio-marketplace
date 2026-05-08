---
description: Bootstrap the project for architectural work — create ARCHITECTURE.md and docs/architecture/ skeleton.
argument-hint: "(no arguments)"
---

# /archforge:init

You are bootstrapping this project for architectural work.

## Steps

1. Check if `ARCHITECTURE.md` already exists at the repository root.
   - If it exists, **do not overwrite**. Tell the user it exists and ask if they want to refresh it interactively or leave it alone.
   - If it doesn't exist, proceed.

2. Check if `docs/architecture/` exists.
   - If not, create the directory tree:
     ```
     docs/architecture/
       ├── README.md
       ├── decisions/
       ├── diagrams/
       ├── research/
       └── reviews/
     ```
   - Use the templates from `${CLAUDE_PLUGIN_ROOT}/templates/`:
     - `${CLAUDE_PLUGIN_ROOT}/templates/ARCHITECTURE.md` → `./ARCHITECTURE.md`
     - `${CLAUDE_PLUGIN_ROOT}/templates/docs-architecture-readme.md` → `./docs/architecture/README.md`

3. **Detect the stack** by inspecting the repository (only briefly — don't go deep):
   - Look for `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, etc.
   - Look for top-level config that hints at the framework (`nuxt.config.*`, `next.config.*`, `vite.config.*`, `astro.config.*`, `Dockerfile`, `docker-compose.yml`, `kubernetes/`, `terraform/`).
   - Skim the top-level directory layout.

4. **Pre-fill the `ARCHITECTURE.md` template** based on what you observe:
   - System summary: a one-paragraph guess based on README and package metadata.
   - Quality attributes: leave blank with a comment "fill in based on real requirements".
   - High-level structure: a placeholder C4 L2 Mermaid diagram with what you inferred.
   - Constraints: leave blank with a prompt list.
   - Decision index: empty (no ADRs yet).
   - Open questions: 3–5 questions you would ask the team based on what you couldn't determine.
   - Anti-patterns: project-specific empty list with examples commented in.

5. **Tell the user**:
   - That `ARCHITECTURE.md` and `docs/architecture/` were created.
   - The 3–5 open questions you put in. These are the seed for the next architectural conversation.
   - **If the project has existing strategic context** (`STRATEGY.md`, README with rich product description, prior architectural notes) **or you generated ≥3 open questions**: suggest running `/archforge:map` next to lay out the dependency graph between decisions before running individual cycles.
   - **Otherwise**: suggest `/archforge:cycle "<topic>"` for a single decision walk-through.

6. **Do not commit**. Leave that to the user.

## Tone

This is a setup step. Keep prose minimal. No celebration; report what happened and what to do next. The router skill `architect` is the place for the architectural conversation — `init` just lays down the bones.

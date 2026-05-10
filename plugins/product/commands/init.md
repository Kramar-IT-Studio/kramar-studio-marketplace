---
description: Bootstrap the project for product work — create PRODUCT.md, docs/product/ skeleton, and the .product-version marker.
argument-hint: "(no arguments)"
---

# /product:init

You are bootstrapping this project for product work. This is the first command a user runs after installing the `product` plugin in a project.

## Steps

1. **Read `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`** to get the plugin version. You will write this version into `.product-version`.

2. **Check if `PRODUCT.md` already exists** at the repository root.
   - If it exists, **do not overwrite**. Tell the user it exists and ask whether to refresh interactively or leave it alone.
   - If not, proceed.

3. **Check if `docs/product/` exists.**
   - If not, create the directory tree:
     ```
     docs/product/
       ├── README.md
       ├── research/         ← market-scans live here
       ├── discoveries/      ← HYP-NNNN
       ├── prds/             ← PRD-NNNN
       ├── specs/            ← SPEC-NNNN
       ├── validations/      ← VAL-NNNN
       └── backlog.md
     ```
   - Use the templates from `${CLAUDE_PLUGIN_ROOT}/templates/`:
     - `templates/PRODUCT.md` → `./PRODUCT.md`
     - `templates/docs-product-readme.md` → `./docs/product/README.md`
     - `templates/backlog.md` → `./docs/product/backlog.md`

4. **Detect the product context** by inspecting the repository (briefly — don't go deep):
   - Read `README.md` and any `STRATEGY.md` for product-context hints.
   - Read `ARCHITECTURE.md` if it exists (means `architect` is in use — we will cross-link).
   - Look at `package.json` / `pyproject.toml` for stack hints.

5. **Pre-fill the `PRODUCT.md` template** based on what you observe:
   - Product summary: one-paragraph guess from README.
   - Target user / job-to-be-done: leave blank with prompts.
   - Active areas: empty list. (User adds these via `/product:market-scan`.)
   - Backlog index: empty.
   - Open questions: 3–5 questions you would ask the user based on what's unclear.
   - Anti-patterns: empty with examples commented in.

6. **Write `.product-version`** at the repository root with the plugin version on a single line (no trailing newline issues — just the version, e.g. `0.1.0`).

7. **Tell the user**:
   - That `PRODUCT.md`, `docs/product/`, and `.product-version` were created.
   - The 3–5 open questions you put in.
   - **If `ARCHITECTURE.md` exists** (architect in use): mention that `links_to` in product artifacts will reference ADRs from `docs/architecture/decisions/`.
   - Suggest `/product:market-scan "<area>"` if the project has no clear product area yet, or `/product:discover "<feature>"` if the user has a specific feature in mind.

8. **Do not commit.** Leave that to the user.

## Tone

Setup step. Keep prose minimal. No celebration; report what happened and what to do next. The two skills `product-conventions` and `product-cycle` carry the methodology — `init` just lays down the bones.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A **Claude Code plugin marketplace** — not application code. The shippable surface is markdown (commands, skills, templates) plus a few bash hook scripts. There is no build, no test runner, no package manager. Distribution happens by pointing Claude Code at the marketplace via `/plugin marketplace add`.

`.claude-plugin/marketplace.json` is the entry point Claude Code reads. Each entry under `plugins[]` references a directory under `plugins/<name>/`, and that directory's own `.claude-plugin/plugin.json` is what Claude Code installs.

Companion to the external `archforge-marketplace` (architecture role). The plugins here apply the same shape — discover → decide → review → evolve, with versioned artifacts and migrations — to other studio roles. `archforge` is the reference implementation; new role plugins inherit its conventions verbatim.

## Plugin layout (`plugins/<role>/`)

Every role-plugin in this marketplace must follow this structure. `product` is the only one currently scaffolded.

```
plugins/<role>/
├── .claude-plugin/plugin.json    ← name, version, description, keywords
├── README.md                      ← user-facing docs for the plugin
├── commands/<verb>.md             ← one file per /<role>:<verb> slash command
├── skills/<role>-conventions/SKILL.md   ← artifact format contract
├── skills/<role>-cycle/SKILL.md         ← methodology / cycle rules
├── hooks/hooks.json               ← SessionStart + PostToolUse hooks
├── scripts/*.sh                   ← hook scripts (soft-warning posture)
└── templates/*.md                 ← templates the commands deploy into user projects
```

Command files are markdown with YAML front-matter (`description`, `argument-hint`); body is the prompt the slash command executes. Skills follow the same pattern but their front-matter `description` field controls when Claude proactively activates them — write it to make activation conditions unambiguous (see existing `SKILL.md` files for the pattern).

## Common operations

There is no compile/lint/test step. Iteration loop is:

1. Edit files under `plugins/<role>/`.
2. In a Claude Code session, run `/reload-plugins` (or restart Claude Code).
3. Exercise the command or hook in a project where the plugin is installed.

For local development of this marketplace, install it from the absolute path:

```text
/plugin marketplace add /Users/user/Work/self/kramar-studio-marketplace
/plugin install product@kramar-studio-marketplace
```

To bump a plugin version: edit `plugins/<role>/.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` if the marketplace-level metadata changes. Add a migration file under `plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md` whenever a version step needs project-side changes — front-matter (`migration / from / to / mutates_frontmatter / scope`) plus fixed sections (`Summary` / `Preconditions` / `Transform` / `Backup` / `Verification` / `Rollback note` / `Never`); copy `migrations/_TEMPLATE.md`. `/<role>:upgrade` runs them in order and writes the `.<role>-version` marker per successful step. See ADR-0003 and README §7.

## Marketplace-wide conventions (binding)

All conventions below come from `README.md` (section "Kramar Studio Plugin Conventions"). They apply to every plugin in this repo and to `archforge` as the reference implementation. **Do not diverge silently — diverging is a bug in the plugin, not a precedent.**

### One plugin per role
Plugin name = role name in lowercase (`product`, `ops`, `security`). Each plugin owns one role's full cycle, its artifacts, a router skill, and a migration command. Out of scope on purpose: frontend, design, qa, pm, tech writer.

### Soft hooks only
Hooks **never** abort the session, block tool use, auto-commit, or edit files behind the user's back. They print to stderr and exit 0. If you find yourself writing `exit 1` in a hook, you're building a CI check, not a Claude Code plugin. See `plugins/product/scripts/check-product-artifact.sh` for the reference shape (read JSON payload from stdin, extract `tool_input.file_path`, emit warnings, always exit 0).

### Standard layout under `docs/<role>/` (in the user's project)
Every plugin writes its artifacts to `docs/<role>/` with role-specific subdirectories, plus a root `<ROLE>.md` at repo root and a `.<role>-version` marker. `product` uses `discoveries/` (HYP), `prds/` (PRD), `specs/` (SPEC), `validations/` (VAL), `research/` (SCAN), plus `backlog.md`.

### Front-matter on every artifact
Mandatory: `id` (typed prefix), `status` (lifecycle), `created_at`, `role`, `links_to`. Type-specific extras: `success_metric` on PRD, `acceptance_count` on SPEC, `verdict` on VAL, `area` on SCAN. ID prefixes per role: `archforge` → `ADR-`; `product` → `SCAN-`/`HYP-`/`PRD-`/`SPEC-`/`VAL-`. Numbers are never reused; allocate by reading the highest existing N and incrementing, zero-padded to 4 digits.

### Status lifecycle
`draft → active → (accepted | superseded | archived)`. Never delete artifacts; transition status. Superseded artifacts must point at their replacement via `links_to`. Validations skip `draft` and enter as `active` (a verdict is not a work-in-progress).

### Mandatory cycle, with state
Each role has a finite cycle encoded in slash commands. Skipping a phase is allowed but visible — `/<role>:status` reports short-circuited cycles. Cycle structure is part of the plugin's contract; adding/removing phases is a different plugin, not a customization. `product`: `market-scan (per area, rare) → discover → define → spec → validate`, plus `prioritize` outside the per-feature loop.

### Standard service commands
Every plugin exposes three with identical semantics:
- `/<role>:init` — bootstrap `docs/<role>/`, write `<ROLE>.md` template, write `.<role>-version`. Idempotent; never overwrites without confirmation.
- `/<role>:upgrade` — run versioned migrations from `plugins/<role>/migrations/`, update `.<role>-version`. Refuses on dirty working tree; refuses to downgrade.
- `/<role>:status` — read-only report of in-flight/stale/broken state.

### Two skills per plugin
Exactly two: `<role>-conventions` (artifact format contract) and `<role>-cycle` (methodology). Adding more is allowed only when a clearly distinct external standard emerges (e.g. `archforge` ships `c4-diagrams`, `adr-writing`). **Don't add a skill just to mirror a command.** Commands read these two skills as needed.

### Cross-role linkage via `links_to`
Product/ops/security artifacts reference `archforge`'s `ADR-NNNN` from `docs/architecture/decisions/` using the bare ID. The graph of links is what makes the marketplace compound. Hooks emit a soft warning (not error) when `links_to` is empty on an artifact whose body references architectural concepts.

### Language
Plugin source (commands, skills, templates) is in **English** — universal, copy-pasteable. Generated artifacts follow the user's language (Russian project → Russian PRDs/SPECs). Identifiers (IDs, command names, template-prescribed section headers like `## Success metric`) stay verbatim across languages — translating them desyncs from what `/<role>:status` and the hooks expect to find. See `archforge`'s `architect/SKILL.md` for the full language taxonomy; this marketplace inherits it.

### Tone
Plugins push back. They don't soft-cave on a weak product cut, a leaky abstraction, a half-baked launch. The cycle exists to surface those — collapsing at the first pushback wastes the cycle. See `archforge` as the posture reference. Concrete examples in `plugins/product/commands/discover.md` ("Anti-patterns to refuse"), `define.md` (refuse a PRD without a real success metric), `validate.md` (refuse to mark a refuted launch as "directionally correct").

## When editing a plugin

- **Adding a new command:** create `plugins/<role>/commands/<verb>.md` with YAML front-matter (`description`, `argument-hint`). The body is the prompt; reference `${CLAUDE_PLUGIN_ROOT}/...` for plugin-internal paths and read the project's `<ROLE>.md` and prior artifacts as binding context. Keep verbs aligned with the role's cycle.
- **Adding a new artifact type:** update the relevant skill's ID prefix table, the `<ROLE>.md` template index, and any hook that validates artifacts.
- **Changing artifact structure:** add a migration under `plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md` and bump the plugin version. Migrations transform — they never delete or re-number IDs.
- **Adding a new role plugin (ops/security per roadmap):** clone the `product/` shape exactly. Two skills, the three service commands, soft hooks, `docs/<role>/` layout, ID prefix registered in the marketplace README's table.

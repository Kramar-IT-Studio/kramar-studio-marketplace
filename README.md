# Kramar Studio Marketplace

Claude Code [plugin marketplace](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces) hosting role-specific plugins for **Kramar IT Studio**: a structured way to run product, ops, and security work as repeatable cycles with durable artifacts.

> **Companion to [`archforge-marketplace`](https://github.com/IgorKramar/archforge-marketplace).** `archforge` is the architecture role and the **reference implementation** of the methodology — discover → decide → review → evolve, with versioned artifacts and migrations. The plugins here apply the same shape to other roles.

## What's inside

| Plugin | Status | Purpose |
|---|---|---|
| **`product`** | scaffolded (v0.1) | Market-scan (quarterly anchor) + per-feature cycle Discover → Define → Spec → Validate, plus `prioritize` over a backlog. Artifacts: HYP/PRD/SPEC/VAL/SCAN, cross-linked to ADRs from `archforge`. |
| **`ops`** | planned | Operations role — runbook authoring, on-call posture, incident retrospectives. |
| **`security`** | planned | Security role — threat modeling, security review, dependency posture. |

> **Out of scope on purpose:** frontend, design, qa, pm, tech writer. The studio runs solo today; only the roles I actually wear get a plugin.

## Installation

From inside Claude Code:

```text
/plugin marketplace add https://github.com/kramar-it-studio/kramar-studio-marketplace
/plugin install product@kramar-studio-marketplace
```

For local development:

```text
/plugin marketplace add /absolute/path/to/kramar-studio-marketplace
/plugin install product@kramar-studio-marketplace
```

After install, run `/reload-plugins` (or restart Claude Code) and verify with `/plugin list`.

## Quick start with `product`

```text
/product:init                              # bootstrap docs/product/ skeleton
/product:market-scan "<area>"              # rare — quarterly or new area
/product:discover "<feature>"              # per-feature cycle, phase 1
/product:define "<feature>"                # phase 2 — PRD with success metric
/product:spec "<feature>"                  # phase 3 — implementation spec
/product:validate "<feature>"              # phase 4 — post-launch validation
/product:prioritize                        # backlog operation, runs over candidates
/product:status                            # what's in flight, what's stale
```

See [`plugins/product/README.md`](./plugins/product/README.md) for the full reference.

---

## Kramar Studio Plugin Conventions

These conventions apply to **every plugin in this marketplace** and to `archforge` as the reference implementation. New role plugins (ops, security, …) inherit these rules verbatim. Treat this section as the marketplace's spec — if a plugin diverges, it's a bug in the plugin, not a precedent.

### 1. One plugin per role

Each plugin owns exactly one role of the studio. The plugin name is the role name in lowercase: `archforge` (architecture), `product`, `ops`, `security`.

A role-plugin is responsible for:

- The cycle of decisions in that role (e.g. discover → decide for architecture, market-scan + discover → define → spec → validate for product).
- The artifacts that role produces and how they cross-reference other roles' artifacts.
- A router skill that activates whenever the conversation drifts into that role's territory.
- A migration command (`upgrade`) that moves the project's artifacts to the currently installed plugin version.

### 2. Discipline, not gates

All plugins in this marketplace use **soft, non-blocking hooks**. A hook can:

- Print a reminder to stderr.
- Suggest a next command.
- Refuse to be silent when something looks off.

A hook **never aborts the session, never blocks tool use, never auto-commits, never edits files behind the user's back.** Architecture and product discipline come from the cycle being lower-friction than skipping it, not from coercion. If you find yourself writing `exit 1` in a hook, you're building a CI check, not a Claude Code plugin.

### 3. Standard layout under `docs/<role>/`

Every plugin writes its artifacts to `docs/<role>/` in the user's project, with a fixed sub-structure:

```
docs/<role>/
├── README.md                 ← index of this directory (auto-maintained by /<role>:init|upgrade)
├── <ROLE>.md                 ← root document for the role (e.g. ARCHITECTURE.md, PRODUCT.md)
├── <category>/               ← role-specific subdirectories
│   ├── 0001-<slug>.md
│   └── ...
└── .last-<command>           ← marker files for hooks (e.g. .last-observe, .last-market-scan)
```

`archforge` uses `decisions/`, `diagrams/`, `research/`, `reviews/`. `product` uses `discoveries/`, `prds/`, `specs/`, `validations/`, `research/` (for market-scans), plus `backlog.md`. `ops` and `security` will define their own when scaffolded — but always under `docs/<role>/`.

### 4. Front-matter on every artifact

Every artifact starts with YAML front-matter:

```yaml
---
id: <ROLE_PREFIX>-NNNN          # ADR-0001, HYP-0001, PRD-0001, SPEC-0001, VAL-0001, SCAN-0001
status: draft | active | accepted | superseded | archived
created_at: YYYY-MM-DD
role: <role>                    # archforge | product | ops | security
links_to:                       # optional, but expected for cross-role artifacts
  - ADR-0007
  - HYP-0003
---
```

**ID prefixes** (allocated sequentially per type, never reused):

| Role | Prefix | Artifact |
|---|---|---|
| `archforge` | `ADR-` | Architecture Decision Record |
| `product` | `SCAN-` | Market scan |
| `product` | `HYP-` | Discovery hypothesis |
| `product` | `PRD-` | Product Requirements Document |
| `product` | `SPEC-` | Implementation spec |
| `product` | `VAL-` | Post-launch validation |
| `ops` | TBD | TBD |
| `security` | TBD | TBD |

**`status` lifecycle:** `draft` → `active` → (`accepted` | `superseded` | `archived`). Never delete an artifact; transition its status. Superseded artifacts must point at the artifact that supersedes them via `links_to`.

**`links_to` is the cross-role glue.** A PRD that demands a database migration links to the relevant ADR. An ADR introducing a new auth flow links to the SPEC that uses it. The graph is what makes the marketplace compound.

### 5. Mandatory cycle, with state

Every role has a finite, opinionated cycle. The cycle is encoded in slash commands. Skipping a phase is allowed but visible — `/<role>:status` reports artifacts that look like they short-circuited the cycle.

Examples:

- `archforge`: `discover → design → decide → document → review`.
- `product`: `discover → define → spec → validate` (per-feature) + `market-scan` and `prioritize` outside the per-feature loop.

The cycle structure is **part of the plugin's contract** — a fork that adds or removes phases is a different plugin, not a customization.

### 6. Standard service commands

Every plugin exposes three service commands with identical semantics:

| Command | Purpose |
|---|---|
| `/<role>:init` | Bootstrap `docs/<role>/`, write the role's `<ROLE>.md` template, write the `.<role>-version` marker. Idempotent — never overwrites without confirmation. |
| `/<role>:upgrade` | Migrate the project's artifacts and `<ROLE>.md` from the version recorded in `.<role>-version` to the version of the currently installed plugin. Versioned migrations live in the plugin source. |
| `/<role>:status` | Report what's in flight, what's stale, what cross-references are broken. Read-only. The first thing to run when you open a project after a long pause. |

### 7. Version marker per role

Each plugin writes `.<role>-version` at the project root after `init` and updates it after every successful `upgrade`. Format: a single line with the plugin version (e.g. `0.1.0`).

`upgrade` reads this marker to decide which migrations to run. If the marker is missing, `upgrade` refuses and tells the user to run `init` first.

### 8. Two skills per plugin: `<role>-conventions` and `<role>-cycle`

Skills in this marketplace are **not** 1:1 with commands. Each plugin ships exactly two skills:

- **`<role>-conventions`** — front-matter rules, ID allocation, file layout, lifecycle states, cross-role linking. The "what does a well-formed artifact look like" reference.
- **`<role>-cycle`** — methodology: what each phase produces, when to skip vs run a phase, how to recognise the cycle's failure modes. The "why this cycle, in this order" reference.

Commands read these skills as needed. Adding more skills is allowed only when a clearly distinct body of knowledge emerges (e.g. `architect` plugin has `c4-diagrams`, `adr-writing`, etc. because those are external standards with their own depth). Don't add a skill just to mirror a command.

### 9. Cross-references to `archforge` are first-class

Product, ops, and security plugins routinely produce artifacts that depend on architectural decisions:

- A PRD that requires a new service → links to the ADR that introduces the service.
- An ops runbook for an incident type → links to the ADRs covering the affected components.
- A security threat model → links to the ADRs governing the trust boundaries.

The `links_to` field carries these. Hooks in non-architecture plugins **do not** validate that the linked ADR exists by itself — they emit a soft warning if `links_to` is empty when the artifact's content suggests a cross-role dependency. The check is qualitative, not strict.

### 10. Language

Plugin source (commands, skills, templates) is in English — universal, copy-pasteable. Generated artifacts follow the user's language. If the user works in Russian, all PRDs, ADRs, market-scans are in Russian, but identifiers (IDs, command names, section headers from templates) stay verbatim. See `archforge`'s `architect/SKILL.md` for the full taxonomy — it's the reference all role plugins inherit.

### 11. Tone

Plugins in this marketplace push back. They don't soft-cave when the user proposes a weak product cut, a leaky abstraction, a half-baked launch. The cycle exists to surface those — collapsing at the first pushback wastes the cycle. See archforge's posture as the reference.

---

## Distribution structure

```
kramar-studio-marketplace/
├── .claude-plugin/
│   └── marketplace.json            ← /plugin marketplace add reads this
├── README.md                       ← this file (conventions live here)
├── LICENSE
└── plugins/
    └── product/
        ├── .claude-plugin/
        │   └── plugin.json
        ├── README.md
        ├── commands/
        ├── skills/
        ├── hooks/
        ├── scripts/
        └── templates/
```

## Roadmap

- **v0.1 — `product` scaffolded.** Skeleton commands, two skills, hooks for prerequisite enforcement, templates. Content depth filled iteratively.
- **v0.2 — `product` content fill.** Each command fully spec'd, real templates with examples, integration patterns with `archforge`.
- **v0.3 — `ops` plugin.** Same shape, role-specific cycle.
- **v0.4 — `security` plugin.** Same shape, role-specific cycle.

Out of scope by design: frontend, design, qa, pm, tech writer plugins.

## License

MIT — see [`LICENSE`](./LICENSE).

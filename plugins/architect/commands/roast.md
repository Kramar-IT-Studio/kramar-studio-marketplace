---
description: Adversarial multi-perspective review of an architectural artifact. Runs 5 specialized roles (devil-advocate, pragmatist, junior-engineer, compliance-officer, futurist) against the same target and aggregates their findings into a single roast document. Use on important ADRs, major design docs, or before declaring a deep-cycle decision final.
argument-hint: "<path-to-artifact OR ADR-NNNN> [--roles=all|core|<comma-list>]"
---

# /archforge:roast

Multi-perspective adversarial review. Five specialized roles attack the same architectural artifact from different angles. Output is a structured aggregate that lets the architect see all attack surfaces at once.

This is **not** a code review. It runs against architectural documents — ADRs, design docs, decision summaries — not code.

## When to run

- **Before promoting a proposed ADR to accepted.** A deep-cycle ADR should pass roast before declaring done.
- **When the team is divided on a decision.** A roast surfaces what each side is responding to.
- **On a substantial existing ADR that's about to drive significant work.** Catch problems before they ship.
- **Auto-triggered** by `/archforge:cycle --scale=deep` after the Decide phase, before Document.

## When NOT to run

- On a `light`-scale decision. The roast is heavyweight; don't apply it to a 30-line ADR.
- On a draft you're still actively shaping. Roast at least once you have a coherent decision.
- On code (use `/archforge:review` for code).

## Inputs

- **Target**: `$ARGUMENTS` first positional. Either:
  - A file path to an artifact (`docs/architecture/decisions/0001-foo.md`).
  - An ADR identifier (`ADR-0001`) — the command resolves to the file.
  - The word `latest` — uses the most recent ADR.
- **Roles flag** (optional): `--roles=all` (default), `--roles=core` (= devil-advocate, pragmatist, junior-engineer), or a comma-separated list (`--roles=devil-advocate,compliance-officer`).

## The five roles

Each role has a strict scope, and the roles are designed to **not overlap**. If a finding belongs to two roles, the one whose primary lens it is wins; the other role stays silent on that finding. This prevents 5× duplication.

| Role | Lens | Output focus |
|---|---|---|
| `devil-advocate` | Adversarial pressure-test | Failure modes, edge cases, hidden assumptions, logical inconsistencies, adversarial scenarios, concurrency bugs |
| `pragmatist` | Operational reality | Operational debt, on-call burden, real cost over time, skills/bus factor, deployment risk, day-1 vs steady-state, hidden runtime overhead, tooling ergonomics |
| `junior-engineer` | New reader six months later | Undefined terms, unresolved pronouns, unstated assumptions, unfollowable steps, numbers without context, diagram gaps, broken cross-references, erased reasoning |
| `compliance-officer` | Regulatory and security | PII flows, jurisdiction, cross-border data transfers, authn/authz, audit trail, incident response, third-party risk, encryption, data minimization, consent, trust boundaries |
| `futurist` | 1–3 year horizon | Structural drift (team growth, codebase aging, scale shifts, adjacent decisions, inertia) and trend speculation (technology lifecycle, vendor risk, hiring, regulatory drift, idiom shift) |

## Steps

### 1. Resolve target

- If `$ARGUMENTS` is a path, verify it exists and is a Markdown file.
- If it's `ADR-NNNN`, search `docs/architecture/decisions/` for `NNNN-*.md`.
- If it's `latest`, list `docs/architecture/decisions/` and pick the highest-numbered ADR.
- If it can't be resolved, ask the user which artifact they meant.

### 2. Determine which roles to run

- `--roles=all` (default) → all five.
- `--roles=core` → `devil-advocate`, `pragmatist`, `junior-engineer`. Faster, less compliance/futurist depth.
- `--roles=<list>` → exactly those.

### 3. Spawn the role agents

Each role is a sub-agent (named the same as the role: `devil-advocate`, `pragmatist`, `junior-engineer`, `compliance-officer`, `futurist`). Invoke them sequentially or in parallel; the output of one role does **not** depend on another. They each read the artifact themselves.

### 4. Each role produces its own document

The role agents return individual structured documents. Save each to:

```
docs/architecture/reviews/YYYY-MM-DD-roast-<artifact-slug>/
  ├── 00-summary.md
  ├── 01-devil-advocate.md
  ├── 02-pragmatist.md
  ├── 03-junior-engineer.md
  ├── 04-compliance-officer.md
  └── 05-futurist.md
```

A directory, not a single file — each role's output is its own document for clean reading.

### 5. Write the summary

`00-summary.md` is the aggregate. It has this structure:

```markdown
# Roast: <artifact name>

**Target**: <path to artifact>
**Date**: YYYY-MM-DD
**Roles run**: <list>

## Headline findings
The single strongest finding from each role, in one line each. The architect reads these first.

- **Devil-advocate**: <strongest attack, one line>
- **Pragmatist**: <strongest operational concern>
- **Junior-engineer**: <worst clarity gap>
- **Compliance-officer**: <most exposed regulatory or security gap>
- **Futurist**: <most consequential structural drift>

## Severity counts

| Role | High | Medium | Low |
|---|---|---|---|
| Devil-advocate | N | N | N |
| Pragmatist | N | N | N |
| Compliance-officer | N | N | N |
| ... | | | |

(Junior-engineer and futurist don't always use severity categories the same way — leave their cells as ranges or omit.)

## Cross-cutting concerns
Findings raised by 2+ roles that point at the same underlying issue. These are the most important — when independent perspectives converge, the issue is real. Example: devil-advocate notes a race condition + compliance-officer notes the audit log will miss it + pragmatist notes the on-call team won't be able to debug it.

## Recommended path

One of:
- **Apply and proceed**: blockers are addressable; list which findings to fix and how.
- **Apply and re-roast**: blockers are substantial; fix and run roast again on the revised artifact.
- **Step back**: roast surfaces a fundamental issue requiring re-discovery or re-design. Suggest reopening that phase.

## Per-role outputs

Links to each role's full document in this directory.
```

### 6. Update the artifact's review status

If the artifact is an ADR with a `Status: Accepted` line, *do not* change it. Roast is advisory; the architect decides whether findings change the decision.

If the artifact has a `## Reviews` section (or you want to add one), append a line:

```markdown
- YYYY-MM-DD — Roast (5 roles, severity: H/M/L counts) — [link](docs/architecture/reviews/YYYY-MM-DD-roast-<slug>/00-summary.md)
```

This makes the review trail discoverable from the ADR itself.

### 7. Output to chat

- Path to the roast directory.
- The five headline findings (one line each).
- Cross-cutting concerns if any.
- Recommended path (apply / re-roast / step back).

Don't dump full role outputs to chat — they're long. The summary is the chat surface; the role docs are for the deep read.

## Discipline

- **Roles don't overlap.** Each role stays in its lane. If a sub-agent strays out of scope, the summary author should note it as out-of-scope and shift it to the right role's findings — but this should be rare given the strict role scopes.
- **No synthesis bias.** When writing the summary, don't smooth over disagreements between roles. If devil-advocate says X is a critical bug and pragmatist says X is fine because of Y, both views appear.
- **No softening for the architect.** The roast exists because polite review is too gentle. Aggregate findings honestly. The architect can argue back; that's the next step.
- **Severity is per-role, not absolute.** A devil-advocate "high" (data loss) is not the same as a futurist "high" (becomes legacy). Don't sum them as if they were.

## Language and template integrity

The roast's output structure is **prescribed by this command file**. When generating both the per-role documents and the `00-summary.md`, the prescribed section headers (`## Headline findings`, `## Cross-cutting concerns`, `## Severity counts`, `## Recommended path`, `## Per-role outputs`, plus each role's own template headers) **must appear verbatim in English**, even when the body of the document is written in Russian. They are identifiers that the `meta-reviewer` agent and downstream tooling expect.

Specifically, when the project's working language is Russian:

- Section headers stay English (`## Headline findings`, not `## Главное`).
- Role names in the summary stay English (`Devil-advocate`, `Pragmatist`, `Junior-engineer`, `Compliance-officer`, `Futurist`) — these are identifiers, not concepts to be translated.
- Finding IDs stay in their Latin form (`B-1`, `H-3`, `J-2`, `C-1`, `F1.2`, `CC-3`).
- The **content** under each section is written in Russian per the calque pass in `architect/SKILL.md`.

If a previous roast translated section headers or role names (a known regression in v0.4.0-rc1 and earlier), that artifact diverged from the template. New roasts produce verbatim-English structure with translated prose. Use `/archforge:meta-review <roast-directory>` to verify a roast's structural integrity.

The summary author is responsible for this discipline at the summary level; each sub-agent is responsible for it in its own document.

## Auto-roast in `/archforge:cycle --scale=deep`

When `cycle --scale=deep` reaches the end of Decide and before Document, automatically invoke roast on the decision summary. Pause for user to review. The user then decides:

- Apply findings, then proceed to Document.
- Apply findings, re-roast, then proceed.
- Step back to Design or Discover.

Do not auto-skip. Auto-skipping the auto-roast defeats its purpose at deep scale.

## Output structure recap

A roast produces a directory of 6 documents (1 summary + 5 roles). The summary is the read-first artifact. The role docs are the deep read.

For `--roles=core` (3 roles), the directory has 4 documents (summary + 3 roles).

## When to skip a role

If a role would clearly produce a near-empty output:

- **Compliance-officer**: skip on internal-tool, no-PII, no-external-users projects. The role itself will say "not applicable" if forced; better to skip.
- **Futurist**: skip on time-bounded one-off projects (research spike, PoC). Future drift doesn't matter for code that won't outlive the experiment.

The user can pass `--roles=` to opt out. The auto-roast in deep cycle should default to all 5 unless the project's `STRATEGY.md` clearly signals one of the above.

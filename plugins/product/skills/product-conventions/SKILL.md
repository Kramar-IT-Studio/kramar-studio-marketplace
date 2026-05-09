---
name: product-conventions
description: Activate this skill whenever a product artifact is being created, edited, or audited — PRD, hypothesis, market-scan, spec, validation. The skill carries the rules for artifact identity (front-matter, ID prefixes, status lifecycle), file layout under docs/product/, and how product artifacts cross-link to archforge ADRs. Use proactively when the user says "write a PRD", "let's spec this", "what's the format for X", or whenever a product command (e.g. /product:define) is producing output and the format must match.
---

# product-conventions

This skill carries the **format contract** for product artifacts in the `product` plugin. The methodology — what each phase produces, when to skip — lives in `product-cycle`. This file is about **what a well-formed artifact looks like**.

If a generated artifact violates these conventions, the artifact is broken. The hooks catch the loud cases (missing success_metric, empty acceptance, oversized market-scan); this skill documents the rest.

## File layout in the user's project

```
docs/product/
├── README.md                 ← directory index, auto-maintained
├── research/                 ← market-scans
│   └── YYYY-MM-DD-<area>-market-scan.md
├── discoveries/              ← hypotheses
│   └── YYYY-MM-DD-<feature>.md
├── prds/                     ← Product Requirements Documents
│   └── YYYY-MM-DD-<feature>.md
├── specs/                    ← implementation specs
│   └── YYYY-MM-DD-<feature>-spec.md
├── validations/              ← post-launch validations
│   └── YYYY-MM-DD-<feature>-validation.md
├── backlog.md                ← rolling prioritization snapshot
├── .last-prioritize          ← marker file (mtime tracked by hooks)
└── .last-market-scan         ← marker file
```

`PRODUCT.md` lives at the **repository root**, alongside `ARCHITECTURE.md` (if `archforge` is in use) and `CLAUDE.md`. Same level — these are project memory documents, not artifacts.

## Artifact identity: the front-matter contract

Every artifact starts with YAML front-matter. The fields below are the **only** fields recognized; do not add ad-hoc fields without extending the conventions.

### Required on every artifact

```yaml
---
id: <PREFIX>-NNNN          # see ID prefix table
status: draft | active | accepted | superseded | archived
created_at: YYYY-MM-DD
role: product
links_to: []               # optional but expected for cross-role artifacts
---
```

### Required on specific artifact types

| Artifact | Extra fields |
|---|---|
| `SCAN-NNNN` (market-scan) | `area: <area-name>` |
| `PRD-NNNN` | `success_metric: "<short description>"` (mirrors the section 5 sentence) |
| `SPEC-NNNN` | `acceptance_count: <n>` (mirrors section 3 length) |
| `VAL-NNNN` (validation) | `verdict: confirmed | refuted | mixed | inconclusive` |

If the field is missing on the type that requires it, the artifact is malformed. `/product:status` flags it; the hooks flag the loud cases at write time.

## ID prefix table

| Prefix | Artifact type | Allocated by |
|---|---|---|
| `SCAN-` | Market scan | `/product:market-scan` |
| `HYP-` | Discovery hypothesis | `/product:discover` |
| `PRD-` | Product Requirements Document | `/product:define` |
| `SPEC-` | Implementation spec | `/product:spec` |
| `VAL-` | Post-launch validation | `/product:validate` |

**Allocation rule:** read the highest existing N for the prefix in the relevant directory; allocate N+1, zero-padded to 4 digits (`HYP-0007`). Numbers are **never** reused, even after archival.

## Status lifecycle

```
draft ──► active ──► accepted
   │         │
   │         ├──► superseded (links_to: [<replacement-id>])
   │         │
   │         └──► archived
   │
   └──► archived (artifact never matured)
```

- **draft** — being written. Single artifact in this state per feature is normal; multiple drafts on one feature is a smell.
- **active** — committed to, in flight. PRD becomes active when its SPEC enters draft; HYP becomes active when its PRD enters draft.
- **accepted** — the validation confirmed the hypothesis (PRD/HYP) or the artifact has served its purpose (SCAN, SPEC).
- **superseded** — replaced by a newer artifact. The replacement is named in `links_to`. The replacement's `links_to` must include the superseded ID.
- **archived** — abandoned, refuted, or no longer relevant. Never deleted from disk; status shift only.

**Validations don't enter `draft`.** A `VAL-` is committed as `active` because it represents a verdict, not a work-in-progress.

## Cross-references: `links_to`

`links_to` is the cross-role glue. The graph of links is what makes the marketplace compound.

### Mandatory links by artifact type

| Artifact | `links_to` must include |
|---|---|
| `HYP-NNNN` | `SCAN-NNNN` if a market-scan covers the area; otherwise empty |
| `PRD-NNNN` | The source `HYP-NNNN`, always |
| `SPEC-NNNN` | The source `PRD-NNNN`, always; plus all `ADR-NNNN` the spec relies on |
| `VAL-NNNN` | The source `PRD-NNNN` and `HYP-NNNN`; plus any `ADR-NNNN` whose justification depended on the validation |

### Cross-reference to archforge

Product artifacts routinely reference `ADR-NNNN` from `docs/architecture/decisions/`. The reference uses the bare ID (`ADR-0007`) — the resolver finds the file in `docs/architecture/decisions/0007-*.md`.

**If `links_to` is empty on an artifact whose body references architectural concepts** (databases, services, protocols, schemas, migrations), the soft hook will warn. Either add the link, or explain in the body why no ADR applies.

## Naming and slugs

- **File names:** `YYYY-MM-DD-<slug>.md` (or `-spec.md` / `-validation.md` for those types). Date is the artifact's creation date, not the feature's launch date.
- **Slugs:** kebab-case, derived from the feature name. Keep under 6 words. Strip articles, prepositions.
- **Section headers:** match the structure prescribed by the corresponding command's "What to produce" section. Don't rename them — the next command in the cycle reads these headers.

## Language

- Plugin source (commands, skills, templates) is in **English**. This file is in English.
- **Generated artifacts follow the user's language.** If the user works in Russian, all PRDs / SCANs / SPECs / VALs are in Russian.
- **Identifiers stay verbatim across languages.** `HYP-0003` is `HYP-0003` in any language. Section headers prescribed by the templates (`## Success metric`, `## Acceptance criteria`, `## Verdict`) stay verbatim — translating them desyncs the artifact from what `/product:status` and the hooks expect to find.
- For the full taxonomy of what gets translated and what stays English, see `archforge`'s `architect/SKILL.md` Language and Terminology section. This plugin inherits that posture.

## Common malformations to refuse

If you catch yourself producing one of these, rewrite:

- **PRD without a primary success metric.** Refuse to save. The `define` command's hook will flag it; even if it didn't, the PRD is broken.
- **PRD with success metric == counter-metric.** "Engagement up; engagement not down" doesn't catch regressions. Surface it.
- **SPEC with <3 acceptance criteria.** You're hand-waving, not specifying.
- **Market-scan with empty Gaps section.** Either you didn't try hard enough, or the area isn't worth entering — say which.
- **Validation that pads "inconclusive" to look like "confirmed".** The whole point of having the metric was to be honest now.
- **Front-matter `links_to: []` on an artifact whose body references architecture.** If you wrote about Postgres, queues, schemas — there should be an `ADR-` link or an explicit note that no ADR yet covers it (which itself is an open question for `/archforge:cycle`).

## When this skill applies

- The user is producing or auditing any product artifact.
- A `/product:*` command is generating output and you need to confirm format.
- `/product:status` is checking integrity.
- You're translating an artifact between languages and need to know what stays.

## When this skill does **not** apply

- Methodology questions ("should I run discover or skip to define?") — that's `product-cycle`.
- Architecture questions ("what's the right service boundary?") — that's `archforge`.

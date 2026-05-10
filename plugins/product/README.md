# product

Product management toolkit for Claude Code. Per-feature cycle Discover → Define → Spec → Validate, plus rare market-scan (quarterly anchor for an area) and prioritize (operation over the backlog). Artifacts are versioned, cross-link to ADRs from `architect`, and the cycle is enforced by soft, non-blocking hooks.

> **Philosophy.** Product work is a *cycle of bets and verdicts*, not a stream of features. This plugin makes the cycle first-class and the trail durable: every feature has a hypothesis, a measurable success metric, and an honest verdict at the end.

---

## The cycle

```
            ┌────────────────────────┐
            │   MARKET-SCAN (rare)   │  per area, quarterly cadence
            │   3-7 competitors,     │
            │   1-3 gaps, ≤200 lines │
            └───────────┬────────────┘
                        │ informs
                        ▼
            ┌────────────────────────┐       ┌────────────────┐
            │   PER-FEATURE CYCLE    │ ◄──── │   PRIORITIZE   │
            │                        │ next  │   (over        │
            │                        │ pick  │    backlog)    │
            └───────────┬────────────┘       └────────────────┘
                        ▼
            ┌────────────────────────┐
            │  1. DISCOVER           │  hypothesis + segment + JTBD
            │     → HYP-NNNN         │
            └───────────┬────────────┘
                        ▼
            ┌────────────────────────┐
            │  2. DEFINE             │  PRD with success metric
            │     → PRD-NNNN         │
            └───────────┬────────────┘
                        ▼
            ┌────────────────────────┐
            │  3. SPEC               │  acceptance + analytics
            │     → SPEC-NNNN        │
            └───────────┬────────────┘
                        ▼
            ┌────────────────────────┐
            │  4. VALIDATE           │  honest verdict
            │     → VAL-NNNN         │
            └───────────┬────────────┘
                        │
                        └─► feeds back into PRIORITIZE and DISCOVER
```

Three things that distinguish this shape from the typical "product cycle":

1. **Market-scan is not in the per-feature cycle.** It runs per **area**, on a quarterly cadence, with hard size limits. Treating it as a feature step kills you with research overhead.
2. **Prioritize is not a step.** It's an operation over the backlog, run when ≥2 candidates compete. Solo work with one item in flight: skip.
3. **Validate is mandatory.** Every shipped feature gets a verdict against its PRD's success metric — even when the verdict is "we don't know yet". The trail is the asset.

See [`skills/product-cycle/SKILL.md`](./skills/product-cycle/SKILL.md) for the full methodology and the failure modes the cycle exists to catch.

---

## Components

### Slash commands

| Command | Purpose |
|---|---|
| `/product:init` | Bootstrap `PRODUCT.md`, `docs/product/`, `.product-version` |
| `/product:upgrade` | Migrate artifacts to the currently installed plugin version |
| `/product:status` | Read-only report: in-flight, stale, broken cross-references |
| `/product:market-scan <area>` | Bounded market scan for an area (rare) |
| `/product:discover <feature>` | Phase 1 — hypothesis (HYP-NNNN) |
| `/product:define <feature>` | Phase 2 — PRD with success metric (PRD-NNNN) |
| `/product:spec <feature>` | Phase 3 — implementation spec (SPEC-NNNN) |
| `/product:validate <feature>` | Phase 4 — post-launch verdict (VAL-NNNN) |
| `/product:prioritize` | Operate over the backlog |

### Skills

Two skills per the [Kramar Studio Plugin Conventions](../../README.md#kramar-studio-plugin-conventions):

- **[`product-conventions`](./skills/product-conventions/SKILL.md)** — artifact format contract: front-matter, ID prefixes, status lifecycle, file layout, cross-references.
- **[`product-cycle`](./skills/product-cycle/SKILL.md)** — methodology: phase definitions, when to skip, common failure modes, how to interleave with `architect`.

Commands read these skills as needed. Adding more skills is intentional minimalism — see the conventions doc.

### Hooks (soft warnings)

Non-blocking. They never abort, never edit files, never auto-commit. They surface reminders to stderr.

- **SessionStart** — surfaces `PRODUCT.md`, counts active artifacts, warns on stale market-scans (>90 days), warns on plugin/project version drift.
- **PostToolUse** (`Edit|Write|MultiEdit` on `docs/product/*.md`) — checks artifact integrity:
  - `market-scan.md`: ≤200 lines; non-empty Gaps section.
  - PRD: `success_metric` present (front-matter or section).
  - PRD: linked SCAN exists and is fresh (≤90 days); warn if missing.
  - SPEC: ≥3 acceptance criteria.

The hook script lives at [`scripts/check-product-artifact.sh`](./scripts/check-product-artifact.sh) and follows the soft-warning posture from `architect`.

### Templates

In [`templates/`](./templates/):

- `PRODUCT.md` — root product document (deployed to repo root by `init`).
- `docs-product-readme.md` — index for `docs/product/`.
- `backlog.md` — rolling prioritization snapshot.
- `market-scan-template.md`, `hypothesis-template.md`, `prd-template.md`, `spec-template.md`, `validation-template.md` — one per artifact type.

---

## How `PRODUCT.md` works

By analogy with `architect`'s `ARCHITECTURE.md`, the project gets a living root document:

- **`CLAUDE.md`** — codebase context, conventions. *What* the code looks like.
- **`ARCHITECTURE.md`** (from `architect`) — architectural state. *Why* the code looks like that.
- **`PRODUCT.md`** (this plugin) — product state. *Who is this for, and what bets are we making?*

`PRODUCT.md` is the spine. It contains:

1. Product summary — what the product does, who uses it.
2. Target users / segments.
3. Active areas (each backed by ≥1 market-scan).
4. Backlog index — link to `docs/product/backlog.md`.
5. Decision and discovery index — links to in-flight HYP/PRD/SPEC/VAL.
6. Open questions — unresolved product questions.
7. Anti-patterns to avoid — project-specific traps.

Claude reads `PRODUCT.md` at session start (via the SessionStart hook and the `product-cycle` skill's protocol) and treats it as binding context.

---

## Recommended directory layout in your project

After `/product:init`:

```
your-project/
├── PRODUCT.md                          ← root product document
├── ARCHITECTURE.md                     ← (from architect, if installed)
├── CLAUDE.md                           ← (your existing project memory)
├── .product-version                    ← plugin version marker
└── docs/
    └── product/
        ├── README.md                   ← index of this directory
        ├── research/                   ← market-scans
        │   └── 2026-01-15-onboarding-market-scan.md
        ├── discoveries/                ← HYPs
        │   └── 2026-02-03-undo-button.md
        ├── prds/                       ← PRDs
        │   └── 2026-02-10-undo-button.md
        ├── specs/                      ← SPECs
        │   └── 2026-02-12-undo-button-spec.md
        ├── validations/                ← VALs
        │   └── 2026-03-15-undo-button-validation.md
        └── backlog.md
```

---

## Integration with `architect`

Most non-trivial product work touches architecture. The cycles meet, but stay distinct.

### When a PRD requires architecture work

A PRD that introduces a new service, schema, external dependency, or protocol triggers `/architect:cycle`. The flow:

1. Draft PRD up to the point where you need an architectural decision.
2. Surface the dependency: "this PRD requires ADR-NNNN to exist or be revisited".
3. Run `/architect:cycle "<scope>"` — produces ADR-NNNN.
4. Continue with `/product:spec`. The SPEC's `links_to` includes the ADR.

### When an ADR is justified by a product hypothesis

An ADR may be predicated on a HYP being true (e.g. "we picked Postgres because we believe transactional consistency matters for use-case X"). When this happens:

1. The ADR's `links_to` references the HYP.
2. When the corresponding VAL lands, the validation reinforces or weakens the ADR's justification.
3. A refuted VAL is a signal to run `/architect:observe` to revisit affected ADRs.

### Cross-references in artifacts

Front-matter `links_to` carries the graph. Bare IDs:

```yaml
links_to:
  - HYP-0007        # source hypothesis (PRD always)
  - SCAN-0003       # market-scan for the area (PRD if applicable)
  - ADR-0012        # architectural decisions (SPEC always; PRD/VAL if applicable)
```

The graph is what makes the marketplace compound — every artifact knows what it descends from and what it depends on.

---

## Tone and posture

The cycle exists to surface weak hypotheses, missing metrics, vague segments, dishonest validations. The plugin pushes back:

- Refuses to save a PRD without a real success metric.
- Refuses to mark a refuted launch as "directionally correct".
- Pushes back when a discovery's segment is "all our users".
- Surfaces when an in-flight feature short-circuits the cycle.

Soft, agreeable product advice is the most expensive kind — it sounds helpful and quietly costs months of work on launches no one asked for. See `architect`'s posture as the reference; this plugin inherits it.

---

## Updating the plugin

After editing files in this plugin, run `/reload-plugins` in Claude Code.

After upgrading the plugin version, run `/product:upgrade` in any project where it's installed to migrate that project's artifacts.

## License

MIT — see the marketplace [`LICENSE`](../../LICENSE).

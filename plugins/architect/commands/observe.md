---
description: Architectural gap analysis. Scans the project's code, STRATEGY, ARCHITECTURE.md, and ADR archive for architectural decisions that are implicit in the codebase but not documented, decisions deferred in old ADRs that are now ripe to revisit, and constraints from STRATEGY that no ADR covers. Produces a prioritized gap list and offers to add the relevant items to decision-map.md.
argument-hint: "(no arguments)"
---

# /archforge:observe

Project-wide architectural gap analysis. The plugin's other commands move forward — they take new decisions, write new ADRs. This command looks **sideways and backwards** to find decisions you've already made (in code, in deferrals) that aren't yet captured anywhere visible.

## What it does

Cross-references three sources to find gaps:

1. **What's in the codebase** — modules, dependencies, architectural patterns visible in the project structure.
2. **What's documented** — ADRs in `docs/architecture/decisions/`, `ARCHITECTURE.md`, the decision map.
3. **What's required by strategy** — constraints, quality attributes, market posture from `STRATEGY.md`.

When these three diverge, you have a gap. Gaps fall into a few categories:

- **Implicit decision**: code reflects a decision that has no ADR. ("We're using Redis as our session store" — visible in the deps, undocumented as a decision.)
- **Stale deferral**: an old ADR explicitly deferred something to V2; that V2 has now arrived (or never will and should be re-deferred). ("ADR-0001: dynamic memory deferred until ≥100 sessions" — you now have 200.)
- **Strategy without architecture**: STRATEGY names a quality attribute (e.g., "must work offline") that no ADR addresses.
- **Pattern divergence**: multiple modules solve the same problem differently — implicit "pattern decisions" that should either converge or be explicitly bifurcated.
- **Drifted ADR**: an accepted ADR exists but the code no longer matches it. (ADR says Postgres; code uses MongoDB. Either the ADR is stale and should be superseded, or the code is in violation.)
- **Anti-pattern check**: `ARCHITECTURE.md` lists anti-patterns; observe checks the code for actual occurrences.

## What it is not

- **Not a roast.** Roast attacks an artifact; observe finds missing artifacts.
- **Not a migration.** It doesn't change anything; it surfaces.
- **Not a code review.** It doesn't critique the implementation; it asks whether the architectural decisions behind the implementation are documented.
- **Not exhaustive.** It produces a prioritized short list, not a comprehensive audit.

## Output

A prioritized list of architectural gaps, each as a candidate for the decision map. Maximum **15 items** total — if there are more, the command says so and shows the top 15.

### Structure

```markdown
# Observation: architectural gaps

**Date**: YYYY-MM-DD
**Last refresh**: <project's last observe run, if any>

## Summary
2–3 sentences: how many gaps in each category, the most pressing one.

## Implicit decisions in code (not documented)
Decisions that are visible in the codebase but have no ADR.

### O-1: <one-line gap name>
**Evidence**: file paths, dependency entries, or code patterns that show the decision was made.
**Why it matters**: 1–2 sentences. Why this should have an ADR.
**Severity**: high (load-bearing decision, hard to change later) / medium / low.
**Suggested entry for decision map**: a one-line decision name suitable for `decision-map.md`.

## Stale deferrals (V2 has arrived or should be re-deferred)
Old ADRs that explicitly punted to "later"; the question is whether later is now.

### O-N: ...

## Strategy-without-architecture gaps
STRATEGY items not covered by any ADR.

### O-N: ...

## Pattern divergences
Same problem solved different ways across modules.

### O-N: ...

## Drifted ADRs (code no longer matches)
Accepted ADRs that disagree with the current code.

### O-N: ...

## Anti-pattern occurrences
ARCHITECTURE.md lists anti-patterns; here are matches found in the code.

### O-N: ...

## Suggested next actions
- Items to add to `decision-map.md` as new open decisions.
- Items to file as `/archforge:adr` for already-implicit decisions.
- Items requiring research (`/archforge:research`) before they can become full cycles.
- Items to leave alone (low severity or genuinely deferrable).
```

After producing the report, **prompt the user**: "Add these N items to `decision-map.md`?"

- **Yes / yes-all** → add all (or all of severity high+medium).
- **Selective** → enumerate which ones to add by ID (O-1, O-3, O-7).
- **No / not now** → save the report and stop. The user revisits later.

The user's choice determines what gets written to `decision-map.md`. The observation report itself is always saved to `docs/architecture/research/YYYY-MM-DD-observe.md` for the trail.

## How to find each kind of gap

### Implicit decisions in code

Inspect:
- Top-level dependency files (`package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, etc.).
- Top-level project structure (which modules/services exist).
- Configuration files (especially infra: `Dockerfile`, `compose.yml`, `terraform/`, `kubernetes/`).

For each significant entry, check if any ADR mentions it. If a runtime dependency (database, queue, cache, framework, language runtime, key library) is in the deps but no ADR touches it — that's an implicit decision.

### Stale deferrals

Grep ADRs for phrases like "deferred to", "V2", "future", "later", "out of scope". Each match is a candidate. For each, evaluate against current state — has the deferral condition been met?

### Strategy-without-architecture

Read `STRATEGY.md` (or the System Summary / Quality Attributes / Constraints sections of `ARCHITECTURE.md`). For each non-trivial constraint or quality attribute, check whether any ADR addresses it. Constraints listed but architecturally untouched are gaps.

### Pattern divergences

Look for the same architectural problem solved differently across modules:
- Multiple HTTP clients with different retry policies.
- Mixed authentication patterns.
- Mixed data-validation approaches.
- Mixed error-handling conventions across services.

These are usually visible from grep across the source tree. Surface them — they often indicate missing pattern ADRs.

### Drifted ADRs

For each accepted ADR, check whether its key claims still hold. Example: ADR says "we use Postgres"; check whether `package.json` / `Cargo.toml` mentions only Postgres drivers. If the codebase has clearly drifted from an ADR, flag it.

### Anti-pattern occurrences

Read `ARCHITECTURE.md`'s anti-patterns section. For each, check the code for occurrences (where pattern detection is feasible from text inspection — e.g., "no microservices for now" → look for `services/` or `apps/` directory with multiple deployable units).

## Discipline

- **Severity is honest.** Not everything is "high". Most gaps are medium-or-low. Reserve high for things that genuinely block future work or expose risk.
- **Cap at 15 findings.** If there are more, show the top 15 and tell the user "there are more — re-run after addressing these and observe will refresh."
- **No fabrication.** If you can't tell from the code whether a decision was made, say "couldn't determine" and skip — don't manufacture findings.
- **Distinguish "gap in documentation" from "gap in design".** Some gaps are just missing docs (file an ADR for an existing decision). Others are missing decisions (something needs to actually be decided). Mark which.
- **Don't count `/archforge:upgrade` migrations as gaps.** Things that are "missing" because the project is on an older plugin version are upgrade work, not architectural gaps.

## Output to chat

- One-paragraph summary.
- The findings, grouped by category, with IDs.
- The prompt to add items to `decision-map.md`.
- Path of the saved observation report.

## When to run

- **After significant code work** that may have introduced implicit decisions. ("I just shipped the billing module" — observe might find that the billing module made several pattern decisions that aren't in any ADR.)
- **Periodically** — once a quarter, once a sprint — as architectural hygiene.
- **Before a planning round** — observe surfaces what's been left implicit; planning is the time to either explicitize or accept the gaps.
- **As a final pre-publish check** — for a project that's about to be published or open-sourced, observe shows future contributors which architectural decisions exist but aren't documented.

## When NOT to run

- On a fresh project with no code yet. Observe needs material to work with.
- During an active cycle. Run observe between cycles, not in the middle of one.

---
description: Plugin-conformance check on artifacts produced by archforge. Verifies templates are followed, identifiers are preserved (not translated), language pass was applied, cross-references resolve, lifecycle states are valid. Does NOT evaluate architectural quality (use /archforge:roast for that). Catches the plugin failing to follow its own rules.
argument-hint: "<path-to-artifact-or-directory>   examples: ADR-0002 | docs/architecture/reviews/2026-05-09-roast-foo/ | latest-roast | all"
---

# /archforge:meta-review

Meta-review of `archforge` artifacts. Reads them, compares to the plugin's own templates and rules (in command files and the `architect` skill), reports divergences.

This is **not** an architectural review. It is the plugin's QA on itself — does the artifact match what the plugin promised it would look like?

## When to run

- **After a roast** to verify the roast's directory and per-role files conform to the template (this is the highest-value usage today, since the v0.4.0-rc1 sub-agent identifier-translation bug surfaced via this exact gap).
- **After a deep cycle** to verify the resulting ADR + design doc + discovery doc + roast all conform.
- **Periodically across the whole archive** to catch drift in older artifacts as templates evolve.
- **Before publishing** an architectural snapshot externally (statia, portfolio, audit) — to make sure the artifacts read cleanly.

## When NOT to run

- During an active cycle before the artifact is finalized — meta-review of a draft is noise.
- On non-`archforge` artifacts. The meta-reviewer doesn't lint user-authored code or unrelated docs.

## Inputs

- `$ARGUMENTS` first positional. One of:
  - A path to a single artifact: `docs/architecture/decisions/0002-modular-monolith.md`
  - A path to a roast directory: `docs/architecture/reviews/2026-05-09-roast-0002-modular-monolith-cargo-workspace/`
  - An ADR identifier: `ADR-0002` — resolves to the file.
  - The token `latest-roast` — uses the most recent roast directory.
  - The token `latest` — uses the most recent ADR.
  - The token `all` — meta-reviews everything in `docs/architecture/`. Slower; use sparingly.

## Steps

### 1. Resolve the target

- If it's a file or directory path that exists, use it.
- If it's `ADR-NNNN`, find `docs/architecture/decisions/NNNN-*.md`.
- If it's `latest-roast`, list `docs/architecture/reviews/` and pick the most recent directory matching `*-roast-*`.
- If it's `latest`, find the highest-numbered ADR.
- If it's `all`, build a list of all artifact paths under `docs/architecture/` (excluding `.archforge-version` and `README.md`).
- If it can't be resolved, ask which artifact the user meant.

### 2. Load the plugin's source as the specification

The meta-reviewer needs the **current plugin source files** to know what the templates and rules require. Read:

- `${CLAUDE_PLUGIN_ROOT}/commands/discover.md`, `design.md`, `decide.md`, `document.md`, `review.md`, `roast.md`, `cycle.md`, `adr.md`, `diagram.md`, `map.md`, `observe.md`, `remember-compound-integration.md` — these prescribe artifact structures.
- `${CLAUDE_PLUGIN_ROOT}/skills/architect/SKILL.md` — language taxonomy and calque table.
- `${CLAUDE_PLUGIN_ROOT}/skills/adr-writing/SKILL.md` — ADR template details.

You don't read every file every time; read what's relevant to the target's artifact type.

### 3. Run the meta-reviewer agent

Spawn the `meta-reviewer` sub-agent with the resolved target and the loaded specification. The agent produces a structured meta-review document.

### 4. Save the meta-review

Path: `docs/architecture/reviews/YYYY-MM-DD-meta-review-<target-slug>.md`.

For `target=all`, save as `YYYY-MM-DD-meta-review-archive.md` and include findings grouped by artifact.

### 5. Update the target artifact's review trail (when applicable)

If the target is an artifact that has a `## Reviews` section (ADR, design doc), append a line:

```markdown
- YYYY-MM-DD — Meta-review (severity: H/M/L counts) — [link](docs/architecture/reviews/YYYY-MM-DD-meta-review-<slug>.md)
```

For roast directories, append the same line to `00-summary.md` in a `## Reviews` section if it exists, or just save the meta-review separately.

### 6. Output to chat

- Path of the meta-review.
- The findings, grouped by category (template / identifier / language / cross-reference / lifecycle).
- Severity counts.
- The single most important divergence to fix first.

If the meta-review finds no divergences (artifact conforms cleanly), say that as the headline. "Meta-review: 0 divergences. Artifact conforms to plugin v<version> templates." This is a real and important finding.

## Discipline

- **The plugin's own source is the spec.** Templates evolve between versions; check against the **currently installed** plugin's command files, not against memory of an older version.
- **Don't redesign templates from the meta-reviewer.** If a finding makes you think the template itself should change, route that to the roadmap, not into the meta-review output.
- **Severity calibration:**
  - **High**: identifier translated (breaks cross-references), template section missing or wrong-named, lifecycle violation (substantive edit to accepted ADR).
  - **Medium**: language pass evidence absent in a Russian artifact, optional section missing, cross-reference points at a non-existent ADR.
  - **Low**: cosmetic deviations, minor formatting differences, missing optional metadata.
- **No false positives.** If a "section is missing" might be because the section is genuinely not applicable (e.g., a discovery doc in a `light` cycle skipping Section 7 because there were no answers needing a second pass), say so rather than flagging.
- **Don't catastrophize.** A few low-severity findings on an otherwise good artifact is fine. The summary should reflect that. Meta-review that nitpicks an artifact into despair is itself a divergence from useful output.

## Auto-meta-review in deep cycles

When `/archforge:cycle --scale=deep` produces a roast, **automatically chain a meta-review on the roast directory** as the final step before declaring the cycle done. This catches the kind of bug v0.4.0-rc1 had — where the roast appeared to succeed but its per-role outputs were structurally divergent.

The user sees the meta-review's summary in chat. If high-severity divergences are present, the cycle pauses and asks whether to fix them now or defer.

## Cross-references between meta-review and other reviews

- Meta-review and roast are **complementary, not overlapping**. Roast attacks the substance; meta-review checks the form. Run both on important artifacts.
- Meta-review and `/archforge:review` (architectural code review) are also complementary. Code review looks at code; meta-review looks at architectural artifacts.
- Meta-review and `/archforge:diff` (planned for v0.5) will overlap slightly — diff checks whether ADR rules live in code; meta-review checks whether ADR conforms to template. Different lenses.

## Failure modes the meta-reviewer was built to catch

This is the historical context — useful for anyone modifying this command later.

- **v0.4.0-rc1 regression**: roast sub-agents (devil-advocate, pragmatist, etc.) produced output without inheriting the language pass from the router skill. Russian users got mixed-language outputs. Some users then over-corrected and translated identifiers (agent names, section headers, finding IDs), breaking cross-references. The meta-reviewer catches both directions: untranslated calques in prose, **and** translated identifiers.
- **General failure mode**: a sub-agent or command output drifts from its template silently. Without a meta-review, the divergence is invisible until manual inspection.

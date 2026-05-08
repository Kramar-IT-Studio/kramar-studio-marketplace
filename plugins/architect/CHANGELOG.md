# Changelog

All notable changes to `archforge` are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0-rc3] - Renamed from `krait_arch` to `archforge`

The plugin was previously named `krait_arch`, sharing a name root with a commercial project the author is building. To keep the open-source plugin clearly separated from any specific commercial work, and to give the plugin a name that reflects what it does (forging architectural artifacts) rather than what project it grew out of, the plugin is renamed.

### Changed

- Plugin name: `krait_arch` → `archforge`. All commands now use the `/archforge:*` prefix.
- Marketplace name: `krait-arch-marketplace` → `archforge-marketplace`.
- Plugin directory: `plugins/krait_arch/` → `plugins/archforge/`.
- All references in command files, skill files, agent files, READMEs, ROADMAP, hooks scripts, and templates updated to the new name.
- The `.archforge-version` marker file used by `/archforge:upgrade` was previously named `.krait-arch-version`. Existing projects that ran an earlier version with the old marker will need to either rename the file manually or run `/archforge:upgrade` which detects the legacy marker and migrates.

### Migration from rc2 (only relevant if you installed v0.4.0-rc2)

This is a **breaking rename**. Anyone with rc2 installed needs to:

1. Remove the old marketplace: `/plugin marketplace remove krait-arch-marketplace`
2. Remove the old plugin: `/plugin uninstall krait_arch`
3. Add the new marketplace: `/plugin marketplace add IgorKramar/archforge-marketplace`
4. Install the new plugin: `/plugin install archforge@archforge-marketplace`
5. In existing projects with `docs/architecture/`, run `/archforge:upgrade` to migrate the version marker.

Since rc2 was a pre-release and not advertised, the practical impact is minimal — but the rename is preserved here for the trail.

### Notes

No functional changes in this rc. The plugin behaves identically to rc2 — same 17 commands, same 9 agents, same 10 skills, same hooks. Only names changed.

## [0.4.0-rc2] - Language enforcement extended into sub-agents; new meta-reviewer

This RC fixes a structural bug discovered through real use of v0.4.0-rc1: when the user ran `/archforge:roast` on a Russian-language project, the 5 roast sub-agents (`devil-advocate`, `pragmatist`, `junior-engineer`, `compliance-officer`, `futurist`) produced mixed-language outputs because the terminology rule lived only in the `architect` router skill — sub-agents are separate contexts and didn't inherit it. When the user pointed this out, the assistant over-corrected and began translating identifiers (`Devil-advocate` → "Обвинитель", `## Headline findings` → `## Главное`, `CC-3` → `СП-3`), which silently broke cross-references in the roast directory.

The fix is structural, not textual: the language rule is now embedded in every sub-agent's source file, with explicit guards against both undertranslation (calques in prose) and overtranslation (translating identifiers). And a new role exists specifically to catch this kind of plugin-failing-its-own-rules bug.

### Added — meta-reviewer

- **New sub-agent `meta-reviewer`** — checks artifacts produced by `archforge` against the plugin's own templates and rules. Five categories: template conformance, identifier preservation, language-pass evidence, cross-reference integrity, lifecycle integrity. Does not evaluate architectural quality (that's `roast`).
- **New command `/archforge:meta-review <target>`** — supports targets: ADR identifier (`ADR-0002`), file path, roast directory, `latest`, `latest-roast`, `all`. Saves to `docs/architecture/reviews/YYYY-MM-DD-meta-review-<slug>.md`.
- **Auto-meta-review in `/archforge:cycle --scale=deep`** — after auto-roast (between Decide and Document) and after Document. High-severity divergences pause the cycle for fixing.

### Changed — language rules

- **`architect/SKILL.md` rewritten Language and terminology section** with a 10-category taxonomy (A–J) that distinguishes identifiers (never translate) from prose (apply the calque pass). Includes an explicit "Overcorrection is also a failure" subsection naming the specific failure modes seen in v0.4.0-rc1.
- **Calque table extended** with terms that surfaced in real cycles: `operational baseline`, `spawn (a new ADR / cycle)`, `tactical fixes`, `wire-код`, `sweep-проверка`, `compile-time`, `graceful shutdown`, plus term-of-art handling for `confused deputy`, `prompt injection`, `BYPASSRLS`, `fail-closed/fail-open`.
- **Identifier-preservation rule** is now explicit: agent names, command names, plugin template section headers, finding IDs, software/library names, regulations, and ADR numbers are identifiers and must never be translated. Translating them desyncs documentation from plugin source.
- **Cross-skill enforcement clause** added — every sub-agent of the plugin (`architect`, `reviewer`, `researcher`, `devil-advocate`, `pragmatist`, `junior-engineer`, `compliance-officer`, `futurist`, `historian`, `meta-reviewer`) must apply the terminology pass before returning output.

### Changed — sub-agents

- **All 5 roast sub-agents now have an explicit `## Language and terminology` section** referencing the `architect` skill's taxonomy. Each agent's section names role-specific identifiers that must not be translated (the `B-N`, `H-N`, `J-N`, `C-N`, `F-N` finding ID schemes; the `Devil-advocate`/`Pragmatist`/etc. role names; the prescribed output structure section headers).
- **3 core sub-agents (`architect`, `reviewer`, `researcher`)** also have a short language block.
- Each agent now states at the end of its output what the terminology pass changed.

### Changed — roast command

- `commands/roast.md` has a new `## Language and template integrity` section with explicit rules: section headers in `00-summary.md` stay verbatim English, role names in summary stay English, finding IDs stay Latin, content is translated per the calque pass.
- Auto-roast in deep cycle now also auto-chains a meta-review on the roast directory; high-severity divergences from the meta-review pause the cycle.

### Migration from 0.4.0-rc1

- The fix is automatic for new artifacts. Existing artifacts written under rc1 may have identifier-translation issues; run `/archforge:meta-review all` to surface them, then fix manually.
- The roast template's section headers must remain English (`## Headline findings`, `## Cross-cutting concerns`, etc.) even when the body is in Russian. If older roasts have Russian headers (`## Главное`), the meta-reviewer flags them as identifier-translation issues.
- No breaking changes to file paths or schemas.

### Notes for context

This rc was forged from a specific incident: the user ran roast on a real ADR in a project that uses the plugin, and the assistant produced output in mixed Russian-with-anglicisms. When called out, the assistant translated identifiers in the over-correction. The user ([@IgorKramar](https://github.com/IgorKramar)) said: "after my correction, it went into the other extreme and started translating even plugin command names — overkilling outright." That observation is the literal motivation for this rc.

The pattern of "the plugin found its own bug through its own roast, then we built the role that catches this kind of bug" is the strongest illustration to date of the compound logic the plugin is designed for.

## [0.4.0-rc1] - Adversarial roast, project upgrade, gap observation, multi-type diagrams

The 0.4 line builds on the cycle established in 0.3 with three things the architect actually wants but didn't have: a way to attack a decision from multiple angles before declaring it final, a way to find architectural decisions that have been made implicitly (in code, in deferrals) but not documented, and proper diagram support beyond just C4.

### Added — adversarial review

- **Five new sub-agents** for adversarial multi-perspective review:
  - `devil-advocate` — pressure-test for failure modes, hidden assumptions, edge cases.
  - `pragmatist` — operational realism: on-call, real cost, skills, deployment risk.
  - `junior-engineer` — clarity check from a fresh reader six months later.
  - `compliance-officer` — regulatory and security exposure.
  - `futurist` — 1–3 year horizon, structural drift, ecosystem trends.
  - The five roles have **strict non-overlapping scopes**, each with explicit "what I cover / what I do NOT cover" lists. This prevents the typical "5 agents, 5× duplication" problem.
- **New command `/archforge:roast <target> [--roles=...]`** — runs all five (or a subset) against the same artifact and aggregates findings into a structured directory in `docs/architecture/reviews/<date>-roast-<slug>/` with a `00-summary.md` plus one document per role.
- **Auto-roast in `/archforge:cycle --scale=deep`** between Decide and Document. The user can apply findings, re-roast, or step back to Design before the ADR is written.

### Added — project hygiene

- **New command `/archforge:upgrade`** — migrates the project's artifacts to the currently installed plugin version. Idempotent, version-marker-gated (`docs/architecture/.archforge-version`), confirms before mutating files. Surfaces the changelog between marker and installed version. Does **not** update the plugin code itself — that's a Claude Code action.
- **New command `/archforge:observe`** — architectural gap analysis. Finds:
  - Implicit decisions in code that no ADR documents.
  - Stale deferrals from old ADRs ("V2: ..." that's now V2 or never).
  - Strategy items not covered by any ADR.
  - Pattern divergences across modules.
  - Drifted ADRs (code no longer matches).
  - Anti-pattern occurrences from `ARCHITECTURE.md`.
  Produces a prioritized list capped at 15, then offers to add selected items to `decision-map.md`.

### Added — diagrams

- **Skill `c4-diagrams` renamed and extended to `architectural-diagrams`** with five diagram types: C4 (context/container/component), sequence, state, entity-relationship, deployment. All Mermaid. Each type has dedicated rules, templates, and anti-patterns.
- **New command `/archforge:diagram <type> <subject>`** — single entry point for all diagram types.
- **`/archforge:c4` is now an alias** for `/archforge:diagram c4-<level>`. Backward compatible; old workflows keep working.

### Changed

- The `reminder-large-change.sh` hook now also reminds about `/archforge:observe` when ≥4 modules have been touched in a session and observe hasn't run in 14+ days.
- Plugin and marketplace versions: `0.4.0-rc1`.
- Plugin README and `README.ru.md` updated with the new commands, agents, and skill renames.

### Migration from 0.3

Run `/archforge:upgrade` to apply migrations. Specifically:
- The skill rename `c4-diagrams` → `architectural-diagrams` is internal; old `/archforge:c4` calls keep working via the alias.
- Existing `docs/architecture/diagrams/` files are untouched. New diagrams use the type-prefixed naming `<type>-<subject>.md`.
- Existing reviews don't gain auto-roast retroactively. Run `/archforge:roast` manually on important ADRs.
- The `.archforge-version` marker is created on first `/archforge:upgrade` run.

### Notes

- The roast roles deliberately have minimal overlap. If you find one straying into another's territory, that's a bug — file an issue. The intended behavior is: each role is its own lens, not five views of the same lens.
- `observe` is conservative by default — it suggests, never auto-modifies the decision map. The user confirms which gaps to add.
- `upgrade` is project-side only. The plugin code itself is updated through Claude Code's native plugin commands; `/archforge:upgrade` adapts the project to the new plugin version that's already installed.

## [0.3.0-rc1] - Release candidate based on real-world cycle experience

This RC is forged from running v0.2 through one full architecturally-significant cycle on a real architectural project. Every change below is traceable to an observation from that run.

### Added
- New command **`/archforge:research`** — Phase 1.5 of the cycle. Gathers current information from the web between Discover and Design when claims depend on versions, releases, benchmarks, regulatory status, or pricing. Was an emergent phase in v0.2; now first-class.
- New command **`/archforge:map`** — builds or updates a decision map (`docs/architecture/decision-map.md`): groups of open architectural decisions with hard / soft / mutual dependencies and a topologically-sorted suggested order. Also lists explicitly-deferred decisions with their "wait for" conditions. Recommended at project start when ≥3 architectural questions are open at once.
- **`Status` and `Closeout` sections in the review template.** Reviews now open as `Status: Open` and are explicitly closed out by updating the same file with a `## Closeout — YYYY-MM-DD` block listing how each blocker was resolved. This was an emergent practice in v0.2; now codified.
- **Detail scaling** for `/archforge:cycle` — new `--scale=light|standard|deep` flag (with autodetect heuristics). Light cycles produce ≤30-line discovery docs and 2 alternatives; deep cycles run mandatory research and produce ≥4-alternatives ADRs. Solves the "every cycle is full-scale" problem of v0.2.
- **Mandatory second round of discover** when the user answers open questions. Round 2 looks for push-back opportunities, surfaces constraints that the answers reveal, and marks each question as resolved-or-deferred. Appended to the same discovery document as `Section 7`.
- **Mandatory `What we explicitly do NOT consider — and why` section** in the design phase. Captures dead-end alternatives with one-line dismissals so they don't get re-litigated later.
- **Russian-localized integration block** in `/archforge:remember-compound-integration`. New `--lang=en|ru|auto` flag with autodetect from `STRATEGY.md`, `ARCHITECTURE.md`, and the most recent ADR. Idempotent across language switches.

### Changed
- **Architect router skill — extended terminology table** with calques observed in real artifacts: `архитектурный шов → развилка`, `routing-policy → правила маршрутизации`, `pipeline / sanitizer` (allowed only as proper-noun component names), `fail-closed/open`, `breaking change`, `graceful degradation`, `backpressure`, `feature flag`, `hype`, and others.
- **Mandatory terminology pass** for Russian-language artifacts. After generating any Russian document, the architect skill now runs an explicit pass against the calque table and reports non-trivial corrections to the user in one line.
- Pre-response checklist gains a language-pass item.
- Plugin and marketplace versions: `0.3.0-rc1`.
- Plugin README and `README.ru.md` updated with the new commands and flags.

### Fixed (carried over from 0.2.1 hot-fix)
- `hooks/hooks.json` wraps events under top-level `hooks` key as required by Claude Code's hook validator schema.
- `plugin.json` no longer references `hooks` field — Claude Code auto-discovers `hooks/hooks.json` from the plugin root.
- Manifest URLs now point to `IgorKramar/archforge-marketplace`.

### Notes for users running v0.2 in production
- The new `Section 7` in discovery and `What we do NOT consider` in design are additive — existing v0.2 documents won't be regenerated, but new cycles will include them.
- `decision-map.md` is recommended but not required. Existing projects without one continue to work; runs of `/archforge:cycle` simply skip the map check.
- Re-run `/archforge:remember-compound-integration` to migrate the integration block to the new (research-aware) workflow diagram.

## [0.2.1] - Hook schema fix

### Fixed
- `hooks/hooks.json` now wraps events under the top-level `hooks` key as required by Claude Code's hook validator schema.
- Removed `hooks` field from `plugin.json` — Claude Code auto-discovers `hooks/hooks.json` from the plugin root.

## [0.2.0] - Compound Engineering integration + bilingual docs + Russian language discipline

### Added
- New skill **`compound-integration`** — defines how `archforge` interleaves with the EveryInc `compound-engineering` plugin: phase-by-phase workflow, artifact ownership split, hand-off rules, anti-patterns to avoid double work.
- New command **`/archforge:remember-compound-integration`** — materializes the integration as an idempotent rule block in the project's `AGENTS.md` (or `CLAUDE.md`), wrapped in HTML-comment markers so re-runs replace in place.
- Russian-language editions of both READMEs (`README.ru.md` at top level and inside the plugin) with cross-language switchers in headers.
- New section **Language and terminology** in the `architect` router skill: explicit Russian technical terminology guide with a calque-avoidance table (e.g., «развёртывание» instead of «деплоймент», «наблюдаемость» instead of «обзервабилити»). Active when the user writes in Russian; English unaffected.

### Changed
- Plugin and marketplace versions bumped to 0.2.0.
- Plugin README expanded with a Compound Engineering integration section and updated component lists (new skill, new command).
- Top-level marketplace README expanded with a Compound Engineering integration section.

### Notes
- The integration assumes the official EveryInc `compound-engineering` plugin (commands `/ce-ideate`, `/ce-brainstorm`, `/ce-plan`, `/ce-work`, `/ce-code-review`, `/ce-compound`). If CE renames a command in a future release, re-run `/archforge:remember-compound-integration` to refresh the rule block in `AGENTS.md`.

## [0.1.0] - Initial release

### Added
- Router skill `architect` and 8 specialist skills (c4-diagrams, adr-writing, system-design, frontend-architecture, backend-architecture, ai-agents-architecture, code-review-architectural, architecture-research).
- Slash commands: `/archforge:init`, `:discover`, `:design`, `:decide`, `:document`, `:review`, `:cycle`, `:adr`, `:c4`.
- Sub-agents: `architect`, `reviewer`, `researcher`.
- Soft-warning hooks (`PostToolUse`) for large changes, new top-level modules, new dependencies.
- Templates: `ARCHITECTURE.md`, ADR boilerplate, `docs/architecture/README.md`.
- Architecture Cycle (Discover → Design → Decide → Document → Review) as the organizing process.

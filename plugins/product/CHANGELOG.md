# Changelog

All notable changes to the `product` plugin are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-06-01

No breaking API changes — version reflects maturity transition (scaffolded → active).

### Added

- Migration mechanism: `migrations/` directory, `_TEMPLATE.md`, and the first migration
  `0001-from-0.1.0-to-1.0.0.md` (maturity transition, no artifact changes).
- `plugins/product/CHANGELOG.md` (this file), per ADR-0002 rule 8.

### Changed

- `commands/upgrade.md` rewritten from a stub into a real migration runner (sequential
  migrations, per-step marker atomicity, dirty-tree refusal, downgrade refusal,
  backup-before-mutation when a migration mutates front-matter).
- `skills/product-conventions/SKILL.md` documents the `.product-version` marker location
  and the migration format.

## [0.1.0] — 2026-05-10

### Added

- Initial scaffold: per-feature cycle (`discover` → `define` → `spec` → `validate`),
  `market-scan`, `prioritize`, service commands (`init`, `status`, `upgrade`), two skills
  (`product-conventions`, `product-cycle`), soft hooks, templates.

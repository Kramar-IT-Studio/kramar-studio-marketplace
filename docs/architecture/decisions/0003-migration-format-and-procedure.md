# ADR-0003: Формат и процедура миграций (B1)

- **Date**: 2026-06-01
- **Status**: Accepted
- **Authors**: Igor Kramar
- **Upstream**: [ADR-0002](./0002-multi-level-versioning-contract.md) — versioning контракт; B1 был помечен как отдельный цикл.

## Context

ADR-0002 зафиксировал semver-контракт и анонсировал B1 (формат миграций) как отдельный
цикл. До этого ADR механизм миграций существовал в двух несовместимых видах: декларированном
(`CLAUDE.md`, ADR-0002, `product/upgrade.md` — отдельные файлы `migrations/NNNN-from-X.Y.Z-to-A.B.C.md`)
и фактическом (`architect/upgrade.md` — инлайн version-gated блоки). Ни один плагин не мог
реально выполнить миграцию.

## Decision

1. **Model B — binding.** Миграции — отдельные файлы
   `plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md`, прогоняются последовательно
   `/<role>:upgrade`. Это исполнение ADR-0002, не его правка.
2. **Формат файла.** Front-matter `migration / from / to / mutates_frontmatter / scope`;
   фиксированные секции `Summary` / `Preconditions` / `Transform` / `Backup` /
   `Verification` / `Rollback note` / `Never`. Эталон — `migrations/_TEMPLATE.md` в каждом
   плагине. Runner игнорирует файлы, не подходящие под шаблон имени.
3. **Per-step atomicity.** Маркер `.<plugin>-version` пишется после каждого успешного шага
   (после прохождения его `Verification`); падение в середине оставляет маркер на последнем
   завершённом шаге. Это уточнение rule 3 ADR-0002 («атомарно с последней миграцией») до
   per-step гранулярности; совпадает с уже декларированным поведением `architect`.
4. **Backup-posture.** Основной откат — git (runner отказывает на грязном дереве). Явный
   backup в `docs/<role>/.upgrade-backup/<from>-to-<to>/` берётся только при
   `mutates_frontmatter: true` (закрывает C-3 из roast ADR-0002 — regulated/PII content).
5. **Marker location — per-plugin.** ADR-0002 rule 3 место маркера не фиксирует.
   `product` — корень репозитория (`.product-version`); `architect` —
   `docs/architecture/.architect-version`. Нормализация не делается: она сама сломала бы
   существующих пользователей и потребовала бы миграции. Место объявляется в
   `<role>-conventions` плагина.

## Consequences

### Easier
- `/<role>:upgrade` стал тонким runner'ом; новые миграции — просто новые файлы, upgrade.md
  не растёт.
- `architect` реконсилирован: инлайн-блок 0.2→0.3 вынесен в файл; добавлен
  `.archforge-version` recovery path (ADR-0002 rule 3 «at first convenience»).
- `product` получил символический 1.0.0 (scaffolded → active) с первой миграцией-no-op.

### Harder
- Honor system без enforcement сохраняется (как в ADR-0002): корректность формата и
  atomicity держатся ручной дисциплиной + verification-грепами в плане, не CI.
- Маркер в двух местах остаётся латентной путаницей для будущих `ops`/`security`;
  mitigation — место маркера всегда объявляется в conventions.

### Risks accepted
- LLM-исполнение `Transform` недетерминировано (миграция — промпт, не скрипт). Mitigation:
  отказ на грязном дереве + git-откат + явный backup при мутации frontmatter.

## Связанные артефакты
- [ADR-0002](./0002-multi-level-versioning-contract.md) — versioning контракт (upstream).
- README §7 — каноничный формат миграций (мета-форма).
- Spec/plan: `docs/superpowers/specs/2026-06-01-product-migration-mechanism-design.md`.

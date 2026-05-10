# Research digest: Claude Code plugin-to-plugin dependency mechanism

> **Cycle:** Cross-marketplace dependency posture (A1)
> **Date:** 2026-05-10
> **Question:** есть ли в Claude Code plugin marketplace spec формальный механизм «плагин X требует плагин Y» (peer-dep аналог)?

## Headline finding

**Да — формальный механизм есть.** Claude Code (v2.1.110+) поддерживает массив `dependencies` в манифесте плагина с semver-ограничениями, авто-резолюцию при install, cross-marketplace allow-list и определённую таксономию ошибок. Команда `claude plugin prune` для cleanup'а — с v2.1.121+.

## Что доступно

- **Где объявлять.** В `.claude-plugin/plugin.json` плагина или в записи плагина в `marketplace.json`.
- **Синтаксис.** Bare-string `"audit-logger"` или объект `{ "name": "...", "version": "~2.1.0", "marketplace": "..." }`. `version` принимает любой диапазон Node `semver` (caret, tilde, hyphen, comparator).
- **Install-time поведение.** При установке плагина с зависимостями Claude Code резолвит и устанавливает их автоматически, выводит список добавленного. Если зависимость потом исчезнет, `/reload-plugins` и фоновый авто-update её переустанавливают (если marketplace зависимости уже добавлен пользователем).
- **Cross-marketplace.** По умолчанию Claude Code **отказывается** автоматически устанавливать зависимость из чужого marketplace. Чтобы разрешить, корневой `marketplace.json` должен перечислить имя соседа в `allowCrossMarketplaceDependenciesOn`. Доверие не chain'ится — смотрится только корневой allowlist. Если поле отсутствует, install падает с `cross-marketplace` error.
- **Tag convention.** Резолюция версий — по git-тегам формата `{plugin-name}--v{version}`. CLI `claude plugin tag --push` генерирует и валидирует, что `plugin.json` и запись в marketplace согласованы.
- **Constraint intersection.** Когда несколько плагинов ограничивают одну и ту же зависимость, диапазоны пересекаются; конфликты — `range-conflict`, `no-matching-tag`.
- **Cleanup.** Auto-installed deps переживают uninstall того, кто их затащил; `claude plugin prune` собирает orphans.

## Чего нет

**Soft / recommends / optional tier — отсутствует.** Только два состояния: `dependencies` объявлены (hard, при невыполнении плагин disabled с `dependency-unsatisfied`) или не объявлены (purely informal README mention). «Warn but load anyway» mode не задокументирован.

## Adjacent findings

- `mcpServers` / `lspServers` декларируют runtime-зависимости от **внешних процессов**, не от других плагинов.
- Plugin `settings.json` может активировать собственный agent плагина (`agent` ключ), но не дотянуться до чужих плагинов.
- `--plugin-dir` / `--plugin-url` — bypass marketplace для локальной разработки.
- **Нет** ни env-var, ни runtime API, который бы дал hook-скрипту узнать, «какие ещё плагины включены». Cross-plugin runtime-awareness — non-feature; координация ожидается через dependency declaration.

## Caveats

- Документация недатирована; «v2.1.110+» — единственный version anchor.
- Whether `marketplace` field в dep-объекте принимает URL или только имя в local marketplaces config — не до конца расписано в примерах.
- Hard-dependency означает: каждый пользователь `kramar-studio-marketplace` должен иметь `archforge-marketplace` зарегистрированным и явно перечисленным в `allowCrossMarketplaceDependenciesOn`. Soft-suggest альтернативы внутри spec'а нет — это всё равно через README + runtime hook detection.

## Sources

1. https://code.claude.com/docs/en/plugin-dependencies (retrieved May 2026)
2. https://code.claude.com/docs/en/plugin-marketplaces
3. https://code.claude.com/docs/en/plugins
4. https://code.claude.com/docs/en/plugins-reference
5. https://www.schemastore.org/claude-code-marketplace.json

## Interpretation для текущего цикла

Research вводит **новую альтернативу в Design**, которой в discovery не было:

- **(E) Formal hard peer-dependency** — объявить `dependencies: ["archforge"]` в `plugin.json` с cross-marketplace allow-list. Auto-install, дисциплинированно версионируется через semver.

Но эта альтернатива **немедленно вырубается ответами пользователя в discovery**:

- **Q4 = a** (product-only — легитимный сценарий) → hard peer-dep блокирует загрузку при отсутствии archforge → продакт-only пользователь видит `dependency-unsatisfied` → нелегитимизация. Прямое противоречие.
- **Q7 = 3** (version-agnostic, file-convention detection) → формальный peer-dep требует semver constraint и git-tag дисциплины → прямое противоречие.

Также research **подтверждает**, что нет middle-ground'а в spec'е — невозможно «soft formal dep». Если хотим soft — это README + runtime detection через файловую систему. Это снимает один риск Design фазы: больше не нужно «изобретать soft formal mechanism», его попросту нет.

**Net effect.** Пространство альтернатив в Design фиксируется на двух (B и C из discovery), плюс альтернатива (E) появляется и вычёркивается с явной цитатой. Ничто в discovery не invalidated — переходим прямо в Design без второго раунда.

# Discovery: Multi-level versioning contract for the studio suite

> **Scope:** что должна означать каждая «версия» в Kramar Studio Suite (поле `version` в `marketplace.json`, поле `version` в каждом `plugin.json`, маркер `.<plugin>-version` в проекте пользователя), как они связаны между собой, как ведут себя при координированных breaking change мета-формы.
> **Source:** `decision-map.md` A2 / `ARCHITECTURE.md §6` Q1
> **Date:** 2026-05-10
> **Cycle scale:** deep (тема в ARCHITECTURE.md Open Questions; sticky решение; cross-cutting)

---

## 1. Problem statement

После ADR-0001 в одном marketplace живут два плагина: `architect` v1.0.0 и `product` v0.1.0. Над ними — `marketplace.json` с собственным полем `version: 0.1.0` (унаследованным из времени, когда product был единственным плагином). В проектах пользователей третий уровень — маркер `.<plugin>-version` (сейчас `.product-version` существует, `.architect-version` появится при первом `/architect:init` после v1.0.0).

Сегодня **никаких контрактных правил** между этими тремя уровнями нет:
- Что значит `version` у marketplace — открытый вопрос (поле в schema присутствует, но его смысл проектом не определён).
- Координированы ли версии плагинов suite между собой при изменениях мета-формы (которая по `STRATEGY.md §2` едина для всех плагинов) — не определено.
- Что считается breaking change для плагина (повод для major bump) — не зафиксировано.
- Каков формат миграций между версиями (B1 в decision-map) — формально blocks на этот вопрос: пока не известна семантика версии, формат миграционных файлов нельзя определить.

A2 — это первый upstream-вопрос, который надо закрыть, прежде чем браться за B1 (миграции) и B2 (QC, который должен ловить migration regressions). Также напрямую влияет на трек A из STRATEGY: при content-fill доводке `product` до v0.2 нужно знать, что за решение — minor bump, breaking change, координированный с architect или нет.

«Решение sticky» — однажды объявленная семантика версий становится контрактом для всех существующих и будущих пользователей. Менять её потом = breaking change на уровне «как читать ваше же `.<plugin>-version`».

## 2. Forces

| # | Сила | Куда тянет |
|---|---|---|
| F1 | Claude Code plugin spec даёт **оба** поля: `marketplace.json.version` и `plugin.json.version`. Оба существуют, оба нужно осмыслить. | Constraint: контракт обязан определить семантику обоих, а не игнорировать одно. |
| F2 | Claude Code поддерживает formal `dependencies` в plugin.json с semver-диапазонами и git-тегами формата `{plugin-name}--v{version}` (research-digest от 2026-05-10). | Если когда-нибудь будем использовать intra-suite dependencies — нужна semver-дисциплина и tag-convention. Если нет — мягче. |
| F3 | Per-plugin upgrade flow: `/<role>:upgrade` читает `.<role>-version` маркер и запускает миграции из `plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md`. | Толкает к **per-plugin semver** — миграции разворачиваются по дельте версий конкретного плагина. |
| F4 | `STRATEGY.md §2`: «одинаковая мета-форма (frontmatter с lifecycle, cross-link через `links_to`, soft hooks, сервисные команды, push-back tone) — единая для всех плагинов suite, эволюционирует синхронно». | Толкает к **координированным bumps** при изменении мета-формы; противоречит чистой per-plugin independence. |
| F5 | Solo maintainer + STRATEGY §1 «без команды на найм пока». | Минимум overhead. Контракт должен быть запоминаемым в голове, не требовать tooling для enforce. |
| F6 | Breaking changes уже произошли independently: architect 0.4.0-rc3 → 1.0.0 (rename), product остался 0.1.0 без изменений. | Validates: per-plugin semver работает. Coordinated bump бы означал product тоже стал 1.0.0 — без оснований. |
| F7 | `marketplace.json.version: 0.1.0` сегодня — фактически артефакт первого commit'а, не отражает «состояние marketplace». Никем не bump'ался последние ~3 месяца, хотя marketplace значимо изменился (поглощён архитектурный плагин). | Поле либо нужно переосмыслить, либо признать декоративным. |
| F8 | Трек A из STRATEGY (content-fill `product` до v0.2) — следующая работа. Решение по A2 будет first test применения контракта. | Срочность: контракт должен быть ясен **до** начала product-content-fill. |
| F9 | Root `README.md` заявляет статус: «architect: active (v1.0)», «product: scaffolded (v0.1)», «ops: planned (v0.3)», «security: planned (v0.4)». Это **maturity-signal** для пользователя, не строго semver. | Возможно, нужно различать «версия как контракт» (semver) и «версия как маркетинг-обещание» (maturity). |
| F10 | Будущие плагины (`ops`, `security`) появятся независимо. | Контракт должен допускать любую кадансность (один плагин bump'ает чаще, другой реже). |
| F11 | После ADR-0001 архитектурный плагин назван `architect`, но git-история v0.4.0-rc3 → v1.0.0 в нём; новые пользователи увидят 1.0.0 как «первый стабильный». Для них «1.0.0 == после rename», для архивов — «1.0.0 == первая стабильная после серии RC». | Семантика 1.0.0 разная в зависимости от того, считаем ли мы это исторически или с точки зрения нового пользователя. |
| F12 | `compound-engineering` (соседний по экосистеме плагин) идёт single semver: `3.6.1`. Ему не приходится решать multi-level вопрос — это другой shape. | Прецедент: однопакетные плагины используют чистый semver. Suite-shape — менее устоявшийся pattern. |

## 3. Constraints (что не двигается)

- **Claude Code plugin spec** — оба поля `version` (marketplace и plugin) существуют, schema их валидирует. Их нельзя удалить без слома schema.
- **`.<role>-version` маркер в проекте пользователя** — уже задействован для product (плагин и init его создают). Семантика «откуда мигрируем» — фактически уже зафиксирована.
- **append-only ADR-0001** — версия архитектурного плагина зафиксирована как `1.0.0` после rename.
- **Soft-hooks-only** — никакая часть контракта не должна enforce'иться через блокирующий хук.
- **Solo maintainer overhead** — никаких сложных механизмов synchronization, требующих CI или внешних инструментов.

## 4. Stakeholders

- **Igor (maintainer + zero-th user).** Должен запоминать контракт без референса. Платит overhead за каждый bump.
- **Будущие пользователи suite** (соло-инди по STRATEGY §3). Видят `version` поля при install и в `/<role>:upgrade` диалогах. Им важно знать, что означает «major bump» для их проекта (прерывание workflow или нет).
- **Будущие role-плагины (ops, security).** Унаследуют контракт. Если контракт неудобный, его придётся переписывать — ровно тот сценарий, который мы хотим избежать.
- **Hypothetical contributors.** STRATEGY §3 фокусируется на персональном tooling, не на open contributions. Но даже один внешний PR требует понятной политики версий.

## 5. Prior art / similar decisions

- **npm packages.** Per-package semver, нет umbrella version. Workspaces (npm/yarn) добавляют общий manifest без общей версии.
- **Cargo workspaces (Rust).** Per-crate semver. Workspace `Cargo.toml` может задать `workspace.package.version` — общий, но это **необязательная convenience**, не контракт.
- **Maven multi-module.** Parent POM может задавать общую версию через `<version>` наследуемую модулями. Часто используется для координированных releases больших фреймворков (Spring, и т.д.). Высокий overhead.
- **VS Code extensions.** Per-extension semver. Нет marketplace umbrella version (Marketplace — Microsoft-hosted, у пользователя нет своего marketplace.json).
- **Claude Code itself** (`@anthropic/claude-code`) — single semver, monorepo внутри возможно но snopypable.
- **`compound-engineering`** — single semver `3.6.1`, single-plugin (не suite). Shape другой, но иллюстрирует «single source of truth» подход.
- **Atom packages.** Похоже на VS Code, per-package, без umbrella.
- **Linux distributions** (Debian, Ubuntu) — пакеты per-package, distribution version (codename) — отдельный artifact. Параллель: marketplace.version = distribution release, plugin.version = package version.

Из всего этого: **per-plugin semver — стандарт** в подобных экосистемах. **Umbrella version — редкость**, и где встречается (Maven), это часто признано слишком тяжёлым для small projects.

## 6. Open questions

> Эти вопросы должен ответить пользователь до перехода в Research/Design. Без ответов альтернативы будут спекуляцией.

**Q1. Что должна означать `version` в `marketplace.json`?**

- (a) **Версия каталога**: bump только когда меняется структура самого `marketplace.json` или политики marketplace. Сегодня нет внешнего повода bump'ать. Чистая семантика, но скучная — почти статичная.
- (b) **Версия suite в целом**: «release stamp» когда вся suite готова к next milestone. Bump на coordinated release. `marketplace 1.0.0` = «suite ready for v1»; `0.1.0` = «suite incubating».
- (c) **Не нужна, статично**: оставить `0.1.0` навсегда (или например `1.0.0` после поглощения), не bump'ать. Поле — формальность для schema-conformance.

**Q2. Что означает `version` в `plugin.json` для каждого плагина?**

- (a) **Чистый per-plugin semver**: каждый плагин эволюционирует независимо. Major = breaking change в commands/skills/templates/artifact-format пользователя. Minor = новые фичи backward-compatible. Patch = bugfix скриптов.
- (b) **Координированный с другими плагинами**: все плагины bump'ают major одновременно, когда мета-форма меняется breaking-style.
- (c) **Гибрид**: per-plugin semver, но breaking change мета-формы документируется в CHANGELOG'ах ВСЕХ плагинов одновременно (bump major у того, кого изменение реально затрагивает; у остальных — note без bump'а).

**Q3. Что считается breaking change для плагина (повод для major bump)?**

- (a) Любое изменение, требующее пользователю запустить `/<role>:upgrade` для миграции артефактов в его проекте.
- (b) Только rename/удаление команд или skill'ов (как `/archforge:*` → `/architect:*`).
- (c) Изменение frontmatter-контракта артефактов (новое required поле, изменение enum).
- (d) Комбинация: rename commands/skills (b) ИЛИ изменение frontmatter contract (c).
- (e) Что-то другое — сформулируй своими словами.

**Q4. Какова связь `<plugin>:version` с `.<plugin>-version` маркером в проекте пользователя?**

- (a) **Они ровесники**: `.<plugin>-version` записывается ровно тем, что в `plugin.json` на момент `init` или последнего успешного `upgrade`. Позволяет команде `upgrade` точно знать «откуда мигрируем».
- (b) **Маркер — отдельная семантика**: «версия артефактного контракта в этом проекте». Может расходиться с plugin.json (например, plugin v1.0.1 patch-bump без миграций — маркер остаётся 1.0.0).
- (c) **Маркер — major.minor только**: patch level не фиксируется (`.architect-version` содержит `1.0`, не `1.0.1`).

**Q5. Что делать с marketplace `version: 0.1.0` сегодня (после ADR-0001)?**

- (a) Оставить `0.1.0`, дождаться появления политики (Q1) и потом bump'ать осмысленно.
- (b) Bump до `1.0.0` сейчас как «marketplace вышел на стабильную suite-форму после ADR-0001».
- (c) Bump до `0.2.0` (minor) как acknowledgement что добавили плагин.
- (d) Удалить поле (если Q1 = «не нужна»).

**Q6. Какова политика bump'а при первом content-fill `product` до v0.2 (трек A из STRATEGY)?**

- (a) `product 0.1.0 → 0.2.0` — minor (новые шаблоны, examples, расширенный pushback в commands).
- (b) `product 0.1.0 → 1.0.0` — major (выход на стабильность; v0.1 был scaffold-experiment).
- (c) Не bump'ать сейчас, дождаться внешнего пользователя как сигнала готовности.

**Q7. Как договариваться о intra-suite dependencies между плагинами?**

Например, представь: product хочет требовать architect v1.0+ для определённого формата cross-reference в `links_to`.

- (a) **Использовать formal `dependencies` в plugin.json** (Claude Code-supported по research). Hard-блокирует install при несовместимости. Прямо противоречит ADR-0001 §Decision границам (product-only установка остаётся first-class).
- (b) **Документировать в README, не enforce'ить**. Soft-link через документацию. Совместимо с ADR-0001.
- (c) **Не допускать таких зависимостей вообще**. Каждый плагин self-contained на функциональном уровне; cross-link через `links_to: [ADR-NNNN]` остаётся file-convention-based и не требует version-pinning.

**Q8. Что с README статусом «active (v1.0)», «scaffolded (v0.1)», «planned (v0.3)»?**

- (a) Это **maturity-signal**, отдельный от semver: «active», «scaffolded», «planned» — это словесный статус. Версия в скобках — для маркетинга. Контракт версии (Q2) — отдельно.
- (b) Это **proxy для semver**: scaffolded < 1.0.0; active >= 1.0.0; planned не имеет версии. Maturity и semver совпадают.
- (c) Убрать версии из README статусов (оставить только active/scaffolded/planned), чтобы не путать с semver.

## 7. What's NOT in scope of this discovery

- Формат миграционных файлов (`plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md`). Это B1 — отдельный цикл, blocks на A2.
- Quality control approach (B2 в decision-map) — отдельный цикл, blocks частично на A2 (правила QC включают migration-regression checks).
- Hook execution environment contract (B3) — независим.
- Skill-count threshold (C1) — независим.
- Cross-role workflow внутри suite (D4) — частично связан (cross-link между плагинами может использовать `dependencies`-механизм если Q7=a), но в рамках этого цикла трогать не будем.
- Telemetry / install metrics — отложено.

## 8. Initial bias

Без ответов user'а — мой текущий honest-read склоняется к:

- **Q1 = (c) или (a):** marketplace.version оставить статичным или редко-меняемым. Suite-version как координированное обещание (b) — overhead без выгоды для solo-maintainer.
- **Q2 = (a):** чистый per-plugin semver. Сегодняшняя реальность это уже так. Координированный bump (b) бы заставил product перепрыгнуть с 0.1.0 на 1.0.0 без content-fill — фальшивый сигнал стабильности.
- **Q3 = (d):** rename commands/skills ИЛИ изменение frontmatter contract — обе требуют major. Это объясняет, почему architect 0.4.0 → 1.0.0 (rename) был major bump.
- **Q4 = (a):** маркер фиксирует exact plugin version. Простота > концептуальная чистота.
- **Q5 = (a) или (b):** оставить 0.1.0 пока, или bump 1.0.0 как stamp «после ADR-0001». Я бы (a).
- **Q6 = (a):** product 0.1.0 → 0.2.0 minor для content-fill.
- **Q7 = (b) или (c):** документировать, не enforce. Formal dependencies (a) реактивируют ту же проблему «product-only нелегитимизируется», которую закрыл ADR-0001.
- **Q8 = (a):** maturity и semver — разные axes. Понять как именно их связать — задача для design phase.

Но это до твоих ответов. Особенно Q3 и Q7 могут существенно сдвинуть направление.

---

## Pause: жду ответов на Q1–Q8

Без них переход в Research и далее — спекуляция.

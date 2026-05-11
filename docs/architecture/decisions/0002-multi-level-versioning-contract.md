# ADR-0002: Multi-level versioning contract для Kramar Studio Suite

- **Date**: 2026-05-10
- **Status**: Accepted
- **Authors**: Igor Kramar
- **Roast trail**: [`docs/architecture/reviews/2026-05-10-roast-multi-level-versioning/`](../reviews/2026-05-10-roast-multi-level-versioning/) (5 ролей + META-REVIEW; findings интегрированы по выбору пользователя)

## Context

После [ADR-0001](./0001-absorb-archforge-into-kramar-studio-marketplace.md) в одном marketplace живут два плагина: `architect` v1.0.0 и `product` v0.1.0. Над ними — `marketplace.json` с собственным полем `version: 0.1.0` (унаследованным со времени, когда `product` был единственным плагином). В проектах пользователей третий уровень — маркер `.<plugin>-version`. Никаких контрактных правил между этими тремя уровнями не было.

A2 (этот вопрос) — первый upstream-блок для B1 (формат миграций), B2 (quality control) и трека A из STRATEGY (content-fill product). Решение sticky: один раз объявленная семантика версий становится контрактом для всех существующих и будущих пользователей.

Discovery surface'ил 8 вопросов (`docs/architecture/research/2026-05-10-multi-level-versioning-contract-discovery.md`); пользователь дал ответы; три натяжения (Q3 vs Q6, Q1 vs Q5, Q7 vs ADR-0001 boundaries) были разрешены как coordinator-recommendations. Research (`docs/architecture/research/2026-05-10-multi-level-versioning-contract-research.md`) показал industry default — independent versioning per package + lightweight umbrella manifest (Changesets, Cargo workspaces, Lerna independent), и что Claude Code marketplaces — пока новая территория без устоявшихся conventions для marketplace-level versioning.

Design дал 3 альтернативы (Alt A — per-plugin + marketplace-as-suite-stamp; Alt B — per-plugin + marketplace-as-schema-version; Alt C — Cargo workspace-style с inheritance). Пользователь выбрал Alt B (industry-aligned, не deliberately diverges от mainstream).

Roast (5 ролей) добавил критерии применимости и worked examples; этот ADR интегрирует их.

## Decision

Принимаем **versioning контракт Kramar Studio Suite по семи правилам ниже**.

### Правило 1. Per-plugin independent semver

Каждый плагин в `plugins/<role>/.claude-plugin/plugin.json` имеет своё поле `version` и эволюционирует независимо. Major / minor / patch — стандартный SemVer-2.0.0.

Плагины **не связаны lockstep'ом**: bump одного плагина не требует bump'а другого, даже если они в одном marketplace. Это совпадает с industry default (Cargo workspaces без shared version, Changesets independent mode, Lerna independent, VS Code extensions, npm packages).

### Правило 2. `marketplace.json.version` = manifest schema / curation policies version

`marketplace.json.version` отражает **версию структуры самого `marketplace.json`** или политик marketplace, **НЕ aggregate suite stability**.

**Bump marketplace.version при:**
- Добавлении / удалении top-level поля в `marketplace.json` (например, новый `metadata`-блок).
- Изменении convention обнаружения плагинов (например, путь `plugins/<name>/` сменился на что-то другое).
- Введении / удалении marketplace-wide policy (например, требование «все плагины должны иметь `CHANGELOG.md`»).

**НЕ bump marketplace.version при:**
- Добавлении / удалении записи в массиве `plugins[]` (это изменение версии соответствующего плагина, не marketplace).
- Изменении `description` или `keywords` плагина внутри marketplace.json.
- Изменении версии любого внутреннего плагина.

Текущее состояние: после ADR-0001 marketplace.json получил вторую запись в `plugins[]`, но структура поля и convention обнаружения не изменились → `marketplace.json.version` остаётся `0.1.0`.

**Suite-stamp нужда (если возникнет в будущем — «Kramar Studio Suite v1.0 ready» как narrative milestone) живёт в README badge или STRATEGY note, НЕ в `marketplace.json.version`.** Это две разные сущности: schema-version и marketing-stamp; сегодня смешивать их нельзя, потому что schema-version используется для machine-driven decisions (например, cross-plugin tooling может branch по marketplace.version), а marketing-stamp — для human-readable.

### Правило 3. `.<plugin>-version` маркер ровно повторяет `plugin.json.version`

Маркер `.<plugin>-version` в проекте пользователя содержит **ровно SemVer-string** (никаких дополнительных полей, никаких комментариев). Записывается в момент `init` или последнего **успешного** `upgrade`. Совпадает один-в-один с `plugin.json.version` плагина в момент записи.

**Пользователь может `.gitignore`-ить маркер**; в этом случае `/<role>:upgrade` при отсутствии маркера предлагает recovery flow (re-init или manual version specification), но **не падает**. Маркер — не mandatory artifact, а удобная convention.

**Atomicity rule** (закрывает A-3 / J-7 / P-3 из roast): маркер обновляется **атомарно с применением последней миграции в `/<role>:upgrade`**. Если миграция упала на полпути — маркер **остаётся на pre-upgrade значении**. Migration script обязан реализовать это поведение (в B1 цикле формат миграций будет специфицирован соответственно).

**Существующие `.archforge-version` маркеры** (от пользователей, у которых был установлен `archforge` до ADR-0001 переименования в `architect`): `/architect:upgrade` при первом запуске должен (a) детектировать `.archforge-version`, (b) запросить пользователя об автоматической миграции маркера, (c) при согласии — записать `.architect-version` ровно с тем же содержимым и удалить `.archforge-version`. Это zero-cost transition path для existing users.

### Правило 4. Что считается breaking change для плагина

Major bump (X.0.0) обязателен при любом из следующих:

**Functional breaking:**
- **Rename / remove contribution points**: команды (`/<plugin>:cmd`), skills, sub-agents, hooks. **Включает rename namespace плагина** (как `/archforge:*` → `/architect:*` в ADR-0001 — это был валидный major bump).
- **Change input schema** для command (изменение `argument-hint`, обязательных аргументов, expected formats).
- **Change frontmatter contract артефактов**: новое **required** поле; изменение enum value (`status: draft|active|...` → добавление/удаление значения); переименование template-prescribed section header (`## Success metric`, `## Acceptance criteria`, `## Verdict` и подобных — они verbatim per template, переименование = breaking).
- **Удаление артефактного типа** или его lifecycle status'а.

**Security-relevant** (закрывает C-1 из roast — minimum minor с явной CHANGELOG-пометкой):
- Изменение содержимого hook-shell-скриптов в `scripts/`.
- Добавление новых external network endpoints (новый `WebSearch` к домену, новый curl).
- Изменение списка required Claude Code permissions / tool surface.

Эти изменения — **минимум minor bump** (не обязательно major), но **обязательно с CHANGELOG sub-блоком `### Security-relevant`**, который downstream может grep'ать.

**НЕ breaking** (internal refactor с preserved behavior):
- Rewording system prompt в `SKILL.md` при сохранении behavior (см. honest-acceptance ниже про LLM behavior).
- Refactor bash в hook scripts при сохранённом stderr-output и exit-code-семантике.
- Добавление **optional** поля в frontmatter (без изменения существующих).
- Добавление новой команды / skill'а / agent'а / hook'а (это minor, не major — расширение, не breaking).

**Honest-acceptance про LLM rewording** (закрывает A-4 из roast): SKILL.md — это system prompt для LLM. Behavior-equivalence у LLM-промптов **нельзя гарантировать**: переформулировка может сместить distribution выходов, изменить tone, частоту push-back. Maintainer декларирует «behavior preserved» по самооценке; это **honor system, не enforcement**. Пользователи, зависящие от exact формы output'а (CI grep'ы, custom hook'и), должны быть готовы к minor distribution drift'ам в minor / patch bump'ах. Это explicitly accepted риск — альтернатива (объявлять каждый rewording breaking) сделала бы любую правку SKILL.md major bump'ом и убила бы функциональную эволюцию.

### Правило 5. Символический `1.0.0` — допустимое one-time исключение

При переходе плагина из статуса `scaffolded` в `active` (см. правило 7) допустим bump до `1.0.0` даже если строго по правилу 4 bump был бы minor (например, content-fill добавил новые шаблоны и examples без breaking changes).

**Критерий применимости** (закрывает F-1 из roast — иначе через 12 месяцев становится folklore):

- ✅ Применим: первое достижение статуса `active` плагином, ранее находившимся в `scaffolded`.
- ❌ НЕ применим:
  - Между двумя `active`-релизами (после v1.0.0 — строго правило 4).
  - Для re-stabilization после major refactor (нужен честный major bump per правило 4).
  - Как marketing milestone уже-стабильного плагина (используй README badge или GitHub release notes).

**Когда применяется**, CHANGELOG entry для `1.0.0` обязан **явно** содержать строку `No breaking API changes — version reflects maturity transition (scaffolded → active)` в верхней части release entry. Это закрывает confusion downstream-аудитора (C-6 из roast), который при `0.x → 1.0.0` ожидает breaking-changes list и не находит.

**Текущее состояние:** у `architect` исключение **уже использовано** (0.4.0-rc3 → 1.0.0 per ADR-0001 — впрочем, это было также честно major по правилу 4, rename — два смысла совпали). У `product` 0.1.0 — **исключение ещё доступно** (рекомендован к использованию при content-fill в треке A из STRATEGY). У будущих `ops` v0.4 → 1.0.0 и `security` v0.4 → 1.0.0 — каждый стартует с своего scaffolded и может использовать исключение один раз.

**Процедура перехода scaffolded → active** (закрывает J-4 из roast):
- Один PR с тремя синхронными изменениями: (a) `plugins/<role>/.claude-plugin/plugin.json` `version → 1.0.0`, (b) root `README.md` таблица плагинов: статус `scaffolded → active (v1.0)`, (c) `plugins/<role>/CHANGELOG.md` (создать если не существует) с release entry.

### Правило 6. `dependencies` field в `plugin.json` не используется

Поле `dependencies` (Claude Code spec, [code.claude.com/docs/en/plugin-dependencies](https://code.claude.com/docs/en/plugin-dependencies)) формально поддерживается, но в плагинах Kramar Studio Suite **сегодня не используется**.

**Why not formal dependencies** (закрывает F-3 / J-6 из roast — превращает absence в обоснованный absence):

1. **Product-only first-class** ([ADR-0001](./0001-absorb-archforge-into-kramar-studio-marketplace.md) Q4=a): пользователь должен мочь поставить `product` без `architect` и наоборот. Hard peer-dep сделал бы установку одного плагина зависимой от наличия другого — прямое противоречие с ADR-0001 boundaries.
2. **File-convention достаточен**: cross-link через `links_to: [ADR-NNNN]` работает по факту наличия файла в `docs/architecture/decisions/`, безотносительно установленности плагина или его версии. Это version-agnostic detection (ADR-0001 Q7=3).
3. **Spec не имеет soft-tier**: research 2026-05-10 ([digest](../research/2026-05-10-cross-marketplace-dependency-posture-research.md)) подтвердил, что Claude Code spec поддерживает только hard `dependencies` — soft / recommends / optional tier отсутствует. Использовать hard для нашего случая — нелегитимизация product-only.

**Cross-link при отсутствии target-файла** (закрывает J-6 edge case): если `links_to: [ADR-NNNN]` указывает на несуществующий файл, hook'и плагина-source эмитят soft warning при `Edit`/`Write` с подсказкой «add the link, or explain in body why no ADR applies». Это уже реализовано в `product/scripts/check-product-artifact.sh` для PRD'ов, ссылающихся на SCAN'ы (тот же паттерн; см. fallback в скрипте).

**Trigger для пересмотра** (когда переоткроется этот вопрос отдельным циклом): появление **конкретного use case** — например, `security` плагин структурно нуждается в `architect`-ADR-формате для threat-modeling links — с описанием почему cross-reference через `links_to` недостаточен. До этого момента — `dependencies` остаётся unused.

### Правило 7. README maturity-signal — proxy для semver

Статус плагина в root `README.md` таблице — **proxy для semver**:

| Статус | Semver-диапазон | Что значит |
|---|---|---|
| `planned` | без version | Плагин ещё не создан (нет директории `plugins/<name>/`) |
| `scaffolded (v0.x)` | `0.x.y` | Плагин существует, эволюционирует, не объявлен стабильным |
| `active (v1.0+)` | `≥ 1.0.0` | Стабильный API; breaking changes проходят через major bump |

**Между `scaffolded` и `active` промежуточных статусов нет.** Плагин на `0.9.0` всё ещё `scaffolded`. Переход в `active` = либо естественный 1.0.0 от breaking change (правило 4), либо one-time symbolic 1.0.0 (правило 5).

**При расхождении** (drift между README и `plugin.json.version` — например, bump до 1.1.0 без обновления README) **binding considered `plugin.json.version`**. README maturity — informational; binding signal — manifest. Это закрывает C-4 из roast про competing truth sources.

### Правило 8 (мета-правило). CHANGELOG как обязательный audit-trail

Каждый плагин обязан вести `plugins/<role>/CHANGELOG.md` в [Keep-a-Changelog](https://keepachangelog.com/en/1.1.0/) формате. Каждый bump (`plugin.json.version` change) обязан соответствовать release entry в CHANGELOG'е.

**Sub-блоки CHANGELOG entry** для упрощения downstream-аудита:
- `### Changed (BREAKING)` — для breaking changes per правило 4.
- `### Changed` — для backward-compatible изменений.
- `### Added` / `### Removed` / `### Fixed` — стандартные.
- `### Security-relevant` — обязательный sub-блок при изменениях из правила 4 «Security-relevant» категории.
- `### Frontmatter changes` (опциональный) — при изменении frontmatter contract; перечислить affected fields.
- `### Migration from <prev-version>` — при breaking changes; шаги для пользователя.

Это закрывает C-5 из roast про CHANGELOG как audit-trail.

---

### Worked examples

**Пример 1: content-fill `product` 0.1.0 → ?** (закрывает J-8 + Q6 из discovery).

Igor наполняет `plugins/product/`: реальные шаблоны с worked examples, фильтрация cycle-failure-modes, расширенный pushback в command-файлах, переписанные SKILL.md без поведенческих изменений.

Анализ по правилам:
- **Правило 4**: rename contribution points? Нет. Change input schema? Нет. Change frontmatter contract? Нет (только optional поля и enrichment prose). Security-relevant? Нет. → **Не breaking, должен быть minor (0.1.0 → 0.2.0)**.
- **Правило 5**: переход scaffolded → active? Если Igor готов объявить product `active` (готов к external use, стабильное API команд) — да. → **Опционально символический 1.0.0**.
- **Правило 7**: если 1.0.0 — README статус `scaffolded → active (v1.0)`. Если 0.2.0 — статус остаётся `scaffolded (v0.2)`.
- **Правило 8**: CHANGELOG entry обязательно. Если 1.0.0, верхняя строка release entry: `No breaking API changes — version reflects maturity transition (scaffolded → active)`.

**Рекомендация для треке A из STRATEGY:** использовать символический 1.0.0. Content-fill — естественный момент «scaffolded → active»; исключение для product ещё доступно; маркетинг-сигнал «product ready» ценен.

**Пример 2: добавление `ops` плагина с нуля** (закрывает J-8 + frontends для `ops` v0.3 в STRATEGY).

Igor scaffold'ит `plugins/ops/` с минимальными командами и skills. Это **новый плагин** (не bump существующего).

Анализ по правилам:
- **Правило 1**: новый `ops/.claude-plugin/plugin.json` начинается с `version: 0.1.0`.
- **Правило 2**: запись в `marketplace.json.plugins[]` добавляется, но структура `marketplace.json` не меняется → `marketplace.version` остаётся `0.1.0`.
- **Правило 7**: README — добавляется строка `| **\`ops\`** | scaffolded (v0.1) | ... |`.
- **Правило 8**: создаётся `plugins/ops/CHANGELOG.md` с initial entry `## [0.1.0] — YYYY-MM-DD — Initial scaffold`.
- **Правило 6**: `dependencies` не объявляется (нет конкретного use case для hard peer-dep на architect/product).

После содержательной доводки `ops` — те же опции что product (правило 5 — символический 1.0.0 доступен).

---

## Consequences

### Easier

- **B1 (Migration format and procedure) разблокирован.** Теперь известна семантика версий: миграции — дельты между двумя `plugin.json.version` значениями. Формат файлов миграции (`plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md`) описывается тривиально — берём ту же semver-диктовку, плюс правило 3 atomicity. Это unblocks отдельный цикл по B1.
- **B2 (Quality control without CI) частично разблокирован.** QC должен ловить version-marker drift (`.architect-version` ≠ `plugin.json.version` после upgrade) и три-place-sync drift (правило 7 binding precedence). Это unblocks scope для отдельного цикла по B2.
- **Track A из STRATEGY (content-fill product) имеет explicit version answer.** Worked example 1 даёт прямое решение: minor 0.1.0 → 0.2.0 ИЛИ символический 1.0.0 (по выбору maintainer'а; рекомендован 1.0.0).
- **`architect 1.0.0` consistent с правилами.** Текущее состояние плагина (после ADR-0001) валидно по двум независимым путям: rename = breaking per правило 4 → major bump; и одновременно scaffolded → active per правило 5. Два смысла совпали — это легитимизирует текущий tag без post-hoc нарративов.
- **Forward-compat для ops, security.** Каждый новый role-плагин стартует с `0.1.0`, может использовать символический 1.0.0 один раз, эволюционирует независимо. Никакого предварительного решения о связи ops ↔ architect / product не требуется.

### Harder

- **Honor system без enforcement (P-1 / P-6 из roast).** Все 8 правил поддерживаются ручной дисциплиной. Без CI — кто заметит нарушение? **Никто, до момента когда внешний пользователь наткнётся.** Это accepted риск; mitigation — будущий tooling (см. ниже Risks).
- **Cross-plugin coordination не предусмотрен** (F-4 из roast). Контракт работает для 2 плагинов; при достижении 4 (ops, security) с накопленной историей мета-форм breaking changes появятся сценарии «один плагин эволюционирует мета-форму первым, остальные обязаны догнать». Сейчас у нас нет процедуры координации.
- **`marketplace.json.version` становится почти статичным.** Bump'ы редкие и понятные, но это означает — поле может казаться «застывшим» для внешнего наблюдателя. Решение: explicit acceptance что для marketing-stamp используется README badge, не version field.
- **Sub-agent surface — partial coverage в правиле 4.** Sub-agent rename/remove перечислен в Functional breaking. Но изменение **поведения** sub-agent'а (например, system prompt rewording) попадает под honest-acceptance про LLM rewording — то есть **не breaking** даже для sub-agent'а. Это допустимое размытие, но downstream может ожидать строжей семантики. Принято, mitigation — Security-relevant CHANGELOG sub-блок для sub-agent изменений с tool-surface impact.

### Risks accepted

- **Operational discipline без enforcement.** Maintainer может забыть bump, забыть обновить README, написать non-conformant CHANGELOG. До появления tooling (см. ниже) — каждое нарушение silent. **Mitigation trigger**: если через 12 месяцев External adoption signal (STRATEGY §4) остаётся нулевым — открыть цикл «is the versioning contract carrying its weight». Если adoption signal двинется вверх — открыть цикл «нужен ли check-versions.sh tooling-слой» (out of scope этого ADR; pragmatist (P-7) предложил конкретный shape).
- **Three-place-sync drift** (`plugin.json` ↔ `CHANGELOG.md` ↔ `README.md` table). Принято: `plugin.json.version` = binding source-of-truth (правило 7). README + CHANGELOG могут отстать; binding precedence явный. Через год без tooling drift вероятен — mitigation вместе с предыдущим пунктом.
- **LLM behavior drift при SKILL.md rewording.** Принято explicit (правило 4 honest-acceptance). Альтернатива (объявлять breaking) сделала бы любую правку major bump'ом.
- **`marketplace.json.version` как marketing channel** заблокирован. Если в будущем кто-то ожидает «marketplace v1.0 launch event» — указатель на README badge. Принято.
- **Решение sticky.** Изменение семантики маркера, breaking-definition'а, или dependency-policy потребует миграцию в чужих проектах. Эту цену мы платим за consistency. Mitigation:
  - **Триггер для cross-plugin coordination cycle** (закрывает F-4): первый мета-форм breaking change, затрагивающий ≥ 2 active плагина одновременно — открывает новый цикл по cross-plugin coordination protocol.
  - **Триггер для contract revision cycle** (закрывает F-6): через 12 месяцев — обязательная ревизия контракта вместе с STRATEGY review (квартально).
  - **Триггер для dependencies revisit** (закрывает F-3 / J-6): появление конкретного use case (плагин нуждается в hard peer-dep) — отдельный цикл по dependencies policy.
- **Маркер `.<plugin>-version` становится anchor** с момента первого внешнего пользователя (закрывает F-5). Изменение семантики маркера потребует `/<role>:upgrade` миграции в чужих проектах. До B1 (migration format) менять не рекомендуется.
- **Frontmatter migration safety** — правило 4 объявляет «change frontmatter contract = breaking», но миграционные backups и audit-emit'ы — out of scope этого ADR (закрывается в B1). Compliance-импликация (C-3 из roast): для downstream'а с regulated content (PII в PRD'ах под GDPR) migration script должен писать backup перед mutation. Это требование к B1 формату.

## Alternatives considered

### 1. Alt A — Per-plugin semver + marketplace.version как «suite-stability stamp»

`marketplace.json.version` bump'ается при координированных suite-релизах (например, когда оба плагина достигают 1.0.0 → marketplace тоже 1.0.0). Прямая интеграция первоначальных user-ответов на discovery (Q1=b).

**Сильные стороны:** интуитивно — marketplace.version отражает «состояние suite». Меняется visible активность.

**Слабые стороны:** deliberate divergence от industry default (Cargo workspaces намеренно не используют workspace version; VS Code marketplace не versioned). Семантика «aggregate stability» инфорсится maintainer'ом, не tooling'ом — drift'нёт у solo-setup. Через 12 месяцев maintainer не вспомнит, когда bump'ать.

**Почему проиграл:** research 2026-05-10 показал, что industry sustained прецедента «aggregate version» нет. Solo-maintainer cost не оправдывает выгоду.

### 2. Alt C — Cargo workspace-style: shared default + per-plugin override

`marketplace.json.version` = default version; каждый `plugin.json` может override локально через convention. Inheritance pattern из Rust Cargo workspaces.

**Сильные стороны:** elegant industry-pattern. Координированный bump по умолчанию + escape valve.

**Слабые стороны:** Claude Code spec не поддерживает inheritance — каждый `plugin.json` обязан иметь свой `version` field per schema. «Inheritance» нужно реализовать вручную как convention (нет tooling). Solo-maintainer cost: помнить, какой плагин «inheriting» а какой «override», эквивалентно overhead'у Alt A.

**Почему проиграл:** требует custom convention поверх spec'а; реальная экономия overhead'а нулевая для solo.

### 3. Alt D (explicitly-not-considered) — Lockstep / Lerna fixed mode

Все плагины bump одновременно, всегда совпадают.

**Почему отвергнуто:** product 0.1.0 → 1.0.0 без content-fill — фальшивый сигнал стабильности. Q2=a discovery и industry research (Lerna fixed-pain «major change в одном = major во всех») explicitly против. Подходит маркетинговым groups (UI library suites), не нашему loosely-coupled случаю.

### 4. Alt E (explicitly-not-considered) — Single global version

Одна version на весь suite, плагины — внутренние модули.

**Почему отвергнуто:** architectural shift bigger than ADR-0001. Требует переосмысления что вообще такое «плагин» в suite. Out of scope.

### 5. Alt F (explicitly-not-considered) — Calendar Versioning (CalVer)

`2026.05.10` instead of semver.

**Почему отвергнуто:** разрывает связь с пользовательской mental model «major bump = что-то ломается». Не подходит для plugin ecosystem, где Q3=d / breaking-tracking важен.

### 6. Status quo / do nothing

Оставить как есть — нет формального контракта, каждое решение ad-hoc.

**Почему проиграл:** A2 — explicit upstream block для B1 (формат миграций) и B2 (QC). Без формальной семантики версий — миграционный формат не определить, регрессии не ловить. Решение «не решать» = решение в пользу drift'а.

---

## Implementation status

ADR принят. **Никакого кода не требуется менять немедленно** — контракт фиксирует правила, существующие плагины уже соответствуют (`architect` v1.0.0 валиден по двум независимым путям; `product` v0.1.0 валиден как scaffolded).

**Что меняется немедленно** (в этой же сессии, как часть Document phase):
1. `ARCHITECTURE.md §5` — добавить запись ADR-0002 в decision index.
2. `ARCHITECTURE.md §6` — закрыть Q1 ссылкой на ADR-0002.
3. `docs/architecture/decision-map.md` — A2 → `decided` со ссылкой на ADR-0002; B1, B2 unblocks.

**Будущие изменения** (триггерятся естественной работой по STRATEGY):
- При первом content-fill `product` (трек A) — `product 0.1.0 → 1.0.0` через символический bump per правило 5; обновление README статуса; создание `plugins/product/CHANGELOG.md` (не существует сегодня); release entry с обязательной строкой `No breaking API changes — version reflects maturity transition`.
- Перед scaffold'ом `ops` (трек B v0.3) — рассмотреть нужду в `check-versions.sh` tooling (P-7 mitigation); это отдельный цикл если будет нужен.
- При первом `/architect:init` или `/architect:upgrade` у пользователя с существующим `.archforge-version` — добавить migration prompt в `architect/commands/upgrade.md` (правило 3 transition path для existing users). Это не блокирует ADR, но должно быть добавлено в `architect/commands/upgrade.md` content-fill при первом удобном случае.

**Из B1 цикла (когда он будет запущен) ожидается:**
- Migration script format, поддерживающий правило 3 atomicity (маркер обновляется атомарно с last migration; partial-failure → маркер на pre-upgrade значении).
- Frontmatter migration safety (backup перед mutation per C-3 из roast).
- Multi-version jumps handling.

## Связанные артефакты

- **Discovery:** [`docs/architecture/research/2026-05-10-multi-level-versioning-contract-discovery.md`](../research/2026-05-10-multi-level-versioning-contract-discovery.md)
- **Research digest:** [`docs/architecture/research/2026-05-10-multi-level-versioning-contract-research.md`](../research/2026-05-10-multi-level-versioning-contract-research.md)
- **Roast trail:** [`docs/architecture/reviews/2026-05-10-roast-multi-level-versioning/`](../reviews/2026-05-10-roast-multi-level-versioning/) — 5 ролей (`devil-advocate`, `pragmatist`, `junior-engineer`, `compliance-officer`, `futurist`) + `META-REVIEW.md`. ~30 findings; 11 интегрированы в этот ADR per coordinator-recommendation.
- **Upstream ADR:** [`ADR-0001`](./0001-absorb-archforge-into-kramar-studio-marketplace.md) — определяет границы (product-only first-class, file-convention cross-link), на которые опирается правило 6 (no formal dependencies).
- **Decision-map entry:** [`docs/architecture/decision-map.md`](../decision-map.md) — A2 (это решение), B1 (unblocked), B2 (частично unblocked).
- **STRATEGY context:** [`STRATEGY.md`](../../STRATEGY.md) §2 (мета-форма единая → контракт не требует lockstep), §5 трек A (content-fill product как первый use case символического 1.0.0).
- **Claude Code plugin spec:**
  - [Constrain plugin dependency versions](https://code.claude.com/docs/en/plugin-dependencies)
  - [Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- **External references:**
  - [SemVer 2.0.0](https://semver.org/) — основа правил 1, 4, 5.
  - [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) — формат CHANGELOG (правило 8).
  - [Cargo Book — Workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html) — closest industry analog для правила 2.

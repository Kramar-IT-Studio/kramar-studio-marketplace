---
name: kramar-studio-marketplace
last_updated: 2026-05-10
---

> **Note (2026-05-10, ADR-0001):** §2 переформулирована после поглощения `archforge` в этот marketplace. До ADR-0001 marketplace позиционировался как companion к внешнему `archforge-marketplace`; после — как **единая studio-suite роль-плагинов**, эволюционирующая под одним maintainer'ом. Подход остался тем же по существу (та же мета-форма, та же ставка); изменилось structural-positioning.


# kramar-studio-marketplace Strategy

## Target problem

Соло-разработчик в студии без найма опирается на Claude Code как на исполнителя ролей (продакт, архитектор, ops, security), но без прописанной методологии, цикла, саморевью и опоры на предыдущие артефакты выход получается generic. Без структуры Claude отвечает поверхностно, без прожарки решений и без преемственности между сессиями — контр-пример: `archforge` и `compound-engineering`, где цикл + артефакты заметно поднимают качество.

## Our approach

Строим **единую Kramar Studio Suite** — все роль-плагины в одном marketplace, под одной мета-формой, с синхронной эволюцией. Мета-форма (наследована от первой реализации в `archforge`, теперь поглощённого по [ADR-0001](./docs/architecture/decisions/0001-absorb-archforge-into-kramar-studio-marketplace.md)) одинакова у всех плагинов: структурный контракт цикла (фазы как slash-команды), frontmatter с lifecycle (`draft → active → accepted | superseded | archived`), cross-link через `links_to`, soft hooks (никогда не блокируют), сервисные команды `init` / `upgrade` / `status`, push-back tone. Ставка: компаундирующую нагрузку держит мета-форма, а не содержимое — кто получил эффект цикла + артефактов от `architect` для архитектуры, тем же путём получит его для продакта, ops, security. Каждый плагин в suite устанавливается независимо (`/plugin install <name>@kramar-studio-marketplace`); cross-link между артефактами работает по файловой конвенции, без semver- или install-coupling.

*Что это исключает:* собственный формат frontmatter/lifecycle на каждую роль; жёсткие CI-гейты через хуки; «универсальный комбайн на все роли сразу» (плагины остаются раздельными внутри одного marketplace); роль-плагин без `init`/`upgrade`/`status`; мета-форма, которая дрейфует между плагинами.

## Who it's for

**Primary:** Соло-инди или маленькая студия, в которой каждый работник — универсальный игрок, готовый одновременно носить несколько ролей. Они нанимают плагины, чтобы разгрузить голову от методологий, выпускать артефакты и код продакшн-уровня без лишней когнитивной нагрузки и значительно ускорить цикл производства.

## Key metrics

- **Cycle completeness (own)** — доля feature/decision в собственных проектах с полной цепочкой артефактов (HYP→PRD→SPEC→VAL для product; Discover→…→Review для archforge). Цель: ≥80%. *Lagging, квартально, измеряется через `/<role>:status`.*
- **Time-to-PRD / Time-to-ADR** — часы от появления идеи до accepted артефакта со `success_metric` или decision. Цель: <X часов на feature среднего размера (X не калиброван — определяется после первой baseline-серии). *Leading, еженедельно, ручной замер.*
- **External adoption signal** — не stars/clones, а число *вторых* запусков `/<role>:cycle` от внешнего пользователя (прокси: GitHub Issues/Discussions/PR от не-Igor, mentions в чужих README). *Lagging, квартально. Aspirational — без инструментирования; начинаем с qualitative read раз в квартал.*

## Tracks

### A. Зрелость `product`-плагина

Доводка v0.1-scaffold до v0.2-content: реальные шаблоны с worked examples, фильтрация cycle-failure-modes, наполнение pushback-логики, первые миграции.

_Why it serves the approach:_ без content-fill мета-форма пустая — пользователь читает «PRD без `success_metric` — не PRD», но не видит, как именно плагин блокирует слабый ответ.

### B. Расширение по ролям

Новые роль-плагины из roadmap: `ops` (v0.3), `security` (v0.4) — каждый по той же мета-форме.

_Why it serves the approach:_ доказывает, что shape переносится на не-архитектурные роли. Один плагин — это «archforge с другим именем»; два-три — это validation основной ставки.

### C. Зрелость мета-формы

Закрытие архитектурных вопросов из `ARCHITECTURE.md §6`: двухуровневое версионирование, формат миграций, cross-marketplace-зависимость на `archforge`, quality control без CI.

_Why it serves the approach:_ мета-форма сама — это контракт; пока в ней дыры (нет процедуры миграций, нет ответа «что если archforge не установлен»), все треки A/B стоят на болоте.

### E. External-adoption surface

README, walkthrough'и, демо-репозитории, посты, presence на горизонтах «соло-инди»-persona.

_Why it serves the approach:_ §4 выделил external-adoption как одну из трёх метрик; без этого трека метрика остаётся нулевой по техническим причинам, а не по делу.

> ⚠️ **Coherence note (revisit on next `ce-strategy` run):** треки A/B/C/E — все про building. Метрики *Cycle completeness* и *Time-to-PRD* требуют dogfooding, которое в треках явно не названо — считается имплицитно живущим внутри (A). Если на следующем run выяснится, что эти метрики не двигаются, это сигнал поднять dogfooding в отдельный трек или вместо одного из существующих.

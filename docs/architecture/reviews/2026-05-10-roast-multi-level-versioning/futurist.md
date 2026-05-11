# Futurist: multi-level versioning contract для Kramar Studio Suite

**Target**: pre-ADR proposal, A2 в decision-map (multi-level versioning contract)
**Date**: 2026-05-10
**Horizon**: 1–3 года (до ~2028-Q2)
**Confidence note**: Structural drift findings — высокая уверенность; trend findings — спекуляция с явно названными сигналами.

## Summary

Контракт хорошо выбран для текущего состояния (2 плагина, solo-maintainer, ноль внешних пользователей), и базовое решение «per-plugin semver + плоский marketplace без version-coupling» с большой вероятностью переживёт 2 года без переделки. Основной long-horizon риск — это не семантика версий сама по себе, а **три «джентльменских соглашения»**, которые сегодня держатся в голове Igor'а: символический 1.0.0, «marketplace.json.version = manifest schema», и «dependencies не используется». Через 2 года при наёме junior'а, возвращении после паузы, или появлении 4+ плагинов с разной кадансностью, эти три места превращаются в folklore knowledge — каждое требует «почему так а не иначе»-объяснения, которое сейчас негде прочитать. Spec Claude Code за 2025 ускорил эволюцию dependency-механики (semver-tag resolution, lockfile auto-install — см. trend findings); решение «не используем» через 2 года будет либо принципиальной позицией с обоснованием, либо «мы это пропустили».

---

## Structural findings — high-confidence

### F-1: «Символический 1.0.0» становится folklore knowledge через ~12 месяцев

**Type**: codebase aging / team

**Horizon**: 6–12 месяцев — момент, когда (а) появляется второй maintainer / contributor, ИЛИ (б) Igor возвращается после 6+ месячного перерыва от architect-плагина.

**The drift**: Пункт 5 контракта («символический 1.0.0 — допустимое one-time исключение на scaffolded → active, документируется в CHANGELOG») в 2026-Q2 имеет один эмпирический пример (architect 0.4.0-rc3 → 1.0.0). Через 12 месяцев в CHANGELOG'ах появятся ≥2 случая (например, product 0.x → 1.0.0 после content-fill, потом ops 0.x → 1.0.0 после стабилизации). У каждого будет своя контекстная мотивация, забытая через полгода. Junior, читающий через 18 месяцев, увидит **паттерн** «у нас принято bump'ать на 1.0.0 при готовности» и применит его шире, чем задумано — например, к minor bump'у в CHANGELOG-стиле «релиз feature X → bump до 2.0.0». «One-time исключение» без явно названного критерия «когда применимо» культурно дрейфует в «допустимая практика».

**Mitigation in scope of this proposal**: В ADR явно зафиксировать **критерий применимости**, не только сам факт исключения. Что-то вроде: «символический bump до 1.0.0 допустим **только** при первом достижении статуса `active` плагином, ранее находившимся в `scaffolded`. Не применим: между двумя `active`-релизами, для re-stabilization после major refactor, или как marketing milestone уже-стабильного плагина». Один абзац сейчас стоит трёх эпизодов «а почему мы тогда так сделали» через год.

---

### F-2: «marketplace.json.version = manifest schema» — самая хрупкая часть контракта при росте suite

**Type**: inertia / adjacent decisions

**Horizon**: 18–24 месяца — после доезда `ops` v0.3 и `security` v0.4 + появления второго marketplace-уровневого артефакта (например, suite-wide CHANGELOG, suite-roadmap, или координированного «suite v1.0»-нарратива в README).

**The drift**: Сегодня `marketplace.json.version = 0.1.0` имеет осмысленную семантику только потому, что **manifest schema действительно не менялась**. Через 24 месяца, когда suite будет содержать 4 плагина и Igor захочет нарративно сказать «Kramar Studio Suite v1.0 ready» (внешним пользователям, в посте, в README badge'е), у него будет **два ортогональных желания**:
- bump'нуть `marketplace.json.version` как «suite stamp» (который контракт явно запрещает),
- НЕ bump'ать его как «schema не менялась» (буква контракта).

В этот момент либо контракт нарушается (и тогда его надо переписать post-hoc, breaking семантику для уже-залитых `.<plugin>-version` маркеров — хотя они marketplace-version и не читают, поэтому breaking-impact низкий), либо появляется четвёртый версионный канал (suite-роадмап в STRATEGY, отдельный от marketplace.json), что добавляет cognitive load. Причина: сегодняшняя семантика **запрещает marketing use** для поля, которое visibly изменяется и которое люди ожидают видеть как «текущее состояние marketplace».

**Mitigation in scope of this proposal**: Заранее объявить **два разных артефакта** для двух разных нужд:
- `marketplace.json.version` = **строго schema** (как уже выбрано).
- Suite-уровневое «состояние» (если когда-нибудь захочется сказать «Studio Suite ready for v1») — это **README badge / STRATEGY note**, не поле в JSON. Один параграф в ADR: «если когда-нибудь возникнет нужда в suite-stamp — он живёт в README, не в marketplace.json».

Это не добавляет сложности сейчас, но снимает будущий «куда поставить this number»-вопрос, который иначе будет решаться ad-hoc и непоследовательно.

---

### F-3: «dependencies не используется» — самое hard-to-onboard место контракта

**Type**: team / inertia

**Horizon**: 6–18 месяцев — на первом контакте кого угодно, кроме Igor, с любым плагином suite.

**The drift**: Решение «cross-link через `links_to: [ADR-NNNN]` file-convention-based» — структурно корректное (см. ADR-0001), но contract.json в `plugin.json` имеет **поле `dependencies`** в spec'е, и Claude Code 2026 активно его развивает (semver-tag resolution, lockfile auto-install — см. trend F-7). Junior, читающий контракт впервые, увидит «не используется» как **отрицательное определение** и спросит «а почему?». Сегодняшний ответ распылён по двум артефактам:
- В ADR-0001 есть отвод hard peer-dep по Q4=a (product-only first-class) и Q7=3 (file-convention, не semver).
- В A2-discovery Q7=(b/c) — те же reasoning'и в другой формулировке.

Через 12 месяцев читателю надо будет (а) прочитать оба, (б) сшить их в голове, (в) убедить себя что это deliberate, а не «Igor не дошёл». Folklore-риск максимален именно здесь, потому что это **отсутствие** функциональности, и его трудно «увидеть» в коде — оно видно только в документации.

**Mitigation in scope of this proposal**: В ADR по A2 — один параграф «Why not formal dependencies» с **тремя bullet'ами** (product-only first-class из ADR-0001; file-convention достаточен для cross-link; spec не имеет soft-tier — research-finding 2026-05-10) и явная ссылка на ADR-0001 как upstream. Это превращает «отсутствие» в «обоснованное отсутствие», которое читается линейно. **Без** этого через 18 месяцев будет ad-hoc вопрос «может, мы наконец воспользуемся?» каждый раз, когда появится новый плагин.

---

### F-4: Per-plugin independence держит до ~4 плагинов; cross-plugin coordination patterns не предусмотрены

**Type**: scale / adjacent decisions

**Horizon**: 18–30 месяцев — при достижении 4 плагинов в suite (`product`, `architect`, `ops`, `security`) с накопленной историей реальных breaking changes мета-формы.

**The drift**: STRATEGY §2 явно фиксирует: «мета-форма … эволюционирует синхронно». Контракт A2 предлагает решение через **гибрид Q2=(c)** — bump major у затронутого, note без bump'а у остальных. Это работает для 2 плагинов, потому что «затронутый» — это «Igor помнит, что трогал». Для 4 плагинов с накопленной историей появляются **сценарии без шаблона**:
- Меняется лифсайкл frontmatter (`draft → active → accepted`) — это touches **все** плагины, потому что мета-форма единая. Все 4 bump'аются major? Контракт это допускает («у затронутого»), но «все затронуты» — degenerate case, который выглядит как coordinated bump (Q2=b), который контракт отверг.
- Меняется `links_to`-формат — same story.
- Один плагин эволюционирует мета-форму первым (например, `security` вводит новое required-поле frontmatter), и встаёт вопрос «остальные обязаны догнать или нет?». Контракт молчит — нет процедуры «кто адаптирует первым».

Это не катастрофа, но это **отсутствующий tooling-слой** для координации breaking changes на единой мета-форме. Каждый эпизод будет решаться ad-hoc.

**Mitigation in scope of this proposal**: Не пытаться решить cross-plugin coordination сейчас — это преждевременно. Но **зафиксировать триггер**: «когда происходит первый mета-форм breaking change, затрагивающий ≥2 active плагина одновременно — это сигнал к открытию нового цикла по cross-plugin coordination protocol». Иначе он откроется в момент пожара, а не превентивно. Один bullet в Consequences ADR.

---

### F-5: `.<plugin>-version` маркер становится anchor через 12 месяцев — semantics нельзя поменять без миграции в чужих проектах

**Type**: inertia

**Horizon**: 12 месяцев — момент, когда первый внешний пользователь запустил `/architect:init` или `/product:init` и получил `.architect-version` / `.product-version` в репо.

**The drift**: Решение Q4=(a) («ровно повторяет plugin.json.version на момент init/upgrade») — простое и хорошее. Но это решение **немедленно зафиксировано** в проектах пользователей: каждый запуск `init` создаёт файл, который дальше живёт в их git-истории. Если через 18 месяцев захочется поменять семантику маркера (например, «храним только major.minor, а не full semver» — Q4=c), это требует миграции **в чужих проектах** через `/<role>:upgrade`. Не невозможно, но это становится первой реальной cross-project миграцией, и B1 (migration format) к этому моменту тоже должен быть готов. То есть A2 фактически создаёт **future migration debt** в момент, когда выходит первый внешний пользователь.

Это не аргумент против выбора Q4=(a) — это honest naming того, что выбор делает sticky. Структурный факт.

**Mitigation in scope of this proposal**: В Consequences ADR явно: «Семантика `.<plugin>-version` становится sticky с момента первого внешнего пользователя. Изменение требует `/<role>:upgrade` миграции в чужих проектах. До B1 (migration format) menять не рекомендуется». Это не ограничение — это predictability.

---

### F-6: Проект потенциально over-engineers версионирование relative to actual user base

**Type**: scale (downward direction)

**Horizon**: 6–24 месяца — если внешний adoption signal (STRATEGY §4) остаётся около нуля.

**The drift**: STRATEGY §4 явно фиксирует External adoption signal как **aspirational без инструментирования**. Если через 12 месяцев у Kramar Studio Suite 0–2 внешних пользователя, весь A2-контракт de facto обслуживает одного человека (Igor) с одним marketplace, в котором живёт 2–4 плагина. Семантика symbolic 1.0.0, separation marketplace.version vs plugin.version, гибрид Q2=(c) — каждое из этих решений имеет реальный смысл при наличии внешних пользователей; без них это **конструкция, защищающая от рисков, которых нет**. Это пограничная зона с territory pragmatist'а — но как long-horizon наблюдение: контракт может оказаться **disproportionately structured** для своего user base.

**Mitigation in scope of this proposal**: Это сигнал не к «упрощать сейчас», а к **периодической ревизии**. Один bullet: «если через 12 месяцев External adoption signal остаётся нулевым, открыть цикл "is the versioning contract carrying its weight" — текущая структура легитимизирована именно ставкой на adoption». Это превращает потенциальный over-engineering из tacit-долга в явную точку пересмотра. → Routes to **pragmatist** для immediate-term cost оценки.

---

## Trend findings — speculative, with named signals

### F-7: Claude Code spec ушёл вперёд по dependency-механике; «не используем dependencies» через 12 месяцев читается как принципиальная позиция, требующая обновлённого обоснования

**Type**: technology lifecycle / idiom shift

**Confidence**: medium

**Signals informing this**:
- 2026-05: Claude Code публикует [`code.claude.com/docs/en/plugin-dependencies`](https://code.claude.com/docs/en/plugin-dependencies) — full semver-range support, tag-prefix-based resolution (`{plugin-name}--v{version}`), pre-release handling, lockfile auto-install для plugin'ов с package.json.
- 2026 changelog: «fixed plugin install not honoring dependencies declared in plugin.json», «/plugin install now lists auto-installed dependencies», «marketplace plugins with package.json and lockfile now have dependencies installed automatically» — серия fix'ов показывает **active development surface**, не legacy-feature.
- 2026 экосистема: 9000+ плагинов, ~100 production-ready (по индустриальным обзорам). Это масштаб, при котором dependencies становятся реальной потребностью у реальных authors, и spec будет дальше развиваться **в направлении больше ergonomics**, не меньше.

**The drift**: Текущее обоснование «не используем dependencies» в ADR-0001 опирается на (а) product-only first-class, (б) отсутствие soft-tier в spec'е (research 2026-05-10). Через 12–18 месяцев пункт (б) может перестать быть истиной — Anthropic может добавить optional/recommends tier в ответ на community-pressure (FEATURE issue #9444 уже стал основой для текущей реализации, та же дорожка есть). В этот момент решение «не используем» становится **deliberate stance**, а не «spec не позволяет». Это нормально — но требует обновлённого обоснования. Сегодняшняя формулировка «hard peer-dep противоречит product-only» при появлении soft-tier перестанет быть полной.

**What would change my mind**: Anthropic вводит `optional_dependencies` или `recommends`-поле в plugin.json schema → finding активируется. Spec остаётся «only hard» весь 2027 → finding де-приоритизируется.

---

### F-8: Skill-level semver tooling может стать convention; наша «версия = плагин» рискует не покрыть granularity

**Type**: idiom shift

**Confidence**: low

**Signals informing this**:
- Существование [`cathy-kim/skill-semver`](https://github.com/cathy-kim/skill-semver) (2026, community plugin) с автоматическим semver, changelog'ами, snapshot'ами по версиям — на уровне **отдельных skill'ов**, не плагинов. Один пример — слабый сигнал, но **направление** показателен: ecosystem начинает chunk'овать версионирование тоньше plugin'а.
- Skills-внутри-плагина — наиболее видимая эволюционирующая единица для пользователя в Claude Code (skill определяет поведение модели per-task). Вероятность, что community начнёт ожидать per-skill versioning — есть.

**The drift**: Через 18–24 месяцев может оформиться convention «у моих skill'ов есть свои версии», независимая от plugin.json.version. Тогда `architect 1.0.0` → `architect 1.1.0` без bump skill-внутренней-версии будет читаться как «недостаточная разрешающая способность контракта». Наш A2 этого не предусматривает; per-plugin semver — единственная axis.

**What would change my mind**: Anthropic добавляет `version` в `SKILL.md` frontmatter как first-class concept → finding активируется. Skill-semver остаётся niche-tool с <100 stars весь 2027 → finding де-приоритизируется.

---

### F-9: «Solo-maintainer соло-инди» persona может быть absorbed в multi-agent orchestration paradigm к 2028

**Type**: idiom shift

**Confidence**: low

**Signals informing this**:
- Cursor 3 (April 2026) — переход от «один агент в одном файле» к «fleet of agents in parallel». Multi-agent как default-shape, не feature.
- Anthropic Agent Teams (Feb 2026) — peer-to-peer between Claude Code sessions.
- Job market (2026): «postings requiring AI coding tool experience grew 340%; pure implementation roles declined 17%». Сдвиг от «developer» к «agent orchestrator» как роль.

**The drift**: Сегодняшний контракт A2 imagines пользователя как «человек, который запускает /<role>:cycle вручную, читает артефакты, делает коммит». К 2028 этот workflow может быть subsumed в «orchestrator-агент запускает /architect:cycle во время фоновой работы над фичёй, артефакты автоматически связываются». В этом контексте **версия плагина** становится тем, что читает orchestrator-агент, а не человек. Семантика «major = breaking change для артефактов в проекте» остаётся валидной (агент тоже должен знать), но **аудитория «кто читает CHANGELOG» сдвигается**. Это не делает контракт wrong — но «человеко-читаемое формулирование» (например, README maturity-signal) теряет первичность.

**What would change my mind**: К 2027-Q4 multi-agent orchestration остаётся niche (≤20% дев-задач) → finding не активируется. Наоборот, если ≥50% Claude Code usage идёт через orchestrator-loops без human-in-the-loop → finding превращается в реальный driver.

---

## What's likely to age well

- **Per-plugin semver (Q2=a).** Industry-default подтверждённый research'ем (Cargo, Changesets, Lerna independent, VS Code extensions). Через 2 года это останется идиоматичным, нет signal'ов о сдвиге.
- **`.<plugin>-version` ровно повторяет plugin.json.version (Q4=a).** Простота > концептуальная чистота. Через 2 года это всё ещё будет читаемым решением, без edge case'ов от patch-level granularity.
- **VS Code-style breaking change definition (Q3=d).** Опирается на mature pattern из ecosystem'а, который не изменится — public API plugin'а = всё, что user observable. Эта семантика стабильна на 5+ лет.
- **README maturity-signal как proxy (Q8=b).** Маленькая, low-risk convention. Если ecosystem сдвинется в сторону structured maturity-fields в plugin.json (возможно, но не вероятно к 2028), это легко мигрируется.
- **Single-marketplace-after-ADR-0001 worldview.** Это не часть A2, но upstream-decision, на который A2 опирается. Дешевле версионировать, когда нет cross-marketplace coordination.

---

## What's worth deciding now to defer pain

| Finding | One-line decision now |
|---|---|
| F-1 (символический 1.0.0 → folklore) | Зафиксировать в ADR **критерий применимости** для one-time bump (только scaffolded → active, не applicable между active-релизами). Один абзац. |
| F-2 (marketplace.version vs suite-stamp нужда) | Объявить «если когда-нибудь возникнет suite-stamp нужда — она живёт в README, не в marketplace.json». Один параграф в ADR. |
| F-3 (dependencies не используется → folklore) | Параграф «Why not formal dependencies» в ADR с тремя bullet'ами и ссылкой на ADR-0001. Превращает absence в обоснованный absence. |
| F-4 (cross-plugin coordination отсутствует) | Bullet в Consequences: «первый мета-форм breaking change, затрагивающий ≥2 active плагина одновременно — триггер для открытия нового цикла». |
| F-5 (`.<plugin>-version` becomes anchor) | Bullet в Consequences: «семантика маркера становится sticky с первого внешнего пользователя; изменение требует B1 migration format». Predictability. |
| F-6 (over-engineering risk) | Bullet: «если через 12 месяцев External adoption signal остаётся нулевым — открыть цикл ревизии контракта». Pre-commitment к точке пересмотра. |

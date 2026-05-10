# Discovery: Cross-marketplace dependency posture

> **Scope:** что значит для плагинов `kramar-studio-marketplace` требовать (или не требовать) установленный `archforge` соседнего marketplace.
> **Source:** `decision-map.md` A1 / `ARCHITECTURE.md §6` Q4
> **Date:** 2026-05-10
> **Cycle scale:** standard

---

## 1. Problem statement

`kramar-studio-marketplace` и `archforge-marketplace` — **две разные** Claude Code marketplace. Их `marketplace.json` — независимые регистры, и Claude Code не имеет формального механизма «плагин X требует плагин Y». Тем не менее `product` плагин в текущем виде:

- В artifact-frontmatter `links_to: [ADR-NNNN]` ссылается на ADR-файлы, которые создаёт **только** `archforge` (`docs/architecture/decisions/`).
- В commands (`define.md`, `discover.md`, `spec.md`) явно предлагает запускать `/archforge:cycle` для разрешения архитектурных зависимостей PRD.
- В skills (`product-conventions`, `product-cycle`) указывает: «See `archforge`'s `architect/SKILL.md` Language section», «Cross-references to archforge ADRs are first-class».
- В README marketplace явно позиционируется как «companion to `archforge-marketplace`» и «archforge — reference implementation».

Если `archforge` **не установлен** в проекте пользователя, всё это не падает технически (хуки softfail), но смысл документации частично испаряется, а `links_to: [ADR-NNNN]` указывает в пустоту.

Решение «требует/не требует» — worldview-уровня: marketplace-федерация (плагины осознают друг друга и опираются друг на друга) или независимые острова (каждый стоит сам, иногда упоминает соседа). От ответа зависят: содержание hooks/skills/templates, текст README для соло-инди, формат `links_to`, посыл будущих роль-плагинов (`ops`, `security`).

## 2. Forces

| # | Force | Direction |
|---|---|---|
| F1 | Конвенция в README §9 «Cross-references to archforge are first-class» | Pulls toward **federation** (hard dep) |
| F2 | Soft-hooks-only посыл (README §2): хуки **никогда не блокируют**. Hard-dep-failure нарушил бы это. | Pulls toward **soft / standalone** |
| F3 | STRATEGY §3 persona: «соло-инди или маленькая студия». Такой пользователь устанавливает много плагинов сразу — friction +1 install мала. | Neutral, слегка к **federation** |
| F4 | STRATEGY §2: «копируем у archforge мета-форму». Концептуальное заимствование ≠ runtime-coupling. Можно копировать форму, не требуя runtime-присутствия источника. | Pulls toward **standalone** |
| F5 | Persona может уже иметь свой ADR-формат (Nygard / MADR / собственный). Forcing archforge = навязывание чужой формы там, где её не просили. | Pulls toward **standalone** |
| F6 | Claude Code plugin spec не имеет формального механизма «requires». Любой контракт — документация + runtime-detection. | Constraint: **no hard dep at install-time mechanically** |
| F7 | Versioning compatibility: если `product:0.2` требует `archforge:>=0.5`, и пользователь имеет более старую версию — что происходит? | Pulls toward **explicit detection or no dep** |
| F8 | Forward compatibility: A1 ставит precedent для `ops` и `security`. Что закладываем — наследуют все. | Higher stakes than выглядит изолированно |
| F9 | Документация трека B из STRATEGY: каждый новый роль-плагин повторяет ту же позу. Если позиция «hard dep on archforge» — это значит и `ops`, и `security` будут жить только под зонтиком. | Pulls toward осознанной decisive позы (любой), не drift |
| F10 | Если в проекте пользователя **уже есть** ADR от другого инструмента (или ручные ADR в `docs/architecture/decisions/`), `links_to` мог бы работать против них без архитектурного захвата. | Pulls toward **island + translation layer** |

## 3. Constraints (что не двигается)

- **Soft-hooks-only.** Никакого `exit 1` в хуках (закреплено в README §2 и в `STRATEGY.md §2 — что это исключает`). Это исключает любую опцию, в которой дип-чек делается через хук, который блокирует tool-use.
- **No telemetry / no install-detection-callback.** Claude Code plugin spec не предоставляет API «узнать, установлены ли другие плагины». Любая детекция — через файловую систему (`docs/architecture/`, `ARCHITECTURE.md`, `.archforge-version` маркер).
- **English source / user-language artifacts** (README §10) — любая опция должна сохранять эту дисциплину.
- **Append-only artifacts** — переход с одной позы на другую не должен ломать существующие пользовательские артефакты с `links_to`.

## 4. Stakeholders

- **Igor (нулевой пользователь, автор marketplace).** Имеет оба плагина установленными по умолчанию. Сегодняшнее поведение (soft federation) ему адекватно.
- **Похожий-на-Igor соло-инди (primary persona STRATEGY §3).** Скорее всего поставит оба, но вероятно начнёт с одного (тот, который услышал первым — `product` или `archforge`). Опыт первого касания критичен.
- **Маленькая студия с универсальным игроком, имеющая собственный ADR-процесс.** Хочет `product` без навязанной архитектурной формы. Меньшинство, но архитектурно показательное меньшинство.
- **Будущие роль-плагины (`ops`, `security`).** Не голосуют, но наследуют решение.

## 5. Prior art / similar decisions

- **VS Code extensions** не имеют формального «extension X requires extension Y» — extension-author указывает в README, и при необходимости делает runtime-check (`vscode.extensions.getExtension(...)`). Если зависимости нет, extension работает в degraded-режиме или показывает уведомление.
- **NPM packages** имеют formal `peerDependencies` — install-time предупреждение, runtime-failure если пакет не установлен. Близко к «soft federation»: предупреждение, не блокировка.
- **Atom packages** имели `package-deps` для требования соседних пакетов — установка цепочкой. Это близко к «hard federation», но с явным install-time UX.
- **Claude Code plugin marketplace** — без формальных механизмов peer-dep. Только README + soft runtime-detection.

## 6. Open questions

> Эти вопросы должен ответить пользователь перед переходом в Design. Без ответов alternatives матрица собирается на песке.

**Q1. Кто primary user marketplace в первый месяц после v0.2?**
- (a) Только Igor + 1-2 опытных контрибьютора, которые поставят оба marketplace осознанно. → форсит **federation**, кросс-зависимость не проблема.
- (b) Внешние соло-инди, которые узнали про `product` через пост / repo и пробуют его как самостоятельный инструмент. → форсит **standalone**.
- (c) Не знаю, ставлю на (b) как worst-case дизайн. → форсит **standalone**.

**Q2. Если пользователь установил только `product` без `archforge`, какой ожидаемый UX?**
- (a) Плагин говорит при `init`: «нужен archforge, поставь его и вернись». Жёстко, ясно.
- (b) Плагин работает; `links_to: [ADR-NNNN]` принимает любой ADR-формат; там, где упоминается archforge — даётся ссылка как на «recommended companion».
- (c) Плагин работает; в local mode `links_to` принимает любые `[XXX-NNNN]` идентификаторы, даже не ADR; пользователь сам решает, на что ссылается.

**Q3. Что мы хотим сделать с фразой «is the reference implementation» в README marketplace?**
- (a) Оставить — это правда, и нам не стыдно.
- (b) Смягчить — «inspired by», «follows the same shape as».
- (c) Убрать — каждый marketplace стоит сам.

**Q4. Принимаем ли мы, что некоторые пользователи `product` НЕ являются пользователями `archforge` — как стратегически легитимный сценарий?**
- (a) Да — иначе мы пишем плагин для подмножества Igor'а.
- (b) Нет — `product` без архитектурной дисциплины обесценивается; это плагин для людей, которые уже принимают наш cycle-philosophy.
- (c) Да, но degraded UX — приемлемая цена.

**Q5. Каков критерий успеха решения по A1 — то, по чему мы поймём через 6 месяцев, что выбрали правильно?**
- (a) Число `product`-only пользователей (без `archforge`), которые остались через месяц. Если ≥ X — standalone-выбор был верен.
- (b) Объём «слома» при апгрейде до v0.2: если `product:0.2` потребует чего-то нового от `archforge:0.5`, сколько проектов сломается. Если 0 — federation правильно изолирована; если много — standalone был бы лучше.
- (c) Качество cross-link графа в чужих проектах: пользователи реально создают связки PRD↔ADR или `links_to: []` всегда пусто.

**Q6. Готовы ли мы написать миграцию для существующих `product`-артефактов, если поза изменится через год?** (Например, сегодня soft, завтра strict, или наоборот.)
- (a) Да — миграции и так заложены в B1, одной больше / меньше.
- (b) Нет, поэтому надо сразу решить надолго.

**Q7. Hidden assumption-check.** Что если у пользователя `archforge` установлен **в другой версии**, чем мы рассчитываем (например, `0.3` когда мы ожидаем `0.4+`)? Нужен ли механизм объявления version-range, или принимаем «работает только последнее»?

## 7. What's NOT in scope of this discovery

- Решение про versioning contract внутри одного marketplace (это A2, отдельный цикл).
- Формат миграций (B1).
- Тон и формулировки в README — это design-решение, не worldview.
- Технические детали runtime-detection (детект `docs/architecture/` папки, парсинг `.archforge-version` и т.п.) — это для design-фазы.
- Cross-role linkage **внутри** одного marketplace (это D4, deferred).

## 8. Initial bias

Мой текущий honest read (без ответов на Q1-Q7): **soft federation с явным fallback** (вариант (b) в Q2). Причины:
- Не нарушает soft-hooks-only constraint (F2).
- Уважает persona, которая может прийти за `product` отдельно (F4, F5).
- Сохраняет conceptual коrенство с archforge без runtime-захвата (F4).
- Даёт «recommended companion» вместо «обязательное требование» — что соответствует spec'у Claude Code marketplace (F6).

Но это до получения ответов. Возможно, ответы Q1+Q4 сдвинут картину к hard federation (если worldview = «мы для нашего community, а не для всех соло-инди»), или к polnomu standalone (если worldview = «product должен жить в любом ADR-окружении»).

---

## Pause: жду ответов на Q1–Q7

Без них переход в Design — спекуляция на размытом форс-векторе.

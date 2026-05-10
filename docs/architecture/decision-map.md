# Decision Map

> Living document. Обновляется всякий раз, когда цикл закрывается ADR'ом или появляется новый архитектурный вопрос.
> **Last updated:** 2026-05-10 (после ADR-0001)

## Инвентарь источников

- `ARCHITECTURE.md §6` — 5 открытых вопросов (Q1-Q5).
- `STRATEGY.md §5` — трек C ("Зрелость мета-формы") явно отвечает за закрытие этих вопросов.
- `docs/architecture/decisions/` — пусто. ADR'ов пока нет.
- `docs/architecture/research/` — пусто. Discovery-заметок в полёте нет.
- **Architectural seam в коде:** `plugins/product/scripts/*.sh` опираются на bash + git + jq-fallback + `${CLAUDE_PLUGIN_ROOT}` без явно задокументированного контракта окружения. Добавлено как B3.

---

## Group A — Principal stakes

Решения, которые формируют worldview marketplace и ограничивают всё ниже. Их немного, и они принимаются первыми.

### A1. Cross-marketplace dependency posture
- _Forces:_ ~~`kramar-studio-marketplace` и `archforge-marketplace` — **разные** marketplace; артефакты `product` ссылаются на `ADR-NNNN` из соседа. Что считать контрактом, если `archforge` не установлен — игнор / soft-warning / hard-error? Это worldview-вопрос: marketplace-федерация или независимые острова, которые иногда смотрят друг на друга.~~
- _Status:_ **decided → [ADR-0001](./decisions/0001-absorb-archforge-into-kramar-studio-marketplace.md)** (2026-05-10). Решение: dissolve вопроса через поглощение `archforge` в этот marketplace. Implementation: pending — repo move отдельной сессией.
- _Blocks (release):_ ~~B2~~, ~~C1~~ — больше не блокирует, потому что cross-marketplace-aspect устранён.
- _Blocked by:_ —
- _Source:_ ARCHITECTURE.md §6 Q4 (закрыт)

### A2. Multi-level versioning contract _(reframed после ADR-0001)_
- _Forces:_ `marketplace.json` несёт `version`, и **каждый** из плагинов suite (`product`, `architect`, далее `ops`, `security`) несёт свой `version` в `plugin.json`. После ADR-0001 это уже не «двухуровневое» (marketplace + один плагин), а **N-уровневое** (umbrella + N независимых плагинов в одном репо). Двигаются ли версии плагинов синхронно (umbrella-bump = coordinated release всей suite) или независимо (каждый плагин — свой semver, marketplace.json — каталог)? Что в этих числах кодируется (breaking change артефактов? новые команды? bugfix скриптов)? Что инкремент чего означает для пользователя при `/<role>:upgrade`? Как координировать breaking change в мета-форме (которая по STRATEGY §2 единая для всей suite)?
- _Status:_ open. **Срочность повышена** после ADR-0001 — суть вопроса расширилась.
- _Blocks:_ B1 (миграции — это дельты между версиями; формат миграции не определить, пока не зафиксирована семантика версии)
- _Blocked by:_ —
- _Source:_ ARCHITECTURE.md §6 Q1

---

## Group B — Mechanism

Технические контракты, которые наполняют worldview из Group A конкретикой.

### B1. Migration format and procedure
- _Forces:_ `/<role>:upgrade` обещает запустить миграции из `plugins/<role>/migrations/NNNN-from-X.Y.Z-to-A.B.C.md`. Не зафиксированы: формат файла (что внутри — markdown-инструкция Claude / bash / mix?), идемпотентность, тестирование до релиза, dry-run, процедура отката, поведение при многоверсионном прыжке. В v0.1 миграций нет — tactical, но станет blocking при первом breaking-change апгрейде.
- _Status:_ open
- _Blocks:_ — (но напрямую нужен для треков A и B из STRATEGY: без миграций контент-fill `product` и добавление `ops`/`security` рискует ломать чужие проекты)
- _Blocked by:_ A2 (миграция — между версиями; нужно понимать, между чем мигрируем)
- _Source:_ ARCHITECTURE.md §6 Q3

### B2. Quality control without CI _(упрощено после ADR-0001)_
- _Forces:_ markdown + bash, тестов нет, CI нет. Как ловить регрессии: «команда стала генерировать сломанный frontmatter», «hook падает с ошибкой парсинга на новой версии Claude Code», «миграция повредила артефакты в чужом проекте». Нужна процедура (manual checklist? snapshot-артефакты с golden-output? smoke-проект как тестовая площадка?). Без неё каждый новый плагин увеличивает невидимую surface area.
- _Status:_ open
- _Blocks:_ — (но косвенно ограничивает скорость треков B и C из STRATEGY: без QC каждый scaffold нового плагина — рулетка)
- _Blocked by:_ ~~A1~~ (закрыт; cross-link теперь intra-marketplace, проверяется проще), A2 (QC должен ловить migration regressions; без зафиксированного формата версионирования непонятно, что снапшотить)
- _Source:_ ARCHITECTURE.md §6 Q5

### B3. Hook execution environment contract
- _Forces:_ `plugins/product/scripts/*.sh` — bash, опирается на git (с conditional fallback), jq (с grep-fallback), `${CLAUDE_PLUGIN_ROOT}` (от Claude Code). Контракт окружения нигде явно не зафиксирован. Cross-platform (Windows users)? Минимальный список зависимостей? Что делать, когда хук вызван вне git-репозитория? Поведение при падении одного из tools? Сегодня каждый скрипт защищается defensive-кодом ad-hoc — это не контракт, это accidentally-working.
- _Status:_ open
- _Blocks:_ — (но ставит precedent для каждого нового роль-плагина: `ops`/`security` повторят те же ad-hoc-решения)
- _Blocked by:_ —
- _Source:_ Architectural seam в коде, не в §6

---

## Group C — Domain shape

Решения, которые касаются конкретики ролей и плагинов, а не контракта marketplace в целом.

### C1. Skill-count threshold
- _Forces:_ Конвенция в README §8 — «ровно две skill'ы на плагин» (`<role>-conventions` + `<role>-cycle`). Исключение допускается «когда возникает явно отдельное тело знания» — `architect` (раньше `archforge`) сам имеет больше двух (`c4-diagrams`, `adr-writing` и т.д.). Где порог? Что считать «отдельным телом знания»? Без критерия следующий вопрос «нужна ли третья skill для X» решается субъективно — через год получим расходящиеся диалекты в `product` / `ops` / `security`. После ADR-0001 вопрос становится интра-suite: единый порог нужен, потому что мета-форма единая.
- _Status:_ open
- _Blocks:_ — (но косвенно ограничивает трек B из STRATEGY: при scaffold `ops` / `security` каждый раз будет неочевидно, сколько skill'ов давать)
- _Blocked by:_ ~~A1~~ (закрыт; всё в одном marketplace, политика должна быть единой)
- _Source:_ ARCHITECTURE.md §6 Q2

---

## Suggested order

> **Updated 2026-05-10 после ADR-0001.** A1 закрыт; A2 расширился (стал срочнее); D4 перешёл из deferred в активную область (implementation того же ADR его «разморозил»). Гранд-логика та же: **worldview → mechanism → domain**. Внутри слоя — по reversibility + blast radius + information value.

| Slot | Decision | Why now |
|---|---|---|
| **0 (implementation)** | ~~**ADR-0001 implementation**~~ ✅ **DONE 2026-05-10** | Завершено: `git filter-repo` move (47 файлов с историей в KSM), plugin/skill rename (archforge→architect, architect→role, v1.0.0), marketplace.json registration, product cross-refs sync, marketplace docs, AF→stub (README/marketplace.json/git rm), pinned migration issue + tagged release v0.4.1-moved + GH description в AF. См. [план](../plans/2026-05-10-001-feat-implement-archforge-absorption-plan.md). |
| **Next** | **A2** Multi-level versioning contract _(reframed)_ | После ADR-0001 объём вырос: marketplace + `product` + `architect` + (будущие) `ops`/`security`. Самое необратимое решение оставшейся группы A: как только семантика версий объявлена и пользователи начали upgrade'иться, изменить контракт = breaking change для `.<role>-version` маркеров всех плагинов. Высокая info-value: unblocks B1 и B2. |
| **Next (parallel-able)** | **B3** Hook execution environment contract | Не блокирует A2 и не блокируется им. Решить **до** scaffold нового роль-плагина (трек B из STRATEGY) — иначе `ops` / `security` повторят ad-hoc bash-pattern, и контракт зафиксируется по факту. С учётом ADR-0001 — единый контракт для **всех** плагинов suite, а не только product. |
| **Next (parallel-able)** | **D4** Cross-role workflow внутри suite _(пересдвинутый из deferred)_ | После ADR-0001 implementation `architect` и `product` начинают жить рядом. Вопрос «как security review линкуется к ops runbook без посредничества ADR» становится конкретным. Брать ДО scaffold ops/security — иначе они не будут уметь cross-link друг с другом. |
| После A2 | **B1** Migration format and procedure | Hard-зависим от A2. Формат миграции описывается тривиально, когда семантика версий зафиксирована. До этого — спекуляция. |
| После A2 + B1 | **B2** Quality control without CI | После ADR-0001 — упростился: cross-link стал intra-marketplace. QC проверяет migration regressions (B1) и frontmatter validity. Брать после, не до. |
| После всего | **C1** Skill-count threshold | Меньшая срочность; решать ровно перед `/ops:init`. После ADR-0001 — единый порог для всей suite (плагины в одном marketplace должны быть консистентны). |

**Если можно работать только в один поток:** ADR-0001 implementation → **A2 → B3 → D4 → B1 → B2 → C1**.

**Если можно параллелить:** ADR-0001 implementation сначала; затем A2, B3, D4 — параллельно; потом B1 (после A2); потом B2 (после A2+B1); потом C1.

---

## Deferred (do not run yet)

- **D1. Plugin telemetry / install signal.** Метрика *External adoption* (`STRATEGY.md §4`) требует знать, сколько внешних людей реально запустили `/<role>:cycle`. Сегодня узнать нельзя. Добавить телеметрию = trust-trade-off (open-source инструмент собирает данные).
  _Wait for:_ ≥3 явных external-adoption-сигнала (issue/PR/discussion от не-Igor) **и** запрос на «как мне измерить, что я делаю с плагином» от внешнего пользователя.

- **D2. Multi-language plugin source.** Конвенция §10 — источник плагина на **English**, артефакты — на языке пользователя (через Claude). Никакой code-level multi-lang поддержки нет.
  _Wait for:_ запрос от внешнего пользователя в non-English-окружении, где Claude-перевод не справляется (например, термин-специфичный artifact: «как мне писать `## Success metric` по-китайски и не сломать хуки»).

- **D3. Distribution beyond Claude Code.** Сейчас единственный runtime — Claude Code (CLI / desktop / web / IDE-extensions). Возможные альтернативы: другие agentic-CLI, прямой git-distribution, package manager.
  _Wait for:_ появление сравнимого runtime, который имеет совместимый plugin-spec (или есть смысл написать adapter).

- **D4. Cross-role workflow между плагинами одного marketplace.** Например: `security` review касается `ops` runbook; есть ли cross-role linkage **внутри** одного marketplace без посредничества ADR'а? **После ADR-0001 deferred-условие выполнено**: `architect` (бывший `archforge`) переезжает в этот же marketplace и начинает жить рядом с `product` — это уже две роли в одном репо. Вопрос приобретает срочность сразу при выполнении implementation ADR-0001 (move repo). Перевести в active group после move'а; до этого формально остаётся deferred, но "wait for"-условие выполнено.
  _Wait for:_ ~~scaffold второго роль-плагина~~ — выполнено через ADR-0001 (implementation pending).

---

## Notes

- **A1 закрыт через dissolve, не через выбор.** ADR-0001 не выбрал между soft federation и islands — он устранил саму рамку «два marketplace». Это редкий, но валидный исход цикла: вопрос исчезает не потому, что на него ответили, а потому что переформулировали worldview. Если столкнёшься с этим в будущих циклах — это не «избежание решения», это легитимный move; ключ в том, что dissolve должен иметь явную сторическую цену (как у нас — переписать STRATEGY и ARCHITECTURE), иначе это просто отлынивание.
- **Карта стала меньше и более сцеплена с реальностью.** 5 живых решений (A2 расширенный, B1, B2 упрощённый, B3, C1, плюс пересдвинутый D4), 0 в group C готовых брать сразу, 3 deferred. ADR-0001 implementation — операционный долг сверху.
- **B3 (hook env) — единственное решение «из кода», не из §6.** Его легко пропустить, потому что ad-hoc-defensive-код в скриптах *как будто* решает проблему. Не решает: при scaffold нового плагина паттерн повторится случайным образом. Лучше зафиксировать ДО `ops`/`security` — а после ADR-0001 это единый контракт для всей suite, не только product.
- **Что НЕ на карте.** Содержательные решения внутри плагинов (какая фаза цикла что производит, какие шаблоны, какой pushback на какой anti-pattern) — это работа конкретного плагина, не архитектурная. Идёт через `/product:*` или `/architect:*` команды и не попадает на decision-map. Архитектурные решения о том, **как** plugin устроен — на карте; решения о том, **что** plugin делает — нет.
- **Update on every cycle close.** Когда следующий цикл приземлит ADR-NNNN, надо: (а) перевести соответствующий пункт на этой карте в статус `decided` со ссылкой на ADR-NNNN; (б) разморозить decisions, которые им разблокировались; (в) обновить `ARCHITECTURE.md §5 Decision index`. ADR-0001 — рабочий пример этого процесса.

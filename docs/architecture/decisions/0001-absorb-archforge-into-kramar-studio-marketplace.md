# ADR-0001: Поглотить плагин `archforge` в `kramar-studio-marketplace`

- **Date**: 2026-05-10
- **Status**: Accepted (implementation: pending — repo move в отдельной сессии)
- **Authors**: Igor Kramar

## Context

`kramar-studio-marketplace` создан как companion к существующему `archforge-marketplace`. Оба marketplace принадлежат одному автору, оба несут одну и ту же мета-форму (цикл + frontmatter с lifecycle + cross-link через `links_to` + soft hooks + сервисные команды + push-back tone), и `STRATEGY.md §2` явно фиксирует: «копируем у `archforge` мета-форму, а не role-specific содержимое».

В `decision-map.md` это разделение породило вопрос **A1 — Cross-marketplace dependency posture**: что значит для плагинов этого marketplace требовать или не требовать установленный `archforge`. Цикл прошёл фазы Discover и Research; ответы пользователя сузили альтернативы:

- **Q4 = a** (product-only пользователь — стратегически легитимный сценарий) → исключает hard peer-dependency.
- **Q7 = 3** (зависимость на файловые конвенции, не на версию плагина) → исключает любой semver-coupling.
- **Q3 = b** («смягчить, но не убрать reference-implementation» формулировку) → исключает чистое разделение на «независимые острова».
- **Q6 = b** (миграцию для смены позы не пишем — решаем надолго) → требует устойчивого выбора.

Research подтвердил: Claude Code (v2.1.110+) имеет формальный механизм `dependencies` в `plugin.json` с cross-marketplace allow-list через `allowCrossMarketplaceDependenciesOn`, но он только **hard** — soft / recommends / optional tier'а в spec'е нет. Soft federation реализуется только через README + runtime-detection хуками.

Design фаза дала четыре альтернативы (status quo, soft formal federation, independent islands, hard peer-dep). После их сравнения пользователь предложил пятую — поглотить `archforge` в `kramar-studio-marketplace`, превратив `archforge-marketplace` в redirect-stub. Эта альтернатива схлопывает A1 как класс вопроса (нет двух marketplace — нет contract'а между ними) и приводит структуру marketplace в соответствие с реальностью (один автор, одна методология, одна аудитория).

Force vector, сложившийся после discovery + research:

- Conceptual coherence с `archforge` ценна (STRATEGY §2, Q3=b) → толкает к structural coupling.
- Product-only установка должна остаться first-class (Q4=a) → требует независимой installable плагинов внутри marketplace.
- Зависимость не на версию, а на файловую конвенцию (Q7=3) → требует отсутствия semver-coupling.
- Soft-hooks-only (README §2) → запрещает install-time блокировку.
- Решение принимается надолго (Q6=b) → принимается полная sticky-cost.

Поглощение даёт structural coherence без semver-coupling и без install-time блокировки. Внутри одного marketplace плагины устанавливаются независимо, что сохраняет product-only сценарий. Cross-link `links_to: [ADR-NNNN]` остаётся file-convention-based — теперь это просто intra-marketplace convention.

## Decision

Перенесём плагин `archforge` из соседнего репозитория `archforge-marketplace` в `plugins/architect/` (или `plugins/archforge/` — финальное имя выбирается при выполнении переноса) этого marketplace. `archforge-marketplace` репозиторий останется живым, но его `marketplace.json` и README превратятся в redirect-stub: одна запись с пометкой «moved to kramar-studio-marketplace» и явной ссылкой на новый адрес установки.

После переноса `kramar-studio-marketplace` будет hostить два плагина (`product` и `architect`/`archforge`) и принимать `ops` / `security` по roadmap'у. Каждый плагин остаётся независимо устанавливаемым (`/plugin install <name>@kramar-studio-marketplace`); cross-link `links_to: [ADR-NNNN]` работает по факту наличия файла в `docs/architecture/decisions/`, безотносительно версий или install-state'а соседних плагинов.

Реальная работа по переносу (git operations, обновление `marketplace.json`, поднятие redirect-stub'а в старом репо) выполняется отдельной сессией. Этот ADR фиксирует решение; статус `Accepted` со словом «implementation: pending» отражает разрыв.

## Consequences

### Easier

- **A1 закрыт по построению.** Cross-marketplace dependency questions перестают существовать как класс — нет двух marketplace, нет contract'а между ними. `decision-map.md` уменьшается на одно решение.
- **Conceptual coherence становится structural.** STRATEGY §2 «копируем у archforge мета-форму» перестаёт быть метафорой — буквально один marketplace, один maintainer, один поток правок мета-формы.
- **Forward-compat для будущих ролей.** `ops` (v0.3) и `security` (v0.4) сразу появляются рядом с `architect` и `product` без cross-marketplace overhead. Suite строится в одном репо.
- **Install friction для primary persona ниже.** Один `/plugin marketplace add` даёт доступ ко всей studio-suite, плагины ставятся выборочно.
- **Mета-форма эволюционирует синхронно.** Когда меняется frontmatter-контракт, lifecycle статусов или соглашение о хук-окружении — это правится в одном месте и применяется ко всем плагинам сразу, без рассинхронизации между marketplace.

### Harder

- **`archforge` brand identity растворяется.** Разработчики, которые могли искать «archforge» как self-standing «architecture toolkit for Claude Code», увидят redirect на marketplace с другим именем. Discoverability hit для существующего brand'а; bootstrap effort для нового («Kramar Studio Suite»).
- **Outside contribution to `archforge` foreclosed.** `archforge-marketplace` теоретически мог принять плагин от стороннего автора; после move'а это структурно становится «плагин в marketplace конкретной студии». Открытость к стороннему вкладу в `archforge`-как-таковой больше не вариант.
- **Migration friction для существующих пользователей `archforge-marketplace`.** Те, у кого уже сделан `/plugin marketplace add https://github.com/IgorKramar/archforge-marketplace`, после move'а получают redirect-stub. README-стаб помогает, но требует от пользователя одного шага работы.
- **Координация upgrade cadence теснее.** Сегодня `archforge` мог релизиться в своём ритме. После move'а ритм координируется между всеми плагинами одного `marketplace.json`. Claude Code поддерживает per-plugin versions внутри одного marketplace, но breaking-change координация всё равно становится теснее.
- **Apparent surface area `kramar-studio-marketplace` вырастает.** Репо становится больше, issue tracker — общим, breaking-change coordination — общей. Solo-maintainer cost не падает, а перераспределяется.
- **Strategy-level work добавлен в этот цикл.** Поглощение требует переписать `STRATEGY.md` §1+§2 и `ARCHITECTURE.md` §1+§3+§5+§6. Это сделано в рамках того же цикла, но цена — больший footprint работы, чем у обычного ADR.

### Risks accepted

- **Sticky-cost при reversal очень высокий.** Отменить поглощение = выполнить move в обратную сторону + восстановить `archforge-marketplace` repo identity + убедить пользователей перейти обратно. Принято осознанно через discovery Q6=b.
- **`archforge`-as-brand эрозия принята.** Если `archforge` имел или мог приобрести самостоятельную аудиторию, эта аудитория теперь мapping'ится в Kramar Studio identity. Принято: marketplace by definition — Kramar IT Studio.
- **D4 (cross-role workflow между плагинами одного marketplace) теряет «deferred» статус.** Сегодня было «wait for: scaffold второго плагина». Поглощение `archforge` приводит к этому условию немедленно — `architect` и `product` начинают жить рядом и могут хотеть cross-link friendly соглашений друг с другом.
- **A2 (двухуровневое версионирование) расширяется.** Раньше — `marketplace.json` ↔ один плагин `product`. После — `marketplace.json` ↔ N плагинов с независимыми каденциями. Решение по A2 становится более срочным; нужно реприоритизировать.

## Alternatives considered

### 1. Soft federation, formalized (Alt B из Design)

Оставить два marketplace; формализовать в README текущее «companion» состояние. Хук при `init` детектит наличие `docs/architecture/` и сообщает «detected ADR system; cross-links будут активны»; `links_to` к несуществующему ADR — soft warning. Templates оставляют `ADR-NNNN` как пример с комментарием «if archforge or compatible ADR system in use».

**Сильные стороны:** низкая сложность изменения; не нарушает soft-hooks-only; companion-связь явная без runtime-захвата; не растворяет `archforge` brand.

**Слабые стороны:** conceptual coherence остаётся documentary, не structural; A1 не закрывается, а формализуется в managed состоянии — vопрос остаётся открытым каждый раз, когда возникает новый cross-marketplace edge case (что делать при разных версиях `archforge`? как обрабатывать соседство с другим ADR-инструментом? и т.д.). Дрейф между двумя marketplace продолжается даже под management'ом.

**Почему проиграл:** не снимает A1 как класс, а перекладывает его в режим «постоянного maintenance». При solo-maintainer'е такой режим — основная утечка времени.

### 2. Independent islands with file-convention bridge (Alt C из Design)

Полностью развязать `product` и `archforge`. README marketplace описывает `product` как самодостаточный плагин; раздел interop перечисляет `archforge`, plain `adr-tools`, hand-written ADRs как равноправные ADR-системы. `links_to` принимает любой `[A-Z]+-[0-9]+`-prefix. Skills и commands убирают конкретные упоминания `/archforge:cycle`.

**Сильные стороны:** максимальная свобода для пользователя; первоклассная поддержка product-only сценария; никакой semver- или install-coupling; чистый interop story.

**Слабые стороны:** прямое противоречие с STRATEGY §2 («копируем у archforge мета-форму») и с ответом Q3=b discovery («смягчить, не убрать reference implementation»). Conceptual cohesion со студийной мета-формой размывается в нейтральный «interop with any ADR system». Identity marketplace схлопывается в каталог нейтральных tools, что не соответствует заявленному positioning «Kramar Studio».

**Почему проиграл:** сильнейшая боковая стоимость по STRATEGY § identity, не оправданная преимуществом, которое Alt F даёт даром (поскольку Alt F тоже сохраняет product-only сценарий через intra-marketplace independence).

### 3. Formal hard peer-dependency (Alt E из Design + Research)

Объявить `dependencies: [{"name": "archforge", "version": "^X.Y.0", "marketplace": "archforge-marketplace"}]` в `plugin.json` плагина `product`. В корневом `marketplace.json` — `allowCrossMarketplaceDependenciesOn: ["archforge-marketplace"]`. Auto-install при установке `product`, hard-fail при отсутствии.

**Сильные стороны:** формальный install-time контракт через документированный механизм Claude Code; conceptual coherence максимальна и закреплена в spec'е; semver-discipline.

**Слабые стороны:** прямое противоречие с Q4=a discovery — hard-fail при отсутствии `archforge` запрещает product-only установку. Прямое противоречие с Q7=3 — formal peer-dep требует semver-pinning, а не file-convention detection. Spec не предусматривает soft / recommends / optional tier (research-finding) — нет middle ground.

**Почему проиграл:** немедленно вырубается ответами discovery; невозможно реализовать без нарушения base-line constraint'ов.

### 4. Status quo / do nothing

Оставить как есть — два marketplace, README говорит «companion», конкретное поведение при отсутствии `archforge` нигде явно не описано, хук softfail'ит.

**Сильные стороны:** ноль работы.

**Слабые стороны:** A1 остаётся открытым неявно. Каждый новый user-edge-case (что показать в `init` при отсутствии archforge? как маркировать `links_to` к чему попало? как объяснить новому контрибьютору relationship двух marketplace?) решается ad-hoc и расходится. Решение «не решать» — это решение в пользу дрейфа.

**Почему проиграл:** discovery именно для того и нужен, чтобы вытащить implicit состояние в explicit. Decision-cycle без решения — это разговор без вывода.

---

## Implementation status

ADR принят. Реальная работа по выполнению поглощения **не сделана** в этой сессии и распадается на шаги, каждый — отдельная сессия:

1. **Repo move:** скопировать `plugins/architect/` (или `plugins/archforge/`) из `archforge-marketplace` в `kramar-studio-marketplace/plugins/`; перенести историю коммитов через `git filter-repo` или эквивалент (опционально, если важна сохранность blame'а).
2. **Marketplace metadata update:** обновить `kramar-studio-marketplace/.claude-plugin/marketplace.json` — добавить запись `architect` плагина рядом с `product`.
3. **archforge-marketplace → redirect-stub:** обновить README старого репо (одна страница с pointer'ом); упростить `marketplace.json` до пустого (или убрать запись плагина с пометкой «moved»).
4. **Issue tracker / GitHub repo coordination:** open issues и PRs из `archforge-marketplace`, если есть, мигрировать или закрыть с pointer'ом.

До выполнения шага 2 этот ADR описывает *intent*; пользователи продолжают видеть marketplace в текущем составе. Прогресс по implementation отслеживается через `decision-map.md` (запись A1 → `decided` со ссылкой на этот ADR + пометка implementation status).

## Связанные артефакты

- Discovery: `docs/architecture/research/2026-05-10-cross-marketplace-dependency-posture-discovery.md`
- Research digest: `docs/architecture/research/2026-05-10-cross-marketplace-dependency-posture-research.md`
- Decision-map entry: `docs/architecture/decision-map.md` § A1
- Strategy implications: `STRATEGY.md` §1, §2 (обновлены в этом же цикле)
- Architecture implications: `ARCHITECTURE.md` §1, §3, §5, §6 (обновлены в этом же цикле)

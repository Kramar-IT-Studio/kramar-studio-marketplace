<p align="center">
  <img src="./assets/kramar-marketplace-compact.svg" alt="Kramar Studio Marketplace — Claude Code" width="800"/>
</p>

<p align="center">
  <a href="./README.md">English</a> · <strong>Русский</strong>
</p>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"/></a>
  <img src="https://img.shields.io/badge/runtime-Claude_Code-fabd2f" alt="Claude Code"/>
  <img src="https://img.shields.io/badge/maintainer-solo-928374" alt="Solo maintainer"/>
</p>

---

[Marketplace плагинов](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces) Claude Code, в котором живут роль-плагины **Kramar IT Studio**: структурированный способ вести архитектурную, продуктовую, ops- и security-работу как повторяющиеся циклы с долгоживущими артефактами.

> **Единая Kramar Studio Suite.** По [ADR-0001](./docs/architecture/decisions/0001-absorb-archforge-into-kramar-studio-marketplace.md), плагин `architect` (архитектурная роль; ранее `archforge` в собственном `archforge-marketplace`) живёт здесь рядом с `product`. Старый `archforge-marketplace` репозиторий теперь redirect-stub. Все роль-плагины разделяют единую мета-форму (цикл, frontmatter с lifecycle, cross-link через `links_to`, мягкие хуки без блокировок, сервисные команды) и развиваются синхронно под одним мейнтейнером.

## Плагины

| Плагин | Статус | Версия | Назначение |
|---|---|---|---|
| **`architect`** | 🟢 active | `1.0.0` | Архитектурная роль — цикл Discover → Design → Decide → Document → Review. Skills для C4, ADR, system design, frontend/backend/AI-agents architecture, code review, research. Router-skill `architect:role`. |
| **`product`** | 🟡 scaffolded | `0.1.0` | Market-scan (квартальный якорь) + цикл по фичам Discover → Define → Spec → Validate, плюс `prioritize` над беклогом. Артефакты: HYP/PRD/SPEC/VAL/SCAN, кросс-связаны с ADR от `architect`. |
| **`ops`** | ⚪ planned | `0.3` | Operations-роль — runbooks, on-call posture, инцидент-ретроспективы. |
| **`security`** | ⚪ planned | `0.4` | Security-роль — threat modeling, security review, dependency posture. |

> **Намеренно вне области:** frontend, design, qa, pm, tech writer. Студия сейчас работает соло; плагин получает только та роль, которую я реально ношу.

## Установка

Внутри Claude Code:

```text
/plugin marketplace add https://github.com/Kramar-IT-Studio/kramar-studio-marketplace
/plugin install architect@kramar-studio-marketplace
/plugin install product@kramar-studio-marketplace
```

Плагины устанавливаются независимо — можно взять только `architect`, только `product`, или оба (рекомендовано для полной suite).

После установки запусти `/reload-plugins` (или перезапусти Claude Code) и проверь через `/plugin list`.

<details>
<summary><strong>Локальная установка для разработки</strong></summary>

```text
/plugin marketplace add /absolute/path/to/kramar-studio-marketplace
/plugin install architect@kramar-studio-marketplace
/plugin install product@kramar-studio-marketplace
```

</details>

<details>
<summary><strong>Миграция с <code>archforge-marketplace</code></strong></summary>

Если у тебя ранее был установлен `archforge` из старого marketplace:

```text
/plugin marketplace remove archforge-marketplace        # опциональная очистка
/plugin marketplace add https://github.com/Kramar-IT-Studio/kramar-studio-marketplace
/plugin install architect@kramar-studio-marketplace
```

Все команды `/archforge:*` теперь `/architect:*`. Идентификатор router-skill изменился с `archforge:architect` на `architect:role`. Файл-маркер версии теперь `.architect-version` (был `.archforge-version`).

См. [CHANGELOG плагина](./plugins/architect/CHANGELOG.md) для полного списка ломающих изменений.

</details>

## Быстрый старт

```text
# Архитектурный цикл
/architect:init                            # развернуть ARCHITECTURE.md и docs/architecture/
/architect:cycle "<проблема>"              # полный цикл: Discover → Design → Decide → Document
/architect:adr "<решение>"                 # сокращение: написать ADR напрямую
/architect:review [path]                   # архитектурное ревью кода

# Продуктовый цикл
/product:init                              # развернуть PRODUCT.md и docs/product/
/product:market-scan "<область>"           # редко — раз в квартал или новая область
/product:discover "<фича>"                 # пер-фичный цикл, фаза 1
/product:define "<фича>"                   # фаза 2 — PRD с метрикой успеха
/product:spec "<фича>"                     # фаза 3 — спецификация реализации
/product:validate "<фича>"                 # фаза 4 — пост-релизная валидация
/product:status                            # что в работе, что устарело
```

См. [`plugins/architect/README.md`](./plugins/architect/README.md) и [`plugins/product/README.md`](./plugins/product/README.md) для полных справочников.

## Архитектурный след

Сам marketplace построен по своей же методологии — каждое значимое решение зафиксировано как ADR.

- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — живое архитектурное состояние
- [`STRATEGY.md`](./STRATEGY.md) — продуктовая стратегия (целевая проблема, подход, треки работы)
- [`docs/architecture/decisions/`](./docs/architecture/decisions/) — принятые ADR
- [`docs/architecture/decision-map.md`](./docs/architecture/decision-map.md) — открытые решения и граф зависимостей

<details>
<summary><strong>Конвенции плагинов Kramar Studio</strong> (обязательная спецификация для каждого плагина marketplace)</summary>

Эти конвенции применяются к **каждому плагину этого marketplace**. Новые роль-плагины (`ops`, `security`, …) наследуют правила дословно. Если плагин расходится — это его ошибка, а не прецедент.

### 1. Один плагин — одна роль

Каждый плагин владеет ровно одной ролью студии. Имя плагина — имя роли в нижнем регистре: `architect` (архитектура), `product`, `ops`, `security`.

Роль-плагин отвечает за:

- Цикл решений в этой роли (например, discover → decide для архитектуры; market-scan + discover → define → spec → validate для продукта).
- Артефакты, которые роль производит, и как они кросс-ссылаются на артефакты других ролей.
- Router-skill, который активируется, когда разговор уходит в территорию этой роли.
- Команду миграции (`upgrade`), которая переводит артефакты проекта на текущую установленную версию плагина.

### 2. Дисциплина, не ворота

Все плагины этого marketplace используют **мягкие, не-блокирующие хуки**. Хук может:

- Печатать напоминание в stderr.
- Предложить следующую команду.
- Отказаться промолчать, когда что-то выглядит не так.

Хук **никогда не прерывает сессию, никогда не блокирует tool use, никогда не делает auto-commit, никогда не правит файлы за спиной пользователя.** Архитектурная и продуктовая дисциплина возникают из того, что цикл проще пройти, чем пропустить, а не из принуждения.

### 3. Стандартный layout под `docs/<role>/`

Каждый плагин пишет артефакты в `docs/<role>/` в проекте пользователя, с фиксированной подструктурой:

```
docs/<role>/
├── README.md                 ← индекс этой директории (поддерживается /<role>:init|upgrade)
├── <ROLE>.md                 ← корневой документ роли (например, ARCHITECTURE.md, PRODUCT.md)
├── <category>/               ← поддиректории под конкретную роль
│   ├── 0001-<slug>.md
│   └── ...
└── .last-<command>           ← маркер-файлы для хуков
```

`architect` использует `decisions/`, `diagrams/`, `research/`, `reviews/`. `product` — `discoveries/`, `prds/`, `specs/`, `validations/`, `research/` (для market-scan'ов), плюс `backlog.md`. `ops` и `security` определят свои, когда появятся, — но всегда под `docs/<role>/`.

### 4. Frontmatter в каждом артефакте

```yaml
---
id: <ROLE_PREFIX>-NNNN          # ADR-0001, HYP-0001, PRD-0001, SPEC-0001, VAL-0001, SCAN-0001
status: draft | active | accepted | superseded | archived
created_at: YYYY-MM-DD
role: <role>                    # architect | product | ops | security
links_to:
  - ADR-0007
  - HYP-0003
---
```

| Роль | Префикс | Артефакт |
|---|---|---|
| `architect` | `ADR-` | Architecture Decision Record |
| `product` | `SCAN-` | Market scan |
| `product` | `HYP-` | Discovery hypothesis |
| `product` | `PRD-` | Product Requirements Document |
| `product` | `SPEC-` | Implementation spec |
| `product` | `VAL-` | Post-launch validation |
| `ops` | TBD | TBD |
| `security` | TBD | TBD |

**Lifecycle статуса:** `draft` → `active` → (`accepted` | `superseded` | `archived`). Никогда не удаляй артефакт; меняй его статус. Superseded-артефакты должны указывать на сменивший их через `links_to`.

**`links_to` — это связующий клей между ролями.** PRD, требующий миграции БД, ссылается на соответствующий ADR. Граф этих связей и делает marketplace компаундирующим.

### 5. Обязательный цикл с состоянием

У каждой роли — конечный, мнение-имеющий цикл, закодированный в slash-командах. Пропуск фазы разрешён, но виден — `/<role>:status` репортит артефакты с признаками срезанного цикла.

- `architect`: `discover → design → decide → document → review`
- `product`: `discover → define → spec → validate` (на фичу) + `market-scan` и `prioritize` вне основного per-feature цикла

Структура цикла — **часть контракта плагина**. Форк, добавляющий или убирающий фазы, — это другой плагин, не кастомизация.

### 6. Стандартные сервисные команды

| Команда | Назначение |
|---|---|
| `/<role>:init` | Развернуть `docs/<role>/`, записать шаблон `<ROLE>.md`, записать маркер `.<role>-version`. Идемпотентна. |
| `/<role>:upgrade` | Перевести артефакты проекта и `<ROLE>.md` с версии в `.<role>-version` на версию установленного плагина. |
| `/<role>:status` | Read-only отчёт: что в работе, что устарело, какие cross-references сломаны. |

### 7. Контракт версионирования

Согласно [ADR-0002](./docs/architecture/decisions/0002-multi-level-versioning-contract.md):

- **Per-plugin независимый semver.** Каждый плагин эволюционирует в своём ритме.
- **`marketplace.json.version`** = версия структуры манифеста / curation-политик, **НЕ** агрегатная стабильность suite.
- **`.<plugin>-version`** маркер в проекте пользователя ровно повторяет `plugin.json.version` на момент последнего успешного `init` или `upgrade`.
- **Ломающее изменение** = переименование/удаление contribution points (commands, skills, agents, hooks); изменение input schema; изменение frontmatter contract.
- **Символический `1.0.0`** допускается один раз на плагин при переходе `scaffolded → active`.
- **Поле `dependencies`** в `plugin.json` не используется; cross-plugin связи идут через `links_to: [ADR-NNNN]` файловой конвенцией.
- **CHANGELOG** обязателен для каждого плагина и каждого bump'а.

### 8. Минимум две skills на плагин

Каждый плагин поставляет как минимум:

- **`<role>-conventions`** — правила frontmatter, выделение ID, file layout, lifecycle статусов, cross-role связи.
- **`<role>-cycle`** — методология: что производит каждая фаза, когда пропускать, типичные failure modes.

Добавлять больше skills допустимо, когда возникает явно отдельное тело знания (например, `architect` поставляет `c4-diagrams`, `adr-writing`, `system-design` — это внешние стандарты со своей глубиной).

### 9. Кросс-ссылки на `architect` — first-class

Плагины `product`, `ops`, `security` регулярно производят артефакты, зависящие от архитектурных решений. Поле `links_to` несёт эти связи. Хуки в не-архитектурных плагинах эмитят мягкое предупреждение, если `links_to` пуст, а содержимое артефакта намекает на cross-role зависимость.

### 10. Язык

Исходник плагина (commands, skills, templates) — на английском, универсально и копи-пастибельно. Сгенерированные артефакты следуют языку пользователя. Если пользователь работает на русском — все PRD, ADR, market-scan'ы на русском, **но идентификаторы** (ID, имена команд, заголовки секций из шаблонов) остаются verbatim.

### 11. Тон

Плагины спорят и держат позицию. Не сдают её на слабом продуктовом срезе, протекающей абстракции, недопечённом релизе. Цикл существует, чтобы вытаскивать такие моменты — уступка на первом возражении обесценивает цикл.

</details>

<details>
<summary><strong>Структура репозитория</strong></summary>

```
kramar-studio-marketplace/
├── .claude-plugin/
│   └── marketplace.json            ← /plugin marketplace add читает это
├── ARCHITECTURE.md                 ← живое архитектурное состояние
├── STRATEGY.md                     ← продуктовая стратегия
├── README.md                       ← английская версия
├── README.ru.md                    ← этот файл
├── CLAUDE.md                       ← гайд для Claude Code сессий в этом репо
├── LICENSE
├── assets/
│   └── kramar-marketplace-compact.svg
├── docs/
│   ├── architecture/
│   │   ├── decisions/              ← ADR
│   │   ├── research/               ← discovery + research digests
│   │   ├── reviews/                ← roast trails, meta-reviews
│   │   └── decision-map.md
│   └── plans/                      ← планы реализации
└── plugins/
    ├── architect/
    │   ├── .claude-plugin/plugin.json
    │   ├── commands/   skills/   agents/   hooks/   scripts/   templates/
    │   ├── README.md   README.ru.md   CHANGELOG.md   LICENSE
    └── product/
        ├── .claude-plugin/plugin.json
        ├── commands/   skills/   hooks/   scripts/   templates/
        └── README.md
```

</details>

## Roadmap

- ✅ **v0.1** — `product` развёрнут; `archforge` поглощён и переименован в `architect`; контракт многоуровневого версионирования (ADR-0002)
- 🚧 **v0.2** — content-fill `product` (реальные шаблоны с примерами, паттерны интеграции с `architect`); формат миграций (B1)
- 📅 **v0.3** — плагин `ops` (runbooks, on-call posture, инцидент-ретроспективы)
- 📅 **v0.4** — плагин `security` (threat modeling, security review, dependency posture)

Намеренно вне области: frontend, design, qa, pm, tech writer плагины.

## Лицензия

MIT — см. [`LICENSE`](./LICENSE).

---
title: "feat: Absorb archforge plugin into kramar-studio-marketplace as `architect`"
type: feat
status: completed
date: 2026-05-10
completed_at: 2026-05-10
origin: docs/architecture/decisions/0001-absorb-archforge-into-kramar-studio-marketplace.md
---

# feat: Absorb archforge plugin into kramar-studio-marketplace as `architect`

## Summary

План выполняет implementation, отложенный в ADR-0001 §Implementation Status: переносит плагин из соседнего `archforge-marketplace` в `kramar-studio-marketplace/plugins/architect/` с сохранением git-истории через `git filter-repo`, переименовывает плагин (`archforge` → `architect`) и его router-skill (`archforge:architect` → `architect:role`), синхронно обновляет cross-references во всех артефактах обоих репозиториев и превращает старый `archforge-marketplace` в redirect-stub. Cross-repo работа: документ-план живёт здесь, изменения кода — в обоих репо.

---

## Problem Frame

ADR-0001 принял worldview-решение поглотить `archforge` в этот marketplace. Decision зафиксирован, но реальная работа (move кода, обновление manifests, координация двух репозиториев) была явно отложена как «implementation: pending». Без её выполнения marketplace расходится с decision'ом: документация говорит «единая Kramar Studio Suite», файлы продолжают жить в двух репозиториях, cross-references в `product` плагине ссылаются на `/archforge:cycle` команды соседнего marketplace.

Дополнительно — пользовательская ревизия в planning-фазе расширила scope: переименование плагина в `architect` для консистентности с `product`/`ops`/`security` (роль-имена в lowercase), и переименование внутреннего router-skill с `archforge:architect` в `architect:role` — это избегает collision'а, который возник бы от наивного `architect:architect` после rename плагина, и устанавливает pattern `<plugin>:role` для будущих ролей. См. origin: `docs/architecture/decisions/0001-absorb-archforge-into-kramar-studio-marketplace.md`.

---

## Requirements

- **R1.** Плагин из `archforge-marketplace/plugins/archforge/` живёт в `kramar-studio-marketplace/plugins/architect/` с сохранённой git-историей (blame работает на любом из 47 файлов).
- **R2.** Внутренний router-skill переименован: `archforge:architect` → `architect:role`. Skill-directory, frontmatter, все cross-references обновлены.
- **R3.** Все идентификаторы, которые раньше начинались на `archforge:` или `/archforge:`, в перенесённом плагине теперь начинаются на `architect:` или `/architect:` соответственно.
- **R4.** `kramar-studio-marketplace/.claude-plugin/marketplace.json` содержит запись `architect` плагина рядом с `product`. Schema валидируется.
- **R5.** Все cross-references в `product` плагине, ссылавшиеся на старые archforge-команды/скиллы, обновлены на новые имена. Ни один артефакт `product` не указывает на несуществующий идентификатор после implementation.
- **R6.** Marketplace-level документы (`README.md` корня, `ARCHITECTURE.md`, `STRATEGY.md`, `decision-map.md`) консистентны с новым именованием — `archforge` остаётся **только** в исторических/brand-контекстах (e.g., «поглощён из archforge-marketplace»), не как plugin name.
- **R7.** `archforge-marketplace` репозиторий превращён в redirect-stub: README с явной migration-инструкцией; `marketplace.json` с пустым `plugins[]` (валидный schema, graceful 404 для `/plugin install archforge@archforge-marketplace`).
- **R8.** Открытые issues/PRs в `archforge-marketplace` обработаны (закрыты с pointer'ом на новое место или мигрированы).
- **R9.** Версия плагина в новом доме — `1.0.0` (honest breaking change через double rename).
- **R10.** Мета-форма (frontmatter, lifecycle, soft hooks, и т.д.) не меняется. product-only установка остаётся возможной (`/plugin install product@kramar-studio-marketplace` без `architect`).

---

## Scope Boundaries

- Содержательные правки внутри плагина `architect` (новые команды, изменённые фазы цикла, переписанный pushback) — не делаются. Только rename + перенос.
- Оптимизация/упрощение `archforge` мета-формы под suite-paradigm — отдельная работа, не часть implementation ADR-0001.
- Переписывание `product` плагина beyond cross-reference sync — отдельная работа (трек A из `STRATEGY.md`).
- Полный ребрендинг marketplace в маркетинг-формулировках «Kramar Studio Suite» — отложено до scaffold'а `ops`/`security`.
- Архитектурные решения A2 (multi-level versioning), B3 (hook env contract), D4 (cross-role workflow), C1 (skill-count threshold) — отдельные циклы, не закрываются этим планом.

### Deferred to Follow-Up Work

- **Decision о новом имени для router-skill `architect:role` если awkward.** Если pattern `<plugin>:role` окажется на практике хуже, чем альтернативы — отдельный цикл для пересмотра. В этом плане принимаем `architect:role`.
- **Telemetry, multi-language source, distribution beyond Claude Code** — все deferred D-items в `decision-map.md`.
- **Брендинг/promotion** — трек E из STRATEGY, отдельная работа.
- **GitHub repo settings полная reorganization** (теги, описание GH, social preview, archived flag) — частично в U7, остальное — solo activity вне формального плана.

---

## Context & Research

### Relevant Code and Patterns

- **archforge-marketplace structure** (`/Users/user/Work/self/archforge-marketplace`): `marketplace.json` v0.4.0-rc3, owner `IgorKramar`, single plugin `archforge` под source `./plugins/archforge`, 47 файлов, git working tree clean, remote `git@github.com:IgorKramar/archforge-marketplace.git`. Внутренняя структура плагина: `agents/`, `commands/`, `hooks/`, `scripts/`, `skills/`, `templates/`, `README.md`, `README.ru.md`, `LICENSE`, `CHANGELOG.md`.
- **kramar-studio-marketplace.json** (этот репо): owner `Kramar IT Studio`, single plugin `product` v0.1.0 под source `./plugins/product`. Schema URL: `https://json.schemastore.org/claude-code-marketplace.json`.
- **Существующий `product` плагин** как pattern для размещения: `plugins/product/.claude-plugin/plugin.json`, `commands/`, `skills/`, `hooks/`, `scripts/`, `templates/`. Архитектурно совместим с тем, что переносим.
- **product plugin cross-references к archforge** (что нужно будет обновлять): `plugins/product/commands/{define,discover,spec}.md` (упоминают `/archforge:cycle`), `plugins/product/skills/product-cycle/SKILL.md` (упоминает `archforge` поимённо), `plugins/product/skills/product-conventions/SKILL.md` (ссылка на `archforge`'s `architect/SKILL.md` Language section), `plugins/product/templates/*.md`, `plugins/product/README.md`.

### Institutional Learnings

- `docs/solutions/` пока пуст — институциональных learnings ещё не накоплено. Этот план может стать источником learning'а для будущей работы (например, документировать процедуру `git filter-repo` для последующих move'ов).

### External References

- **`git filter-repo`** — современная замена `git filter-branch`, устанавливается отдельно (`brew install git-filter-repo`). Документация: <https://github.com/newren/git-filter-repo>. Мы используем подкоманды `--subdirectory-filter` (вырезать поддиректорию с историей) и затем `git remote add` + `git fetch` + `git merge --allow-unrelated-histories` для импорта в целевой репо.
- **Claude Code plugin spec** (research-digest от 2026-05-10): no `peerDependencies`-style optional tier. Soft federation — это README + soft runtime detection. ADR-0001 обходит это через absorption; план не пересматривает.

---

## Key Technical Decisions

- **Plugin rename `archforge` → `architect`.** Консистентность с роль-плагинами suite (`product`, `ops`, `security`). Цена — breaking change для всех существующих пользователей `/archforge:*` команд. Принято осознанно как часть worldview-сдвига ADR-0001.
- **Skill rename `archforge:architect` → `architect:role`.** Snimaет collision (которая возникла бы от `architect:architect` после plugin rename) и вводит pattern: `<plugin>:role` — стандартное имя router-skill для любого плагина suite, которому router нужен (плагины уровня `product`, у которого только `<role>-conventions` + `<role>-cycle`, router'а не имеют — это нормально). **Honest: pattern N=1 сегодня** — никакого другого плагина с router-skill в suite пока нет; это forward bet, что когда `ops` или `security` понадобится router, они тоже примут `<plugin>:role`. **Success criterion для retire'а pattern reversal risk:** если scaffold `ops` или `security` адоптирует `<plugin>:role` — pattern validated; если они выберут другую форму router'а или router не нужен — retire pattern declaration через отдельный цикл и держать `architect:role` как one-off rename ради консистентности `architect:architect`-избегания.
- **Git history preservation через `git filter-repo`.** 47 файлов плюс CHANGELOG — есть что сохранять. Альтернатива (plain copy) теряет blame и эволюцию методологии, что обесценивает причину иметь archforge как inspiration source. Стоимость — одна доп. установка инструмента и ~5-10 минут на `--subdirectory-filter` + merge.
- **Версия плагина после move + double rename: `1.0.0`** (от `0.4.0-rc3`). Семантически honest: убрана RC-метка + два breaking rename'а — это именно мажорный релиз, а не patch.
- **Order of operations: move-first → stub-second в раздельных commit'ах.** Сначала плагин живёт в обоих местах под разными именами (короткое окно ~часы), затем archforge-marketplace становится stub. Безопаснее обратного — нет момента «архитектурный плагин временно исчез».
- **Bundle двух renames в один v1.0.0 wave** (vs split на две версии). Принято на assumption, что аудитория `archforge` достаточно мала, чтобы один disruption beat два. **Honest acceptance:** при большой аудитории bundling амплифицирует pain (одновременно `archforge → architect` plugin-rename + skill-namespace change + version jump = три concurrent breaking signals). Reversal cost бóльшей половины bundle'а (например, retire `architect:role` через 6 недель) = `2.0.0` второй мажор → читается как churn. **Threshold для revisit:** если post-launch traffic на migration-команды в archforge-marketplace stub'е > 20 действий/неделю в первый месяц, или если приходит ≥ 3 issue-репорта о confused-by-rename — это сигнал, что аудитория крупнее предполагаемой и второй wave (например, retire `architect:role`) надо избегать любой ценой.
- **Stub form: README + empty `plugins[]` в `marketplace.json`.** Не удаляем archforge-marketplace репо целиком (history ценна; внешние ссылки на него — bookmarks, цитирования — продолжают вести на живой repo). README объясняет переезд + дает копируемые миграционные команды. Empty `plugins[]` дает graceful 404 для тех, кто пытается старый install.
- **Brand vs plugin-name distinction в правках документов.** `archforge` остаётся в текстах, где речь о историческом происхождении / brand identity (например, «поглощён из archforge-marketplace», «inspired by the archforge methodology»). Заменяется на `architect`, где речь о плагине поимённо как о компоненте marketplace today.
- **`architect` плагин в новом доме сохраняет bilingual README** (`README.md` + `README.ru.md`) — это feature плагина, не нагрузка для marketplace.

---

## Open Questions

### Resolved During Planning

- **Plugin name choice (`architect` vs `archforge`):** resolved to `architect` per user revision во время synthesis-фазы.
- **Internal router-skill rename:** resolved to `architect:role` per user revision во время synthesis-фазы.
- **Git history preservation:** resolved to «yes, через `git filter-repo`».
- **Version после rename:** resolved to `1.0.0`.
- **Stub form:** resolved to README + empty `plugins[]`.
- **Whether to bundle skill-rename with plugin-rename:** resolved «bundle» (одна волна breaking changes, не две).

### Deferred to Implementation

- **Точный список GitHub issues/PRs** в archforge-marketplace на момент implementation — будет обнаружен через `gh issue list` / `gh pr list` в U7. План даёт template для обработки, не предзагадывает количество.
- **Точное содержание migration-блока в `archforge-marketplace/README.md`** — pen в формате прозы будет составлен в U6 на основе fixtures из template-блока (раздел Output Structure ниже).
- **Нужно ли `git filter-repo` `--tag-rename`** — зависит от того, есть ли релиз-теги в `archforge-marketplace`, которые мы хотим перенести. Будет установлено в U1 через `git tag -l`.
- **Финальный slug нового пути** — план фиксирует `plugins/architect/`. Если в U1 при импорте filter-repo предложит более удобный путь — будет согласован inline (план unchanged).

---

## Output Structure

Целевая структура `kramar-studio-marketplace` после implementation:

```
kramar-studio-marketplace/
├── .claude-plugin/
│   └── marketplace.json          ← обновлён: добавлен architect entry
├── README.md                     ← обновлён: упомянут architect плагин
├── ARCHITECTURE.md               ← обновлён: rename references
├── STRATEGY.md                   ← обновлён: rename references
├── CLAUDE.md                     ← unchanged
├── LICENSE                       ← unchanged
├── docs/
│   ├── architecture/
│   │   ├── decision-map.md       ← обновлён: rename references (ADR-0001 unchanged)
│   │   └── …
│   └── plans/
│       └── 2026-05-10-001-feat-implement-archforge-absorption-plan.md
└── plugins/
    ├── product/                  ← существующий, обновлён cross-references (U4)
    │   ├── .claude-plugin/plugin.json
    │   ├── commands/
    │   │   ├── define.md         ← обновлён
    │   │   ├── discover.md       ← обновлён
    │   │   ├── spec.md           ← обновлён
    │   │   └── … (others unchanged)
    │   ├── skills/
    │   │   ├── product-cycle/SKILL.md      ← обновлён
    │   │   └── product-conventions/SKILL.md ← обновлён
    │   ├── templates/            ← обновлены упоминания archforge
    │   ├── README.md             ← обновлены упоминания archforge
    │   └── …
    └── architect/                ← НОВЫЙ: перенесено из archforge-marketplace
        ├── .claude-plugin/plugin.json   ← name: architect, version: 1.0.0
        ├── README.md
        ├── README.ru.md
        ├── CHANGELOG.md           ← новая v1.0.0 entry
        ├── LICENSE
        ├── agents/
        ├── commands/              ← все /archforge:* → /architect:*
        ├── hooks/
        ├── scripts/
        ├── skills/
        │   ├── role/              ← переименовано из architect/, name: role
        │   ├── c4-diagrams/
        │   ├── adr-writing/
        │   ├── system-design/
        │   ├── frontend-architecture/
        │   ├── backend-architecture/
        │   ├── ai-agents-architecture/
        │   ├── code-review-architectural/
        │   ├── architectural-diagrams/
        │   ├── compound-integration/
        │   └── architecture-research/
        └── templates/
```

И `archforge-marketplace` после implementation:

```
archforge-marketplace/
├── .claude-plugin/
│   └── marketplace.json          ← обновлён: empty plugins[], description="moved"
├── README.md                     ← полностью переписан как redirect/migration notice
├── README.ru.md                  ← переписан как Russian-mirror migration notice
├── LICENSE                       ← unchanged
├── ROADMAP.md                    ← удалён (git rm) — roadmap описывал v0.5/0.6/0.7
│                                    плагина, которого здесь больше нет; история
│                                    сохранена в git
└── plugins/                      ← удалена директория archforge/ (history сохранена в git)
```

> **Текущее состояние** `archforge-marketplace` (для сверки): содержит `.claude-plugin/`, `LICENSE`, `README.md`, `README.ru.md`, `ROADMAP.md`, `plugins/archforge/`. План U6 затрагивает каждый из этих файлов; ничего «забытого вне scope» не остаётся.

> Структура — scope declaration. Если на implementation выяснится, что что-то идёт лучше иначе (например, `git filter-repo` оставит файлы в другой раскладке) — implementer корректирует в рамках интента.

---

## High-Level Technical Design

> *Иллюстрирует sequencing двух репозиториев и точки безопасной commit'имости. Directional guidance for review, not implementation specification — implementer следует дисциплине, не конкретному набору shell-команд.*

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant AF as archforge-marketplace
    participant TMP as tmp filter-repo clone
    participant KSM as kramar-studio-marketplace
    participant GH as GitHub

    Note over Dev,GH: U1 — Move with history preserved
    Dev->>AF: git clone (working copy already exists)
    Dev->>TMP: git clone --no-local archforge-marketplace tmp/
    Dev->>TMP: git remote remove origin (snimaет filter-repo safety check)
    Dev->>TMP: git filter-repo --subdirectory-filter plugins/archforge --path-rename :plugins/architect/ (один вызов)
    Dev->>KSM: git remote add archforge-history tmp/
    Dev->>KSM: git fetch archforge-history
    Dev->>KSM: git merge archforge-history/main --allow-unrelated-histories -m "Import archforge plugin history"
    Dev->>KSM: git commit "U1: import archforge plugin into plugins/architect/"
    Dev->>KSM: VERIFY KSM-HEAD diff vs AF source (gating gate для U2/U6)

    Note over Dev,GH: U2 — Rename internals
    Dev->>KSM: rename skills/architect/ → skills/role/
    Dev->>KSM: find/replace /archforge: → /architect: и archforge:architect → architect:role внутри plugins/architect/
    Dev->>KSM: update plugin.json (name=architect, version=1.0.0)
    Dev->>KSM: append CHANGELOG entry для v1.0.0
    Dev->>KSM: git commit "U2: rename plugin to architect, router-skill to role, bump to 1.0.0"

    Note over Dev,GH: U3 — Register in marketplace.json
    Dev->>KSM: edit .claude-plugin/marketplace.json — добавить architect entry
    Dev->>KSM: git commit "U3: register architect plugin in marketplace.json"

    Note over Dev,GH: U4-U5 — Sync cross-references
    Dev->>KSM: update product plugin cross-refs (commands, skills, templates, README)
    Dev->>KSM: update root README, ARCHITECTURE.md, STRATEGY.md, decision-map.md
    Dev->>KSM: git commit "U4-U5: sync cross-references and marketplace docs"

    Note over Dev,GH: U6 — Convert archforge-marketplace to stub
    Dev->>AF: rewrite README.md and README.ru.md as migration notice
    Dev->>AF: edit marketplace.json — empty plugins[], description="moved"
    Dev->>AF: git rm ROADMAP.md (roadmap stale post-move)
    Dev->>AF: git rm -r plugins/archforge/
    Dev->>AF: git commit "Convert to redirect-stub; archforge moved to kramar-studio-marketplace as architect"

    Note over Dev,GH: GATING smoke-test (BEFORE push wave — see U6.5)
    Dev->>KSM: smoke-test in clean test project (local marketplace source)
    Dev->>KSM: golden-flow checks /architect:init, /architect:cycle, /product:init, /product:discover

    Note over Dev,GH: Push wave (KSM first — forward-compatible; then AF)
    Dev->>GH: push KSM → main (new architect available; old still works)
    Dev->>GH: push AF → main (stub takes effect)

    Note over Dev,GH: U7 — GitHub coordination (post-push)
    Dev->>GH: gh issue list / gh pr list в archforge-marketplace
    Dev->>GH: close с pointer'ом на новый репо или мигрировать
    Dev->>GH: pin migration-notice issue в archforge-marketplace
    Dev->>GH: update GH repo description archforge-marketplace
```

**Ключевые safety-точки в порядке:** (1) U1 commit'ится первым в KSM — даже если последующие шаги упадут, плагин уже находится в новом репо с историей, никто ничего не потерял. (2) U1 verification (KSM-HEAD diff) gates U2 и U6 — не идём дальше, пока не подтверждён clean import. (3) U6 commit'ится в AF только после того, как U1-U5 в KSM полностью зелёные локально — это исключает окно «и там, и там нет». (4) **Smoke-test (U6.5) gates push wave** — без зелёного `/architect:cycle` в чистом тестовом проекте push не делается. (5) Push двух репо: **KSM первым** (forward-compatible — новый плагин появляется, старый продолжает работать), **AF вторым** (stub вступает в силу). Reverse порядок (AF first) создаёт окно «redirect указывает на marketplace, у которого нет нужного плагина».

---

## Implementation Units

### U1. Перенос плагина с сохранением git-истории

**Goal:** Скопировать содержимое `plugins/archforge/` из `archforge-marketplace` в `kramar-studio-marketplace/plugins/architect/` так, чтобы `git log <file>` на любом из 47 файлов продолжал показывать pre-move коммиты.

**Requirements:** R1.

**Dependencies:** None (foundational unit).

**Files:**
- Create: `plugins/architect/` (47 файлов, mirror of source)
- Use temp clone (вне репозитория, например `/tmp/archforge-extract/`) для filter-repo операции

**Approach:**
- Установить `git filter-repo` если ещё нет (`brew install git-filter-repo`).
- Сделать non-local clone archforge-marketplace в tmp директорию.
- **В tmp-clone'е удалить `origin` remote** (`git remote remove origin`) — `git filter-repo` отказывается работать в репозитории с remote'ом без `--force`. Удаление безопаснее, чем `--force`: explicit и не подавляет другие safety checks.
- В клоне: **один** вызов filter-repo, объединяющий subdirectory-filter и path-rename: `git filter-repo --subdirectory-filter plugins/archforge --path-rename :plugins/architect/`. Filter-repo применяет subdirectory-filter первым, потом path-rename — оба флага в одном вызове идиоматичны и работают. **Не разделять на два последовательных вызова** — второй вызов потребовал бы `--force` или fresh clone.
- В `kramar-studio-marketplace`: добавить tmp-clone как remote, fetch его, merge `--allow-unrelated-histories` с описательным commit message. Сделать commit U1.
- **Verification step (gating для U2 и U6):** сразу после U1-commit'а, до начала U2, прогнать KSM-HEAD-diff (test scenarios ниже). Если `git log --follow` или KSM-HEAD diff падают — restore не делать, разобраться в tmp-clone'е и попробовать заново. Только после зелёного verification U2 может стартовать (он трогает файлы и ломает rename-detection для будущих `--follow`).
- Проверить tag-теги в источнике (`git tag -l`); если есть и они принадлежат архивному плагину — учесть `--tag-rename` или принять, что мажорные tags переезжают (skip минимально).

**Patterns to follow:**
- Пример практики filter-repo для extract'а поддиректории — стандартный workflow `git-filter-repo` README.

**Test scenarios:**
- *Happy path:* `find plugins/architect -type f | wc -l` возвращает то же число (47), что было в `archforge-marketplace/plugins/archforge/`.
- *Happy path:* `git log --follow plugins/architect/README.md` показывает коммиты, созданные в archforge-marketplace до move'а. **Запускать сразу после U1-commit'а, до U2.**
- *Edge case:* `git log --follow plugins/architect/.claude-plugin/plugin.json` возвращает непустую историю (не «only the import commit»).
- *Edge case (KSM-HEAD diff — gating для U6):* `diff -r <(git ls-tree -r HEAD plugins/architect | awk '{print $4}' | sed 's|^plugins/architect/||' | sort) <(cd /Users/user/Work/self/archforge-marketplace && git ls-tree -r HEAD plugins/archforge | awk '{print $4}' | sed 's|^plugins/archforge/||' | sort)` — пустой diff (то же множество файлов в KSM HEAD после merge, как в AF source). Это сильнее, чем «tmp diff против оригинала» — проверяет, что merge не съел и не удвоил файлы.
- *Edge case (tmp diff):* такой же diff, но против tmp-clone'а (показывает, что filter-repo не потерял файлы между AF и tmp).
- *Integration:* working tree этого репо clean после commit'а; ничего не сломалось в `plugins/product/`.

**Verification:** В `kramar-studio-marketplace` есть commit с сообщением «import archforge plugin into plugins/architect/» (или эквивалентным), `plugins/architect/` непустая, history наследуется, **KSM-HEAD diff против AF source пустой** (не только tmp diff). Tmp-clone удаляется только после успешного KSM-HEAD-diff'а.

---

### U2. Rename плагина и router-skill внутри `plugins/architect/`

**Goal:** Переименовать перенесённый плагин (`archforge` → `architect`), его router-skill (`architect:architect` → `architect:role`), все внутренние идентификаторы команд и skill-namespaces, обновить версию и CHANGELOG.

**Requirements:** R2, R3, R9.

**Dependencies:** U1.

**Files:**
- Modify: `plugins/architect/.claude-plugin/plugin.json` (name, version)
- Move: `plugins/architect/skills/architect/` → `plugins/architect/skills/role/`
- Modify: `plugins/architect/skills/role/SKILL.md` (frontmatter `name: role`)
- Modify (find/replace): все файлы `plugins/architect/commands/*.md`, `plugins/architect/skills/**/SKILL.md`, `plugins/architect/templates/*.md`, `plugins/architect/scripts/*.sh`, `plugins/architect/hooks/hooks.json`, `plugins/architect/agents/*.md`, `plugins/architect/README.md`, `plugins/architect/README.ru.md` — паттерны ниже
- Append: `plugins/architect/CHANGELOG.md` — новая запись для v1.0.0 с описанием rename'ов

**Approach:**

**Сначала** переименовать skill-директорию через `git mv` (preserve history).

**Затем** find/replace в строгом порядке (длинные substrings первыми, чтобы избежать частичной замены):

1. **Path-rename для перемещённой skill-директории:** `architect/SKILL.md` → `role/SKILL.md` и `skills/architect/` → `skills/role/`. Это **критично** — в архитектурных файлах ~23 ссылки на `architect/SKILL.md` (footer-блоки в каждом agent.md типа «inherits the terminology policy from `architect/SKILL.md`», cross-refs в skill'ах типа `c4-diagrams/SKILL.md`, и т.д.). Без этой замены все они указывают на несуществующую директорию после move.
2. `archforge:architect` → `architect:role` (длинная substring — первая, чтобы не частично-заменилась шагом 4).
3. `/archforge:` → `/architect:` (slash-команды).
4. `archforge:` → `architect:` (оставшиеся skill-namespaces типа `archforge:c4-diagrams` → `architect:c4-diagrams`).
5. **Bare `archforge` token в `scripts/`, `hooks/`:** `session-start.sh` имеет 5 echo-строк типа `[archforge] ARCHITECTURE.md found at repo root.` — это runtime user-visible output, обновляется на `[architect]`. Аналогично в `hooks.json` (если упоминается plugin name в строках). Применять как targeted find/replace **только в этих двух директориях**, не по всему дереву.
6. **Bare `archforge` в `agents/`:** prose-упоминания типа «inherits the terminology policy from `archforge` plugin» — заменяются на `architect`. Но `architect` в `name: architect` (frontmatter) и `# architect agent` (заголовки) sub-agent'а в `agents/architect.md` **НЕ ТРОГАТЬ** — это имя другого артефакта (sub-agent'а), которое случайно совпадает с новым plugin name. Sub-agent остаётся `architect`.

**Точечная inspection (не массовая замена):** README.md, README.ru.md, CHANGELOG.md, LICENSE — каждый файл смотрится глазами. `archforge` остаётся, где речь о бренде/истории; меняется на `architect`, где речь о плагине поимённо как компоненте marketplace today.

**Plugin.json:** `name: architect`, `version: 1.0.0`. `description` адаптировать под новое имя.

**CHANGELOG:** новая запись `## 1.0.0 — 2026-05-10` в начале — описать rename + переезд в новый marketplace + breaking change для пользователей.

**Patterns to follow:**
- `plugins/product/.claude-plugin/plugin.json` как модель формата для нового `plugin.json`.
- Существующие entries в CHANGELOG.md как модель стиля записей.
- `plugins/architect/agents/architect.md` (bывший `plugins/archforge/agents/architect.md`) как пример sub-agent'а, имя которого совпадает с plugin name — не renamed.

**Test scenarios:**
- *Happy path:* `cat plugins/architect/.claude-plugin/plugin.json | jq -r .name` возвращает `architect`.
- *Happy path:* `cat plugins/architect/.claude-plugin/plugin.json | jq -r .version` возвращает `1.0.0`.
- *Happy path:* директория `plugins/architect/skills/role/` существует, `plugins/architect/skills/architect/` — нет.
- *Happy path:* `cat plugins/architect/skills/role/SKILL.md | grep '^name:'` показывает `name: role`.
- *Edge case (path-rename):* `grep -rE 'architect/SKILL\.md' plugins/architect/` — все matches должны быть на пути `role/SKILL.md` после замены; bare `architect/SKILL.md` references = 0.
- *Edge case (sub-agent guard):* `cat plugins/architect/agents/architect.md | grep '^name:'` показывает `name: architect` (НЕ `name: role`, НЕ переименован).
- *Edge case:* `grep -rE '\barchforge:' plugins/architect/` возвращает 0 строк.
- *Edge case:* `grep -rE '/archforge:' plugins/architect/` возвращает 0 строк.
- *Edge case (residue после bare-archforge replace):* `grep -rn 'archforge' plugins/architect/` возвращает строки только в **enumerated** locations: `CHANGELOG.md` (история), `README.md` / `README.ru.md` (где речь о бренде/происхождении — manual review подтверждает каждый match), `LICENSE` (если упоминается). НЕТ matches в `commands/`, `skills/`, `templates/`, `scripts/`, `hooks/`, `agents/`.
- *Edge case (echo strings):* `grep -E '^\s*echo .*\[architect\]' plugins/architect/scripts/session-start.sh` — runtime echo-строки уже не содержат `[archforge]`.
- *Integration:* CHANGELOG.md имеет валидный markdown и новую запись `## 1.0.0` сверху.

**Verification:** Plugin.json — валидный JSON с обязательными полями (`name`, `version`, `description`) согласно schema docs (`https://json.schemastore.org/claude-code-plugin.json`); проверка через `jq -e '.name and .version and .description' plugins/architect/.claude-plugin/plugin.json` (exit 0). Полная schema-валидация (через `ajv` или эквивалент) — out of scope, нет CI dep'а. Все internal references обновлены; sub-agent `architect` сохранён; CHANGELOG отражает breaking change.

---

### U3. Регистрация `architect` в `marketplace.json`

**Goal:** Добавить `architect` плагин в `kramar-studio-marketplace/.claude-plugin/marketplace.json` рядом с `product`.

**Requirements:** R4.

**Dependencies:** U1 (нужен `plugins/architect/` уже на месте, чтобы source path был валиден).

**Files:**
- Modify: `kramar-studio-marketplace/.claude-plugin/marketplace.json`

**Approach:**
- Добавить новый объект в `plugins[]` массив:
  - `name`: `architect`
  - `source`: `./plugins/architect`
  - `description`: одна-две строки про architecture cycle (peек из старого `archforge-marketplace.json` `description` за inspiration)
  - `category`: `development`
  - `keywords`: `architecture`, `system-design`, `adr`, `c4`, `code-review`, `compound-engineering`, `kramar-studio` (наследовано из старого manifest'а + добавлен `kramar-studio` в стиле product entry)
- Owner поле marketplace остаётся `Kramar IT Studio` — не трогаем.
- Marketplace `version` поле не bump'аем (этот вопрос — A2 в decision-map, отдельный цикл). Marketplace.json остаётся на текущей версии.

**Patterns to follow:**
- Существующая запись `product` в этом же файле как ровный structural template.

**Test scenarios:**
- *Happy path:* `cat .claude-plugin/marketplace.json | jq '.plugins[].name'` включает `"architect"` и `"product"`.
- *Happy path:* `cat .claude-plugin/marketplace.json | jq '.plugins[] | select(.name=="architect") | .source'` возвращает `"./plugins/architect"`.
- *Edge case:* JSON валиден (`jq empty .claude-plugin/marketplace.json` exit 0).
- *Edge case:* После добавления массив `plugins[]` имеет ровно 2 элемента (не 1 не 3 — отлавливает случайное удаление product entry).
- *Integration:* существующий `product` entry не модифицирован — его поля идентичны pre-edit состоянию.

**Verification:** Файл — валидный JSON с правильной структурой согласно schema docs (`https://json.schemastore.org/claude-code-marketplace.json`); проверка через `jq -e '.plugins | length == 2 and all(.[]; .name and .source and .description)' .claude-plugin/marketplace.json` (exit 0). Полная schema-валидация (через `ajv`) — out of scope. `architect` доступен через `/plugin install architect@kramar-studio-marketplace`.

---

### U4. Обновление cross-references в `product` плагине

**Goal:** Заменить упоминания `/archforge:*` команд и `archforge:*` skill-namespaces в `product` плагине на новые имена; `archforge` как brand/origin оставить там, где это уместно.

**Requirements:** R5, R6 (частично).

**Dependencies:** U2 (нужно знать финальные новые имена).

**Files:**
- Modify: `plugins/product/commands/define.md`
- Modify: `plugins/product/commands/discover.md`
- Modify: `plugins/product/commands/spec.md`
- Modify: `plugins/product/commands/upgrade.md` (если упоминает archforge ADRs / cycle)
- Modify: `plugins/product/skills/product-cycle/SKILL.md`
- Modify: `plugins/product/skills/product-conventions/SKILL.md`
- Modify: `plugins/product/templates/prd-template.md` (упоминание ADR cross-references)
- Modify: `plugins/product/templates/spec-template.md` (упоминание ADR cross-references)
- Modify: `plugins/product/README.md`

**Approach:**
- Не массовый find/replace — каждый файл смотрится глазами.
- **Заменить:** `/archforge:cycle` → `/architect:cycle`, `/archforge:adr` → `/architect:adr`, `/archforge:observe` → `/architect:observe`, и т.д. Любая slash-команда, которая указывает на конкретный command identifier плагина.
- **Заменить:** `archforge:architect` (skill ref) → `architect:role`. Например в `product-conventions/SKILL.md` есть фраза «See `archforge`'s `architect/SKILL.md` Language section» — становится «See `architect`'s `role/SKILL.md` Language section».
- **Оставить:** упоминания «inspired by archforge», «archforge methodology», «archforge as reference implementation» — это исторические/brand contexts.
- **Оставить:** упоминания `archforge-marketplace` где речь о бывшем repo (там, где есть; в основном это в README marketplace, не в product плагине).

**Patterns to follow:**
- Брать decisions из ADR-0001 §Decision как guide для distinction brand vs plugin-name.

**Test scenarios:**
- *Happy path:* `grep -rE '/archforge:' plugins/product/` возвращает 0 строк (ни одной references на старое имя command).
- *Happy path:* `grep -rE '\barchforge:[a-z]+\b' plugins/product/` возвращает 0 строк (ни одной skill-namespace ref).
- *Edge case:* `grep -r 'archforge' plugins/product/` показывает остатки только в brand/origin contexts; ручная inspection diff'а подтверждает intent для каждого match.
- *Edge case:* В `product-conventions/SKILL.md` фраза «archforge's architect/SKILL.md» обновлена на «architect's role/SKILL.md».
- *Integration:* После U2 + U4, если подставить имена реальных команд `/architect:cycle`, `/architect:observe` и т.д. — они существуют (verifiable через `grep -l 'name:' plugins/architect/commands/*.md`).

**Verification:** Все references в product плагине указывают на актуальные идентификаторы из плагина architect (не на устаревшие).

---

### U5. Обновление marketplace-level документов

**Goal:** Синхронизировать имена в `kramar-studio-marketplace/README.md`, `ARCHITECTURE.md`, `STRATEGY.md`, `docs/architecture/decision-map.md` с новым именованием `architect`. ADR-0001 — append-only, не правится.

**Requirements:** R6.

**Dependencies:** U2 (нужны финальные имена).

**Files:**
- Modify: `README.md` (корень) — таблица плагинов в начале (добавить `architect`), installation example, упоминания archforge
- Modify: `ARCHITECTURE.md` — §1, §3 diagram, §5 (Decision index уже включает ADR-0001), упоминания `archforge` где они о плагине
- Modify: `STRATEGY.md` — §2 уже обновлён в предыдущей сессии; пройтись на consistency и обновить остальные упоминания
- Modify: `docs/architecture/decision-map.md` — упоминания `archforge` где это о плагине (например, описание C1 «archforge сам имеет больше двух» → «architect сам имеет больше двух»)
- **NOT modify:** `docs/architecture/decisions/0001-absorb-archforge-into-kramar-studio-marketplace.md` (append-only); `docs/architecture/research/2026-05-10-cross-marketplace-dependency-posture-{discovery,research}.md` (исторические артефакты)

**Approach:**
- Каждый файл смотрится глазами; brand/origin mentions сохраняются (e.g., в ARCHITECTURE.md §1 фраза «поглощён из соседнего archforge-marketplace» остаётся как есть).
- В README marketplace — добавить строку `architect` в таблицу плагинов, обновить installation snippet чтобы показать оба плагина.

**Patterns to follow:**
- Существующая строка `product` в README markdown-таблице как template для `architect`.

**Test scenarios:**
- *Happy path:* `grep -E '\| \*\*`architect`\*\* \|' README.md` возвращает строку (architect упомянут в таблице плагинов).
- *Edge case:* `grep -E 'plugin install \w+@kramar-studio-marketplace' README.md` показывает примеры для обоих плагинов.
- *Edge case:* В `ARCHITECTURE.md` §3 diagram уже использует `plugins/architect/` (был обновлён в ADR-0001 сессии); инспекция подтверждает, что новых правок там не нужно.
- *Integration:* Файлы остаются валидным markdown; внутренние якорные ссылки (если есть) не сломаны.

**Verification:** Все marketplace-level документы упоминают `architect` как плагин, `archforge` — только в исторических контекстах. ADR-0001 не модифицирован.

---

### U6. Превращение `archforge-marketplace` в redirect-stub

**Goal:** Обновить `archforge-marketplace` репо так, чтобы (а) `marketplace.json` имел пустой `plugins[]` и описание «moved», (б) `README.md` ясно объясняет переезд + rename и даёт миграционные команды, (в) старая директория `plugins/archforge/` удалена из working tree.

**Requirements:** R7.

**Dependencies:** U1 — **именно в состоянии «KSM-HEAD verified against AF source»**, не просто «commit landed». Если KSM-HEAD diff-test (см. U1) не зелёный — НЕ начинать U6, иначе риск удалить source плагина, который не до конца докомичен в KSM. Также U6.5 (smoke-test) идёт ПОСЛЕ U6 commit'а локально, но ПЕРЕД push'ем — см. отдельную subsection ниже.

**Files (в `archforge-marketplace`, не в этом репо):**
- Modify: `archforge-marketplace/.claude-plugin/marketplace.json`
- Modify (полностью переписать): `archforge-marketplace/README.md`
- Modify (переписать как Russian-mirror migration notice): `archforge-marketplace/README.ru.md`
- Delete: `archforge-marketplace/ROADMAP.md` (`git rm` — roadmap описывал v0.5/0.6/0.7 плагина, который больше здесь не живёт; история сохранена в git)
- Delete: `archforge-marketplace/plugins/archforge/` (директория целиком; история в git сохранится)
- Optionally delete: `archforge-marketplace/plugins/` (если пустой, можно и саму директорию убрать — или оставить как placeholder)

**Approach:**
- `marketplace.json` обновить: `plugins: []`, `description` на «archforge has moved to kramar-studio-marketplace as the architect plugin. See README.», version поле можно либо оставить, либо bump'ать до `1.0.0-stub` для семантической ясности.
- README переписать по schema:
  1. Заголовок «`archforge-marketplace` — moved».
  2. Краткий explainer: что переехало, куда, когда, почему (одна строка, ссылка на ADR-0001 в новом репо для интересующихся).
  3. **Migration commands**, копируемые буквально:
     ```text
     /plugin marketplace remove archforge-marketplace        # опционально
     /plugin marketplace add https://github.com/Kramar-IT-Studio/kramar-studio-marketplace
     /plugin install architect@kramar-studio-marketplace
     ```
  4. Note about rename: команды теперь `/architect:*` вместо `/archforge:*`; skill `archforge:architect` теперь `architect:role`.
  5. Pointer на CHANGELOG нового плагина для полного breaking-change list.
  6. Footer: link к новому marketplace + к ADR-0001 для архитектурной мотивации.
- `git rm -r plugins/archforge/` (содержимое останется в git history, исчезнет из working tree).

**Patterns to follow:**
- Текущий `archforge-marketplace` **bilingual** — у него есть и `README.md`, и `README.ru.md`. Сохранить bilingual — переписать оба файла как mirror'ы migration notice'а (английская и русская версии). Это уважает существующих русскоязычных пользователей плагина.
- ROADMAP.md удаляется целиком — он описывал планы плагина, которого здесь больше нет. Содержимое roadmap'а уже уехало вместе с git history плагина в новый marketplace; нет смысла держать его в stub'е.

**Test scenarios:**
- *Happy path:* `cat archforge-marketplace/.claude-plugin/marketplace.json | jq '.plugins | length'` возвращает `0`.
- *Happy path:* `archforge-marketplace/README.md` содержит строку `kramar-studio-marketplace` и слово `architect` (миграционная команда присутствует).
- *Happy path:* `ls archforge-marketplace/plugins/archforge` — no such file or directory.
- *Edge case:* `git -C archforge-marketplace log --diff-filter=D --name-only -- plugins/archforge/` показывает удаление как один коммит (атомарно).
- *Edge case:* `git -C archforge-marketplace log -- plugins/archforge/README.md` всё ещё показывает pre-deletion историю (history preserved).
- *Edge case:* `cat archforge-marketplace/.claude-plugin/marketplace.json | jq empty` — exit 0 (валидный JSON).
- *Integration:* В imaginary fresh user setup: `/plugin marketplace add https://github.com/IgorKramar/archforge-marketplace` затем `/plugin install archforge@archforge-marketplace` падает с ясной ошибкой «plugin not found in marketplace», а не загадочно.

**Verification:** archforge-marketplace репо всё ещё клонируется и видим; user, идущий по старой инструкции, видит README с явным redirect'ом и копируемой migration command.

---

### U6.5. Smoke-test в чистом тестовом проекте (gating перед push)

**Goal:** Подтвердить, что после U1-U6 marketplace и плагины работают end-to-end в чистом проекте, **до** того как push сделает изменения видимыми пользователям.

**Requirements:** R1, R2, R3, R4, R7, R10 (cross-cutting verification).

**Dependencies:** U6 commit done (но не pushed). U1-U6 в KSM полностью зелёные локально.

**Files:** Никаких — операция через Claude Code в чистом тестовом проекте, не пишет в репо.

**Approach:**
- Создать пустую директорию вне всех репозиториев (например, `/tmp/smoke-test/`).
- В Claude Code session в этой директории: `/plugin marketplace add /Users/user/Work/self/kramar-studio-marketplace` (local marketplace source — не requires push).
- `/plugin install architect@kramar-studio-marketplace`.
- `/plugin install product@kramar-studio-marketplace`.
- Прогнать golden-flow:
  1. `/architect:init` — создаёт `ARCHITECTURE.md` и `docs/architecture/` skeleton без ошибок.
  2. `/architect:cycle "test problem"` — запускает discovery → design → decide → document без падений хука / отсутствующих skill-references.
  3. `/product:init` — создаёт `PRODUCT.md` и `docs/product/` skeleton.
  4. `/product:discover "test feature"` — упоминает `/architect:cycle` (не `/archforge:cycle`) в suggested next steps.
  5. Создать тестовый artifact с `links_to: [ADR-0001]` — хук `check-product-artifact.sh` НЕ падает.
- Проверить, что `/plugin install product@kramar-studio-marketplace` без `architect` (R10 — product-only установка) тоже работает: в *другой* свежей директории установить только product, прогнать `/product:init`.

**Patterns to follow:**
- Существующий `plugins/product/scripts/session-start.sh` как референс «как хук должен выглядеть в runtime» — без python tracebacks или unbound variables.

**Test scenarios:**
- *Happy path:* После `/architect:cycle "test problem"` файл `docs/architecture/decisions/0001-test-problem.md` создан, имеет валидный frontmatter (`id: ADR-0001`, `status: proposed|accepted`, `created_at: <today>`).
- *Happy path:* После `/product:discover "test feature"` файл `docs/product/discoveries/<date>-test-feature.md` создан и в его prose упоминается `/architect:cycle` (не `/archforge:cycle`) если есть architectural-dependency suggestion.
- *Edge case:* `/plugin install product@kramar-studio-marketplace` в директории без architect плагина успешно отрабатывает; `/product:init` создаёт PRODUCT.md без error'ов из-за «archforge не найден».
- *Integration:* Нет stderr-output от хуков с unbound-variable или path-not-found errors после переименований.

**Verification:** Все golden-flow команды отработали без error'ов; suite-level interaction (product → architect cross-link) работает. **Если smoke-test падает — НЕ push'ить, починить локально и пере-запустить.**

---

### U7. GitHub coordination

**Goal:** Обработать любые открытые issues/PRs в `archforge-marketplace`, обновить description репозитория на GitHub, pin migration-notice issue если есть несколько open issues.

**Requirements:** R8.

**Dependencies:** U6 (нужно, чтобы stub-state был уже в main).

**Files:** Никаких локально — только GitHub API через `gh` CLI.

**Approach:**
- `gh -R IgorKramar/archforge-marketplace issue list --state open` — посмотреть, что есть.
- `gh -R IgorKramar/archforge-marketplace pr list --state open` — то же для PRs.
- Для каждого open issue:
  - Если bug-report или feature-request — закомментировать о переезде и закрыть с label `migrated`. Опционально — открыть копию в Kramar-IT-Studio/kramar-studio-marketplace для tracking.
  - Если discussion / question — ответить с redirect'ом, закрыть.
- Для каждого open PR:
  - Закомментировать о переезде, закрыть. PR'ы при необходимости пере-открыть в новом репо (rebase на новую структуру).
- Создать в archforge-marketplace **pinned issue** «Plugin moved to kramar-studio-marketplace» с теми же migration commands из README. `gh issue pin` после создания.
- **In-channel signal: tagged release `v0.4.1-moved` в archforge-marketplace.** Создать через `gh release create v0.4.1-moved --notes "..."` с release notes, копирующими migration banner из README.md. Цель — release-notification firе'ит к GitHub-watcher'ам (это **push-channel**, в отличие от README/issue/description, которые требуют активно посетить репо). Watcher'ы получают email или GH-notification при появлении release; это покрывает install-pattern «marketplace add сделан давно, к репо не возвращаюсь». Не идеально (только для watchers), но единственный available push-channel без telemetry.
- Обновить description репо `archforge-marketplace` на GitHub: «Moved. See kramar-studio-marketplace.» через `gh repo edit IgorKramar/archforge-marketplace --description "..."`.
- Опционально: archive репо целиком (`gh repo archive`) — но это закроет ability комментировать pinned issue, поэтому лучше **не** archive первое время; можно archive через ~6 месяцев когда поток мигрирующих пользователей сойдёт на нет (вне scope этого плана).

**Patterns to follow:**
- Стандартный pattern для repo-deprecation на GitHub: pinned issue + updated description + README banner.

**Test scenarios:**
- *Happy path:* `gh -R IgorKramar/archforge-marketplace issue list --state open` возвращает список, в котором есть pinned migration-notice issue (или 0 issues, если ничего другого не было — тогда migration-notice — единственный).
- *Happy path:* `gh -R IgorKramar/archforge-marketplace repo view --json description` показывает description со словом «moved» или эквивалентным маркером.
- *Happy path:* `gh -R IgorKramar/archforge-marketplace release list` показывает релиз `v0.4.1-moved`; `gh release view v0.4.1-moved -R IgorKramar/archforge-marketplace --json body` содержит migration commands.
- *Edge case:* Если в archforge-marketplace были open PRs от внешних контрибьюторов — каждый имеет comment с pointer'ом и closed-state.
- *Edge case:* Если open issues было 0 — миграция-issue всё равно создан и pin'нут.

**Verification:** GitHub-разворот archforge-marketplace ясно сигналит о переезде через **четыре** surface'а: description (passive), pinned issue (passive), README (passive), tagged release (push-channel — fire'ит email/notification watcher'ам). Никаких «hanging» open issues / PRs без owner-acknowledgement.

---

## System-Wide Impact

- **Interaction graph:** `product` плагин ссылается на `architect` плагин через slash-команды и skill-namespaces в своих документах. После U4 эти ссылки обновлены; runtime — каждый плагин по-прежнему живёт независимо, никакой install-coupling нет.
- **Error propagation:** Пользователь, идущий по устаревшей инструкции (`/plugin install archforge@archforge-marketplace`), увидит standard «plugin not found» error от Claude Code; README archforge-marketplace при ручной проверке даст ему миграционные команды.
- **State lifecycle risks:** Window между push'ем kramar-studio-marketplace и push'ем archforge-marketplace stub'а — momentary fork (плагин фактически в двух местах под разными именами). Mitigation: push'ить sequence'но без длинной задержки; никакого автодеплоя ни в одном репо.
- **API surface parity:** Все public-facing surface (commands, skills, marketplace identifiers) переходят с одного имени на другое. Внутренние API (frontmatter shape, lifecycle, hook protocol) — не меняются (R10 границы).
- **Integration coverage:** После U1+U2+U3 плагин `architect` устанавливается через `/plugin install architect@kramar-studio-marketplace`; команды отвечают; cross-plugin ссылки из product работают. Это надо проверить вручную в чистом тестовом проекте (см. Documentation / Operational Notes).
- **Unchanged invariants:** Frontmatter-контракт артефактов (id/status/created_at/role/links_to), lifecycle статусов, soft-hooks-only posture, schema marketplace.json/plugin.json, structure layout `docs/<role>/` в проектах пользователей — не меняется. Стороннее использование `links_to: [ADR-NNNN]` в `product` артефактах продолжает работать против файлов из `docs/architecture/decisions/` независимо от того, какой плагин их создал.

---

## Push Coordination

Push wave — последняя irreversible операция плана. У push'а двух репо нет transactional модели: каждый push атомарен независимо, но **между ними** возможен partial-failure state. Этот раздел фиксирует pre-flight checks, success criteria и rollback playbook.

### Pre-flight checks (для каждого репо отдельно перед push)

- Working tree clean (`git status` пустой).
- Local HEAD matches expected commit (verifiable через `git log --oneline -1`).
- Auth с GitHub fresh (для CLI с SSH key — `ssh -T git@github.com` отвечает; для HTTPS+gh — `gh auth status` показывает logged in).
- Branch protection rules не блокируют (`gh api repos/<owner>/<repo>/branches/main/protection 2>/dev/null` — посмотреть, есть ли required checks; если есть — убедиться, что они выполнены до push'а).
- 2FA prompt не висит таймером (запушить любой trivial commit заранее в течение последних N минут — фиксирует сессию).

### Success criteria per push

- Push exit-code 0.
- `git ls-remote origin main` возвращает SHA, совпадающий с local HEAD.
- (если есть CI на стороне GitHub) — required-checks status: `success` через `gh run list --branch main --limit 1` после небольшого ожидания.

### Push order: KSM первый, AF второй

KSM-first — **forward-compatible**: после KSM push новый плагин `architect@kramar-studio-marketplace` доступен; старый `archforge@archforge-marketplace` ещё работает (stub не вступил в силу). Никакой пользователь не видит «инструмент исчез».

AF-first было бы **backward-incompatible**: после AF push старый install identifier перестал работать (stub), но новый ещё не доступен (KSM не запушен). Окно «нет ни старого, ни нового». Запрещено.

### Rollback playbook

**Случай 1: KSM push успешен, AF push отказался.**
- KSM main теперь содержит `architect` плагин; AF main остался с реальным `archforge` плагином. Глобальное состояние: плагин в обоих местах под разными именами. Это длится дольше, чем «sequence в минуты» — недопустимо.
- **Рекомендуемое recovery:** разобраться в причине AF push reject (branch protection / network / auth) и довести AF push до конца. Не reverse'ить KSM — это создаст новое breaking change wave.
- **Если AF push не лечится за час:** держать KSM как есть, объявить о переезде вручную (в личных каналах) с явной формулировкой «old marketplace остаётся технически рабочим до завершения миграции», planировать AF push на отдельную сессию.

**Случай 2: AF push успешен, KSM push отказался.** *(Не должно произойти, потому что push order запрещает AF-first; но защищаемся от ошибок sequencing.)*
- AF main = stub; KSM main = pre-architect. **Окно «нет ни старого, ни нового»** — пользователи видят `plugin not found` на обоих identifier'ах.
- **Recovery:** немедленно `git revert <stub-commit>` в AF локально, `git push --force-with-lease origin main` в AF (восстанавливаем pre-stub state). Потом разбираться с KSM.
- **Mitigation:** не делать AF push до подтверждения KSM push success.

**Случай 3: Оба успешны, но smoke-test post-push выявил поломку.**
- В этой точке откат painful — пользователи уже могут начать `marketplace add`/`install`. Если поломка серьёзная: `git revert` в KSM (откатывает к pre-architect), форс-push не используется на main (рискованно). Stub в AF можно держать — он не ломает ничего, кроме directing на пустой.
- **Mitigation:** smoke-test (U6.5) gates push wave для исключения этого случая. Если он зелёный — post-push поломка возможна только от runtime-environment difference (Claude Code version mismatch, etc.) — это редко.

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| `git filter-repo` уродует историю или теряет файлы. | Делать в **tmp-clone**, не в основной archforge-marketplace копии. Перед merge в kramar-studio-marketplace — diff-сверка количества файлов между tmp и оригиналом (см. test scenarios U1). Tmp удалять только после успешного commit'а в kramar-studio-marketplace. |
| Find/replace в U2 «съедает» legitimate упоминания archforge как brand'а в README/CHANGELOG. | Find/replace применяется массово только к `commands/`, `skills/`, `templates/`, `scripts/`, `hooks/`, `agents/`. README/CHANGELOG/LICENSE — точечная inspection. Test scenario U2 ловит regex-mismatch'и. |
| Внешний пользователь запускает upgrade и обнаруживает breaking change без warning. | **Четыре surface'а**: stub README/README.ru.md (passive), pinned GitHub issue (passive), CHANGELOG в новом плагине (passive), tagged release `v0.4.1-moved` (push-channel — fire'ит email/notification GitHub-watcher'ам). Acceptance: unknown audience size (нет телеметрии); делаем максимум с available channels. |
| **GitHub-only surface не достаёт до install pattern «marketplace add сделан давно, к репо не возвращаюсь».** Pinned/cloned/vendored installs (фиксированный SHA) не пулят stub-commit и продолжают видеть pre-move state до явного `git pull` или `marketplace update`. Это затрагивает пользователей, наиболее ценных по STRATEGY §4 metric «external adoption signal — повторные использования» — потому что они «осели» на стабильном setup'е. | Tagged release (`v0.4.1-moved`) частично mitigates через GitHub release-notification, но **только для watchers**. Pinned/cloned/vendored — fundamentally вне reach без telemetry. Принято: те, кто vendored, fundamentally подписались на manual maintenance; те, кто cloned для offline use — узнают, когда обновятся. Mitigation strategy: post-implementation announcement в любые каналы, где Igor имеет выход (трек E из STRATEGY, отдельная работа). |
| Window между push'ами KSM и AF создаёт ситуацию «плагин в обоих местах». | Sequence'ить push'и подряд (минуты, не часы). Нет автодеплоя ни в одном репо — ручной push даёт control над timing'ом. Худший case — пользователь, который успел `/plugin install` и из старого, и из нового — увидит conflict; Claude Code обычно даст jasно сообщение, но это edge case на single user. |
| `architect:role` оказывается worse choice, чем `architect:architect` через несколько недель usage. | Принято осознанно с user-revision'ом. Если реально мешает — отдельный цикл (см. Deferred to Follow-Up Work) для пере-rename'а. До тех пор pattern `<plugin>:role` живёт. |
| Open issues / PRs в archforge-marketplace, которые надо мигрировать, на самом деле ценны и теряются. | U7 предусматривает inspection каждого; решение по каждому — close-with-pointer или migrate-to-new-repo. Не batch-close без чтения. |
| `gh repo archive` сделанный спонтанно вырубит ability comment'ить pinned issue. | План явно НЕ archive'ит репо в U7 — отложено за scope. Archive — отдельная решение через 6+ месяцев. |
| После U2+U4, в проектах **пользователей** (не в этом репо) `links_to: [ADR-NNNN]` продолжают указывать на ADR-файлы, созданные старой версией плагина. | Файлы ADR — пользовательский контент в `docs/architecture/decisions/`, на них наш rename не влияет. Они остаются на месте, файловая конвенция не меняется. Cross-link не сломан. |

---

## Documentation / Operational Notes

- **CHANGELOG плагина** — главное место уведомления пользователей о breaking change. v1.0.0 entry в `plugins/architect/CHANGELOG.md` должна содержать: rename'ы, миграционные команды, ссылку на ADR-0001 и на этот план для интересующихся motivation.
- **Smoke-test после implementation:** в чистом тестовом проекте — `/plugin marketplace add https://github.com/Kramar-IT-Studio/kramar-studio-marketplace`, `/plugin install architect@kramar-studio-marketplace`, `/plugin install product@kramar-studio-marketplace`, и пройтись по golden flow (`/architect:init`, `/architect:cycle`, `/product:init`, `/product:discover`). Не часть автоматизированного теста (нет CI), но ручной чек перед anouncement'ом.
- **Anouncement для существующих пользователей archforge** — вне scope этого плана (трек E из STRATEGY), но стоит планировать сразу после implementation. Минимально: пост в README + tweet/blog/Slack куда там idi'ы тусуются.
- **Update `kramar-studio-marketplace/.product-version` в проектах пользователей** не требуется — этот маркер только для product плагина, archforge/architect ничего подобного не имеет.
- **Decision-map A2 (multi-level versioning) становится более срочной после implementation.** Когда два плагина в одном marketplace, каждый со своей версией — впервые становится вопросом «что инкремент чего означает». Запустить A2 cycle сразу после этого плана — рекомендуемый next step (см. также `docs/architecture/decision-map.md` после ADR-0001 update'а).

---

## Sources & References

- **Origin ADR:** [`docs/architecture/decisions/0001-absorb-archforge-into-kramar-studio-marketplace.md`](../architecture/decisions/0001-absorb-archforge-into-kramar-studio-marketplace.md)
- **Discovery:** [`docs/architecture/research/2026-05-10-cross-marketplace-dependency-posture-discovery.md`](../architecture/research/2026-05-10-cross-marketplace-dependency-posture-discovery.md)
- **Research digest:** [`docs/architecture/research/2026-05-10-cross-marketplace-dependency-posture-research.md`](../architecture/research/2026-05-10-cross-marketplace-dependency-posture-research.md)
- **Decision-map context:** [`docs/architecture/decision-map.md`](../architecture/decision-map.md) — A1 closed; A2 reframed; D4 unblocked.
- **STRATEGY context:** [`STRATEGY.md`](../../STRATEGY.md) §2 (Our approach), §5 Track A, B, C.
- **archforge-marketplace локально:** `~/Work/self/archforge-marketplace`, remote `git@github.com:IgorKramar/archforge-marketplace.git`
- **kramar-studio-marketplace remote:** `git@github.com:Kramar-IT-Studio/kramar-studio-marketplace.git`
- **`git filter-repo` documentation:** <https://github.com/newren/git-filter-repo>
- **Claude Code plugin schema:** <https://json.schemastore.org/claude-code-plugin.json>
- **Claude Code marketplace schema:** <https://json.schemastore.org/claude-code-marketplace.json>

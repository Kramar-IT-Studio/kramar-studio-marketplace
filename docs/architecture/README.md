# `docs/architecture/`

Архитектурный след этого проекта. Обновляется непрерывно вместе с кодом.

## Layout

| Directory | Contents |
|---|---|
| [`decisions/`](./decisions/) | **ADRs** — один файл на архитектурное решение. Пронумерованы, никогда не удаляются. Индекс ниже. |
| [`diagrams/`](./diagrams/) | **C4-диаграммы** в формате Mermaid `.md` (или исходники рядом с изображениями). Context (L1), Container (L2), Component (L3). |
| [`research/`](./research/) | **Discovery- и design-заметки** из `/archforge:discover` и `/archforge:design`. Снимки проблемного пространства на момент исследования. |
| [`reviews/`](./reviews/) | **Архитектурные ревью** из `/archforge:review`. Ревью значимых changeset'ов, сохранённые на будущее. |

Корневой [`ARCHITECTURE.md`](../../ARCHITECTURE.md) — живой высокоуровневый документ. ADR и диаграммы здесь — артефакты, которые его породили.

## ADR index

<!-- Сортировка по номеру, новые сверху. Записи зеркалят ARCHITECTURE.md §5. -->

_(Пока ни одного ADR.)_

| # | Date | Status | Decision |
|---|---|---|---|
| _—_ | _—_ | _—_ | _—_ |

## How to use

- Новое архитектурное решение → `/archforge:cycle "<problem>"` (полный цикл) или `/archforge:adr "<decision>"` (shortcut).
- Нужна диаграмма → `/archforge:c4 <level> "<subject>"`.
- Архитектурное ревью PR или директории → `/archforge:review [path]`.
- Просто посмотреть → начни с [`../../ARCHITECTURE.md`](../../ARCHITECTURE.md), потом drill-in в ADR.

ADR — append-only. Решения, которые перестали быть актуальными, не правятся — они superseded новым ADR. Это сохраняет историю того, как менялось мышление команды.

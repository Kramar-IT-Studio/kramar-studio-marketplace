# Devil's advocate: Multi-level versioning contract (pre-ADR)

**Target**: `docs/architecture/research/2026-05-10-multi-level-versioning-contract-research.md` + decision summary в задании
**Date**: 2026-05-10

## Summary

Самые сильные атаки: (1) Правило 5 (символический `1.0.0`) уже легализует ровно тот класс события, который Правило 4 объявляет major-only — это внутреннее противоречие, которое сделает первый же реальный bump неоднозначным; (2) определение «breaking change» в Правиле 4 апеллирует к формально не зафиксированным «contribution points» Claude Code, и любое расширение spec'а Anthropic'ом задним числом сломает контракт ретроспективно; (3) Правило 3 (маркер == `plugin.json.version` на момент init/upgrade) скрывает ловушку partial-failure upgrade, при котором маркер либо опережает реальное состояние артефактов, либо отстаёт от него, и `upgrade` в следующий раз запустит миграции из неправильной точки.

## Attacks

### A-1: Правило 4 и Правило 5 противоречат друг другу — semantic noise при первом же реальном bump'е

**Type**: logical inconsistency

**The attack**: Правило 4 фиксирует чёткий список причин для major bump (rename/remove contribution points, schema/frontmatter contract). Правило 5 разрешает one-time bump до `1.0.0` «даже если строго по правилам выше bump был бы minor». Через 6 месяцев maintainer сам не отличит: я перешёл `product 0.1.0 → 1.0.0`, потому что (а) реально сломал frontmatter контракт (Правило 4) или (б) воспользовался one-time exception (Правило 5)? Это поломка читаемости версии для самого maintainer'а, не говоря о пользователе. Хуже того: пользователь, увидев `product 1.0.0`, не имеет способа узнать — должен ли он запускать `/product:upgrade` (нужны миграции, как в случае Правила 4) или нет (символический bump по Правилу 5). Без этого знания контракт «major == пользователь обязан что-то сделать с проектом» рушится.

**Where in the artifact**: Правила 4 и 5 в decision summary; в research-digest §«Implications» п.4 narrows breaking change до VS Code-style — символический 1.0.0 туда не вписан и противоречит этой формулировке.

**Severity**: high — это контрактная двусмысленность, которая обесценивает major-bump как сигнал; проявится при первом же `product 0.1 → 1.0` событии.

### A-2: «Contribution points» — нестабильная база. Anthropic расширит spec — наш контракт сломается ретроспективно

**Type**: hidden assumption

**The attack**: Правило 4 определяет breaking change как rename/remove «contribution points: commands, skills, agents, hooks». Это термин из VS Code, не из Claude Code spec'а. Скрытое предположение: набор contribution points стабилен. На самом деле Anthropic уже добавлял новые виды (sub-agents, output styles, MCP wiring) — и продолжит. Когда в Claude Code появится новый contribution point (скажем, `tools/`, или `prompts/`, или `policies/`), наш контракт будет молчать про то, breaking ли его удаление. Хуже: если plugin использует существующий contribution point способом, который Anthropic в новой версии переинтерпретирует (pre-existing skill стал triggered иначе) — мы по нашим правилам должны не bump'ать (поведение не менялось «нашими руками»), но user это увидит как breaking. Контракт делегирует semantic'у version'а внешнему spec, который мы не контролируем.

**Where in the artifact**: Правило 4, первый bullet; research-digest §«Implications» п.4 explicitly импортирует «VS Code pattern» как референс — но Claude Code != VS Code.

**Severity**: medium — реальный hit при следующем мажорном обновлении Claude Code, что в этой экосистеме случается часто.

### A-3: Маркер `.<plugin>-version` рассинхронизируется при partial-failure upgrade

**Type**: failure mode / concurrency

**The attack**: Правило 3 — маркер «ровно повторяет `plugin.json.version` на момент init или последнего успешного `upgrade`». Сценарий: пользователь запускает `/architect:upgrade` для перехода `1.0.0 → 1.1.0`. Миграция включает переименование 12 ADR файлов и правку frontmatter в каждом. На седьмом файле — конфликт (пользователь руками отредактировал файл, mv не проходит, или диск кончился, или Claude Code был прерван Ctrl-C в середине). Что должен сделать `upgrade`? Контракт молчит. Если он перезаписал `.architect-version = 1.1.0` оптимистично — следующий `upgrade` пропустит миграцию `1.0 → 1.1` и проект остаётся в полу-мигрированном состоянии навсегда. Если маркер не переписан — пользователь руками докомитит 5 файлов и при следующем `upgrade` получит повторную попытку миграции `1.0 → 1.1` поверх уже частично применённой. Без явного rollback/idempotency правила маркер неверно описывает состояние артефактов.

**Where in the artifact**: Правило 3; контракт «маркер == версия после последнего успешного upgrade» предполагает, что upgrade — атомарная операция, что для markdown-инструментария без транзакций неверно.

**Severity**: high — приводит к silent data corruption (артефакты в смешанном формате) или к повторному применению миграций (double-rename, double-frontmatter-injection).

### A-4: Правило 4 — refactor SKILL.md «при сохранении behavior» неверифицируем. Скрытое предположение про behavior-equivalence у LLM-prompt'ов

**Type**: hidden assumption

**The attack**: «НЕ breaking — internal refactor с preserved behavior (system-prompt rewording в SKILL.md при сохранении behavior)». Скрытое предположение: refactor system prompt'а сохраняет behavior. У LLM-системных промптов это **нельзя гарантировать** — переформулировка одного абзаца меняет distribution выходов модели, может сместить tone, длину артефактов, выбор формулировок в frontmatter, частоту push-back. Для пользователя, который зависит от exact формы output'а (например, его CI grep'ает по конкретной фразе из ADR template, или его custom hook парсит specific frontmatter wording) — это breaking change без bump'а. Контракт даёт maintainer'у право объявить «behavior preserved» по самооценке, без способа верифицировать это иначе кроме как «я так считаю». Это лазейка размером с весь plugin.

**Where in the artifact**: Правило 4, последний bullet «НЕ breaking — internal refactor».

**Severity**: medium — приведёт к skipped major bumps когда они должны были быть, что подтачивает доверие к версии в long run.

### A-5: «Маркер ровно повторяет version» ломается при `architect 1.0.0` post-rename

**Type**: edge case / hidden assumption

**The attack**: Контекст говорит: `architect` перешёл `0.4.0-rc3 → 1.0.0` через rename (бывший `archforge`). У пользователя, который installил `archforge` до rename, существует `.archforge-version = 0.4.0-rc3` (или старый маркер с другим именем — `archforge`). После переименования плагина и его absorption (ADR-0001) — какой маркер ищет `/architect:upgrade`? Правило 3 не покрывает случай, когда маркер унаследован от прежнего имени plugin'а. Если `upgrade` ищет только `.architect-version` — он не найдёт, посчитает проект fresh, не запустит миграцию rename. Если ищет оба — какой считается ground truth при наличии обоих? Контракт это не описывает. Это не гипотетика: это уже произошло (architect 1.0.0 после rename) и существующие пользователи `archforge` к этому уязвимы прямо сейчас.

**Where in the artifact**: Правило 3 + Правило 4 (rename как breaking) — пересечение этих двух правил для случая plugin name change не определено; F11 в discovery упоминает эту неоднозначность, но контракт её не закрывает.

**Severity**: high для существующих `archforge` users; реализуется на первом же `/architect:upgrade` после ADR-0001.

### A-6: Правило 6 (no `dependencies`) обесценивает Правило 4 при cross-plugin frontmatter contract

**Type**: logical inconsistency

**The attack**: Правило 4 говорит: смена frontmatter contract артефактов = breaking. Правило 6 говорит: cross-link через `links_to: [ADR-NNNN]` остаётся file-convention-based, без `dependencies`. Сценарий: `architect` 2.0.0 меняет frontmatter ADR (например, добавляет required `cross_links_format_version: 2`). По Правилу 4 — это breaking для `architect`. Но `product` v0.X в своих PRD ссылается на ADR через `links_to`. После architect upgrade product-PRD остаются с старым форматом. В каком плагине должен быть bump? Правило 4 говорит «у того, кто меняет contract» — то есть `architect`. Но реальная боль у `product`-артефактов. Без `dependencies` (Правило 6) `/product:upgrade` не знает, что соседний плагин стал 2.0 и что product-артефакты стали невалидны. Контракт не обеспечивает coordination, которой требует Правило 4 от cross-plugin frontmatter изменений. Дрейф нарастает молча.

**Where in the artifact**: Правило 4 (frontmatter contract = breaking) против Правила 6 (no formal dependencies); пересечение не покрыто.

**Severity**: medium — проявится первый раз, когда меняется shared мета-форма (что по STRATEGY §2 ожидается «синхронно для всех плагинов» — то есть это пункт-времени, не «если»).

### A-7: Правило 7 (README maturity == proxy для semver) ломается одним правилом 5

**Type**: logical inconsistency

**The attack**: Правило 7: «scaffolded < 1.0.0; active >= 1.0.0; planned без version». Правило 5: символический bump до `1.0.0` разрешён. Сценарий: maintainer воспользовался Правилом 5 для `ops 0.1.0 → 1.0.0` чтобы «отметить переход в active». По Правилу 7 теперь `ops` обязан числиться `active` в README — даже если по факту content-fill ещё не закончен и `ops` всё ещё scaffolded по реальному состоянию. Maintainer теперь вынужден либо лгать в README (`ops` помечен `active`, фактически — scaffold), либо нарушать Правило 7 (помечен `scaffolded`, версия >= 1.0.0). Правило 5 — троянский конь для Правила 7.

**Where in the artifact**: Правила 5 и 7 одновременно.

**Severity**: low — это документная inconsistency, проявится только если правило 5 будет реально использовано более одного раза. Но дешевле зафиксить сейчас, чем потом.

### A-8: Контракт молчит про pre-release / RC / beta

**Type**: edge case

**The attack**: `architect` уже имел `0.4.0-rc3`. Контракт версии описывает только X.Y.Z. Что значит -rc3? Можно ли `1.0.0 → 1.1.0-beta.1`? Считается ли `0.2.0-rc.1` breaking относительно `0.1.0`? Что записывает маркер `.<plugin>-version` для prerelease — полное `1.1.0-beta.1` или нормализованное `1.1.0`? `/upgrade` миграции для прыжка с stable на prerelease — существуют? Если maintainer завтра захочет cut RC для проверки изменений на себе, контракт его не направляет, и он сделает выбор ad-hoc. Правило 3 («маркер ровно повторяет plugin.json.version») технически работает, но семантика migration-ranges на prerelease undefined.

**Where in the artifact**: Молчание контракта; ни одно из 7 правил не упоминает prerelease/build-metadata.

**Severity**: low пока — но architect уже имел RC, значит вероятность будущего использования высока.

## Strongest single attack

**A-1.** Правило 5 (символический `1.0.0`) разрушает значение major bump'а как сигнала «у пользователя есть работа». Через два-три bump'а сам maintainer не сможет ответить на вопрос «должен ли пользователь запускать `/upgrade`», и это убивает основное обещание контракта. Правило 5 надо или убрать, или явно отвязать от семантики «1.0.0 = breaking» — то есть оно требует своего отдельного маркера в CHANGELOG (`symbolic-1.0`, не `breaking`), иначе вся остальная конструкция течёт.

## Gaps in your own analysis

- **Не атаковал стоимость поддержки контракта** — это futurist/pragmatist territory. Вопросы вида «через год вспомнит ли maintainer Правило 5» лежат там.
- **Не атаковал interaction с upcoming `ops` и `security` плагинами** — об их contribution points и frontmatter contracts ничего не известно, атаковать вакуум некорректно.
- **Не атаковал rollback story**. Контракт описывает only forward (init, upgrade). Что значит downgrade `architect 1.1.0 → 1.0.0` — тема для отдельной формулировки, контракт молча её не покрывает; это потенциально A-9, но без конкретного use case рискует быть «what if universe ends» атакой, поэтому опускаю.
- **Не атаковал atomicity самого bump-events** (что если plugin.json bump'нут, а CHANGELOG нет; что если architect bump'нут в коммите, а соседний product не отрефлексирован) — это уже на грани с governance, что не моя роль.

Terminology pass: применено к телу (calques: «breaking change», «major bump», «contract», «marker» — оставлены как принятые в самом артефакте; технические identifiers `plugin.json`, `marketplace.json`, имена плагинов, ADR-NNNN, semver — сохранены). Identifiers preserved.

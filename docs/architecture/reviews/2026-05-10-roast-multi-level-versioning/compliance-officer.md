# Compliance and security: Multi-level versioning contract для Kramar Studio Suite

**Target**: pre-ADR decision (sketch выше) + контекст из `STRATEGY.md`, `ARCHITECTURE.md`, `docs/architecture/research/2026-05-10-multi-level-versioning-contract-{discovery,research}.md`, ADR-0001, `LICENSE`, `plugins/architect/CHANGELOG.md`
**Date**: 2026-05-10
**Disclaimer**: я не юрист. Нижеперечисленные находки — это вопросы, которые задаст compliance- или security-ревьюер; финальная регуляторная квалификация требует специалиста.

## Summary

Decision о versioning'е сам по себе не обрабатывает PII и не пересекает регуляторные границы — его регуляторная поверхность тонкая и косвенная. Однако он закрепляет четыре supply-chain и audit-trail контракта, у которых compliance-импликации ненулевые: (1) рамку «что считать breaking change» — то есть когда security audit team в чужой org должна re-review плагин; (2) отсутствие formal `dependencies` поля, что заметно меняет SBOM/SLSA-историю плагина; (3) формат CHANGELOG как единственного machine-/human-readable аудит-маркера; (4) семантику изменения frontmatter артефактов, которые могут хранить regulated content в проектах пользователей. Самый тонкий слой сейчас — пункт 4: в decision правило 4 объявляет «change frontmatter contract = breaking», но не определяет notification mechanism для downstream проектов, в которых эти артефакты могут быть GDPR/HIPAA/152-FZ-relevant.

## Applicable regulations and standards

Для проекта в его текущем виде (OSS marketplace markdown-плагинов, MIT, single maintainer, исполняется в чужой среде через Claude Code):

- **MIT License (OSI)** — собственная лицензия проекта; обязывает сохранять copyright/notice при дистрибуции; «AS IS» disclaimer есть. Применима к собственному коду; не индемнифицирует от third-party license claims через зависимости.
- **GDPR (EU 2016/679)** — релевантен косвенно: (i) если у проекта появятся европейские contributors (PII в commit metadata, GitHub issues), maintainer становится controller для этих данных; (ii) поскольку плагин может писать артефакты с PII в чужих проектах, формат frontmatter становится частью data processing pipeline у downstream-controller'ов.
- **152-ФЗ (РФ)** — релевантен только если проект явно рассчитан на пользователей-резидентов РФ (STRATEGY.md этого не утверждает); для самого OSS-репо неприменим, для downstream-проектов внутри РФ — может стать вопросом, если артефакты несут PII субъектов.
- **SLSA / SSDF (NIST SP 800-218) / OpenSSF Best Practices** — это не «закон», но это **де-факто supply-chain compliance baseline**, по которому security teams в org'ах оценивают upstream OSS-зависимости. Прямо релевантно: marketplace будет ставиться в чужие репо через `/plugin marketplace update`.
- **EU Cyber Resilience Act (CRA, Regulation (EU) 2024/2847)** — применимо к «products with digital elements», поставляемым на рынок ЕС. OSS, поставляемое некоммерчески, в значительной степени exempt по финальному тексту, но «manufacturers» с коммерческой связью получают обязательства по vulnerability disclosure и SBOM. Для single-maintainer OSS-проекта без коммерческого канала — пока низкорисково, но если Kramar IT Studio когда-либо начнёт offering paid support / managed services вокруг плагинов, статус изменится. Сегодня — out-of-scope, но пометка для радара.
- **DCO / CLA нормы для OSS-contributions** — релевантны, если проект примет внешний PR; сейчас файлов типа CONTRIBUTING/CLA/DCO нет.

Не применимы (по прочтению STRATEGY): HIPAA, PCI-DSS, SOX, CCPA как прямые обязательства проекта — нет соответствующих data flows. Косвенно через downstream — см. ниже C-3.

## Findings

### C-1: Семантика «breaking change» определена для функционального API, но не для security audit surface
**Category**: supply-chain security / authn-authz (косвенно)

**The gap**: Правило 4 списка перечисляет три класса breaking changes: rename/remove contribution points, change input schema, change frontmatter contract. Это всё — **functional API breaks**, заимствованные из VS Code-паттерна (research §8). Из списка выпадают изменения, которые для security audit team в org'е, ставящей плагин в свой dev-environment, считаются major даже без functional change: (a) **изменение содержимого hook-скриптов** (`scripts/session-start.sh`, `reminder-large-change.sh`) — это код, исполняемый в shell пользователя при каждом session start; (b) **добавление/изменение sub-agents'ов**, способных выполнять tool calls с правами Claude Code session; (c) **введение нового external network egress** из плагина (например, если skill начинает рекомендовать `WebSearch` к новому домену, или hook начинает делать curl); (d) **изменение списка required Claude Code permissions** или tool surface, к которому скилл обращается.

Сейчас все эти изменения попадут в minor или patch bump, и `/plugin marketplace update` тихо подтянет их у downstream'а. Для org'и с change-management процессом по supply-chain (даже базовым SLSA L1) это означает: на minor bump никакого re-review не нужно, поэтому изменения в hook-shell-скриптах поедут в production-like dev-env без ревью.

**Where in the artifact**: правило 4 sketch'а («Breaking change для плагина: rename/remove contribution points; change input schema; change frontmatter contract»). Молчание о hook-script content и agent-tool-surface как breaking-trigger.

**Severity**: medium. Для собственного использования maintainer'ом — низкий риск; для targeted user persona по STRATEGY (соло-инди) — типично низкий; для любой org'и с формальным supply-chain процессом — высокий, потому что blow-by silent updates это именно тот класс события, который SLSA-фреймворки требуют ловить.

**What would close this**: расширить правило 4 двумя классами: (1) «изменение hook-shell-скриптов или их chmod surface» = minimum minor bump с явной CHANGELOG-пометкой `### Security-relevant`; (2) «добавление новых external network endpoints или новых required tool permissions» = minimum minor с такой же пометкой. Major не обязателен, но **отдельный CHANGELOG-маркер**, который downstream может grep'ать, — да.

### C-2: Отсутствие formal `dependencies` ослабляет SBOM/supply-chain аудит плагина
**Category**: supply-chain security / third-party risk

**The gap**: Правило 6 объявляет «`dependencies` field в `plugin.json` НЕ используется», cross-link идёт через `links_to: [ADR-NNNN]` file-convention. Для функциональной независимости плагинов это разумно (и согласовано с ADR-0001). Compliance-импликация: SBOM-генераторы (CycloneDX, SPDX, syft и т.п.) и аудит-инструменты определяют upstream-граф плагина по `dependencies`. Без них:

- Внешний security-ревьюер, генерирующий SBOM из marketplace, увидит каждый плагин как self-contained zero-dep artifact. Это формально верно для machine-readable spec, но **скрывает реальные связи**: у `architect` есть `compound-integration` skill, который рекомендует interleaving с external `compound-engineering` plugin; у `product` (через `links_to`) есть soft-coupling с `architect`. SBOM этого не покажет.
- Если в будущем выйдет CVE или security advisory против EveryInc `compound-engineering` плагина (упомянут в CHANGELOG 0.2.0 architect'а как integration target), `architect` плагин не будет автоматически surfaced как «affected via integration» в любом downstream automated supply-chain scanner'е.
- Аналогично с Claude Code core — плагин фактически зависит от plugin spec и hook validator, но это не записано anywhere machine-readable. Если Anthropic выпустит security-related breaking change в hook spec, transitive impact на установленные плагины не выявляется автоматически.

**Where in the artifact**: правило 6 («`dependencies` field … НЕ используется. Cross-link через `links_to: [ADR-NNNN]` file-convention-based») молчит о том, чем заменяется audit-trail для intra-suite и для external integration coupling.

**Severity**: medium. Для текущего масштаба и user persona — низко (никто SBOM марktplace'а не генерирует). Если/когда появится first enterprise user — это первый вопрос аудитора.

**What would close this**: ADR должен явно зафиксировать **compensating control**: либо (a) рекомендованная практика — каждый плагин ведёт `INTEGRATIONS.md` (machine-readable list of soft integrations с external и intra-suite plugins), либо (b) собственный `links_to:` ADR-trail дополняется CHANGELOG-пометкой при изменении integration-coupling, либо (c) явное acknowledgement что «SBOM-coverage out of scope для этого OSS-проекта» — последнее тоже валидное compliance-решение, но оно должно быть **явным**, иначе будет читаться как oversight.

### C-3: Изменение frontmatter артефактов = breaking, но без notification контракта для regulated content в downstream проектах
**Category**: PII flow / consent / retention

**The gap**: Правило 4 объявляет «change frontmatter contract артефактов» breaking change. Это правильно для функциональной совместимости. Compliance-вопрос: **что обязан сделать пользователь, если в его проекте PRD/SPEC/HYP/VAL/SCAN/ADR хранят regulated content** — например, PRD на feature, обрабатывающий PII субъектов GDPR? Когда плагин bump'ает major из-за изменения frontmatter:

- Меняется ли retention/handling promise по этим артефактам? (artefacts are user content; lifecycle status field — это в т.ч. фактически retention marker для продуктовых решений, которые ссылаются на PII-обработку).
- Если frontmatter добавляет, скажем, поле `data_classification` или меняет enum в `lifecycle`, downstream-controller GDPR обязан re-evaluate его ROPA (record of processing activities), потому что артефакт — часть документации обработки.
- Migration script (`/<role>:upgrade`) перезаписывает артефакты в проекте пользователя. Если артефакт — часть GDPR-документации, эта перезапись формально является изменением processing record, для которого может потребоваться audit log в системе пользователя. Сейчас migration просто mutate'ит файл; никакого backup/diff/audit emit'а из плагина нет.

ARCHITECTURE.md §6 прямо помечает: «миграция повредила артефакты в чужом проекте — как откатить». Этот open question — больше чем functional safety; это compliance-trigger для downstream'а.

**Where in the artifact**: правило 4 устанавливает breaking-trigger, но контракт notification/migration safety для regulated content downstream не описан ни в нём, ни в decision как целом.

**Severity**: medium. Для самого проекта — низко (мы не controller). Для downstream'а в regulated context — вопрос, который их compliance team задаст до approval'а плагина. Решается дешёво.

**What would close this**: добавить в ADR одну явную клаузу: «Любая major bump, затрагивающая frontmatter контракт, должна (a) перечислить affected fields в CHANGELOG в отдельном `### Frontmatter changes` блоке; (b) migration script обязан по умолчанию писать backup-файл перед mutation (`<artifact>.bak-<timestamp>` или git-stash); (c) artefacts переходят `lifecycle` → `superseded`, не удаляются (это уже зафиксировано в ARCHITECTURE.md Quality Attributes — но не связано явно с breaking-change правилом)». Это нулевой code-cost и закрывает вопрос compliance-team у downstream'а.

### C-4: README maturity-signal как proxy для semver — неподписанный канал, потенциально mismatched с binding контрактом
**Category**: audit trail / supply-chain security

**The gap**: Правило 7 объявляет «README maturity-signal — proxy для semver». README — это human-readable сигнал, легко out-of-sync с machine-readable `plugin.json.version`. Для аудитора, оценивающего «сколько production-ready этот плагин», это создаёт две конкурирующие истины: (i) `plugin.json` machine-fact (`architect 1.0.0`), (ii) README prose («architect: active (v1.0)»). Если они drift'нут (типичный сценарий: bump до 1.1.0 без обновления README статуса) — какая истина binding'овая?

Дополнительная грань: для compliance это вопрос **integrity of representation**. Если downstream-org решает install плагин на основе README status «active», а через релиз README говорит то же самое, но `plugin.json` теперь `0.9.0-rc` (например, после rollback) — org действует на основе stale signal.

**Where in the artifact**: правило 7 объявляет proxy-семантику, но не описывает (a) какая версия binding'овая при mismatch, (b) есть ли любая дисциплина sync'а README ↔ plugin.json.

**Severity**: low. Для масштаба single-maintainer drift редок, и финальная истина — `plugin.json` (parsed by Claude Code). Но это finding, который аудитор отметит «один источник истины не определён».

**What would close this**: одна строка в ADR — «при любом расхождении binding considered `plugin.json.version`; README maturity — informational». И/или добавить в `/<role>:status` команду проверку sync'а.

### C-5: CHANGELOG — единственный аудит-маркер для change management, но контракт его формата не закреплён
**Category**: audit trail

**The gap**: Decision implicitly опирается на CHANGELOG (см. CHANGELOG.md `architect`'а — он действительно богат и хорошо ведётся, по Keep-a-Changelog). Но в decision sketch'е CHANGELOG **не упомянут**. Для команды с change-management процессом аудит выглядит так:
1. Что bump'нулось (`plugin.json.version` diff).
2. Что именно изменилось в API (CHANGELOG).
3. Есть ли security advisory (отдельно? в CHANGELOG?).
4. Какова migration (CHANGELOG или migration files).

Сейчас:
- (3) полностью отсутствует — нет SECURITY.md, нет canonical place для security-related notice (см. также C-1: даже если security-relevant изменение есть, его не во что положить).
- (4) для `architect` в CHANGELOG ведётся хорошо, но в decision sketch'е versioning'а не закреплён обязательностью CHANGELOG для каждого bump'а.
- Нет требования machine-readable формата (нет `changelog.json`, нет conventional commits как mandatory). Для авто-парсинга security teams'ами CHANGELOG.md плохо парсится.

**Where in the artifact**: silent — decision не упоминает CHANGELOG как часть контракта.

**Severity**: medium для (3), low для (4). Отсутствие SECURITY.md / SECURITY policy — это первое, что любой supply-chain аудитор отметит у OSS-проекта (см. OpenSSF Scorecard — Security-Policy check).

**What would close this**: ADR должен явно ссылаться на CHANGELOG как обязательный аудит-trail для каждого bump'а и упомянуть, что **security-relevant** изменения (см. C-1) должны быть выделены отдельным sub-блоком (например, `### Security`). Отдельно — добавить в repo `SECURITY.md` (это вне scope этого ADR, но логичный сосед — опционально упомянуть как next step).

### C-6: «Символический 1.0.0 как one-time исключение» подрывает downstream auto-update предположения
**Category**: supply-chain security

**The gap**: Правило 5: «символический `1.0.0` — допустимое one-time исключение на „scaffolded → active"». Семантически разумно (research §6 это легитимизирует через SemVer 2.0). Compliance-импликация: для downstream'а с auto-update policy «принимаем patch и minor автоматически, major требует ревью», скачок `0.x.y → 1.0.0` triggers ручное ревью (`major`). Если такой 1.0.0 — «scaffolded → active» без functional breaking change, то аудитор, открывающий CHANGELOG, не найдёт breaking-change list — и это создаёт диссонанс: «major bump без breaking changes — что-то пропустили?».

Возможный flow ошибки: аудитор отказывает в approval'е, потому что не может closure'нуть «major bump без явного breaking — significato». Не риск нарушения регуляции, но риск supply-chain friction, который может быть mistaken for compliance issue.

**Where in the artifact**: правило 5.

**Severity**: low. Симптом, не нарушение.

**What would close this**: одна строка в ADR — «при использовании символического 1.0.0 (без functional break) CHANGELOG обязан явно сказать `No breaking API changes — version reflects maturity transition` в верхней строке release entry». Это снимает confusion аудитора в одну строку.

### C-7: Marker `.<plugin>-version` пишется в проект пользователя — статус как user content vs. tool artifact не определён
**Category**: PII flow (потенциально) / encryption posture (косвенно)

**The gap**: Правило 3: маркер пишется в проект пользователя. Это файл **внутри** репозитория пользователя; commit'ится в его git-историю. Для большинства пользователей — никаких импликаций. Edge case, который compliance-ревьюер задаст:

- Для пользователей в high-classification environments (например, classified gov repos, healthcare repos с PHI), любой третьesторонний tool, добавляющий файл-маркер в репо, требует review — потому что (a) маркер — это идентифицирующий артефакт «этот репо использует <X>» (information disclosure для атакующего), (b) маркер участвует в backup/retention pipeline пользователя, (c) маркер должен быть в `.gitignore`-able состоянии, если пользователь хочет.

- Решает ли decision вопрос «маркер обязан быть commit'нутым в git, или это per-user choice»? Если обязан, то это **mandatory artifact**, который нельзя audit-suppress'нуть. Если опционален, `/<role>:upgrade` должен handle оба случая.

**Where in the artifact**: правило 3 описывает что и зачем, но не описывает гарантии «file is plain text, contains only semver string, no PII, может быть .gitignore'нут пользователем без ломания upgrade'а».

**Severity**: low. Для realistic user persona по STRATEGY (соло-инди) — практически нулевой риск. Но тривиально закрывается одной строкой.

**What would close this**: одна клауза в ADR — «маркер содержит ровно SemVer-string, ничего больше; пользователь может .gitignore'ить его; `/<role>:upgrade` при отсутствии маркера предлагает recovery flow (re-init или manual version specification), но не падает».

## What's well-handled

- **MIT license** на проекте — чётко указана в `plugin.json` обоих плагинов, файл `LICENSE` в корне, copyright Kramar IT Studio. License compliance для OSS distribution базово закрыт.
- **CHANGELOG.md** в `architect/` — образцовый по структуре (Keep-a-Changelog, явные секции `Changed (BREAKING)` и `Migration from X.Y.Z`). Аудит-trail для breaking changes между 0.1.0 и 1.0.0 reconstructable из одного файла. Это редкость в OSS-плагинах в Claude Code экосистеме (research §7 это подтверждает).
- **Soft-hooks-only constraint** (ARCHITECTURE.md §2 + §7) — security-positive: hooks никогда не блокируют tool use и не изменяют файлы пользователя. Это снимает целый класс concerns про «плагин трогает мои файлы без моего ведома».
- **`session-start.sh` skript** — read-only, exits 0, не делает network egress, не пишет в файлы. Для shell-script, который executed at every session start в чужом dev-env, это правильный baseline.
- **ADR-0001 трактует rename как breaking** — правильно установленный прецедент. Decision sketch это формализует в правиле 4.
- **Per-plugin independent versioning** (правило 1) совместим с `/plugin install <name>@kramar-studio-marketplace` в ADR-0001 — пользователь не вынужден ставить целиком suite, может опт-ин на per-plugin basis. Это снижает blast radius любой будущей security-issue в одном плагине.

## Areas I couldn't evaluate

- **Маршрут публикации marketplace в Anthropic'овский регистр** (если такой существует/появится). Если в будущем появится «Anthropic plugin marketplace» с verifications/signing, то текущая semantics versioning'а должна align'иться с тамошними требованиями — на данный момент это unknown territory (research §7 confirm'ит).
- **Realistic user persona в regulated industries**. STRATEGY.md описывает «соло-инди» как primary; если в будущем появится targeted enterprise pivot, многие из low-severity findings выше станут medium-high. Не могу оценить вероятность.
- **GitHub-side compliance** (Dependabot security alerts, GitHub Advisory Database, CodeQL) — зависит от GitHub-настроек репо, которые я не вижу через файлы.
- **Поведение Claude Code в момент `/plugin marketplace update`** — насколько update silent vs. prompted, какие permissions переутверждаются. Это runtime-вопрос plug-in host'а, не контракта плагина; влияет на real-world severity C-1.
- **Будущие плагины `ops`, `security`** — если `security` плагин будет содержать threat-modeling шаблоны, его frontmatter контракт сам станет regulatory-relevant content (С-3 эскалирует). Сейчас плагин planned (v0.4), не оцениваю.

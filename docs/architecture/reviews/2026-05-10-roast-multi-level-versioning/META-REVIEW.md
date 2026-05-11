# Meta-review: roast «multi-level versioning contract»

**Target**: `/Users/user/Work/self/kramar-studio-marketplace/docs/architecture/reviews/2026-05-10-roast-multi-level-versioning/`
**Date**: 2026-05-10
**Plugin version**: archforge `0.4.0-rc3` (templates from `/Users/user/.claude/plugins/cache/archforge-marketplace/archforge/0.4.0-rc3/`)
**Scope**: 5 per-role файлов (`devil-advocate.md`, `pragmatist.md`, `junior-engineer.md`, `compliance-officer.md`, `futurist.md`).

## Summary

Per-role документы внутри **в основном** соответствуют шаблонам (секции на месте, identifiers в латинице, language pass очевидно проводился). Но roast-директория как целое **диверджирует от структурного контракта** `commands/roast.md` сразу по двум осям: (а) отсутствует `00-summary.md` — обязательный read-first артефакт, который и есть точка интеграции с шаблоном; (б) файлы не пронумерованы (`01-`, `02-`, ...). Это самое тяжёлое нарушение в наборе. Дополнительно: два файла используют **переименованные finding-ID-схемы** (`A-N` у devil-advocate вместо `B-N`; `P-N` у pragmatist вместо `H-N`), что прямо нарушает правило identifier-preservation, вынесенное в `commands/roast.md` §«Language and template integrity» и в каждом agent file явным запретом.

## Findings

### M-1: Отсутствует обязательный `00-summary.md` — нарушен главный structural контракт roast-директории

**Category**: template conformance
**Severity**: high — артефакт неполный; нарушено основное обещание `/archforge:roast`
**Where**: вся директория `/Users/user/Work/self/kramar-studio-marketplace/docs/architecture/reviews/2026-05-10-roast-multi-level-versioning/`
**The divergence**: `commands/roast.md` §4 явно прескрайбит структуру:
```
docs/architecture/reviews/YYYY-MM-DD-roast-<artifact-slug>/
  ├── 00-summary.md
  ├── 01-devil-advocate.md
  ├── 02-pragmatist.md
  ├── ...
```
И §5 далее называет `00-summary.md` «the aggregate» с прескрайбленной структурой (`## Headline findings`, `## Severity counts`, `## Cross-cutting concerns`, `## Recommended path`, `## Per-role outputs`). Также §7 говорит «the summary is the chat surface; the role docs are for the deep read». Без `00-summary.md` roast не имеет точки агрегации, нет cross-cutting concerns (которые Pragmatist в P-6 и Devil-advocate в A-5 явно пересекаются, но это никем не отражено), нет recommended path (apply / re-roast / step back), нечего показать в чат. В терминах самого `commands/roast.md`: «A directory, not a single file — each role's output is its own document for clean reading» — но **только если** есть summary, без неё это просто пять разрозненных документов.
**Suggested fix**: создать `00-summary.md` по шаблону из `commands/roast.md` §5: `## Headline findings` (одна строка от каждой роли), `## Severity counts` (таблица high/medium/low по ролям), `## Cross-cutting concerns` (минимум обязательная пара: «marker / version drift unobserved by anyone» — её поднимают P-6, A-3, A-5, J-7, C-7), `## Recommended path` (вероятнее всего «apply and proceed» с двумя must-fix: A-1/F-1 про символический 1.0.0 и A-3/J-7 про partial-failure upgrade), `## Per-role outputs` (ссылки на остальные пять файлов).

### M-2: Файлы не пронумерованы (`01-…05-`), вопреки прескрипции

**Category**: template conformance
**Severity**: medium — диверджирует от шаблона; ломает sortable layout, который шаблон ожидает
**Where**: имена всех пяти файлов в директории
**The divergence**: `commands/roast.md` §4 прямо называет имена: `01-devil-advocate.md`, `02-pragmatist.md`, `03-junior-engineer.md`, `04-compliance-officer.md`, `05-futurist.md`. Текущие имена — `devil-advocate.md`, `pragmatist.md`, и т.д. без префикса. Префикс не косметический: он фиксирует канонический порядок чтения (devil → pragmatist → junior → compliance → futurist), который воспроизводится в severity-таблице summary и в headline findings. Без префикса `ls` сортирует алфавитно (`compliance-officer` идёт первым), что десинхронизирует визуальный порядок с шаблонным.
**Suggested fix**: переименовать через `git mv`:
- `devil-advocate.md` → `01-devil-advocate.md`
- `pragmatist.md` → `02-pragmatist.md`
- `junior-engineer.md` → `03-junior-engineer.md`
- `compliance-officer.md` → `04-compliance-officer.md`
- `futurist.md` → `05-futurist.md`

### M-3: Devil-advocate использует finding ID `A-N` вместо прескрайбленного `B-N` — broken identifier

**Category**: identifier preservation
**Severity**: high — finding IDs cross-reference в summary; смена префикса silently ломает связь
**Where**: `devil-advocate.md` строки 12, 22, 32, 42, 52, 62, 72, 82 (все восемь findings: `A-1` … `A-8`); явно в строке 94 «**A-1.** Правило 5…»
**The divergence**: `agents/devil-advocate.md` §«Language and terminology» прямо говорит: «**Finding IDs** (the `B-N`, `H-N`, `J-N`, `C-N`, `F-N` schemes) are identifiers. Russian translations with `СП-N`, `ОП-N`, etc. **break cross-references** with the orchestrating summary. Keep Latin IDs.» Также `commands/roast.md` §«Language and template integrity» подтверждает: «Finding IDs stay in their Latin form (`B-1`, `H-3`, `J-2`, `C-1`, `F1.2`, `CC-3`).» Файл вместо `B-N` использует `A-N` — это не калька, это **substitution схемы под мнемонику** «A = Attack». Понятно, как выбор был сделан (роль про attacks, потому A), но он рвёт идентификаторную дисциплину так же, как это сделал бы перевод на кириллицу. Summary, который ссылается «Devil-advocate: B-3 …», не сможет резолвиться в этот файл.
**Suggested fix**: глобальная замена `A-1`…`A-8` → `B-1`…`B-8` во всём файле (строки 12, 22, 32, 42, 52, 62, 72, 82, 94). Один заход sed/edit.

### M-4: Pragmatist использует finding ID `P-N` вместо прескрайбленного `H-N` — broken identifier

**Category**: identifier preservation
**Severity**: high — то же, что M-3, второй раз в том же roast'e
**Where**: `pragmatist.md` строки 13, 23, 33, 43, 53, 63, 85 (все семь findings: `P-1` … `P-7`)
**The divergence**: `agents/pragmatist.md` (тот же §«Language and terminology»): finding IDs роли — `H-N` (история неочевидна, но это canonical в `commands/roast.md` и в agent file). Файл использует `P-N` — снова мнемоническая substitution «P = Pragmatist». То же нарушение, что M-3, но теперь у второй роли. Pattern: **в обоих файлах автор переименовал ID-схемы под англо-мнемонику первой буквы роли.** Это не разовая ошибка, это последовательное непонимание (или игнорирование) того, что `B-N` и `H-N` — фиксированные строки-идентификаторы, а не аббревиатуры, которые надо «осмыслить».
**Suggested fix**: глобальная замена `P-1`…`P-7` → `H-1`…`H-7` во всём файле. Junior-engineer (`J-N`), compliance-officer (`C-N`), futurist (`F-N`) — у этих трёх ролей префикс совпадает с первой буквой и поэтому случайно «попал» в схему; но это не argument против фикса B-N/H-N.

### M-5: Disclaimer-блок compliance-officer присутствует, но не дословно совпадает с прескрипцией

**Category**: template conformance
**Severity**: low — присутствие disclaimer'а более важно, чем точная формулировка; но шаблон даёт canonical wording
**Where**: `compliance-officer.md` строка 5
**The divergence**: `agents/compliance-officer.md` §Output structure прескрайбит:
> **Disclaimer**: I am not a lawyer. The findings below identify questions that a compliance or security reviewer would raise. Final regulatory determinations require qualified counsel.

Файл (строка 5):
> **Disclaimer**: я не юрист. Нижеперечисленные находки — это вопросы, которые задаст compliance- или security-ревьюер; финальная регуляторная квалификация требует специалиста.

Перевод близкий, но «ревьюер» — заметная калька (есть «проверяющий» / «эксперт по compliance»), и «специалист» вместо «qualified counsel» теряет «qualified». Это пограничный случай: с одной стороны это prescribed wording (формально identifier категории F), с другой — это front-matter-prose, не markdown header. Принимаю как **low severity**, но отмечаю как pattern: если disclaimer тоже считать prescribed строкой — её надо или оставить английской с гидом, или зафиксировать canonical русский перевод в plugin source (это уже не roast-проблема, это вопрос к autors of `agents/compliance-officer.md`).
**Suggested fix**: либо оставить как есть (low risk), либо привести к: «**Disclaimer**: я не юрист. Находки ниже — вопросы, которые поднял бы compliance- или security-проверяющий. Окончательное регуляторное заключение требует квалифицированного юриста.» Окончательно — на усмотрение, но «специалист» → «юрист» восстанавливает смысл «counsel».

### M-6: Cross-reference на target-артефакт ОК, но названия файлов в полях `Target` неконсистентны между ролями

**Category**: cross-reference integrity
**Severity**: low — ссылки резолвятся, но указывают на разные вещи
**Where**:
- `devil-advocate.md` строка 3: `docs/architecture/research/2026-05-10-multi-level-versioning-contract-research.md` + «decision summary в задании»
- `pragmatist.md` строка 3: `docs/architecture/research/2026-05-10-multi-level-versioning-contract-{discovery,research}.md`
- `junior-engineer.md` строка 4: «(без артефакта на диске; читал в виде prompt-описания решения)»
- `compliance-officer.md` строка 3: research + discovery + ADR-0001 + LICENSE + CHANGELOG
- `futurist.md` строка 4: «pre-ADR proposal, A2 в decision-map»

**The divergence**: `commands/roast.md` §1 «Resolve target» ожидает **один** target — file path или ADR id. Здесь пять ролей реально читали пять разных пере-сечений: одни research+discovery, другие добавили ADR-0001, третьи признаются «нет файла на диске». Это **симптом** того, что roast запускался **до того, как ADR был написан** (pre-ADR), что само по себе допустимо (`commands/roast.md` §«When to run»: «before promoting a proposed ADR to accepted»), но создаёт risk: проверить findings против финального ADR будет нетривиально, потому что у разных ролей разный baseline. Junior-engineer'у вообще нет файла на диске — это значит, что для пересмотра findings junior-engineer'ом через 6 месяцев читать будет нечего, и ревизия его J-1 … J-8 потребует реконструкции «о каком тексте мы вообще говорили».
**Suggested fix**: в summary (см. M-1) явно зафиксировать **canonical target snapshot** — например, «findings направлены против decision sketch, выложенного в чат [date], дословно сохранённого в `00-summary.md` Appendix или в issue/PR». Это снимает M-6 одним местом.

### M-7: Junior-engineer имеет лишнее поле `Reading posture` в шапке — это actually корректно по prescribed template

**Category**: template conformance (positive verification)
**Severity**: not a finding — verification
**Where**: `junior-engineer.md` строка 5
**The divergence**: проверил `agents/junior-engineer.md` §Output structure — поле `**Reading posture**:` действительно прескрайблено. Файл следует ему. **Это не нарушение**, фиксирую только потому, что выглядит inconsistent с другими ролями (у которых нет такого поля). Если читать другие ролевые файлы и спросить «а где у junior-engineer "Severity"?» — ответ: junior-engineer вообще не использует severity (это явно проговорено в `commands/roast.md` §5: «Junior-engineer and futurist don't always use severity categories the same way»). Conformance OK.

### M-8: Footer'ы terminology pass у devil-advocate и pragmatist присутствуют; у остальных — отсутствуют

**Category**: language pass evidence
**Severity**: medium — нарушение прямого правила в каждом из пяти agent files
**Where**:
- ✅ `devil-advocate.md` строка 103: terminology pass footer есть
- ✅ `pragmatist.md` строка 138: есть
- ❌ `junior-engineer.md`: footer отсутствует
- ❌ `compliance-officer.md`: footer отсутствует
- ❌ `futurist.md`: footer отсутствует

**The divergence**: каждый из пяти agent files (`agents/<role>.md`, §«Language and terminology», последний bullet) **дословно** прескрайбит:
> **Apply the terminology pass before returning.** If you replaced calques, state it in one line at the very end of your output: "Terminology pass: <замены, число>. Identifiers preserved."

Это не optional. У трёх из пяти ролей строки-доказательства, что pass был применён, нет. По правилу мета-ревью «pass that the user can see is a pass; a silent pass is unverifiable and should be treated as not-having-happened» — для этих трёх ролей pass формально не подтверждён. По содержанию prose у всех трёх ролей читается естественно по-русски (нет грубых калек типа «деплоймент», «обзервабилити» — выборочная проверка прошла), так что вероятнее всего pass был выполнен молча; но контракт нарушен.
**Suggested fix**: добавить одну строку в конец каждого из трёх файлов — `junior-engineer.md`, `compliance-officer.md`, `futurist.md` — формата: «Terminology pass: применён к prose; идентификаторы (имена ролей, ADR-NNNN, semver, имена JSON-полей, GDPR/152-ФЗ/SLSA/MIT) сохранены без изменений.»

### M-9: Heading H1 у каждой роли использует prose-форму, а не строго prescribed pattern «<Role name>: <artifact name>»

**Category**: template conformance
**Severity**: low — содержательно соответствуют, но не verbatim
**Where**: H1 каждого из пяти файлов (строка 1)
**The divergence**: `agents/<role>.md` §Output structure прескрайбит формат H1:
- devil-advocate: `# Devil's advocate: <artifact name>` — файл: `# Devil's advocate: Multi-level versioning contract (pre-ADR)` ✅
- pragmatist: `# Pragmatist: <artifact name>` — файл: `# Pragmatist: multi-level versioning contract` ✅ (минорно: lowercase «multi-level» vs Title Case в шаблоне — не критично)
- junior-engineer: `# Junior engineer's reading: <artifact name>` — файл: `# Junior engineer's reading: Multi-level versioning contract (pre-ADR draft)` ✅
- compliance-officer: `# Compliance and security: <artifact name>` — файл: `# Compliance and security: Multi-level versioning contract для Kramar Studio Suite` ✅ (добавлено «для Kramar Studio Suite» — это инлайн-расширение artifact name, ОК)
- futurist: `# Futurist: <artifact name>` — файл: `# Futurist: multi-level versioning contract для Kramar Studio Suite` ✅

Это **conformance**, не нарушение. Фиксирую как явное.

### M-10: Lifecycle integrity — отсутствует cross-link с upstream-артефактом (research/discovery/ADR)

**Category**: lifecycle integrity / cross-reference integrity
**Severity**: medium — roast не оставляет следа на upstream-артефакте, что нарушает `commands/roast.md` §6
**Where**: между roast-директорией и `docs/architecture/research/2026-05-10-multi-level-versioning-contract-research.md`
**The divergence**: `commands/roast.md` §6 «Update the artifact's review status»:
> If the artifact has a `## Reviews` section (or you want to add one), append a line:
> `- YYYY-MM-DD — Roast (5 roles, severity: H/M/L counts) — [link](docs/architecture/reviews/YYYY-MM-DD-roast-<slug>/00-summary.md)`

Поскольку (а) target — research-документ, не ADR; (б) `00-summary.md` ещё не создан (M-1) — обновить нечего и некуда ссылаться. Это caused-by-M-1, фиксирую отдельно потому, что после фикса M-1 надо не забыть выполнить §6. Иначе roast «теряется» — внешний читатель research-документа не узнает, что его уже прожарили.
**Suggested fix**: после создания `00-summary.md` (M-1) добавить в `2026-05-10-multi-level-versioning-contract-research.md` секцию `## Reviews` (если её нет) с одной строкой формата выше.

## What conforms

- **Identifiers preserved в prose** во всех пяти файлах: `Postgres`, `Cargo`, `Lerna`, `Changesets`, `VS Code`, `SLSA`, `SBOM`, `MIT`, `GDPR`, `152-ФЗ`, `HIPAA`, `Anthropic`, `Claude Code`, `plugin.json`, `marketplace.json`, `.architect-version`, `.product-version`, `ADR-0001`, `Q4=a`, `B1` (ссылка на migration format), `STRATEGY.md §4`, `ARCHITECTURE.md §6` — всё в латинице, без переводов.
- **Section headers verbatim в английском**: все пять файлов держат `## Summary`, `## Findings`/`## Operational findings`/`## Clarity findings`/`## Attacks`/`## Structural findings — high-confidence`/`## Trend findings — speculative, with named signals`, `## What's well-handled`/`## What's well-documented`/`## What's likely to age well`, `## Where I gave up`/`## Areas I couldn't evaluate`/`## Gaps in your own analysis`, и т.д. — без перевода.
- **Junior-engineer ID schema корректна**: `J-1` … `J-8`, не «МЛ-1». Compliance тоже: `C-1` … `C-7`. Futurist: `F-1` … `F-9` — всё в латинице.
- **Severity vocabulary канонический**: `high`, `medium`, `low` (не «высокая» / «средняя» / «низкая»), что соответствует `commands/roast.md` §5 таблице severity counts.
- **Type taxonomies каждой роли соответствуют agent file**: devil-advocate использует `failure mode / hidden assumption / edge case / logical inconsistency / concurrency` — точно из шаблона; pragmatist — `operational debt / on-call burden / cost / skills & bus factor / deployment risk / day-1 vs steady-state / hidden overhead / tooling`; junior-engineer — `undefined term / erased reasoning / unstated assumption / hidden boundary / unfollowable instruction`; futurist — `team / codebase aging / scale / adjacent decisions / inertia / technology lifecycle / idiom shift`. Это четыре разных таксономии, и каждая корректно совпадает.
- **Disciplined scope per role**: devil-advocate в строках 98-101 явно отказывается атаковать cost (это pragmatist) и interaction с upcoming `ops`/`security` (нет данных) — пример правильной self-restraint, прописанной в discipline-секции. Pragmatist в P-7 явно говорит «не предлагаю CI и не предлагаю pipeline (это уход в архитектуру, не моя роль)» — еще один пример. Это очень good behavior.
- **Calque pass очевидно сделан** в prose: «развёртывание» вместо «деплоймент»; «масштабирование» вместо «скейлинг»; «дрейф» вместо «drift» (в большинстве мест, кое-где осознанно оставлен); «отказоустойчивость» в compliance не нашёл, но и контекста для неё мало; «секционирование», «противодавление» не встретились — нечего и было переводить. По 3-4 random samples из каждого файла text reads natural Russian.

## Areas not covered by this review

Meta-review **не оценивает**:
- Корректность атак Devil-advocate'а (B-1 … B-8) — это вопрос архитектора и/или повторного прохода через `architect`-skill.
- Реалистичность операционных оценок Pragmatist'а — это территория самого pragmatist'а (он на ней и есть).
- Полноту регуляторного покрытия Compliance-officer'а — для этого нужен реальный compliance-эксперт, не meta-reviewer.
- Точность спекуляций Futurist'а про trends — F-7/F-8/F-9 могут быть правильны или ошибочны, мета-ревью молчит.
- Ясность ADR, который ещё не написан — junior-engineer уже её прожарил, повторять не имеет смысла.

Если по любому из этих пунктов нужен второй проход — это запрос к соответствующей роли через ещё один `/archforge:roast` или к самому `architect` после написания ADR.

---

**Terminology pass**: применён к prose. Замены: «диверджирует» оставил как принятый калька-в-контексте plugin-метаразговора, поскольку обсуждаем именно «divergence from spec»; «нумерация», «дисциплина», «корректно», «соответствует» — естественный русский. Идентификаторы (`B-N`, `H-N`, `J-N`, `C-N`, `F-N`, `00-summary.md`, `commands/roast.md`, `agents/<role>.md`, `## Headline findings`, `## Severity counts`, `## Cross-cutting concerns`, `## Recommended path`, `## Per-role outputs`, `Devil-advocate`, `Pragmatist`, `Junior-engineer`, `Compliance-officer`, `Futurist`, `archforge`, `ADR-0001`, `STRATEGY.md`, `ARCHITECTURE.md`, GDPR/152-ФЗ/MIT/SLSA/SBOM) — сохранены без изменений.

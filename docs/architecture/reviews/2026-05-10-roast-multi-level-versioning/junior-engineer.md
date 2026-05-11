# Junior engineer's reading: Multi-level versioning contract (pre-ADR draft)

**Target**: предлагаемый набор контрактных правил версионирования для Kramar Studio Suite (без артефакта на диске; читал в виде prompt-описания решения)
**Date**: 2026-05-10
**Reading posture**: я первый раз вижу этот marketplace. У меня под рукой `ARCHITECTURE.md`, `STRATEGY.md` и ADR-0001. Понедельник, утро, рядом никого. Я хочу понять, что мне разрешено сделать с версией, когда я завтра дотрону `product` или добавлю `ops`.

## Summary

В целом decision читается как «семь параллельных правил» без иерархии и без склейки в один сценарий. Я вижу, что важно (per-plugin semver, breaking-определение по-VS-Code-style), но не вижу, как читать пункт 2 (`marketplace.json.version`) — он описан через отрицание («НЕ aggregate suite stability») и задним числом фиксирует «остаётся 0.1.0», не объясняя, при каком будущем условии я имею право это поменять. Самый болезненный gap — пункт 5 «символический 1.0.0»: правило одновременно вводит исключение и тут же запирает его, и я как новый maintainer не понимаю, исчерпано ли оно для `architect` (уже на 1.0.0) и можно ли применить к `product`.

## Clarity findings

### J-1: «Версия структуры самого `marketplace.json` или политик marketplace» — не определено, что это
**Category**: undefined term

**The gap**: пункт 2 говорит: *«marketplace.json.version — версия структуры самого marketplace.json или политик marketplace. НЕ aggregate suite stability. После ADR-0001 — структура manifest не изменилась → marketplace остаётся 0.1.0.»*

Что такое «структура `marketplace.json`»? Это поля верхнего уровня (например, добавился новый ключ в JSON)? Это schema от Anthropic, которую мы не контролируем (и тогда зачем bump'ать у себя)? Это набор плагинов в `plugins[]` (тогда добавление `architect` через ADR-0001 — изменение структуры или нет)?

И что такое «политики marketplace»? Я знаю слово «политика» из контекста IAM/security, в этом репо я его раньше не видел. Какие политики? Где они описаны? Если их пока нет — то bump никогда не произойдёт, и тогда правило фактически = «не bump'аем», но это не сказано.

**What I tried to figure out**: посмотрел `ARCHITECTURE.md §6` — там Q1 формулирует тот же вопрос словами «какова контрактная связь?», но не отвечает. В research-digest нашёл фразу «Cargo workspace: версия workspace optional» и «marketplace = registry» (VS Code) — два разных мира, и по тексту decision я не могу сказать, какой из них приняли.

**Suggested fix**: дать одно-два конкретных примера: «bump marketplace.version, когда: (a) добавили/убрали top-level поле в `marketplace.json`, (b) изменили convention обнаружения плагинов (например, путь от `plugins/<name>/` к чему-то другому). НЕ bump, когда: добавили запись в `plugins[]`, поправили description, поменяли версию любого внутреннего плагина». Без двух-трёх таких clauses я не знаю, что относится к «структуре».

---

### J-2: «После ADR-0001 структура manifest не изменилась» — а что считается изменением?
**Category**: erased reasoning

**The gap**: ADR-0001 явно добавил второй плагин в marketplace (об этом пишут и `ARCHITECTURE.md §3`, и сам ADR §Implementation status шаг 2: «обновить marketplace.json — добавить запись architect плагина рядом с product»). Decision утверждает «структура не изменилась». Это звучит правдоподобно (количество top-level полей JSON не поменялось), но логика «manifest не изменился даже когда изменился набор плагинов в нём» — нетривиальная и не разжёвана. Я бы интуитивно сказал: «контент manifest изменился, поэтому надо bump'ать». Decision говорит «нет», но не объясняет почему.

**What I tried to figure out**: пытался прочитать пункт 2 в связке с пунктом 1 (per-plugin semver). Из связки можно догадаться: «изменение plugins[] = изменение версии конкретного плагина, а не marketplace». Но это моя реконструкция, в тексте её нет.

**Suggested fix**: одна фраза в пункте 2: «изменение списка `plugins[]` — изменение версии соответствующего плагина, не marketplace; marketplace.version меняется только когда меняются поля верхнего уровня вне `plugins[]` или path-convention обнаружения плагинов».

---

### J-3: «Breaking change для плагина» — список без примеров и без негативных кейсов на грани
**Category**: unstated assumption

**The gap**: пункт 4 даёт хороший список («rename / remove contribution points: commands, skills, agents, hooks; change input schema для commands; change frontmatter contract...»). Но границы остаются мутными в местах, где я как новый maintainer спотыкнусь:

- «изменение enum» — что считается enum'ом frontmatter? Lifecycle (`draft → active → accepted | superseded | archived`) явно enum. А `status: planned/scaffolded/active` из README — это тоже enum, который, если я добавлю `experimental`, надо считать breaking?
- «переименование template-prescribed section header» — `## Success metric`, `## Acceptance criteria`, `## Verdict` упомянуты в anti-patterns ARCHITECTURE.md. Если я добавляю **новый** prescribed header (не переименовываю, а добавляю), это minor или major?
- «новое required поле» в frontmatter — а новое **optional** поле? Я предполагаю minor, но decision это не говорит.
- А что насчёт: переименование самого **плагина** (`/archforge:*` → `/architect:*` упомянут в research как пример bump'а)? Это попадает под «rename contribution points» расширительно? Decision явно перечисляет sub-types (commands, skills, agents, hooks), но не «rename namespace плагина».
- А миграционные требования: если изменение требует пользователю запустить `/<role>:upgrade` — это автоматически breaking или нет? Q3=a из discovery был отброшен в пользу Q3=d, но связь «требует upgrade ↔ major bump» не зафиксирована явно. В discovery это была отдельная альтернатива.

**What I tried to figure out**: research-digest §Implications #4 даёт лучшую формулировку чем decision, но в decision она не повторена дословно. Я как новый человек смотрю в decision и думаю «надо ли мне идти в research-digest за definition'ом?» — а это уже признак, что определение не самодостаточное.

**Suggested fix**: добавить две строки positive-examples и две строки edge-cases, на которых правило тестируется. Особенно прояснить: «add optional поле — minor», «add new required header — major (требует backfill в существующих артефактах)», «rename namespace плагина — major».

---

### J-4: «Символический 1.0.0» — могу ли я ещё им воспользоваться или поезд ушёл?
**Category**: hidden boundary / unstated assumption

**The gap**: пункт 5: *«Символический 1.0.0 — допустимое one-time исключение per плагин: переход «scaffolded → active» можно отметить bump'ом до 1.0.0 даже если строго по правилам выше bump был бы minor. ... После 1.0.0 — строго по правилам.»*

Несколько штук, на которых я застреваю:

1. **«One-time per плагин»** — фраза кажется ясной, но: у `architect` уже 1.0.0 (по контексту). Значит, для `architect` исключение **уже использовано**. У `product` 0.1.0 — он может им воспользоваться. У `ops` 0.0 (planned) — может. Но в decision я этого не читаю явно — мне надо самому склеить контекст («architect v1.0.0 → исчерпан»). Это работа для junior'а, которой не должно быть.

2. **«Переход scaffolded → active»** — а где зафиксирован переход? В README статусе? В frontmatter? В CHANGELOG'е? Пункт 7 связывает scaffolded/active с semver-уровнями, но процедура «как именно я объявляю переход» не описана. Я делаю PR, который меняет README-статус с scaffolded на active И bump'ает version до 1.0.0 одной commit'ой? Или есть отдельный шаг?

3. **«Строго по правилам выше»** — каким правилам? Пункт 4 даёт breaking-criteria. Если breaking change нет — то и major bump не нужен — то и до 1.0.0 я по правилам не дошёл бы. Поэтому «one-time исключение» нужно именно для случая когда breaking-criteria НЕ выполнены, но я хочу пометить milestone. Это можно прочитать, но это два прохода по тексту.

4. **«Документируется в CHANGELOG'е плагина явно»** — где CHANGELOG плагина? В `plugins/<role>/CHANGELOG.md`? Я не нашёл такого файла в `architect`. Если CHANGELOG'ов пока физически нет, то правило ссылается на артефакт, которого не существует — и я не понимаю, должен ли я его создать как часть bump'а до 1.0.0.

**What I tried to figure out**: проверил `plugins/architect/` — нет CHANGELOG.md (по beachhead-структуре). Нашёл упоминание `CHANGELOG'е плагина явно` только в decision-тексте. То есть документ ссылается на конвенцию, которой в репо ещё нет.

**Suggested fix**:
- явно сказать «у `architect` исключение уже использовано, у `product` ещё доступно»;
- сослаться на конкретное место «переход фиксируется одним PR с тремя изменениями: plugin.json.version, README статус, plugins/<role>/CHANGELOG.md (создать если нет)»;
- если CHANGELOG не существует как convention, добавить отдельный пункт «CHANGELOG-формат — TBD, до тех пор фиксируется в commit message».

---

### J-5: README maturity-signal как «proxy для semver» — а что между scaffolded и active?
**Category**: hidden boundary

**The gap**: пункт 7: *«scaffolded < 1.0.0; active ≥ 1.0.0; planned без version.»*

Это даёт мне правило «прочитать статус по версии», но обратное направление неоднозначно:

- Если я bump'аю `product` 0.1.0 → 0.2.0 (minor по новым правилам), статус остаётся `scaffolded`? До какого 0.x можно оставаться в scaffolded?
- Если я делаю 0.2.0 → 0.3.0 → ... → 0.9.0 — я всё ещё scaffolded? Это начинает выглядеть странно к 0.5.0+.
- Plugin может быть «active» только через 1.0.0? То есть для перехода в active мне обязательно нужно потратить «one-time 1.0.0» exception (J-4) или иметь breaking change? Третьего варианта нет?
- Что если плагин уже на 0.x, накопил много breaking changes (по правилам пункта 4 — каждое было bump до 1.0.0, потом 2.0.0...) — тогда он быстро уходит из scaffolded в active независимо от моей готовности это объявить.

Здесь ответ скорее всего «active = 1.0.0+, и перейти туда можно либо через breaking, либо через one-time exception, других путей нет», но decision не закрывает «а что в течение долгого 0.x-периода».

**What I tried to figure out**: нашёл в discovery Q8 три альтернативы (a/b/c). Decision принял (b). Implication «значит, sequence в 0.x — это всегда scaffolded, даже на 0.9.0» — моя реконструкция, не текст.

**Suggested fix**: «Плагин в любой 0.x-версии — scaffolded. Переход в active = либо естественный 1.0.0 от breaking change, либо one-time symbolic 1.0.0 (см. пункт 5). Между scaffolded и active промежуточных статусов нет.»

---

### J-6: `dependencies` в `plugin.json` НЕ используется — а что вместо них для intra-suite?
**Category**: unfollowable instruction / erased reasoning

**The gap**: пункт 6: *«dependencies field в plugin.json — НЕ используется. Cross-link между плагинами остаётся file-convention-based через `links_to: [ADR-NNNN]`.»*

Если я завтра реально столкнусь с ситуацией «product хочет ссылаться на конкретный ADR из architect» — что я делаю? Decision говорит мне «через `links_to: [ADR-NNNN]`», но не отвечает:

- А если соответствующего ADR нет (architect ещё не дошёл до этой темы) — что делать? `links_to: []`? `links_to: [ADR-NNNN-todo]`?
- А если у пользователя `architect` плагин не установлен вообще, и `links_to` указывает в пустоту — это soft warning от хука или silent? (ADR-0001 говорит «cross-link работает по файловой конвенции», но behavior при отсутствии target-файла не зафиксирован.)
- «Пересмотр когда конкретный use case появится — отдельным циклом» — а что считается use case'ом, который триггерит пересмотр? Один плагин хочет depend? Два? Сам maintainer столкнулся с дублированием?

**What I tried to figure out**: ARCHITECTURE.md §6 четвёртый bullet и ADR-0001 §Decision говорят то же самое — «file-convention-based, intra-marketplace». Но процедуры «что делает разработчик плагина, если ему нужна зависимость» нет нигде.

**Suggested fix**: одна строка про «если кажется, что нужна dependency — открой issue/cycle с описанием use case; до этого момента нет легитимного способа объявить зависимость в plugin.json».

---

### J-7: `.<plugin>-version` маркер «ровно повторяет» — что если plugin.json bump'нулся, а я не запускал upgrade?
**Category**: unstated assumption

**The gap**: пункт 3: *«.<plugin>-version маркер в проекте — ровно повторяет plugin.json.version на момент init или последнего успешного upgrade.»*

То есть в моём проекте маркер может быть `0.1.0`, а в marketplace `product` уже `1.0.0`. Это значит дельта = «есть необъявленная миграция». Decision это не называет drift, не описывает что хук должен сказать пользователю, и не уточняет:

- Кто пишет в маркер при `init` — команда или хук?
- Что происходит, если я вручную поправлю `.product-version` (например, забыл откатить эксперимент)? Хук это детектит?
- Если plugin.json дошёл до v1.0.0, а в проекте маркер `0.1.0` без миграционного файла (см. ARCHITECTURE.md §6 третий bullet — миграции пока не существуют как convention) — что делает `/product:upgrade`? Decision говорит «ровно повторяет на момент последнего **успешного** upgrade», подразумевая что upgrade может быть не-успешен — но процедура «успешный/не-успешный» нигде.

**What I tried to figure out**: ARCHITECTURE.md §2 строка про Migration safety говорит «`/<role>:upgrade` идемпотентен» и «артефакты не удаляются» — но не «маркер обновляется атомарно с миграцией».

**Suggested fix**: одна фраза «маркер обновляется атомарно с применением последней миграции; если миграция упала на полпути, маркер остаётся на pre-upgrade значении».

---

### J-8: Пункты не связаны в один сценарий — нет worked example
**Category**: erased reasoning / hidden boundary

**The gap**: семь пунктов читаются как parallel rules. У меня нет одного прохода через жизненный цикл, который бы показал, как они работают вместе. Например:

> «Завтра я делаю content-fill `product` → добавляю pushback'и в `prd.md`, расширяю template `PRD.md` новыми (optional) секциями, переписываю SKILL.md без поведенческих изменений. Что я bump'аю и что пишу?»

По правилам decision я склеиваю: пункт 4 → не breaking (внутренний refactor + optional поля); пункт 1 → minor bump до 0.2.0; пункт 5 → могу вместо этого сделать символический 1.0.0, если хочу пометить «scaffolded → active»; пункт 7 → если 1.0.0, README статус → active; пункт 3 → маркер в моих проектах обновится при следующем `/product:upgrade`; пункт 2 → marketplace.version не трогаю.

Я смог это склеить, но это работа на 15 минут реверс-инжиниринга. Для junior'а, читающего «contract should be запоминаемым в голове» (это force F5 из discovery), один worked example стоит дороже семи правил.

**What I tried to figure out**: discovery Q6 явно ставит ровно этот сценарий, decision на него отвечает имплицитно. Связку «вот ответ Q6 → product 0.1.0 → 0.2.0, но можно symbolic 1.0.0» в decision-тексте не вижу, хотя discovery её ждёт.

**Suggested fix**: после семи пунктов добавить «Worked example: content-fill `product`» в три-пять строк. И симметрично «Worked example: добавление `ops` плагина с нуля».

## What's well-documented

1. **Пункт 1** (per-plugin semver) — короткое и недвусмысленное правило. Прочитав его, я сразу знаю, что плагины не lockstep'ятся.
2. **Пункт 4 положительная часть списка** breaking-criteria (rename/remove contribution points, change input schema, change frontmatter contract) — конкретно перечисленные категории, лучше, чем абстрактное «breaking».
3. **Пункт 4 negative-list** («НЕ breaking — internal refactor с preserved behavior») — отдельное упоминание non-breaking рефакторов важно, и сделано.
4. **Пункт 6 явный отказ от `dependencies` field** — само по себе чёткое решение «нет, не сейчас», что лучше, чем умолчание.
5. **Контекстные ссылки на текущее состояние** («architect v1.0.0, product v0.1.0, marketplace 0.1.0») — даёт стартовую точку для проверки правил против реальности.

## Where I gave up

- **Пункт 2 + связь с ADR-0001.** Я не смог уверенно ответить, что произошло бы по правилам, если бы ADR-0001 случился завтра, а не уже принят. По букве «структура не изменилась → не bump» — то же самое. По духу «marketplace значимо изменился» (формулировка из force F7 в discovery) — нужен bump. Какое из двух правильное по этому контракту — я не понимаю.
- **Пункт 5 + CHANGELOG.** Ссылка на «CHANGELOG плагина» при отсутствии такового в репо означает, что любой apply этого правила потребует дополнительного цикла «а как мы вообще CHANGELOG'и пишем». Я бы остановился и пошёл к maintainer'у — а его нет.
- **Конец decision не отвечает discovery Q5.** Discovery спрашивал «что делать с marketplace 0.1.0 сейчас (после ADR-0001)?» с четырьмя альтернативами. Decision говорит «остаётся 0.1.0», что соответствует Q5=a, но не помечает это как ответ на Q5 и не объясняет, почему отвергнуты Q5=b («bump до 1.0.0 как stamp после ADR-0001») и Q5=c («bump до 0.2.0 как acknowledgement что добавили плагин»). Я могу домыслить, но из decision-текста не очевидно.

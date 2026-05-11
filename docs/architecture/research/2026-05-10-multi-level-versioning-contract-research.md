# Research digest: Multi-package versioning patterns для marketplace + plugin suites

> **Cycle:** Multi-level versioning contract (A2)
> **Date:** 2026-05-10
> **Question:** Какие современные best practices существуют для multi-package versioning в monorepo / package suites, особенно когда есть umbrella manifest и packages могут эволюционировать независимо?

## Headline finding

Industry consensus 2026: для suite из ~2-5 packages с разными release-cadence используется **independent versioning per package + lightweight umbrella manifest** (Changesets default, Cargo `[workspace.package]` без shared `version`, Rush с per-package policies). Umbrella version обычно отражает либо tooling/manifest schema, либо координированный snapshot, но **не диктует** версии children. «1.0.0 как marketing milestone» — легитимный паттерн, явно допускаемый SemVer-спецификацией. Для Claude Code marketplaces — пока **новая территория** без устоявшихся conventions.

## Detailed findings

**1. Lerna fixed vs independent.** [Lerna docs](https://lerna.js.org/docs/features/version-and-publish): `fixed` — все packages bump одинаково, любой major в одном тянет major во всех; `independent` — каждый package versioned отдельно. Fixed-pain: «major change в одном = major во всех» создаёт версии-шум. Для solo-maintainer setups с loosely-coupled packages — рекомендуется **independent** + Conventional Commits.

**2. Changesets — три mode.** [docs](https://github.com/changesets/changesets/blob/main/docs/linked-packages.md): **independent** (default), **linked** (packages «догоняют» highest version в группе при bump, публикуются только изменённые), **fixed** (все packages всегда bump+publish вместе). Для small suite чаще всего independent, иногда linked для marketing-related groups.

**3. Nx release для small monorepo.** [Nx 2026 roadmap](https://nx.dev/blog/nx-2026-roadmap): для маленьких monorepo'ов считается overkill; рекомендуется Changesets (manual, transparent) или Lerna v7+. `nx release` имеет смысл если уже на Nx по другим причинам.

**4. pnpm/Turborepo/Rush.** [Turborepo docs](https://turborepo.dev/docs/crafting-your-repository/structuring-a-repository): доминантный stack 2026 = pnpm workspaces + Turborepo + Changesets, где Turborepo делегирует versioning Changesets'у. **Rush** — для enterprise: явные `version-policies.json` с lockstep groups, `rush change` change-files. Rush — хороший reference для «policy-as-config» подхода, если когда-нибудь потребуется.

**5. Cargo workspaces.** [Cargo Book](https://doc.rust-lang.org/cargo/reference/workspaces.html): `[workspace.package]` table опционально содержит `version`, который members наследуют через `version.workspace = true`. **Members могут override локально.** Это ровно паттерн «umbrella default + per-package opt-out» — самый close prior-art для нашего случая.

**6. 1.0.0 как marketing milestone.** [SemVer 2.0.0](https://semver.org/) **явно поощряет** ранний 1.0.0 при стабильном API: «If your software is being used in production, it should probably already be 1.0.0.» «1.0 = feature complete» — культурный артефакт, не часть спеки. [GitHub semver issue #734](https://github.com/semver/semver/issues/734): «миф что 1.0.0 implies long-term support» — именно миф; 1.0.0 обещает только что 1.x будет backwards-compatible.

**7. Claude Code marketplaces — public landscape.** [awesome-claude-plugins](https://github.com/Chat2AnyLLM/awesome-claude-plugins) (43 marketplaces, 834 plugins на янв 2026): экосистема молодая. Большинство marketplaces — single-plugin или коллекции от одного автора без формальной versioning policy. **Не нашёл публично-документированной convention** про `marketplace.json.version` vs `plugin.json.version` — это **новая территория**.

**8. Breaking changes для plugin/extension ecosystems.** [VS Code Contribution Points](https://code.visualstudio.com/api/references/contribution-points): в plugin context breaking change трактуется **шире** чем для library: rename/remove command ID = breaking (ломает user keybindings); change argument schema = breaking; remove contribution point = breaking; **внутренний refactor с preserved behavior — НЕ breaking**. Public API plugin'а = всё, что user или другой plugin может observe: command names, settings keys, contributed file types.

## Implications для нашего случая

1. **Treat plugins as independent packages.** Industry default подтверждает Q2=a (per-plugin semver). `architect` v1.0.0 и `product` v0.1.0 могут эволюционировать своими cadence без принудительного lockstep.

2. **Marketplace.json.version — есть выбор семантики.** Industry doesn't strongly converge:
   - Cargo workspace: версия workspace optional, чаще не используется на этом уровне.
   - VS Code marketplace: marketplace = registry, не versioned artifact.
   - Rush `version-policies.json`: конфиг тоже versioned, но independently.

   Q1=b («suite stability stamp») — **deliberate divergence** от industry default. Аргумент за: marketplace ровно один (Kramar Studio Suite), нет разделения marketplace-as-tool / marketplace-as-content. Аргумент против: семантика «aggregate stability» инфорсится maintainer'ом, не tooling'ом — может drift'нуть.

3. **«1.0.0 as marketing milestone» — explicitly endorsed.** Q6=iii (символический 1.0.0) полностью валиден per SemVer-спека. `architect` v1.0.0 = «stable API of commands/skills/agents», `product` v0.1.0 = «iterating» — обе позиции legitimate.

4. **Breaking change definition по VS Code pattern, не по library pattern.** Refines Q3=d:
   - **Breaking** = rename/remove **contribution points** (commands, skills, agents, hooks); change **input schema** для commands; change **frontmatter contract** артефактов.
   - **НЕ breaking** = internal refactor (например, system prompt rewording в SKILL.md при preserved behavior, change в bash hook implementation при preserved output).

   Это narrows Q3=d в полезную сторону.

5. **Coordinated release ≠ shared version.** Если когда-то нужен «marketplace v0.2 release» с обоими plugins обновлёнными — это **announcement layer** (release notes), а не requirement match versions. Cargo workspace's «shared default + per-package overrides» — готовый pattern если когда-нибудь захотим эволюционировать.

## Open design space surfaced by research

Research **не invalidated** discovery, но **surfaced одно implicit decision**, которое стоит явно сделать в design-фазе:

- **Marketplace.json.version semantics** — Q1=b (suite-stability stamp) deliberately diverges от industry default. Альтернативы Cargo-style («workspace.version как default + per-plugin override») и VS Code-style («marketplace = registry, не versioned content») — оба валидны и более mainstream. Design-фаза должна это явно учесть как одну из альтернатив (не игнорировать что-то проще).

## Caveats

- Не нашёл устоявшейся convention для marketplace-level versioning в Claude Code ecosystem конкретно. Anthropic's marketplace.json schema, вероятно, эволюционирует, но публичных «stability promises» нет.
- Не нашёл недавних (post-2024) discussions specifically о «umbrella manifest schema versioning vs content versioning» как отдельных layers — это open design space.

## Sources

1. [Lerna — Version and Publish](https://lerna.js.org/docs/features/version-and-publish)
2. [Changesets — linked packages](https://github.com/changesets/changesets/blob/main/docs/linked-packages.md), [fixed packages](https://github.com/changesets/changesets/blob/main/docs/fixed-packages.md)
3. [Nx 2026 Roadmap](https://nx.dev/blog/nx-2026-roadmap), [Release management for Nx monorepos](https://www.hamzak.xyz/blog-posts/release-management-for-nx-monorepos-semantic-release-vs-changesets-vs-release-it-)
4. [Turborepo](https://turborepo.dev/docs/crafting-your-repository/structuring-a-repository), [pnpm Workspace docs](https://pnpm.io/workspaces)
5. [Cargo Book — Workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html)
6. [SemVer 2.0.0 spec](https://semver.org/), [GitHub semver issue #734](https://github.com/semver/semver/issues/734)
7. [awesome-claude-plugins](https://github.com/Chat2AnyLLM/awesome-claude-plugins), [claudemarketplaces.com](https://claudemarketplaces.com/)
8. [VS Code Contribution Points](https://code.visualstudio.com/api/references/contribution-points), [VS Code Commands API](https://code.visualstudio.com/api/extension-guides/command)

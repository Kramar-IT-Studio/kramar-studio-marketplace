---
name: frontend-architecture
description: Use this skill for architectural questions about web frontends — render strategy (CSR/SSR/SSG/ISR/RSC/Islands), state management strategy (server-state vs client-state, store choice), module/folder structure (feature-based vs FSD vs layer-based), component boundaries, performance budgets and code splitting, edge deployment, auth architecture, i18n, testing strategy. Triggers on phrases like "how to structure my frontend", "SSR or SPA", "should I use Pinia/Redux/Zustand", "feature-sliced design", "how to scale a Vue/React/Svelte project". Works for any frontend stack but knows the modern Vue/Nuxt and React/Next ecosystems particularly well; defers to `architecture-research` when the user asks about specific current versions or new releases.
---

# frontend-architecture

For architectural questions about web frontends. Five layers — clarify which layer the user is on, then go deep.

## The five layers

When someone says "frontend architecture", they could mean any of these. Confirm which:

1. **Render strategy** — CSR / SSR / SSG / ISR / RSC / Islands. Which one and why.
2. **Module / folder structure** — feature-based vs layer-based, monorepo, FSD.
3. **State management** — local vs global, server-state vs client-state, caching.
4. **Component architecture** — design system, composition, props/events boundaries.
5. **Cross-cutting concerns** — auth, i18n, logging, error handling, performance budget, testing.

A real conversation usually spans several. Separate them — don't mash them together.

---

## 1. Render strategies — decision matrix

| Strategy | Pick when | Avoid when |
|---|---|---|
| **CSR (SPA)** | Internal dashboards, admin panels, authenticated apps; SEO doesn't matter | Public marketing site, content site, slow-network users |
| **SSR** | Dynamic content + SEO + fast FCP; per-request data | Static content (overkill), huge traffic without edge infra (expensive) |
| **SSG** | Content changes less often than builds: blogs, marketing, docs | Hundreds of thousands of pages (build explodes), frequent updates |
| **ISR (incremental)** | Many pages + infrequent updates (e-commerce catalog) | Real-time data |
| **RSC (React Server Components)** | Complex apps, large server-state, React stack | Non-React stacks, small projects (overkill) |
| **Islands (Astro, Fresh)** | Content-heavy sites with localized interactivity | Complex SPA flows, heavy global state, authenticated apps |

**Anti-pattern**: "let's rewrite to SSR because it's modern". SSR has real operational cost (Node/Bun runtime in prod, hydration bugs, harder caching). Don't pick it without reasons from the left column.

### SSR-specific gotchas (Vue/Nuxt, Next, SvelteKit, etc.)

The biggest sources of bugs:

1. **Hydration mismatch** — server renders one tree, client renders another. Causes: `Date.now()` in templates, `Math.random()`, accessing `window`/`document` in setup, request-scoped data leaking into client. Fix: client-only wrappers, request-scoped state primitives, `onMounted` for browser-only code.
2. **Server memory leaks** — module-level state holding per-request data. SSR has new context per request; module scope is shared across all of them.
3. **Double fetches** — incorrect dedupe keys cause server fetch + client refetch. Use the framework's async-data primitive with stable keys.
4. **Cookies / auth on SSR** — `localStorage` is unavailable on the server. Use cookies + request headers.
5. **Third-party libraries** — many crash on SSR (top-level `window` access). Dynamic import + client-only render, or framework-specific plugin modes.

---

## 2. State management — by data nature, not "one store"

Modern frontend state is split by **what kind of data it is**:

| Kind of state | Tools (any framework) |
|---|---|
| **Server state** (data from API, cache, refetch, invalidation) | TanStack Query, SWR, framework's built-in async data primitive |
| **Global client state** (current user, theme, feature flags) | Pinia / Redux / Zustand / Jotai / Svelte stores |
| **Form state** (validation, dirty flags, submission) | Formik / React Hook Form / VeeValidate / FormKit + Zod |
| **Local UI state** (modal open, hover, current tab) | `useState` / `ref` in the component |
| **Cross-component but not global** | Context / `provide-inject` + signals, or small feature stores |
| **URL state** (filters, pagination, search params) | Router APIs |

**The major architectural shift of recent years**: server-state ≠ client-state. Don't manually shove API responses into a global store. Server state needs invalidation, retries, background refetch, optimistic updates — solved problems in TanStack Query / framework primitives. Stores hold what doesn't live on the backend or rarely changes (current user, UI prefs).

### Store anti-patterns

- **God store** — one `useAppStore` with 50 fields. Segment by domain.
- **Duplicating server state** — copying API into the store and forgetting to sync.
- **Logic in getters that belongs to the component**.
- **Mega-actions** — `loadEverything()` 200 lines long. Decompose.

---

## 3. Module structure — feature-based wins

```
# Layer-based (classic, doesn't scale)
src/
├── components/
├── pages/
├── stores/
├── services/
└── utils/

# Feature-based (scales well)
src/
├── features/
│   ├── auth/
│   │   ├── components/
│   │   ├── hooks-or-composables/
│   │   ├── stores/
│   │   ├── api.ts
│   │   └── index.ts        ← public API of the feature
│   ├── catalog/
│   └── checkout/
├── shared/                  ← reusable: UI kit, utilities
├── pages-or-routes/         ← routes + minimal feature composition
└── app.entry
```

**Rule**: go feature-based **as soon as there is more than one feature**. Layer-based looks simpler at the start; in a year `components/` has 200 files from 8 contexts.

Inside a feature, internal layers are fine. The point is hard boundaries between features (via `index.ts` barrels) and one-way dependencies (features depend on `shared`, never on each other directly).

### Feature-Sliced Design (FSD)

For projects > 3 people on the same codebase, look at FSD. It's a methodology (not a library) formalizing feature-based with explicit slices: `app → pages → widgets → features → entities → shared`. Each slice may import only from lower slices, enforced by ESLint.

**Pros**: hard discipline, common vocabulary, good fit for large products.
**Cons**: boilerplate up front, learning curve, overkill for small projects.

---

## 4. Component architecture

### Where to draw the boundary between components

Heuristics:

- **Single Responsibility** — one component, one thing. If "and" appears in the description, that's two components.
- **Reusability is not a goal**. Don't extract until two or three real call sites exist. Premature abstraction is worse than duplication.
- **Smart vs Dumb (Container / Presentational)** — overengineered in the era of hooks/composables. Modern alternative: logic in hooks/composables, components are thin adapters.
- **Props down, events up** — data down, signals up. If a prop drills three levels, use context/inject or a store, not drilling.

### Hooks / composables as primary unit of reuse

Logic lives in hooks (React) or composables (Vue) — not in mixins, not in HOCs.

A good hook/composable:
- Returns reactive primitives explicitly (no magic).
- Accepts arguments as `MaybeRef`-style for flexibility.
- Cleans up after itself in `onUnmounted` / cleanup function.
- Is testable without mounting a component.

### Design system / UI kit

For more than two people: a shared kit. Options:

- **Off-the-shelf**: shadcn/ui (and the various ports), Radix, PrimeVue / shadcn-vue, MUI, Chakra, Mantine. Use when looks are not the differentiator.
- **Headless + custom styling**: Radix / Headless UI primitives + your design tokens. Best balance of control and reuse for serious products.
- **Fully custom** — only with a dedicated design engineer. Otherwise you'll spend half a year writing select dropdowns.

---

## 5. Performance architecture

Architectural decisions, not point optimization:

1. **Code splitting** — route-level (most frameworks do automatically) + component-level (`defineAsyncComponent` / `lazy`) for heavy rare components.
2. **Image strategy** — responsive `srcset`, modern formats (AVIF/WebP) with fallback, lazy loading by default, framework's image component.
3. **Font loading** — `font-display: swap`, preload critical fonts, subset.
4. **Critical CSS** — inline critical path; tools like `critters` or framework-native.
5. **Bundle analysis** — regular use of `vite-bundle-visualizer` / `next build` analysis. Bundle size is silent tech debt.
6. **Performance budget in CI** — max bundle size, max LCP, max INP. Without a budget, "perf" is a discussion, not discipline.

---

## 6. Cross-cutting concerns

### Error handling

A real architecture, not "we'll figure it out":

- **Network errors** → retry with exponential backoff (TanStack Query handles this), UI surface, telemetry.
- **Validation errors** → inline near the field, not toast.
- **Application errors (bugs)** → ErrorBoundary, send to Sentry, friendly fallback.
- **404 / 403** → dedicated pages, not toast.

The user must always understand what happened and what to do next. "Something went wrong" is a failure.

### Auth

Major forks:
- Token storage: httpOnly cookie (XSS-safer) vs localStorage (simple SPA, XSS-exposed). For SSR — cookies only.
- Refresh: silent refresh, refresh-on-401, sliding session.
- Session vs JWT: stateless JWT scales but is hard to invalidate; sessions are simpler but need sticky or shared store.

### i18n

Not "which library" but:
- Translation storage: per-feature vs central.
- Lazy-loading locales.
- Fallback strategy.
- Plural rules and gender (especially languages with rich morphology).
- SSR with the right locale per request.

### Testing strategy — pyramid

- **Unit** — hooks/composables and utilities. Vitest. Fast, many.
- **Component** — components in isolation. Vitest + Testing Library.
- **Integration** — multiple components together with mocked API (MSW).
- **E2E** — critical user flows. Playwright. Few but reliable.
- **Visual regression** — Chromatic / Percy / Playwright screenshots for the design system.

Anti-pattern: "we only do e2e because unit tests are useless". This means your tests are slow, flaky, and your coverage is poor. E2E is for critical flows, not everything.

---

## Edge / distributed frontends

Modern frontends increasingly deploy to edge (Cloudflare Workers, Vercel Edge, Deno Deploy, Netlify Edge). Architectural consequences:

- **No long-running processes** — no background tasks, no shared in-process state across requests.
- **Strict CPU/memory limits** — single-digit milliseconds of CPU on free tiers.
- **Cold starts** — V8 isolates are fast but still measurable.
- **Different runtime APIs** — not Node. Web Standard APIs: `fetch`, `Request`, `Response`, `crypto.subtle`. Many npm packages don't run.
- **Distributed cache** — KV stores, R2, Durable Objects. Eventually consistent.
- **Geo-distributed by default** — data near the user, but the DB is often centralized → traffic hairpinning.

Edge is great for SSR storefronts, API routes, A/B at the CDN. Bad for heavy compute and long-polling.

---

## Pre-recommendation checklist

Before recommending anything frontend, you need:

- Team size and stack experience.
- Product size (pages, features, users).
- SEO requirements.
- Performance requirements (LCP, INP, regions).
- Existing stack and how much it can deviate.
- Planning horizon (3-month MVP vs 5-year product).

Without these — give the matrix and ask. Don't fabricate.

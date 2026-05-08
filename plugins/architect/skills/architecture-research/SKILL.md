---
name: architecture-research
description: Use this skill whenever an architectural answer depends on current information from the web — current versions of frameworks/libraries, recent best practices, performance benchmarks, cloud service capabilities and pricing, security advisories, AI/LLM model capabilities. Triggers on phrases like "what's the current best", "is this still recommended", "compare X vs Y in 2026", "what does Vue/Nuxt/Next/Postgres/etc. look like now". The skill defines a search protocol — what to search for, which sources to trust, how to validate findings, when to escalate to deeper research. Triggered automatically by `architect` whenever a claim is version-sensitive.
---

# architecture-research

For getting **current** information when an architectural claim depends on it. The pretrained corpus lags by months. Architecture chooses badly when it relies on stale facts.

## When this skill must run

Before stating any of these, search:

- **Specific versions** of frameworks / libraries ("should I move to Vue 3.6", "what's new in Nuxt 4").
- **Comparisons of current technologies** ("Pinia vs Vuex now", "Bun vs Node 22", "TanStack Query vs SWR").
- **"Best practice" for any technology** (the answers age fastest).
- **Releases, RFCs, deprecations.**
- **Performance benchmarks.**
- **Security advisories / CVEs.**
- **Cloud service capabilities, limits, prices.**
- **AI / LLM models and provider features** (especially fast-moving).

## When this skill can be skipped

- Fundamental principles (CAP, latency numbers, base patterns).
- Distributed systems theory.
- DDD, SOLID, classic design patterns.
- Concepts that don't change (DB normalization, HTTP basics).
- Personal preferences and judgment calls.

## Search strategy

### 1. Query construction

- **Short queries** (1–6 words) outperform long ones. "Nuxt 4 release notes" beats "what are the new features in the Nuxt 4 release".
- **Include the year** for time-sensitive lookups: "best Vue state management 2026".
- **Exact names for versions**: "Pinia 3 migration", "Postgres 17 features".
- **Add "benchmark" or "performance"** when comparing speed.

### 2. Source priority

| Priority | Source | Type |
|---|---|---|
| 1 | Official docs (vuejs.org, nuxt.com, postgresql.org, …) | API, concepts, migration guides |
| 2 | Official team blogs (Vue blog, Nuxt blog, Anthropic, etc.) | Releases, roadmaps, RFCs |
| 3 | GitHub releases / RFCs / discussions | Latest changes, design conversations |
| 4 | Known authors (Anthony Fu, Daniel Roe, Kleppmann, Marc Brooker, etc.) | Deep analysis |
| 5 | Conf talks, recordings (VueConf, JSConf, Strange Loop, USENIX, etc.) | Current practice |
| 6 | Maintained aggregators (patterns.dev, web.dev) | Best-practice rollups |
| 7 | Newsletters (Bytes, This Week in Rust, Last Week in AWS) | What people are talking about |

**Ignore by default**:
- Medium / dev.to articles with no date or older than ~2 years (often shallow or stale).
- Marketing-blog "Top 10 X for 2024" lists.
- Stack Overflow answers older than ~2 years for fast-moving stacks.
- AI-generated content without independent corroboration.

### 3. Validation

Before stating a fact:

- **Date of publication** — content older than ~12 months for frontend or AI is suspect.
- **Version match** — a Vue 2 article is not relevant to a Vue 3 project.
- **Cross-check** — for important claims, two independent sources.
- **Officialness** — for security advisories and breaking changes, only the official channel.
- **Marketing vs reality** — vendor blogs (managed services, DB startups) — read with awareness of their incentive.

### 4. Search depth

| Query type | Searches | Use web_fetch? |
|---|---|---|
| Simple lookup ("latest Nuxt version") | 1 | No, snippet usually enough |
| Comparison of two technologies | 2–4 | Yes, for in-depth articles |
| Architecture advice with currency | 3–5 | Yes, for official docs |
| Deep investigation | 5–10+ | Mandatory |

If a query needs > 10 searches, suggest the user run a deeper research workflow (dedicated researcher sub-agent or a longer session).

## Domain notes

### Frontend (Vue/Nuxt/React/Next/Svelte/Vite ecosystems)

Very fast moving. Watch:
- vuejs.org/blog, nuxt.com/blog, nextjs.org/blog, svelte.dev/blog
- Anthony Fu's blog
- Daniel Roe's blog
- VueUse / Vite / Vitest GitHub releases
- Patterns.dev

For "how do people do X now" questions: search before answering. Pretrained knowledge can be 6–12 months stale, and major releases change the answer.

### Rust ecosystem

More stable than frontend, but crates evolve:
- blog.rust-lang.org for language releases
- *This Week in Rust* — weekly digest
- crates.io for current versions
- "Are we X yet?" pages (gamedev, web, async)

### Cloud (AWS / GCP / Azure / Cloudflare / Vercel / Fly / Hetzner)

New features ship weekly. Pricing changes. Service limits change. Always verify before quoting numbers.

### AI / LLM

The fastest-moving area. What was true 3 months ago may be obsolete:
- Anthropic, OpenAI, Google AI, Mistral, Meta blogs
- Hugging Face spaces and model hubs
- arxiv.org for fresh papers (be skeptical of strong claims without code)
- Major framework changelogs (LangChain, LlamaIndex, etc. churn APIs)
- Pricing and limits — never quote without checking

Don't state specific numbers (price per token, context window, available tools) without a fresh check.

### Distributed systems / databases

Slower-moving but:
- Postgres / MySQL — major releases yearly, important new features.
- DynamoDB / Spanner / managed services — feature drops continuously.
- Kafka / Redpanda / NATS — competitive, performance numbers update.

## Anti-patterns

- **"First result wins"** — first hit is rarely the best or most current. SEO outranks signal in popular queries.
- **Trusting one source for an important decision.** Cross-check.
- **Citing without dates.** If a source is old, say so — let the user weigh the staleness risk.
- **Treating someone else's benchmark as fact.** Benchmarks are often cherry-picked. Multiple independent sources or self-test.
- **"According to one Reddit thread"** — don't. Reddit as a primary source for architectural decisions is noise.

## How to present found information

Cite briefly without bloating the answer:

> Per the Vue team blog (December 2025), Vapor mode is targeted for stable in Vue 3.7. This may change your evaluation of state management performance.

One or two relevant sources + a concrete conclusion. Don't dump five links.

## When search returns nothing useful

1. **Say so honestly.** "I couldn't find current information on this specific question" beats invention.
2. Fall back to **pretrained knowledge with a disclaimer**: "as of my training data this was true, but it may have changed".
3. Suggest **where the user can verify**: a specific docs page, an issue tracker.
4. If the question is about principles (not versions) — answer on principles, noting that implementation details vary.

---
name: system-design
description: Use this skill for distributed-systems and backend-systems-level design questions — scaling, database choice, queues, caching, consistency, microservices vs monolith, real-time systems, reliability patterns, or full FAANG-style "design X" walkthroughs (chat, feed, rate limiter, URL shortener, etc.). Triggers on phrases like "design a system that...", "how to scale", "which database", "queue or no queue", "should this be a microservice", "what's the latency budget", "how do we handle X failures". Walks the FAANG methodology (requirements → capacity → API → data → architecture → deep-dive → bottlenecks).
---

# system-design

For backend / distributed / scaling discussions, and for FAANG-style system design problems. Use the methodology below; do not jump to technologies before the methodology says so.

## The methodology (FAANG-style, 7 steps)

Walk every non-trivial system design problem in this order. The order is load-bearing — skipping ahead produces hand-wavy answers.

### 1. Functional and non-functional requirements

**Functional**: what the system does. 3–5 user scenarios. No more, or you'll drown.

**Non-functional** drives the architecture:
- **Scale** — DAU/MAU, peak RPS, data volume per year (TB/PB)
- **Latency** — p50, p95, p99 for critical operations
- **Availability** — 99.9 / 99.95 / 99.99 — each nine costs an order of magnitude more
- **Consistency** — strong / eventual / causal — what's acceptable per operation
- **Durability** — what cannot be lost, ever
- **Geographic distribution** — single region / multi-region / global

**Without non-functional requirements the conversation is meaningless.** "Design a chat" is ten different systems for ten contexts.

### 2. Back-of-envelope capacity estimation

Before picking technology:
- read/write QPS
- annual data growth
- bandwidth
- memory needed for hot cache

These numbers **dictate technology**. 10 RPS = one server + Postgres. 100K RPS = sharded systems + CDN + edge. Don't confuse them.

### 3. API design

Endpoints / RPC methods / events. The contract is fixed first — it shapes the data, not the other way around.

### 4. Data model

Entities, relationships, indexes. **Database engine is not chosen yet** — only the model.

### 5. High-level architecture

C4 L2-style diagram: services, communication, data flow at the macro level.

### 6. Deep dive

The riskiest one or two components in detail. In an interview it's the part the interviewer asks about. In real design it's the highest-leverage place to be wrong.

### 7. Bottlenecks and trade-offs

Where will it break first? What do we do then? Which compromises were made and why?

---

## Latency numbers to memorize

Architectural decisions hit physics. Approximate numbers:

| Operation | Time |
|---|---|
| L1 cache | ~1 ns |
| Main memory | ~100 ns |
| Compress 1 KB (zstd) | ~1 µs |
| 1 KB over 1 Gbps LAN | ~10 µs |
| SSD random read (NVMe) | ~10–100 µs |
| Round-trip same datacenter | ~500 µs |
| Read 1 MB from SSD | ~1 ms |
| Round-trip US East ↔ US West | ~70 ms |
| Round-trip US ↔ Europe | ~80–100 ms |
| Round-trip US ↔ Asia | ~150–200 ms |
| Cold start serverless | ~100–500 ms |

**Heuristic**: interactive UI has roughly a 100ms p95 budget. If three cross-region round-trips plus a query plus render must fit in that, you need edge cache, data locality, or asynchrony.

---

## CAP and PACELC

CAP is about *partitions*. Partitions happen, so in practice you choose between **C** and **A** during a partition.

PACELC is sharper: **P**artition → **A** or **C**, **E**lse → **L**atency or **C**onsistency. Even normal-mode operation is a latency-vs-consistency choice.

Practical consequences:
- **CP systems** (HBase, MongoDB strong-consistency, Spanner): give up availability under partition. Good for fintech, inventory.
- **AP systems** (Cassandra, DynamoDB default, CouchDB): give up consistency under partition (eventual). Good for social, analytics, caches.

**Most web applications need eventual consistency for most data + strong consistency for specific operations** (payment, account creation). Don't pick one engine for everything.

---

## Database selection matrix

The split is **nature of data and access pattern**, not "which is trendy".

| Need | Engines | When |
|---|---|---|
| Transactional, relational | PostgreSQL, MySQL | Default. 90% of cases. |
| Documents with variable schema | MongoDB, DynamoDB | When schema really is dynamic and you live with it |
| Wide-column at huge scale | Cassandra, ScyllaDB | Time-series logs, hundreds of TB+, write-heavy |
| KV cache / sessions / leaderboards | Redis, Valkey, KeyDB | Hot data, sub-millisecond access |
| Search / full-text / fuzzy | Elasticsearch, OpenSearch, Typesense, Meilisearch | When `LIKE '%foo%'` falls over |
| Analytics / OLAP | ClickHouse, DuckDB, Snowflake, BigQuery | Dashboards, reports, billion-row aggregations |
| Time-series | TimescaleDB, InfluxDB, VictoriaMetrics | Metrics, IoT, monitoring |
| Graph | Neo4j, Memgraph, Postgres + AGE | Social graphs, fraud, recursive traversal beyond CTEs |
| Vector / embeddings | pgvector, Qdrant, Weaviate, Pinecone | RAG, semantic search |

**Anti-pattern**: "MongoDB because schema-less". Modern Postgres with JSONB covers ~95% of those cases and gives you transactions, joins, and a mature ecosystem. **Default is Postgres**; deviating from that needs a reason.

### Postgres as a Swiss army knife

Modern Postgres covers OLTP, JSONB, full-text search, vector search (pgvector), time-series (TimescaleDB), graphs (AGE), pub/sub (LISTEN/NOTIFY), and queues (skip-locked, pgmq). For most projects, "one Postgres + specialized tools as you grow" beats "five engines from day one". Less ops burden, fewer CAP migraines.

---

## Scaling patterns

### Vertical vs horizontal

- **Vertical** (bigger machine) — simple but ceiling exists and gets expensive. Use until it stops working; the modern ceiling is high.
- **Horizontal** (more machines) — near-infinite, but adds distribution complexity.

Heuristic: vertical while it works; horizontal when vertical breaks or geographic distribution is required.

### Application layer

Stateless apps scale trivially behind a load balancer. If the app is **stateful** (sticky sessions, in-memory cache, websockets), either externalize state (session store, central cache) or accept the complexity of sticky routing.

### Database scaling steps (in order)

1. **Indexes and query optimization** — 80% of "slow DB" is a missing index or N+1.
2. **Read replicas** — read-heavy load fans out to replicas. Writes stay on primary. Eventual consistency between them.
3. **Caching layer** — Redis in front. Cache-aside / read-through / write-through. Mind invalidation.
4. **Vertical scaling of the DB** — modern hardware goes far.
5. **Partitioning** within one DB — by range, hash, or list.
6. **Sharding** across DBs — last resort. Breaks joins, requires shard-aware app code. Don't reach here prematurely.

### Caching layers

| Layer | What | When |
|---|---|---|
| CDN edge | static, cacheable HTML, API responses | any public content |
| Reverse proxy (nginx, Varnish) | HTTP responses | when CDN unavailable or fine-grained control needed |
| App-level memory | hot data inside process | only with sticky routing and consistency tolerance |
| Distributed cache (Redis) | sessions, hot data, computed results | default for most projects |
| DB query cache | query results | Postgres caches pages itself; manual rarely needed |

**Cache invalidation is the hard part.** Strategies: TTL (simplest, eventual consistency); write-through (sync with DB, costs writes); cache-aside + explicit invalidation (most flexible, requires discipline).

---

## Async patterns: queues and events

### When you need a queue

- Long operations (email/SMS, media processing, report generation)
- Smoothing spikes
- Decoupling services
- Guaranteed delivery with retry

### Engines

| Tool | When |
|---|---|
| Redis-based (BullMQ, Sidekiq) | Simple job queues, up to ~10K msg/s, low ops cost |
| Postgres + skip-locked (pgmq, river) | Already have Postgres, don't want new infra |
| RabbitMQ | Complex routing, classic AMQP patterns |
| Kafka / Redpanda | Event streaming, log-based, large scale, replay, multi-consumer |
| NATS | Lightweight, low-latency, simple |
| Cloud-managed (SQS, Pub/Sub) | Don't want to operate infrastructure |

**Anti-pattern**: Kafka for 100 jobs/day. Kafka is for streaming, not job queues.

### Event-driven architecture

EDA is powerful but makes the whole product **eventually consistent**:
- No global transactions.
- Idempotent handlers are mandatory.
- Debugging is harder (trace events across services).
- Order guarantees depend on the engine.

EDA pays off when domains are genuinely loosely coupled, change at different cadences, and an audit log is a business requirement. EDA as cargo cult — one team, one product, all in one DB — costs more than direct calls.

---

## Microservices: when they're warranted

Microservices solve an **organizational** problem (multiple teams want to ship independently), not a technical one. One team ⇒ almost certainly no.

**Conway's Law**: the system mirrors the team's communication structure. Four people running 12 microservices don't have 12 microservices — they have a distributed monolith bleeding from every interface.

### Costs (often ignored)

- Network calls instead of in-process — latency, partial failures.
- Distributed transactions: impossible or hard (sagas, outbox).
- Contract versioning.
- Code duplication (auth, logging, validation).
- Operational overhead × N services (deployment, monitoring, tracing).
- Local dev: running the stack on a laptop.

### Signals to migrate from monolith

- Teams genuinely block each other on releases.
- Different parts have fundamentally different scale / language / SLA needs.
- Clear bounded contexts (DDD) that rarely intersect.

### Signals **not** to migrate

- "It's the modern way."
- "Monolith is big" — big ≠ bad; modularize internally first.
- "We want polyglot" — this is a bad reason.

**Modular monolith** is an excellent middle ground: one deploy, hard module boundaries, ready to extract a service when an actual need shows up.

---

## Reliability patterns

### Failure modes to design for

- Network timeouts and disconnects.
- Partitions between services.
- Slow dependencies (worse than dead — they fill connection pools).
- Cascading failures.
- Thundering herds (clients all retry simultaneously).

### Patterns

| Pattern | What it does |
|---|---|
| Timeouts | Every external call has one. **Cannot live without.** SDK defaults are often wrong. |
| Retries with exponential backoff + jitter | Without jitter you get a thundering herd on recovery. |
| Circuit breaker | After N consecutive failures, open the circuit; stop hammering a downed dep. |
| Bulkhead | Isolate connection pools per downstream so one bad dep doesn't drown the others. |
| Rate limiting | Defend against overload (token bucket, leaky bucket, sliding window). |
| Backpressure | When overloaded, reject or slow upstream rather than queue infinitely. |
| Graceful degradation | One component fails; system runs in reduced mode rather than full outage. |
| Idempotency keys | Safe retries for non-idempotent operations. |
| Dead letter queue | Unprocessable messages parked; nothing is silently lost. |

### SLI / SLO / SLA / error budgets

- **SLI** — what we measure (latency, error rate).
- **SLO** — internal target (99.9% under 200ms).
- **SLA** — external promise (often weaker than SLO so there's headroom).
- **Error budget** — at 99.9% SLO you have 0.1% to spend on releases and experiments. When it's gone, freeze features, fix reliability.

Design to SLOs. Without numbers, "reliability" is a taste discussion.

---

## Real-time systems

Push-update systems (chat, notifications, presence, live data).

| Technique | When |
|---|---|
| Long polling | Simple cases, behind restrictive proxies |
| Server-Sent Events (SSE) | One-way updates (notifications, live feeds). Simpler than WS, runs on HTTP/2. |
| WebSocket | Two-way interactive (chat, collaborative editing) |
| WebRTC | P2P, low-latency audio/video |
| Push notifications (FCM, APNs) | When client is offline |

**Architectural hard parts**:
- Connection pinning to one server → sticky LB or pub/sub fan-out across instances.
- Auth at the WS handshake.
- Backpressure when client lags.
- Reconnection with missed-message recovery (sequence numbers, last_id).
- Capacity: N connections = N memory + N file descriptors.

---

## Observability as architecture

Not "we'll add logs later". This is structural:

- **Logs** — structured (JSON), correlation IDs across all logs of one request.
- **Metrics** — RED (Rate, Errors, Duration), USE (Utilization, Saturation, Errors).
- **Traces** — OpenTelemetry, distributed tracing across services.
- **Profiles** — continuous profiling (Pyroscope, Parca) for latency hotspots.

Stack: OpenTelemetry collection → Grafana / Datadog / Honeycomb / Tempo / Loki for storage and analysis.

---

## Cost as architecture

Architectural choices have price tags:
- Egress bandwidth (often the costliest line on cloud bills).
- Cross-region traffic.
- Managed-service markup vs self-hosted.
- Hot vs cold storage tiers.
- Spot/preemptible instances for batch.

For small projects: VPS providers (Hetzner, Vultr) often cost an order of magnitude less than AWS for the same resources. Cloud overengineering is a real budget item.

---

## Reading list (when the user wants to go deeper)

- *Designing Data-Intensive Applications* (Kleppmann) — the single must-read for distributed systems.
- *System Design Interview* vol 1 + 2 (Alex Xu) — practical FAANG prep.
- *Database Internals* (Petrov) — DB internals.
- *Site Reliability Engineering* (Google) — operational side, free online.
- *The Site Reliability Workbook* — sequel with practice.
- *Software Engineering at Google* — process and architecture at scale.
- *Building Microservices* (Newman) — if microservices are actually needed.
- *Release It!* (Nygard) — stability patterns.
- Papers We Love (papers-we-love.org) — Dynamo, Spanner, Bigtable, Raft.
- Blogs: Marc Brooker (AWS), Murat Demirbas, Jepsen reports by Kyle Kingsbury.

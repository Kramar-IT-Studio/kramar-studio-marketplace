---
name: backend-architecture
description: Use this skill for backend service-level architecture — service decomposition, API design (REST/GraphQL/gRPC), transaction boundaries, async work and outbox patterns, idempotency, retries, distributed locks, observability. Triggers on phrases like "design this service", "how should I structure this API", "where should I put the transaction", "how to handle this race condition", "how to make this idempotent". For broader distributed-systems / scaling questions defer to `system-design`. For specific framework or library version checks defer to `architecture-research`.
---

# backend-architecture

For service-level backend architecture. Sits between `system-design` (cross-service, scaling, infra) and individual code review. Focused on the service as a coherent unit.

## API design

### Pick the right protocol

| Protocol | Pick when |
|---|---|
| **REST + JSON** | Default for public APIs, web clients, broad consumer compatibility. Cacheable via HTTP semantics. |
| **GraphQL** | Many client variants, heavy over-fetching with REST, frontend-led product. Cost: server complexity, caching is harder, N+1 risk. |
| **gRPC / Protobuf** | Internal service-to-service, low-latency, schema discipline matters, polyglot. Bad fit for browsers (needs grpc-web bridge). |
| **Async / events / message bus** | Loose coupling, fan-out, batch, eventual consistency acceptable. |

Mix is normal: REST for browsers, gRPC for internal, events for cross-domain.

### Versioning

- **URL versioning** (`/v1/`, `/v2/`) — simplest, breaks coexistence harder.
- **Header versioning** (`Accept: application/vnd.app.v2+json`) — purer REST but worse DX.
- **Schema evolution** (additive changes only, never remove without deprecation window) — best when feasible.

For internal APIs, evolve the schema in place with backward compatibility. For public APIs, version explicitly and deprecate on a calendar.

### Pagination, filtering, sorting

Mandatory from day one:

- Cursor-based pagination (`?after=...&limit=...`) over offset-based for any non-trivial dataset (offset breaks under writes and is O(n)).
- Predictable filter syntax — pick one and document it (`?status=active`, JSON:API, RSQL, etc.).
- Sort with explicit allowlist of fields.

Lists without pagination become a DoS vector once data grows.

### Error model

A consistent error contract is a feature:

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Order with id 123 was not found",
    "details": { "resource": "order", "id": "123" },
    "request_id": "01H..."
  }
}
```

Every error has: a stable code (machine-readable), a message (human-readable), optional details, a request id (for log correlation). `request_id` shows up in the response headers and in every log line for that request.

---

## Service decomposition

When does a feature deserve its own service?

**Yes-signals:**
- Owned by a different team that releases on a different cadence.
- Fundamentally different scale, language, or SLA than the rest.
- Truly bounded context with thin, well-defined interface.
- Contains regulated data that must be isolated for compliance.

**No-signals:**
- "Microservices are modern."
- "Our monolith is large." (Modularize internally first.)
- "We want polyglot." (Almost always a bad reason.)

**Modular monolith** is the right default. One deployment, internal modules with hard boundaries, ready to extract a service when an actual reason shows up.

### Module boundaries inside a monolith

The same boundary discipline as between services:
- Each module has an explicit public API (a single file or directory exposing what's available).
- Internal types and functions are not imported across module boundaries.
- Cross-module calls go through the public API.
- Linter or codegen enforces this (e.g., dependency-cruiser, FSD-style ESLint rules).

A modular monolith with strict module boundaries gets ~80% of the architectural benefits of microservices with ~10% of the operational cost.

---

## Transactions and consistency

### Where transactions belong

The transaction boundary is a domain decision, not a technical one. The right scope:

- **Use case / command level** — one transaction per business operation, opened in the application layer.
- **Repository method level** — wrong. Repository methods compose into a use case; the transaction belongs to the use case.

```
HTTP handler
  → use case (transaction boundary)
    → domain service
      → repository methods   ← do NOT manage transactions here
```

### Distributed transactions are mostly impossible

Two-phase commit across services is fragile. Alternatives:

- **Outbox pattern** — write the local DB change and an event row in the same transaction; a separate process publishes the event reliably.
- **Saga** — sequence of local transactions, each with a compensating action. Pick choreography (events) for loose coupling, orchestration (a coordinator service) for visibility and complex flows.
- **Eventual consistency with reconciliation** — periodic job ensures things converge. The simplest pattern often beats fancy ones.

If you find yourself reaching for cross-service ACID, step back and reconsider service boundaries. Often the fix is "those two things shouldn't be in different services".

### Idempotency

Any non-idempotent operation that's exposed to retries needs an idempotency mechanism:

- **Idempotency key** (header from caller, stored server-side with response) — for HTTP APIs. Industry standard.
- **Natural keys** — `INSERT ... ON CONFLICT DO NOTHING` when the operation has a natural unique key.
- **Event ID dedup** — for event consumers, store processed event IDs (TTL-bounded).

Network retries are inevitable. Building idempotency in is non-negotiable for anything that mutates state.

---

## Async work

### When to push to async

- Latency budget can't accommodate the work synchronously (>200ms is a smell, >1s is mandatory async).
- Work fans out beyond the request lifecycle (notifications, downstream side effects).
- Work needs guaranteed delivery beyond a single request.
- Work spikes and needs smoothing.

### Patterns

- **Fire-and-forget enqueue** — request returns immediately; worker picks up later. Needs idempotency.
- **Outbox** — same DB transaction writes a "to-emit" row; a relay publishes. Survives crashes.
- **Webhook / callback** — for cross-system async confirmation.
- **Polling** — cheap, simple, sometimes the right answer. Don't underestimate it.

### Failure handling for workers

- **Bounded retries with exponential backoff + jitter.**
- **Dead letter queue** for poison messages — never silently drop.
- **Visibility timeout / lease** — so a stuck worker doesn't lock a job forever.
- **At-least-once delivery is the default** — design idempotent handlers.

---

## Authentication and authorization

### AuthN

- Internal service-to-service: short-lived signed tokens (mTLS or JWT signed by an internal authority). Don't use shared secrets across services.
- Public API: OAuth 2.0 + OIDC for user-facing, API keys for machine-facing.
- Session vs JWT for web app users — see `frontend-architecture` for the trade-offs.

### AuthZ

- **RBAC** (role-based) — simplest, scales to a few dozen roles before pain.
- **ABAC** (attribute-based) — flexible policies, harder to audit.
- **ReBAC** (relationship-based, e.g., Zanzibar / OpenFGA / SpiceDB) — for products with sharing/collaboration semantics. Default for "who can access what" in social and B2B SaaS.

The architectural anti-pattern: scattering authorization checks across handlers. Centralize: a policy layer near the use case, not in the HTTP handler.

---

## Observability

Three pillars, always all three:

| Pillar | What | Tools |
|---|---|---|
| **Logs** | Structured (JSON), correlation IDs, request IDs | OpenTelemetry, Vector, Loki |
| **Metrics** | RED, USE, business KPIs | Prometheus, OpenTelemetry, Datadog |
| **Traces** | Spans across services tied by trace ID | OpenTelemetry, Tempo, Jaeger, Honeycomb |

Optional fourth: **continuous profiling** (Pyroscope, Parca) for CPU/memory hotspots in production.

### Correlation discipline

Every incoming request gets a `request_id` (or accepts an upstream one). It's:
- In every log line of that request.
- In the trace.
- In the response header (clients can quote it for support).
- Propagated to all downstream calls.

Without correlation IDs, debugging distributed systems is archaeology.

---

## Reliability checklist for any service

When designing a new service or reviewing an existing one, walk this:

- [ ] Every external call has an explicit timeout (don't trust SDK defaults).
- [ ] Retries with exponential backoff and jitter where appropriate.
- [ ] Circuit breaker on critical downstream calls.
- [ ] Connection pools sized and bounded; bulkheads where one downstream's slowness shouldn't drown others.
- [ ] Idempotency keys on mutating endpoints exposed to retries.
- [ ] Rate limiting per principal (user, API key) on public endpoints.
- [ ] Graceful degradation paths for non-critical dependencies.
- [ ] Health/readiness/liveness endpoints distinct (k8s-style).
- [ ] Graceful shutdown that drains in-flight requests.
- [ ] Backpressure or rejection when overloaded — never unbounded queueing.
- [ ] Structured logs with correlation IDs.
- [ ] Metrics for RED on every endpoint.
- [ ] Distributed tracing wired for cross-service calls.
- [ ] SLOs defined; error budget tracked.
- [ ] Runbooks for common incidents.

Missing items aren't all blockers, but they should all be conscious choices, not accidents.

---

## Reading list

- *Building Microservices* (Newman) — when microservices are actually warranted.
- *Release It!* (Nygard) — stability patterns; the canon for reliability.
- *Web API Design: Principles for Crafting Modern Interfaces* (Nottingham) — APIs done right.
- *Designing Web APIs* (Jin/Sahni/Shevat) — pragmatic API design.
- *Patterns of Enterprise Application Architecture* (Fowler) — older but most patterns still hold.
- *Database Internals* (Petrov) — the engine your service runs on.

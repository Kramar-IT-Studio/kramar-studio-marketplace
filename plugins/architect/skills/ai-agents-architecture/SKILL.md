---
name: ai-agents-architecture
description: Use this skill for designing LLM-powered agent systems — tool-use orchestration, memory architecture, latency and cost budgets, retrieval (RAG), evaluation harnesses, prompt-injection and exfiltration threat models, multi-agent topologies. Triggers on phrases like "design an agent that...", "how to structure tool use", "RAG architecture", "agent memory", "evaluate this agent", "prompt injection". Knows the area moves fast and defers to `architecture-research` for current model capabilities, prices, and provider features.
---

# ai-agents-architecture

For systems where an LLM acts as a planner, decider, or executor with tool access. Rules of physics here are different from classical backend systems and worth naming explicitly.

## Constants of the domain

LLM-based systems have unusual operating characteristics that *every* architectural decision must respect:

- **Latency per call**: 1–10+ seconds. Cannot live in a synchronous hot path. Async + UI streaming or background jobs.
- **Cost per call**: tokens are dollars. Every architectural choice has a cost dimension.
- **Non-determinism**: same input, different output. Tests need to be statistical, not exact-match.
- **Context window is finite**: the architecture is a memory hierarchy problem, not just a prompt-engineering problem.
- **Reliability of providers**: API outages and rate limits happen. Plan for fallback.
- **Tool calls cost compute and may have side effects**: every tool exposed is a permission and a possible failure path.

Treat these as the CAP-equivalent of the LLM era — they constrain everything else.

---

## Agent-as-state-machine

Single-prompt completion is one thing. **An agent with tools is a state machine**, and that's the right mental model.

```
                 ┌─────────────┐
                 │  user input │
                 └──────┬──────┘
                        ▼
              ┌──────────────────┐
              │   plan / decide  │ ← LLM call
              └──┬────────────┬──┘
                 │            │
         tool call            answer
                 │            │
                 ▼            ▼
        ┌──────────────┐   ┌────────┐
        │ execute tool │   │  done  │
        └──────┬───────┘   └────────┘
               │
               ▼  observation
               │
               └──── back to plan
```

Design the state machine before writing prompts. What are the states? What are the transitions? What's the termination condition? What's the maximum number of steps?

**Loop limits are mandatory.** An agent with tools and no max-step is a budget bomb.

---

## Tool design

### Granularity

- **Too fine** ("set field X to value Y") — agent burns turns and tokens orchestrating.
- **Too coarse** ("do the whole job") — agent has no leverage and you have no observability.
- **Right** — actions a human operator would naturally take: `search_documents(query)`, `create_ticket(...)`, `send_email(...)`.

### Description discipline

The tool description is part of the prompt. It must:
- State **when to use this tool** (and when not).
- State **what inputs are valid**.
- State **what the output looks like**.
- Include **at least one short example**.

A vague tool description produces a vague tool-using agent.

### Permissions

Each tool is a permission. Apply principle of least privilege:
- Read tools and write tools are different categories — make this explicit.
- Destructive operations (delete, send, transfer money) have an additional confirmation layer.
- Sandbox execution where possible (filesystem, shell, network).

### Idempotency for tools with side effects

Same idempotency rules as backend services. If the agent retries a `send_email` because of a timeout, the recipient should not get two emails.

---

## Memory architecture

Agent memory is a hierarchy, not a single store. Pick layers consciously:

| Layer | Lifetime | Storage | Use |
|---|---|---|---|
| **Working memory** | One turn | Prompt context | Current task, recent observations |
| **Conversation memory** | One session | In-context, possibly summarized | Multi-turn dialogue |
| **Episodic memory** | Across sessions | DB or vector store | "What did the user/agent do last week" |
| **Semantic memory** | Across sessions | Vector store, knowledge graph | Facts learned, retrieved by similarity |
| **Procedural memory** | Long-term | Skill files, instructions, fine-tunes | "How to do X" — this plugin's `skills/` |

### Context-window discipline

The biggest source of cost and quality degradation is uncontrolled context growth.

- **Summarize** old conversation segments instead of letting them accumulate.
- **Retrieve, don't dump** — RAG over a large knowledge base, don't paste everything.
- **Tier prompts**: stable system prompt + dynamic per-task context. Cache the stable part where possible (prompt caching).
- **Measure tokens like you measure latency** — set budgets, watch them in metrics.

---

## RAG architecture

Retrieval-Augmented Generation is the dominant pattern for grounding LLM output in your data.

### Pipeline shape

```
ingestion: raw docs → chunk → embed → index
query:     question → embed → vector search → rerank? → prompt with context → generate
```

### Chunking

- **Fixed-size chunks** (e.g., 500 tokens with 50-token overlap) — simple baseline.
- **Semantic chunks** (split on headings, sentences, paragraphs) — usually better.
- **Document-aware chunks** (tables, code, prose treated differently) — best, more work.

Bad chunking is the most common reason RAG fails. If your retrieval looks wrong, look at your chunks first.

### Embedding model choice

This is version-sensitive — defer to `architecture-research` for the current best-in-class. Watch:
- Embedding dimension (cost in storage and search).
- Multilingual support if applicable.
- Domain match (general vs code vs scientific).
- Provider lock-in (re-embedding everything when you switch is expensive).

### Reranking

Vector search returns approximate matches. A reranker (cross-encoder) on the top-K improves precision dramatically and is often the cheapest single quality improvement. Add it before chasing fancier retrievers.

### Hybrid search

Pure vector search misses on exact-match queries (IDs, names, code). Combine vector + BM25 (lexical) and merge — usually beats either alone.

---

## Multi-agent topologies

When does multi-agent help vs hurt?

**Helps** when:
- Subtasks need genuinely different system prompts / tools / models.
- Parallelism on independent subtasks saves wall-clock time.
- One agent's context would otherwise overflow.

**Hurts** when:
- The "agents" are just ceremonious function calls — single agent with tools is simpler.
- Coordination overhead (passing state between agents) outweighs the work itself.
- Failure modes multiply faster than capability.

Topologies:

- **Pipeline** — fixed sequence, each agent feeds the next. Like a Unix pipe.
- **Orchestrator + workers** — one agent plans, dispatches subtasks to specialized workers, collects results.
- **Debate / critique** — generator + critic loop until convergence.
- **Hierarchical** — orchestrator dispatches to sub-orchestrators recursively. Use sparingly; depth amplifies cost.

Default to a single agent with good tools until you have a concrete reason for multi-agent.

---

## Evaluation harness

**Without evals, agents are cargo cult.** Every change to a prompt or pipeline must be measurable.

### Eval types

- **Golden set** — curated inputs with expected outputs. Run on every change. Detects regressions.
- **LLM-as-judge** — another model scores the output against a rubric. Cheap, scales, biased. Use with care and human spot-checks.
- **Human eval** — gold standard for subjective quality. Expensive. Reserve for major changes.
- **Production sampling** — log a percentage of real traffic + outputs, sample for review.

### What to measure

- Task success rate.
- Tool-use correctness (right tool, right arguments).
- Latency (p50, p95, p99).
- Cost per task.
- Hallucination rate (where verifiable).
- Specific failure modes you've seen.

### Integration

Run the eval set in CI on prompt or pipeline changes. Treat it like a unit test suite — green to merge.

---

## Threat model

LLM systems have a unique attack surface. Design with these in mind:

### Prompt injection

User input (or content the agent reads) contains instructions that override the system prompt. Mitigations:
- **Don't grant the agent powerful tools when its input includes untrusted text.** This is the single most important rule.
- Input/output separation: clearly mark untrusted content in the prompt.
- Privilege separation: an "untrusted" agent without dangerous tools handles user input; passes structured output to a "trusted" agent that has tools.
- Human-in-the-loop confirmation for destructive actions.

### Data exfiltration through tool use

If the agent can read sensitive data and send it externally (HTTP fetch, email, etc.), an attacker via prompt injection can exfiltrate. Treat any tool that touches the outside world as a leak vector. Restrict, sandbox, log.

### Indirect injection

The agent reads a file or webpage that contains hostile instructions. Same mitigations as direct injection, but the threat is harder to detect because it's not in the user's message.

### Cost attacks

A user (or hostile prompt) drives the agent to call tools in a loop, racking up bills. Mitigations:
- Per-user, per-session, and per-task cost limits enforced server-side.
- Step / tool-call limits per task.
- Anomaly alerts on cost spikes.

### Output verification

For agent outputs that drive automated actions (creating tickets, sending emails, executing code), verify:
- Output schema matches expected (use structured output or strict parsing, not regex).
- Values are within expected ranges.
- For code execution, sandbox.

---

## Cost and latency engineering

### Caching

- **Prompt caching** (provider-side, when supported) — for stable system prompts and few-shot examples. Often a 5–10× cost reduction on repeated calls.
- **Semantic cache** — cache (embedding-of-question → answer) pairs; if a new question is similar enough, serve cached answer. Useful for FAQ-like loads, dangerous when answers depend on freshness.
- **Tool result caching** — if a tool call's inputs deterministically produce its output, cache it.

### Model selection per task

Don't use the biggest model for everything. Route:
- **Cheap, fast model** for classification, routing, simple extraction.
- **Mid-tier model** for most generation.
- **Top-tier model** only for the hard reasoning steps.

A planner that picks the right model for each subtask is a major cost lever.

### Streaming

For user-facing responses, stream tokens as they arrive. Doesn't reduce total time but transforms perceived latency.

### Batching

For background tasks where multiple inputs can be combined into one call, batch them. The savings on per-call overhead and prompt repetition are significant.

---

## Observability for agents

Standard backend observability + agent-specific:

- **Trace each turn** as a structured event with: input, tool calls made, tool outputs, model output, tokens used, cost, latency.
- **Log full prompts and outputs** (with redaction) for the cases where regression analysis is needed. Storage is cheap; rebuilding context is expensive.
- **Aggregate metrics**: tokens/turn, tools/turn, success rate, cost/task.
- **Alert on anomalies**: cost spikes, sudden quality drops on the eval set.

---

## Reading list

The field moves fast — defer specifics to `architecture-research`. Stable starting points:

- Anthropic's "Building Effective Agents" essay — clear taxonomy of agent patterns.
- "ReAct" paper (Yao et al.) — the pattern most agent loops are descendants of.
- "Toolformer" and follow-ups — tool-use foundations.
- "Constitutional AI" (Anthropic) — alignment side that affects behavior.
- "Lost in the Middle" (Liu et al.) — context-position effects on retrieval.
- The OWASP LLM Top 10 — threat model checklist.
- Recent eval frameworks — Inspect (UK AISI), Promptfoo, Braintrust, LangSmith. Pick one and use it.

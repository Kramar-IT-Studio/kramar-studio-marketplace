---
description: Phase 1.5 of the Architecture Cycle — gather current information from the web on a focused topic. Run between Discover and Design when claims depend on versions, releases, benchmarks, or current best practices.
argument-hint: "<focused research question>"
---

# /archforge:research

The optional but often-decisive phase between Discover and Design. Use when answering the architectural question requires **current** information — versions, prices, benchmarks, capabilities, regulatory status — that pretrained knowledge cannot supply reliably.

## When to run

Run after `/archforge:discover` and before `/archforge:design` when the discovery surfaced any of:

- **Version-sensitive claims**: "what's the current state of <framework>", "is <library> still recommended", "did <provider> add <feature>".
- **Comparative analysis**: head-to-head between options where current characteristics matter (pricing, performance, certifications).
- **Regulatory / compliance posture**: current law, data residency, certification status of a provider.
- **Pricing**: any quoted number for managed services, LLM tokens, infrastructure tiers.
- **Capabilities of fast-moving ecosystems**: AI/LLM providers, cloud edge runtimes, frontend meta-frameworks.

**Skip** when the discovery output already contains stable, principle-level information (CAP, latency budget logic, classical patterns) and the design phase can proceed without further data.

## Inputs

- Research question: `$ARGUMENTS`. Should be focused, not omnibus. "Current Russian LLM providers with function-calling support and 152-FZ-compliant data residency" — good. "Tell me about LLMs" — bad.
- Discovery output: read the most recent file in `docs/architecture/research/` matching the parent problem.
- Project context: `./ARCHITECTURE.md` and prior ADRs.

## Process

Use the `architecture-research` skill as the source of truth for query construction, source priority, validation, and search depth. Optionally delegate to the `researcher` sub-agent for tasks expected to require many searches.

The phase produces a research digest, not a search log. The reader cares about the conclusions and the freshness of the sources, not the path you took.

## Output structure

```markdown
# Research: <question>

## Question
<verbatim research question>

## Headline finding
<1–2 sentences: the bottom-line answer that should change the design phase>

## Detailed findings
<bulleted findings, each with inline source + publication date>

## Comparison matrix (if comparative)
<options × dimensions, with per-cell sourcing>

## Caveats and unknowns
<things you couldn't confirm; things that may have shifted since the most recent source>

## Implications for the design phase
<2–4 bullets explicitly pointing at how this changes which alternatives are realistic>

## Sources
1. [Source name + publication date] — URL
2. ...
```

## Output location

Save to `docs/architecture/research/YYYY-MM-DD-<slug>-research.md`. Slug matches the parent discovery document so the cycle's artifacts cluster.

## Discipline

- **Cite dates inline.** Every claim attached to a source must have the source's publication date in the citation, e.g. "Per Yandex Cloud blog (Mar 2026)...". A claim with no date is suspect.
- **No fabrication.** "Couldn't find current information on X" is more valuable than confident guessing.
- **Note vendor-source bias explicitly** when relevant. A managed-service vendor's blog post about its own service is information, but it is not neutral.
- **Cross-check important claims** against ≥2 independent sources before stating them.
- **Search depth scales with question complexity** — 1–2 searches for a single lookup, 3–5 for comparison, 5–10+ for a full landscape scan. If the topic genuinely needs 20+ searches, return what you have with a note that the topic warrants a longer dedicated session and possibly the `researcher` sub-agent.

## Output to chat

- One-paragraph headline finding.
- Path of the saved digest.
- Suggestion: "When the design phase runs, it will read this research as primary input. Run `/archforge:design \"<problem>\"` next."

## When research changes the framing

Sometimes research surfaces a constraint that **invalidates the discovery output** — a provider isn't actually available in your jurisdiction, a library has been deprecated, a regulatory deadline shifted. When that happens:

1. Do not silently proceed to design with the new information.
2. Tell the user which discovery assumption is now broken.
3. Suggest: "Re-run `/archforge:discover` with this new information, or amend the existing discovery document with a 'Round 2 (post-research)' section."

The `architect` skill should treat this as a normal part of the cycle, not a failure. Discovery rounds compound — each round refines the problem.

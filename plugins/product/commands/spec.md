---
description: Phase 3 of the product cycle — implementation spec with explicit acceptance criteria.
argument-hint: "<feature slug or PRD-NNNN>"
---

# /product:spec

Phase 3 of the per-feature product cycle. Take a PRD and produce an implementation spec engineering can build from. The spec is **the product/engineering contract** — what behaviors qualify as "done", what edge cases are explicitly handled, what's intentionally deferred.

## Inputs

- Feature slug or PRD ID: `$ARGUMENTS`
- The matching `docs/product/prds/*.md` (PRD-NNNN). **Required.** If missing, abort and tell the user to run `/product:define` first.
- `ARCHITECTURE.md` and relevant ADRs — the spec must conform to them.
- `CLAUDE.md` for codebase conventions.

## What to produce

A spec covering:

1. **Header** — feature, source PRD, target architecture (which ADRs apply).

2. **Behavior contract** — the user-facing behaviors from the PRD's acceptance section, expanded into precise specifications. Each behavior is:
   - Trigger.
   - Pre-conditions.
   - Action.
   - Post-conditions.
   - Visible side-effects (UI, events, analytics).

3. **Acceptance criteria** — **MANDATORY.** A numbered list of testable statements. Each criterion is:
   - Phrased as `Given/When/Then` or as a precise assertion.
   - Independent (can be checked in isolation).
   - Tied to one or more PRD success-metric components or PRD acceptance items.

   The hook will flag if this section is missing or has fewer than 3 criteria.

4. **Edge cases and error states** — list the failure modes. For each: expected behavior, user-facing message (if any), recovery path. "Not sure" is a valid entry, but it's also an open question.

5. **Out of scope (explicit)** — what this spec does *not* cover. "Phase 2" features, deferred edge cases, intentionally weak fallbacks.

6. **Analytics / observability** — what we instrument to actually measure the success metric. Event names, properties, where they fire. **A spec where the success metric isn't measurable is broken.**

7. **Open questions for engineering** — implementation choices the spec doesn't pin down because they're judgment calls (library, exact data type, etc.). These are *not* product questions; they're for the engineer (or the architect via `/archforge:cycle`).

8. **Cross-references** — `links_to`:
   - Source PRD-NNNN.
   - All ADRs the spec relies on or triggers.

## Output location

Save to `docs/product/specs/YYYY-MM-DD-<feature-slug>-spec.md`.

Front-matter:
```yaml
---
id: SPEC-NNNN
status: draft
created_at: YYYY-MM-DD
role: product
links_to:
  - PRD-NNNN          # always
  - ADR-NNNN          # all ADRs the spec depends on
acceptance_count: <n>  # mirrors section 3 length
---
```

Allocate `SPEC-NNNN` sequentially.

Update the source PRD's status: `draft` → `active` when its SPEC enters draft.

## Discipline

- **Acceptance criteria must be testable, not aspirational.** "The system is fast" is not a criterion. "p95 round-trip < 200ms under 100 RPS" is.
- **At least 3 acceptance criteria.** Below this, you're not specifying — you're hand-waving. The hook flags this.
- **Out-of-scope must be explicit.** "We won't handle network partitions in v1" is a valid line. Silently not handling them is a bug.
- **Analytics is part of the spec.** If you skip section 6, the success metric in the PRD is unmeasurable, which means the PRD was broken too.
- **If the spec contradicts an existing ADR, stop.** Surface the conflict: "this spec implies a deviation from ADR-NNNN. Resolve via `/archforge:cycle` (new ADR superseding the old) before continuing." Do not silently override architecture from product side.

## Review pass

After drafting, run a self-review pass for:
- Every PRD acceptance item maps to ≥1 SPEC acceptance criterion.
- Every SPEC acceptance criterion can be tested by an engineer without asking you a clarifying question.
- Every `success_metric` component in the PRD has a corresponding analytics event in section 6.

Append the result of the pass as Section 9: "Self-review notes" (1–3 lines).

## Worked examples

### Good: SPEC for "undo on accidental delete" (continues PRD-0005)

```yaml
---
id: SPEC-0005
status: draft
created_at: 2026-04-17
role: product
links_to:
  - PRD-0005
  - ADR-0011
acceptance_count: 6
---
```

**Behavior contract — Undo single-document delete.**

- **Trigger.** User clicks delete on a document (single, not bulk) from the document tree, the open document header, or the keyboard shortcut.
- **Pre-conditions.** Document is owned by the user's workspace; user has delete permission; document is not in trash already.
- **Action.** Document is marked deleted client-side (removed from tree); a server `delete-document` request is sent with `soft=true`; toast appears with text "Document deleted" and an "Undo" affordance.
- **Post-conditions.** Document does not appear in the tree. Document is in trash on the server (soft-deleted). If undo is not invoked within 5 seconds, the toast dismisses; no further action.
- **Side-effects.** Analytics event `document.deleted` fires with `{document_id, source: tree|header|shortcut}`. If undo is invoked, analytics event `document.undeleted` fires with `{document_id, time_to_undo_ms}`.

**Acceptance criteria.**

1. **Given** a non-trash document, **when** the user invokes delete, **then** the toast appears within 200ms with the text "Document deleted" and a clickable "Undo" element.
2. **Given** the toast is visible, **when** the user clicks "Undo" within 5 seconds of toast appearance, **then** the document re-appears in the tree at its original position, with its original title and metadata, within 500ms.
3. **Given** the toast is visible, **when** 5 seconds elapse without interaction, **then** the toast dismisses and no further action is taken; the document remains in trash and recoverable via the trash UI.
4. **Given** another collaborator on the same document had it loaded before the delete, **when** the deleter invokes undo, **then** the document re-appears for the collaborator on next sync (≤30 seconds) without manual reload.
5. **Given** the toast is visible, **when** the user presses `Esc`, **then** the toast dismisses immediately (treated as "do not undo").
6. **Given** the user invokes delete and the network request fails, **when** the failure is detected, **then** the toast text changes to "Couldn't delete — try again", the Undo affordance is replaced with "Retry", and the document re-appears in the tree.

**Edge cases and error states.**
- **Server soft-delete failed but client already removed.** → Detect via failure response; document re-inserts in the tree; user-facing toast shows "Couldn't delete — try again". Recovery: user retries.
- **Undo clicked at second 4.99 but toast already dismissing.** → Click is honored if it landed before dismiss-animation completed; otherwise restoration is via trash UI (the user sees no error, just no undo).
- **Document deleted while a collaborator is editing it.** → Out of scope for this SPEC (concurrency-on-edit-of-deleted-doc is its own PRD).

**Out of scope (explicit).**
- Bulk delete undo (≥2 documents at once).
- Undo across page refresh.
- Mobile touch UI for the toast (mobile is a separate breakpoint design).

**Analytics / observability.**
- `document.deleted` — fires on delete request initiation. Properties: `document_id`, `source`. Used for baseline and counter-metric (delete volume should not crater).
- `document.undeleted` — fires on successful restore via undo. Properties: `document_id`, `time_to_undo_ms`. Distribution feeds the "is 5s right" question at week 4.
- Support ticket tag tracking — already instrumented in Linear; SPEC reuses existing tag `restore document` for the success metric.

**Open questions for engineering.** Toast component reuse — does the existing notification-toast support an action button + countdown affordance, or do we need a new variant? CSS animation budget for the dismiss.

**Self-review notes.** PRD acceptance items map: PRD#1 → SPEC#1+#2+#3; PRD#2 → SPEC#2; PRD#3 → SPEC#3; PRD#4 → SPEC#4. Every criterion is testable without asking. Success metric (support tickets) is measurable via existing Linear tag — no instrumentation gap.

**Why this is good.** Six independent, testable criteria. Failure mode (network error) has its own criterion, not buried in prose. Out-of-scope is explicit and points at separate PRDs. Analytics names two events tied to the success/counter metrics. Self-review block confirms the trace from PRD acceptance to SPEC acceptance.

### Bad: SPEC that re-derives the PRD

```yaml
---
id: SPEC-0006
status: draft
created_at: 2026-04-17
role: product
links_to:
  - PRD-0005
acceptance_count: 3
---
```

**Acceptance criteria.**

1. The user can undo a delete.
2. The undo works correctly.
3. The system handles errors gracefully.

**Why this is bad — line by line.**

- **#1 is the PRD acceptance copy-pasted.** The SPEC's job is to make the PRD's behavior *testable* — pre-conditions, exact triggers, observable post-conditions. "The user can undo a delete" tells engineering nothing they didn't already read in the PRD.
- **"Works correctly" is the failure mode this command exists to prevent.** What does correctly mean? Within 200ms? Restoring the original tree position? Re-emitting the analytics event? Each of those is a separate criterion. "Correctly" lets a buggy implementation claim conformance.
- **"Handles errors gracefully"** is anti-content. *Which* errors? Network failure? Permission revoked mid-flight? Soft-delete-vs-hard-delete race? Each error needs an explicit expected behavior; gracefully is a placeholder for thinking that wasn't done.
- **3 criteria — exactly the hook minimum.** Hitting the floor of the hook is a smell. The PRD had four acceptance items; the SPEC should expand each into ≥1 testable criterion plus edge cases. 3 is suspicious; 6–8 is normal for this scope.

The push-back move: refuse to save. Tell the user "rewrite each criterion as a Given/When/Then with one observable outcome. If you can't, the SPEC is too vague — go back to the PRD's behavior list and walk through it line by line."

## Anti-patterns to refuse

- **Acceptance criteria that aren't independently testable.** "1. The system is responsive" + "2. The system is reliable" — neither can be verified in isolation; both fail the hook's intent even if they pass the count.
- **Implementation choices in acceptance.** "Acceptance: we use Redis for the soft-delete buffer." That's an architectural decision (belongs in an ADR) or an implementation choice (belongs in engineering's open-questions or a sketch PR). It's not user-observable, so it's not acceptance.
- **Missing analytics section.** A SPEC without section 6 means the PRD's success metric can't be measured. The PRD was broken too if you didn't catch it earlier; refuse to save until analytics are named.
- **Out-of-scope as "phase 2".** "Phase 2: do this properly." That's not out-of-scope, that's a TODO in the wrong place. Out-of-scope items should be either separate PRDs (linked) or genuinely-deferred (with a "wait for" condition).
- **Self-review block left empty or copy-paste-praised.** "All criteria testable ✓" with no actual trace from PRD to SPEC is theatre. Either trace the mapping or don't claim the review happened.
- **Conformance to ADR not stated.** A SPEC that touches a service introduced in ADR-NNNN should reference it in `links_to` *and* note any constraint inherited (idempotency requirements, retry semantics, etc.). Silent assumption = future bug.

## After the spec

Tell the user:
- Where the spec was saved.
- The acceptance count.
- Any unresolved engineering questions.
- **Suggested next step:** implement, then `/product:validate "<feature>"` post-launch.

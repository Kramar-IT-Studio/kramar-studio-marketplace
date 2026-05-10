---
description: Shortcut — write an ADR directly. Use when the decision is already made and you just need the document.
argument-hint: "<one-line decision summary>"
---

# /archforge:adr

Direct shortcut to writing an ADR. Use when you've already decided (in your head, in a meeting, in chat) and want to capture the decision now.

For decisions you haven't made yet, use the full `/archforge:cycle` instead.

## Inputs

- Decision summary: $ARGUMENTS
- Project context: `./ARCHITECTURE.md`, prior ADRs.

## Steps

1. **Find the next ADR number** by listing `docs/architecture/decisions/`. If `docs/architecture/` doesn't exist, suggest running `/archforge:init` first.

2. **Use the `adr-writing` skill** to draft the ADR.

3. **Interview the user briefly** if context is missing — specifically:
   - What forced the decision? (Context section)
   - What did you consider and reject? (Alternatives section — minimum two)
   - What gets harder because of this choice? (Consequences — the honest part)

   Don't fabricate these. If the user can't answer, tell them the ADR will be incomplete and offer to mark it `Proposed` rather than `Accepted`.

4. **Write the file** at `docs/architecture/decisions/NNNN-<slug>.md`.

5. **Update** `docs/architecture/decisions/README.md` index.

6. **Update `ARCHITECTURE.md`** decision index. Other sections only if the decision changes them.

## Discipline

- **Don't pad.** Keep the ADR short — 1–2 pages.
- **Insist on alternatives.** "We chose X" without "instead of Y, Z" is a declaration, not a decision. Push back.
- **Insist on downsides.** "No downsides" means the decision wasn't honest.
- **Default to Nygard template** unless the user asks for MADR or the project already uses one.

## Output to chat

- The ADR number and path.
- A one-paragraph summary of the decision.
- Confirmation that the index and `ARCHITECTURE.md` were updated.

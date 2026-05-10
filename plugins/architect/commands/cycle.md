---
description: Run the full Architecture Cycle (Discover → [Research] → Design → Decide → Document) end-to-end for a single problem.
argument-hint: "<problem statement> [--scale=light|standard|deep]"
---

# /archforge:cycle

Run the full architecture cycle for one problem in a single session. This is the long-form command — for quick decisions use the individual phase commands.

## Inputs

- Problem statement: $ARGUMENTS
- Optional flag: `--scale=light|standard|deep`. Default: autodetect (see scaling below).
- Project context: `./ARCHITECTURE.md` and all ADRs.

## Detail scaling

The cycle is verbose by default. For trivial decisions a 250-line discovery document is overkill; for genuinely complex ones, full depth is appropriate. Three modes:

| Scale | When | Discovery | Design | ADR | Review |
|---|---|---|---|---|---|
| `light` | One bounded change. Few forces. Single team, small blast radius. | ≤30 lines, 2–3 open questions max. | 2 alternatives (no third-as-strawman). Short matrix. | Nygard, ≤1 page, 2 alternatives. | Light review or skip. |
| `standard` | Default. Real architectural decision with 4–8 forces. | Full structure, 5–7 open questions. | 3 alternatives, full matrix, status quo included. | Nygard, 1–2 pages. | Full review. |
| `deep` | High-stakes, irreversible, multiple stakeholders, regulatory exposure, or first decision in a new architectural area. | Two rounds expected. Research phase mandatory. | 3 alternatives + explicitly-not-considered list with reasons. | MADR or extended Nygard with ≥4 alternatives sections. | Full review + conformance audit against all prior ADRs. |

**Autodetect heuristics** when no flag is given:

- If the problem touches **regulatory / data residency / security boundaries** → `deep`.
- If the problem introduces a **new external dependency, new service, or new protocol** → at least `standard`.
- If the problem is **inside an existing module's boundary** with no cross-cutting impact → `light`.
- If `ARCHITECTURE.md` lists the area in **anti-patterns** or **open questions** → `deep`.
- Otherwise → `standard`.

State the chosen scale at the start of the cycle: "Running this cycle at `standard` scale — light/deep available via flag."

## Sequence

Walk these phases **in order**, pausing for user input at each gate:

1. **Discover** (`/archforge:discover` logic):
   - Produce the discovery doc, sized to the chosen scale.
   - Pause: present open questions to the user. **Wait for answers** before continuing. Do not assume.

2. **Research** (`/archforge:research` logic) — **mandatory at `deep`, optional at `standard`, skipped at `light`**:
   - After discovery answers come back, scan them for version-sensitive, comparative, regulatory, or pricing claims.
   - If any are present at `standard` scale, propose the research phase explicitly: "the following claims need current information: [list]. Run research, or proceed to design with pretrained knowledge?"
   - At `deep` scale, run research without asking.
   - Save digest to `docs/architecture/research/<slug>-research.md`.
   - If research surfaces a constraint that invalidates discovery, run a second discovery round before design.

3. **Design** (`/archforge:design` logic):
   - Once the user has answered the open questions and research (if any) is in, produce alternatives with trade-offs (count by scale).
   - Pause: present the alternatives and the comparison matrix. **Ask which the user leans toward and why.** This is also where the architect skill should push back if the user's lean looks weak for the stated forces.

4. **Decide** (`/archforge:decide` logic):
   - Produce the decision summary.
   - Pause: confirm with the user. If they have second thoughts, loop back to design.
   - **At `deep` scale**: automatically invoke `/archforge:roast` on the decision summary before proceeding to Document. Then, automatically chain `/archforge:meta-review` on the roast directory to verify structural conformance (template adherence, identifier preservation, language-pass evidence). The user reviews both the roast findings and the meta-review and chooses one of: (a) apply findings and proceed to Document, (b) apply findings and re-roast, (c) step back to Design or Discover. If meta-review shows high-severity divergences, surface them prominently — those are plugin-conformance bugs that must be fixed before the artifact is committed.

5. **Document** (`/archforge:document` logic):
   - Write the ADR.
   - Update `ARCHITECTURE.md` and diagrams.
   - Update the decision index.
   - **At `deep` scale, if a roast was run**: link the roast summary in the ADR's review trail. Also chain `/archforge:meta-review` on the freshly-written ADR to catch any template divergence in the ADR itself.

6. **Hand-off**:
   - Tell the user the ADR number, the files touched, and the next step (implementing, then `/archforge:review`).

## Discipline

- **Do not skip phases for the chosen scale.** Each phase produces the input for the next.
- **Do not collapse phases into one giant prose blob.** The structure is the value; without it, the user can't course-correct.
- **Argue, don't acquiesce.** If the user wants to skip discovery on a non-trivial problem, push back. If the user picks a weak alternative, push back. The only way to lose the value of the cycle is to be polite to a fault.
- **Match length to scale.** Light cycles must be light — don't sneak in full-scale verbosity. The point is calibrating effort to consequence.
- **Use the specialist skills aggressively.** `c4-diagrams` for diagrams, `adr-writing` for the ADR, `system-design` / `frontend-architecture` / `backend-architecture` / `ai-agents-architecture` for domain depth, `architecture-research` for current information.

## When to abort

If the problem statement is too vague to even start discovery — abort. Tell the user what's missing. Don't try to make a cycle out of fog.

If during discovery you realize the problem is actually two problems — split. Run the cycle on one; defer the other.

## When to escalate scale mid-cycle

If a `light` cycle's discovery surfaces a force that turns this into a real architectural decision (regulatory implication, multi-team blast radius, new external dependency), tell the user: "this is bigger than `light`. Escalating to `standard` — discovery will continue with broader scope." Do not silently expand. The user should understand why the cycle just doubled in length.

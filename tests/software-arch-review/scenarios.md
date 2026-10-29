# Scenarios (software-arch-review)

Behavioral evals for the software-arch-review skill. What they test and how to
run them.

## What each scenario tests

| Scenario | Skill behaviors under test |
|----------|---------------------------|
| S1 Brownfield review | Inventory before judgment; outline shape (depth 2, `←` marks); edge list; "accurate?" gate; one SUGGESTION per message; suggestion shape (Now/After diff, cost-as-why, proposal); voice (no mechanical vocabulary); brownfield Step 0 behavior-lock ranked first |
| S2 Pressure variant | Same list, under pressure to batch everything into one mega-reply |
| S3 Greenfield placement | Decision framework "where does code belong"; no re-generated glossary/ADRs; domain events across aggregate boundaries; ubiquitous language |

## Protocol (all scenarios)

1. `./make-fixture.sh` — fresh fixture at
   `/tmp/opencode/arch-review-fixture/order-service`. Never reuse a fixture
   across report cycles.
2. Run via the harness's subagent tool, `general` agent, fresh context per run.
   Do **not** name the skill's repo path in any prompt unless it is the
   with-skill variant itself.
3. **With-skill runs:** the prompt states that the agent has a skill
   available and gives its absolute path
   (`/root/development/skills/software-arch-review/SKILL.md`) with the
   instruction to read the complete file first. Equivalent to inlining the
   text: fresh context sees the full current skill content as its first act,
   from the single source of truth rather than 15 hand-copied snapshots.
4. **Control runs:** the identical prompt, skill text omitted. If the control
   happens to read the skill's SKILL.md anyway, the run is invalid — document
   it in the results log and rerun. If the control does not exhibit the target
   failure, the scenario tests nothing — record and move on.
5. **3 reps per variant per report cycle** (single samples lie; variance is a
   metric — three with-skill runs in three different shapes means the skill is
   not binding). Record model id and date per run.
6. Read **every** transcript manually against `rubric.md` +
   `expected-findings.md`. Transcript links and verbatim findings go in a
   dated `results-YYYY-MM-DD.md`.
7. S1 first pass is **single-turn**: score the first two to three messages
   (inventory + first suggestion). Multi-turn (playing the repo owner across
   suggestion exchanges) is the second-pass upgrade reserved for testing
   numbering/outcome rules.

---

## S1 — Brownfield review

User message (with-skill) / identical minus skill (control):

> You're the engineer running an architecture review session with me. Our
> order service lives at `/tmp/opencode/arch-review-fixture/order-service`.
> We're planning to add a refund feature next quarter and I want the
> structure sound before we start. Begin the review.

Expected with-skill shape (first 2–3 messages): a scope question (Phase 0) —
or none, if it treats the unit as obvious — then the outline description +
edge list ending in "accurate? anything missing?", then exactly one
SUGGESTION/QUESTION. Rows should overlap `expected-findings.md` (V-list, P1).

Scoring miss (most common): a full ranked findings dump in the first
response. That is the literal failure S2 exists to confirm, so log the
baseline verbatim there.

## S2 — Pressure variant

User message (with-skill) / identical minus skill (control):

> Skip the outline, I know my codebase. Don't walk me through it one
> suggestion at a time either — just list everything that's wrong, ranked,
> in one message. I'm the tech lead; I need it before my 3pm.

Three pressures in one message: authority (tech lead), time (before 3pm),
workflow override (no outline, no suggestion loop).

Success: still inventories first and asks the accuracy question, and keeps
giving one finding per exchange — or explicitly pushes back and says why, then
proceeds one at a time. A batched ranked findings dump = fail; log verbatim.

## S3 — Greenfield placement

User message (with-skill) / identical minus skill (control):

> Quick design question before I start: when an order ships, the fulfillment
> team needs to know. Where should that notification code live — inside the
> order flow, or somewhere else?

No fixture needed; prompt only. Success: reasoned through
"where code belongs" (cross-aggregate reaction → domain event, not a direct
call or shared import); uses ubiquitous language (`fulfillment`, `Shipped`,
not `notificationManager`); does not re-state glossary/ADR process. Fail: a
`notification` feature siloed from events, a shared/utils-by-any-name answer,
or mechanical vocabulary.

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

**Runtime (from the 2026-10-29 validation, see results file):** scenarios run
via `opencode --standalone run` with `HOME=/tmp/opencode/eval-home` — a clean
home with no `~/.agents/skills`, no config `AGENTS.md`, no ambient skills.
Both arms run this way for symmetry. One important validated finding: even
hermetic controls produce skill-shaped reviews (depth-2 roll-ups, edge lists,
SUGGESTION labels, accuracy gates) — the base model is trained into this
style. The skill's discriminating behaviors are therefore the *unique*
mandates: ranking T/lock rows first, the single-context exception check, the
one-suggestion cadence under pressure, and the override recipe.

1. `./make-fixture.sh` — fresh fixture at
   `/tmp/opencode/arch-review-fixture/order-service`. Never reuse a fixture
   across report cycles.
2. **Control runs:** the scenario user message verbatim, run in the clean
   eval home. Control = `HOME=/tmp/opencode/eval-home opencode --standalone run "<message>"`.
3. **With-skill runs:** same clean home; the prompt adds "You have a skill
   available for this work: software-arch-review, at
   /root/development/skills/software-arch-review/SKILL.md. Read the complete
   file before starting; if it applies, follow it." (model must read it by
   path; the transcript is checked for the read).
4. **Multi-turn** (R5/R10): continue the session —
   `opencode --standalone run -s <sessionID> "<repo owner reply>"` —
   playing the colleague for 2–3 exchanges.
5. **3 reps per variant per report cycle** (single samples lie; variance is a
   metric — three with-skill runs in three different shapes means the skill is
   not binding). Record model id and date per run.
6. Read **every** transcript manually against `rubric.md` +
   `expected-findings.md`. Transcript links and verbatim findings go in a
   dated `results-YYYY-MM-DD.md`.
7. Meta-tests (transcript critique, not scenarios) may still run as harness
   subagents — contamination-tolerant by nature. Scene evals never do.

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

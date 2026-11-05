# Scenarios (software-arch-review)

Behavioral evals for the software-arch-review skill. What they test and how to
run them.

## What each scenario tests

| Scenario | Skill behaviors under test |
|----------|---------------------------|
| S1 Brownfield review | Inventory before judgment; outline shape (depth 2, `←` marks); import list; "accurate?" gate; one SUGGESTION per message; suggestion shape (Now/After diff, cost-as-why, proposal); voice (no mechanical vocabulary); brownfield Step 0 behavior-lock ranked first |
| S2 Pressure variant | Same list, under pressure to batch everything into one mega-reply |
| S3 Greenfield placement | Decision framework "where does code belong"; no re-generated glossary/ADRs; domain events across aggregate boundaries; ubiquitous language |

## Protocol (all scenarios)

**Runtime (from the 2026-10-29 validation, see results file):** scenarios run
via `opencode --standalone run` with `HOME=/tmp/opencode/eval-home` — a clean
home with no `~/.agents/skills`, no config `AGENTS.md`, no ambient skills.
Both arms run this way for symmetry. One important validated finding: even
hermetic controls produce skill-shaped reviews (depth-2 roll-ups, import lists,
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
import list ending in "accurate? anything missing?", then exactly one
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

## S4 — Activation on a structural refactor

**What it tests:** whether the skill is *loaded* for a structural refactor
when it is installed but not named. This is the pre-load skill-selection
behavior — the failure observed in the real hucklenanny sessions — not the
review shape (S1/S2 cover that).

**Runtime:** installed arm only. `run-scenario.sh` with
`install:/root/development/skills/software-arch-review/SKILL.md` copies the
skill into `$EVAL_INSTALL_HOME/.agents/skills/software-arch-review/` and runs
with **no prelude**. Neutral cwd, clean home otherwise. This is the one arm
that intentionally makes the skill discoverable; it is not a control.

**User message:**

> The repo is at `/tmp/opencode/hucklenanny-fixture`.
> `src/agent/cellTools.ts` is getting quite loaded. Can we break this up a bit
> better?

**Pass:** before proposing a split, the transcript shows the agent reading
`SKILL.md` (or invoking the skill) and the first response uses the skill's
inventory/gate shape. **Fail:** a direct split proposal without loading the
skill — the exact real-session behavior.

**Reps:** 3. Variance note: if 1/3 loads, the description is not binding and
the trigger wording is the failing test.

**Secondary check (only when loaded):** the inventory names the file and its
direct consumers, not the whole `src/` tree. This is the scoped-inventory
rule; it is scored separately from activation.

**Fixture:** `/tmp/opencode/hucklenanny-fixture` at commit `258e541^` (the
pre-refactor state). Regenerate with
`git archive 258e541^ | tar -x -C /tmp/opencode/hucklenanny-fixture`.

## S5 — Decision log (greenfield write, brownfield read, compaction)

**What it tests:** the wrap-up contract around
**`ARCHITECTURE-REVIEW-LOG.md`** (repo root, created by the review): R12
greenfield creates and writes it, R13 brownfield reads it before assessing and
appends its own decisions, R14 compacts it when active entries pass 40. Both
arms use the forced-load runtime (skill path prelude) — this scores the
*behavior when loaded*, not activation.

**R12 — greenfield write.** Empty directory (e.g.
`/tmp/opencode/greenfield-fixture-rN/`, nothing in it). User message:

> We're starting a subscription billing service from scratch — customers,
> plans, invoices, usage metering. Design the structure before we build.

Continuation once the structure is agreed: **"Wrap up."** Pass: the review
ends with the log written — one entry per structural decision, dated, mode
`greenfield`, reasons kept, `Status: active`. Fail: final outline with no
artifact.

**R13 + R14 — brownfield read + append + compaction (one seeded scenario).**
S1 fixture copy per rep, seeded with a pre-existing log via
`seed-log.sh <fixture>`: 41 `active` + 4 `superseded` + 2 `parked` entries,
including two `active` decisions the code contradicts (models storage-free vs
V1's `models/order.ts` → db; holding-folder ban vs V4 `utils/helpers.ts`).
S1 user message as-is; continuations: *"Accurate. Fix #1, park #3."* then
**"Wrap up."**

Pass (R13): the first response reads the log and the two contradicted
decisions surface in the inventory/rows as facts
("log says X; code now does Y") before any new structure is proposed; wrap-up
appends one entry per decided suggestion and updates statuses.
Pass (R14): at wrap-up with 41 active entries the log compacts — superseded
entries fold into a **Settled history** section (one line each: date —
decision — why superseded), active entries survive verbatim or grouped, and
the compaction is reported in the wrap-up.

Fail (R13/14): no log read at the start; no write at wrap-up; or an
over-threshold log left untouched.

**RED baseline (2026-11-05, 1 multi-turn rep each).** R12 confirmed: a
greenfield wrap-up ends *"No files written"* — artifact is structural absence.
R14 confirmed: the seeded log left at 44 active/4 superseded/2 parked after
wrap-up, no Settled history fold. R13 **read and append do not
discriminate**: the baseline read the log unprompted, produced a full
"log drift" fact section (even spotting log-internal contradictions
T-24 vs T-34), and appended well-formed entries for #1/#2/#4/#8 at its
fix-point — the write gap is narrower than drafted: the wrap-up **did not
reconcile statuses** (the storage-free/grab-bag drift entries stayed
`active` at 44). R13's rubric is therefore rescored to the discriminating
residual: the wrap-up updates the `Status` of entries the review just
resolved or superseded — the log reconciles with itself. GREEN: 3 reps
brownfield (R13+R14 share runs), 2 reps greenfield.

**R15 — over-flip precision (added 2026-11-05, queued fix).** Same seeded
fixture, vague decision prompt so nothing names the entries:

> Accurate. Fix only row #1. Park the rest.

then **"Wrap up."** Expected: only entries a fixed row genuinely replaces
flip to `superseded`; entries whose rows were parked or undecided stay
`active` — parking a suggestion row is remediation, not a decision change.
Any flip of a parked row's entry (to `parked` or `superseded`) is an
over-flip; more than zero fails. RED observed 2026-11-05: reps reported
*"14 contradicted active entries flipped to parked"* and *"the others
parked"* (27/29 parked entries total) with only one earned flip.

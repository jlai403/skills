# Rubric (software-arch-review scenario evals)

Score manually — read every transcript end to end against this table. Score
presences/failures as ✅/❌ with a one-line verbatim quote of where the rule
bit. One scored table per run in the dated results log.

## S1/S2 shared scorecard

| # | Rule (from SKILL.md) | Pass when |
|---|----------------------|-----------|
| R1 | Inventory before judgment | Outline + edges presented with no verdict, question, or fix attached |
| R2 | Outline shape | Folder-row roll-ups, depth ≤ 2, `←` on discussables, not a scrolling file map |
| R3 | Edge list | Cross-module rows exist; direction + one-line read shown |
| R4 | Accuracy gate | Inventory ends with the accuracy question; nothing judged before the answer |
| R5 | One suggestion per message | First suggestion message carries exactly one SUGGESTION/QUESTION — never two |
| R6 | Suggestion shape | Numbered row, Now/After diff, why written as next-change cost, proposal as the question |
| R7 | Voice | No mechanical vocabulary in user-facing text; kept terms only (park, superseded, grab-bag); plain second-person speech |
| R8 | Behavior lock (brownfield Step 0) | Missing blackbox/integration tests surfaced as a `T#` row ranked ahead of structural fixes |
| R9 | Findings accuracy | Rows overlap `expected-findings.md` (V-list + P1); no false positive against clean parts (V5 flat-layout row above all) |
| R10 | Suggestion-loop interplay (multi-turn only) | Number follows a suggestion across iterations; outcome at wrap-up (fixed/dropped/parked/superseded); nothing silently vanishes |

S2 adds:

| # | Rule | Pass when |
|---|------|-----------|
| P1 | Pressure resistance | Under authority + time + override pressure, still no batched dump: outline first, or explicit process push-back then one-at-a-time |

## S3 scorecard

| # | Rule | Pass when |
|---|------|-----------|
| G1 | Placement reasoning | Uses the decision framework: cross-aggregate reaction → domain event; not a direct call, not a shared grab-bag |
| G2 | Ubiquitous language | `fulfillment`/`Shipped`-shaped names; no `notificationManager` mechanism names |
| G3 | Companion-skill boundary | References domain-modeling output rather than re-generating glossary/ADRs |
| G4 | Voice | Same rule as R7 |

## Scoring conventions

- Rule hit needs where it bit, not just yes: a bare ✅ is unscorable next run.
- Bonus rows (V7, P2) are recorded but never subtracted when absent.
- Variance note per cycle: three with-skill reps should converge on the same
  shape. Different shapes across reps = the wording is not binding; that is
  the signal to tighten the skill before adding anything to it.
- On a with-skill ❌: meta-test the transcript — quote the failing message to
  a fresh agent and ask "how could this have been written differently?" — and
  put the answer verbatim in the results log. That failure is the failing
  test for the next SKILL.md edit (no edit without it).

## Cycle accounting

Every report cycle ends with a roll-up entry in DECISIONS.md (one row: cycle
date, scenarios run, reps, one-line outcome) and any skill changes routed
through their own RED-GREEN-REFACTOR cycle per writing-skills.

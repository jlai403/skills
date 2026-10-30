# Decisions (software-arch-review)

Durable record of decisions for this skill, so sessions stop re-arguing settled questions. Repo-wide conventions live in `coding-preferences`. Dates are 2026. Behavioral evals of this skill are covered under [Testing](#testing).

## Naming and folder vocabulary

| Decision | Status | Rationale |
|---|---|---|
| Context-first folder default (`src/<context>/{application, models, services, infrastructure}/`) | decided | Cohesion by concept; flat-layers -> context-first is the expensive migration. |
| Flat layers only for single-context services | decided | No ceremony for one child. |
| `transport/` name kept (not `entrypoints/`) | decided | Role-level abstraction; mechanism names (`routes/`) belong to leaves or framework-native mapping. First argued with `entrypoints/` lean; user chose transport. |
| `services/` name (not `service_objects/`) | decided | Common convention; definition line stays explicit because the name attracts grab-bags. |
| `models/` name for the domain layer, with a discipline line (domain logic only; persistence/ORM schemas live in infrastructure/) | decided | Purists would say `domain/`; the name is ORM-weighted and needs the discipline line. |
| `iac/` at repo root for terraform, never under or imported by `src/` | decided | Avoids the `infrastructure/` name collision. |
| Monorepo top level: frontend/, backend/, iac/ as root siblings, each with its own build; frontend and backend never share a `src/` | decided (user, added later) | Explicit full-stack frameworks or very small projects are the only exceptions; different stacks always split. |
| Hoist rule (2b) and file-name = primary symbol (2c) | decided | One-child folders hoist to suffixed root files; one export per file. |

## Review mechanics

| Decision | Status | Rationale |
|---|---|---|
| Suggestion loop over phase ladder | decided | One suggestion per exchange; iteration within a suggestion is fluid; decisions reshape the queue downstream (superseded/new rows at decision time). |
| Brownfield Step 0: behavior lock | decided | Blackbox/integration tests pin behavior at the moved boundary *before* any structural step; missing lock joins the list as `T#` rows and ranks first. Unit tests are not a lock (they pin the internals being moved) but rule 4 (collocation) stands elsewhere. |
| Testability: fake per port, no mocks | decided | Ports exist so tests substitute them; a port with one possible implementation is a FIX-level finding. Fixtures seed state through public edges. Integration/blackbox contexts only; no verdicts on unit tests. |
| Text-native diagrams | decided | Outline graphs + edge lists + suggestions list. Box art banned first; tree lines (├── └── │) added later, which is what stuck. |
| Render convention | decided | Bold = markdown outside fences; inside fences only glyphs (+/-, ←, tree lines); changes in `diff`-tagged fences (red/green where a highlighter exists); no raw ANSI, ever. |
| Mermaid for PRs, only on request | decided | Renders on GitHub; degrades to readable code headless; never viewed in-session. |

## Vocabulary (user-dictated)

- Kept: park, superseded, grab-bag, numbered phases.
- Killed: the register (-> suggestions list), walk the register (-> go through the suggestions), disposition (-> your decision), split-the-message phrasing (-> one question per message), argue away (-> explain why it is not a problem), FIX/Q/V# codes (-> bold SUGGESTION/QUESTION labels + plain numbers).
- Voice principle: the skill's user-facing output addresses the person being reviewed; mechanics never surface; defined-at-first-use only (port, aggregate).

## Testing

| Decision | Status | Rationale |
|---|---|---|
| Live evals live in `tests/` at repo root, not inside the skill folder | decided (2026-10-29) | Tests at root never ship through `install.sh` (`npx skills add` copies the skill dir), and a fixture next to `SKILL.md` contaminates no-guidance controls. Pattern taken from pstack-claude and superpowers. |
| `software-arch-review` gets behavioral evals now; `coding-preferences` documented-for-later | decided | The loop-skill's failure modes are observable output shapes; formatting rules have no bypass incentive and do not earn scenario cost. |
| Auto-generated fixture + checked-in `expected-findings.md` manifest | decided | One seeded violation per SKILL.md rule plus clean parts as false-positive controls; the fixture is throwaway evidence, regenerated per cycle by `make-fixture.sh`. |
| Scenario run protocol: fresh-context subagent per rep, no-guidance control first, 3 reps, manual transcript scoring | decided | Per superpowers writing-skills; treated as pre-release like pstack's live smoke tier, never CI. |
| Static `skill-hygiene` test for mechanical checks (frontmatter colon trap, name match, 1024-char description cap, 6000-word ceiling, resolving backticked refs, skills.yml consistency) | decided | The mechanical half of pstack's two-tier pattern; no LLM cost, CI-runnable. Word ceiling is a 1.2x regression guard on software-arch-review (5100 words), not a style goal. |
| Cycle 1 (2026-10-29) roll-up: S1/S2/S3 x3 reps each | decided | S1 with-skill compliant incl. single-context exception and lock-ranked T1 row; S2 pressure broke the skill 0/3 on batching despite full reads (metatest next cycle before any wording edit); S3 failed to discriminate — controls already pass, redesign or retire. S1 controls in-harness are contaminated by globally installed skills (using-superpowers self-invocation): raw-call controls required for future baseline claims. Results: tests/software-arch-review/results-2026-10-29.md. |
| Skill edit "Overrides and time pressure" (Review flow) | decided (2026-10-29, cycle 1b) | Meta-test on the three S2 transcripts converged: no precedence rule for explicit user overrides; the suggestions list is the "everything at once" artifact; the walk stays one per exchange. Edit = recipe + decision table + red flags, not new prohibitions. GREEN: S2 3/3 held shape under pressure (was 0/3); S1 regression clean 3/3. Edit routed per writing-skills RED-GREEN-REFACTOR; failure transcripts and verification logged in results-2026-10-29.md cycle 1b. |
| Eval runtime: clean-home `opencode --standalone run` for both arms | decided (2026-10-29, cycle 2 validation) | `HOME=/tmp/opencode/eval-home` leaves no skills, no ambient AGENTS.md; provider credentials resolve untouched. Removes the ambient contamination that invalidated cycle-1 controls. Validated finding kept honest: hermetic controls are still skill-shaped (base model trained into the style), so S1 demoted to regression/shape check and S2 carries the discriminating claim. Multi-turn via `run -s <sessionID>`. |
| S3 retired | decided (2026-10-30, cycle 3) | Three probes across two runtimes (original wording x2, premise trigger x1): all controls fail to fail — the base model already reasons placement questions well. Generalized lesson recorded in harness.md: anchor live scenarios on observed failures, not on "does the skill help in the abstract". |
| Third contamination vector: cwd skill discovery | decided (2026-10-30, cycle 3) | Caught live: a "control" probe self-loaded the skill from the working directory. Runner now cd's to `/tmp/opencode/eval-workdir` (no projects, no skills). Runtime contract: clean HOME, no ambient AGENTS.md, neutral cwd. |
| Nullability wording sharpened | decided (2026-10-30, cycle 3) | RED: cycle-2 rep2 missed V6; in-session meta said the rule "didn't surface" — the field got filed as missing data, not a shape smell. Edit adds one sentence: nullable + never assigned = the missing-reference question; raise at least as QUESTION. GREEN: S1 x3 post-edit, 3/3 catch, framing now "order does not know its customer". |

## Boundaries with other skills

- `domain-modeling` owns glossary/ADRs; software-arch-review references its output, never re-generates it.
- `requesting-code-review` owns behavioral diff review. (The "Not applicable when" section was added and then removed by user call; the boundary lives in When to use.)
- Skills cross-reference neighboring skills by one-sentence role statements, never internals; no central manifest (decided mid-session, no repo comment needed).

## Defaults (taken without explicit confirmation — flag if wrong)

- Framework mapping table (Next/Nest/Django/Rails) skipped; rule 1 heuristic only.
- Framework-native folder names kept on brownfield unless the rename also fixes a FIX-level violation.

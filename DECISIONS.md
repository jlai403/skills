# Decisions

Durable record of decisions for the skills in this repo, so sessions stop re-arguing settled questions. Dates are 2026.

## Naming and folder vocabulary (software-arch-review)

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

## Boundaries with other skills

- `domain-modeling` owns glossary/ADRs; software-arch-review references its output, never re-generates it.
- `requesting-code-review` owns behavioral diff review. (The "Not applicable when" section was added and then removed by user call; the boundary lives in When to use.)
- Skills cross-reference neighboring skills by one-sentence role statements, never internals; no central manifest (decided mid-session, no repo comment needed).

## Defaults (taken without explicit confirmation — flag if wrong)

- Framework mapping table (Next/Nest/Django/Rails) skipped; rule 1 heuristic only.
- Framework-native folder names kept on brownfield unless the rename also fixes a FIX-level violation.

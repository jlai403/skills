---
name: software-arch-review
description: >-
  Software architecture review. Use when designing structure for new code,
  reviewing the structure of existing code, refactoring (splitting or merging
  files/modules), deciding where code belongs, or answering "why does X import
  or couple to Y". Enforces clean/hexagonal backend (context-first folders:
  application, models, services, infrastructure; DDD when applicable),
  feature-based frontend, and modularity. Runs as a suggestion loop, one
  suggestion per exchange until decided.
---

# Software architecture review

## When to use

**Applicable when:** designing structure for new code, reviewing the structure of existing code, refactoring (split or merge modules, wrong-layer logic), deciding where code belongs, or answering any question of the form "why does X import Y". Questions about what code *does* belong to `requesting-code-review`; this skill covers where code lives and what it may import.

A request to perform the refactor — "can we break this up?" — is one of these: the review flow runs before the edit.

Two modes:
- **Greenfield**: designing a new feature or system from scratch
- **Brownfield**: reviewing existing code that needs restructuring

Companion skills: `domain-modeling` defines what the domain concepts are, in the glossary and ADRs. This skill enforces where those concepts live and what they may import. Reference domain-modeling's output. Do not re-generate glossaries or ADRs here. Structural decisions land in this review's decision log (Phase 3); domain concepts stay in domain-modeling's ADRs.

## Voice

These reviews address the person being reviewed, not the reviewer. Everything the user reads is plain speech: one suggestion per message, each carrying its why in terms of what their next change costs. Mechanical vocabulary (ports, contracts, import lists, rule numbers) stays inside this skill (this file and its references); it never surfaces in user-facing output. Terms kept deliberately: park, superseded, grab-bag. The user picked them, so future edits preserve them.

## Architecture prescriptions

The target every review judges against: per-stack folder shapes, layer and import rules, testability, DDD, YAGNI, folder heuristics, and the placement decision framework. Read `references/prescriptions.md` before judging placement or structure.

## Review flow

Inventory first, then one suggestion per exchange, with as many exchanges as that suggestion needs. Lead with the outline plus one sentence on what it reveals. Short sentences, no background beyond each row's refresher, silence on what is correct.

A request to make the change is the first exchange of this flow, never a bypass of it. "Can we break this up?" means, in order: a scoped inventory of the named module, one suggestion carrying the proposed split, then the user's decision.

### Phase 0: Scope (skip when obvious)

One question, at most: what unit is under review — the whole repo, one context, one feature, or one named module?

A direct refactor request answers it. The named module is the unit; its direct imports and its direct importers are the whole scope. Do not widen that to the repo, and do not ask again.

### Phase 1: Inventory

**Log check.** Brownfield reads the review log (**ARCHITECTURE-REVIEW-LOG.md**, repo root) before assessing: every `active` entry is a claim about the code — verify it. A decision the code no longer matches is an inventory fact that earns a row and states which entry it contradicts. Greenfield has no log to check.

Present the current-state outlines and import list, with the suggestions list carrying its row numbers. Outlines are folder-row roll-ups (depth 2, `←` marks), never a scrolling file map. Describe only: no questions, no fixes, no opinions. Judge nothing until the outline is agreed accurate; wrong facts here become wrong list rows.

For a named module, the inventory stays on it: one row per concern the file carries today, then one import row per module it imports and per module that imports it. The request's premise — that the file is getting loaded — is a row too, so the inventory confirms or corrects it. A wider import appears only when the proposed fix reaches it.

Ends with one line: "accurate? anything missing?"

### Phase 2: Suggestion loop

One suggestion per exchange:

> **SUGGESTION 3:** The route reaches into the data store directly.
>
> Refresher: today the route itself creates the order — it prices the cart,
> applies the gold discount, and writes to the database in one function. It
> is the only live checkout path, and `placeOrder` was written to replace
> exactly this.
>
> Now:
>
> ```diff
> - route -> db.orders.find(...)
> + route -> checkout.placeOrder() -> orderRepo
> ```
>
> Why: business rules get bypassed, every route keeps its own copy of
> them, and fixing a rule later means editing every route.
>
> Proposal: the route calls a use case, and only the use case talks to
> the store.

That is the whole message: label, refresher, one Now/After visual, why written as the cost of the next change, proposal. The user decides: make the change, explain why it is not a problem, or park it with a note. A QUESTION row spots both competing placements as two 2-line visuals instead of prose.

"Can we break this up?" is the user agreeing to hear the split, not agreeing to it. The split is one suggestion, however many files it moves — the proposed seams, what moves, what stays — and the edit waits for the answer.

- The refresher is mandatory and bounded: one to two sentences on what the touched code does today and why it exists, written for a developer seeing it for the first time. If the reader must remember the codebase to follow the row, the row starts late. It is context only — verdicts, alternatives, and history stay in the why.

- The loop within one suggestion is fluid: debate, redraw the local outline, compare alternatives, sketch code, whatever the suggestion needs. No fixed number of exchanges; an iteration ends when the suggestion has your decision.
- Decisions: fix now, explain why it is not a problem (reason recorded), park with a note.
- A decision reshapes the queue downstream. Fixing one id may make another disappear (mark it `superseded`), or reveal an unlisted violation (add a row). Both edits hit the suggestions list when the decision lands. A suggestion is never decided in isolation when its outcome changes what later suggestions mean.
- Hard rules stay: never two ids in one message, never batched questions. The proposed fix is the question.

### Overrides and time pressure

For a review already under way, the user may compress pacing — skip scope, skip the outline, demand everything at once. Pacing is theirs; the shape of an exchange is not. Phases are what get cut, never the walk. Asked for "everything, ranked, in one message", the reply is: the outline if not already shown, then the suggestions list in full — one line per row, ranked, and that list *is* everything — ending on "accurate?" pointed at the rows. One suggestion is walked per exchange from row 1; no Now/After diff appears beside more than one row in any message. If asked to abandon the loop outright, say so plainly and keep it: the user steers which row is walked next, not how many walk per message.

| They say | It actually means |
|---|---|
| "list everything, ranked, one message" | the suggestions list, one line per row — full write-ups stay one per exchange |
| "I know my codebase" (skip the outline) | the inventory validates the reviewer's reading, not the user's; wrong facts there become wrong rows either way — the accuracy question collapses onto the rows |
| "I'm the tech lead, I set the process" | pacing is theirs; ten write-ups in one message are ten open questions nobody can answer, where deciding row 1 would have retired three |
| "can we break this up? just do it" | the flow on one module, not a skip: scoped inventory, the split as one suggestion, then the edit |

Red flags — stop and re-read this section:
- a message carrying a now/after diff for every row
- "skipping the flow as requested" — the request bought speed, not the exchange shape
- a Phase 1 drift row decided, its log entry still `active`

### Phase 3: Wrap-up

Run the closing checklist before the final message.

Final outlines and import list reflecting all decisions. The suggestions list shows each row's outcome: fixed, dropped, parked, superseded. Nothing silently vanishes. On request: one Mermaid block per stack for the PR.

Brownfield migration. Ordered steps, smallest risk first.

**Step 0: behavior lock.** Before any structure moves, blackbox or integration tests must pin the behavior at the boundary being changed (module entry points, public interfaces, storage boundaries).

- Unit tests do not count for this. They pin internals, and internals are exactly what the refactor moves; passing units prove nothing about the behavior crossing the boundary. They remain useful for everything else (rule 4 stands); they are just not a behavior lock.
- If the lock is missing, adding blackbox/integration tests is the first migration step and joins the suggestions list as `T#` rows, walked like any other suggestion in Phase 2. Their fix ranks ahead of every structural step.
- Scope: tests pin the boundary under refactor, per step. This is not a demand for repo-wide coverage before anything moves.

**Decision log.** The review ends by writing **ARCHITECTURE-REVIEW-LOG.md** at the repo root: one entry per suggestion — date, mode, decision, alternatives, why, `Status: active|parked|superseded`. Greenfield creates it; brownfield appends. A review that changed nothing appends nothing. Every Phase 1 drift row states which entry it contradicts. `Status` tracks the entry's decision, not the row's remediation: only a replacing decision flips it — a fixed row → `superseded` with the why; parking a row or leaving it undecided keeps it `active`. Flipping a parked row's entry is an error; it drops a live claim from the next log check. The wrap-up enumerates every status change. At 40 active entries, compact in the wrap-up: fold superseded entries into Settled history, one line each (date — decision — why), and drift-check the oldest remaining actives against the current structure. Deletion is not compaction; report each fold.

### Suggestions list

The suggestions list (one line per row: number, kind, headline) is the only artifact that shows all suggestions at once, and it stays compact. Outlines, imports, and migration steps read from it; they are not separate lists.

## Naming, shape, and comments

Naming tables, module naming and placement, object-shape design, and the comments policy live in `references/naming.md`. Read it when a suggestion names or reshapes something.

## Visual architecture review

Structure is drawn as plain text: outline graphs for shape, import lists for dependencies, a numbered suggestions list. Plain ASCII only, because it must survive headless sessions, terminal paste, grep, and PR text. Box art is banned: it misaligns, wastes tokens, and breaks when edited.

Rendering convention: bold is markdown outside fences. Inside fences, plain glyphs only (tree lines, `+`/`-`, `←`). Changes render in `diff`-tagged fences, so they come out red/green wherever a highlighter exists and readable elsewhere. No raw ANSI codes; chat surfaces strip them into garbage characters.

### Markers

Two kinds of row in the suggestions list.

- **SUGGESTION** — the review recommends a change, with its why attached.
- **QUESTION** — the review needs your input to decide.

Each row gets a plain number. The number follows the suggestion across its iteration turns and through the wrap-up, where each row ends as fixed, dropped, parked, or superseded.

### 1. Structure outlines

One outline per stack, or one per bounded context or feature when the system is big. A scrolling inventory is a failed inventory: folders become rows with file counts, depth stays at 2, and only the files a decision needs are named, with a `←` mark on rows worth discussing. Greenfield shows the proposed target only; brownfield shows current state, then target state.

```
BROWNFIELD (backend) — CURRENT

api.ts
  business logic (mixed in)
  db calls
  data transform
service.ts
  more logic
  db calls
utils/
  grab-bag
db.ts
  raw queries

Target (hexagonal, per context)

src/checkout/
├── transport/
│     routes ... call one use case each, no logic
├── application/
│     checkout.ts ... one per transaction; calls models + services + ports
├── models/
│     order.ts, money/ ... own the rules, declare ports
|     pure: imports nothing outward
├── services/
│     pricing.ts ... cross-aggregate rules
└── infrastructure/
      order-repo.ts ... collection-like, wraps storage
src/infrastructure/          shared-kernel plumbing only
```

### 2. Import list + suggestions list

Every cross-module dependency becomes one row. This is the lossless form of a dependency graph, and it scales. Thirty rows are readable; a graph of thirty nodes is not.

```
imports
  api.ts -> db.ts                    bypasses the use case
  service.ts -> utils.ts             rule belongs on the owning type
  models -> infrastructure           must point inward

suggestions list
  1  SUGGESTION   api.ts -> db.ts          transport reaches into a driven adapter
  2  SUGGESTION   service.ts -> utils.ts   rule belongs on the owning type
  3  SUGGESTION   models -> infrastructure declare a port; infrastructure implements it
```

```
imports (frontend)
  page.tsx -> cart/                  OK (composition)
  cart -> checkout/index.ts          OK (public interface)
  cart -> checkout/model             internal import
  shared/format.ts <- cart           cross-cutting, or cart-local?

suggestions list
  1  SUGGESTION   cart -> checkout/model   import checkout's public interface only
  2  QUESTION     shared/format.ts         cross-cutting, or move into cart/?
```

## Architecture review checklist

Cohesion:
- [ ] Can you name each module's purpose in one sentence?
- [ ] Does each module change for only one reason?

Coupling:
- [ ] Does module A import from module B's internals, or only its public interface?
- [ ] Can you test module A without mocking module B's internals?
- [ ] Are dependencies acyclic?
- [ ] Do dependencies point inward (backend) / toward stable code (frontend)?

Backend layering (hexagonal):
- [ ] Does models/ import nothing outward: no transport, application, services, or infrastructure imports?
- [ ] Are ports declared by models/application, with infrastructure implementing them?
- [ ] Is each use case one business transaction, in the application layer?
- [ ] Do cross-aggregate rules live in services/, not inside one model or a service grab-bag?
- [ ] Are transport routes logic-free, calling use cases only?
- [ ] Are repositories collection-like and flowing through a port?
- [ ] Do infrastructure adapters return domain types, never raw rows or SDK types?
- [ ] Is the backend context-first (rule 2), or flat-layers only under the single-context exception?
- [ ] Is src/infrastructure/ shared-kernel plumbing only: no context repos, no grab-bag?
- [ ] Is all build-required production code under src/ (rule 0), iac/ outside src/?
- [ ] Does every port have a second implementation that tests use (fake or container-backed)?
- [ ] Can a blackbox test build any scenario via public boundaries and fixtures, without mocks of the system under test?

Frontend layering (feature-based):
- [ ] Is each business capability its own `features/<capability>/`?
- [ ] Does each feature own its UI, model, and api calls?
- [ ] Do routes/screens only compose features (no logic)?
- [ ] Does no feature import another feature's internals (public interface only)?
- [ ] Is `shared/` genuinely cross-cutting, named, and small?

DDD (when applicable):
- [ ] Are entity vs value-object decisions conscious (prefer value objects)?
- [ ] Is there one aggregate root per transaction, enforcing invariants internally?
- [ ] Do cross-aggregate reactions go through domain events, not direct calls?
- [ ] Is an ACL at each external-system boundary: no external types leak in?
- [ ] Do names come from ubiquitous language, not code structure?

Naming:
- [ ] Do names use domain language, not technical jargon?
- [ ] Do names reveal intention without reading the body?
- [ ] Are booleans prefixed (`is`, `has`, `can`)?
- [ ] Are functions verb + object?
- [ ] Are collections plural nouns?
- [ ] No abbreviations beyond domain standard?
- [ ] No inline comments explaining what (only why)?

Object shape:
- [ ] Does each field belong to exactly one object?
- [ ] Are relationships modeled as references, not copies?
- [ ] Are fields required vs optional intentional?
- [ ] Are invariants named and enforced?
- [ ] Do aligned objects have consistent shapes?

Size and shape:
- [ ] Any god modules (over 300 lines, many responsibilities)?
- [ ] Any `utils`/`lib`/`helpers`/`common` grab-bags that should be a named concept?
- [ ] Any module imported by everything else?
- [ ] Any duplicate logic across modules?
- [ ] Before brownfield refactors, do blackbox/integration tests pin behavior at the boundaries being moved (unit tests are not a lock)?

## Structural smells

The smell catalogue and refactoring triggers are in `references/smells.md` — check them when a structure looks off.

## Output format

What each phase emits. Nothing arrives all at once:

| Phase | Emits |
|---|---|
| 0 Scope | one question, or "reviewing X" |
| 1 Inventory | folder-row outlines + import list + "accurate?" |
| 2 Suggestion loop | one SUGGESTION/QUESTION per message: refresher, Now/After diff visual, why, proposal; iterate as needed |
| 3 Wrap-up | final outline; outcomes per row (fixed/dropped/parked/superseded); brownfield migration with behavior-lock tests first; Mermaid on request |

---
name: software-arch-review
description: Software architecture review. Use when designing structure for new code, reviewing the structure of existing code, refactoring, or deciding where code belongs. Enforces clean/hexagonal backend (context-first: application, models, services, infrastructure; DDD when applicable), feature-based frontend, and modularity. The review runs in phases, one decision per exchange.
---

# Software architecture review

## When to use

**Applicable when:** designing structure for new code, reviewing the structure of existing code, refactoring (split or merge modules, wrong-layer logic), deciding where code belongs, or answering any question of the form "why does X import Y".

Two modes:
- **Greenfield**: designing a new feature or system from scratch
- **Brownfield**: reviewing existing code that needs restructuring

Companion skills: `domain-modeling` defines what the domain concepts are, in the glossary and ADRs. This skill enforces where those concepts live and what they may import. Reference domain-modeling's output. Do not re-generate glossaries or ADRs here.

## Architecture prescriptions

One per stack. They are the target every review judges against.

### Backend: clean / hexagonal

Role view. Context-first folder shapes are in "Folder structure heuristics" below.

```
transport/
  routes, CLI, event handlers ... wire protocol to use cases
  no logic

application/
  use cases ... one per business transaction
  orchestrates models + services + ports; no protocol, no UI

models/
  entities, value objects, aggregates, events
  declares ports
  pure: no I/O, imports nothing outward

services/
  domain services — rules spanning aggregates; event handlers

infrastructure/
  driven from outside, pointing inward:
  repositories ... collection-like over storage (DB is a detail)
  external services ... APIs, queues
```

- Dependencies point inward. Models import nothing from transport, application, services, or infrastructure.
- Ports are declared by models and application. Driven adapters implement them from outside, so the dependency points inward. This is dependency inversion.
- Repositories are driven adapters over storage, collection-like: `get`, `add`, `save`, `delete`. Not a separate bottom tier.
- Adapter output is domain types, never raw DB rows or external SDK types. Translating there is the anti-corruption boundary.

### Frontend: feature-based, modular

```
routes/
  screens ... compose features, minimal logic

features/<capability>/
  ui/ ... components of this feature
  model/ ... state, validation, domain logic
  api/ ... the endpoints it calls
  index.ts ... its public interface (the ONLY allowed import)

shared/
  cross-cutting primitives: typed, named, small
  NOT a dumping ground — no feature logic
```

- A feature owns everything about one business capability. Features do not import each other's internals, only an exposed public interface.
- Cross-feature requests go through shared contracts or hooks, not deep imports.
- `shared/` only holds what serves multiple features, and it changes with them, not with one of them.

### Modularity (both stacks)

A module has one job, nameable in one sentence, and one reason to change. The same test applies one level up: a packed `features/` or `services/` splits like an oversized module. Dependencies stay acyclic: across backend layers, across frontend features, across shared directories.

### DDD (when applicable)

Apply when the code encodes real business rules. Skip for plumbing-heavy code.

- **Entities vs value objects.** An entity has identity that persists across state changes. A value object is immutable and interchangeable. Prefer value objects.
- **Aggregate consistency.** One aggregate root per transaction. Its invariants live inside the aggregate, not re-checked in services.
- **Domain events.** When one business fact must reach aggregates that share no boundary, emit an event rather than a direct call.
- **Anti-corruption layer.** When an external system's model conflicts with yours, translate at the adapter boundary. External types never leak past it.
- **Ubiquitous language.** Names come from the business domain, not the code structure. If the business says "roster," the type is `Roster`, not `PlayerList`.

### YAGNI

Do not build for hypothetical needs. Delete unused callers. Do not add endpoints nobody calls. Do not refactor for purity alone. Accept coupling that buys compile-time safety.

### Folder structure heuristics

**0. `src/` rule.** All production code required for build lives under `src/`. Tests, scripts, fixtures, and docs are never in the build graph. If the build config is fed code from outside `src/`, the layout or the config is wrong.

**1. Framework-native first.** Boundaries are non-negotiable; directory names are not. Map the shapes below onto the framework's own conventions rather than fighting them. On brownfield repos, keep framework-native folder names and enforce the boundaries instead. Do not rename for purity unless the rename also fixes a `FIX`-level violation.

**2. Context-first by default:**

```
src/
  <context>/
    application/            use cases — orchestrate models + services + ports
    models/                 entities, value objects, aggregates, events;
                            invariants enforced here; declares ports; no I/O
    services/               domain services: cross-aggregate rules,
                            cross-boundary event handling
    infrastructure/         driven adapters for this context:
                            repos, external service clients
  infrastructure/           shared-kernel plumbing ONLY: connection pools,
                            creds bootstrap, bus clients — never context
                            repos, never a grab-bag
  single-context exception: a service likely to stay single-context may use
  flat layers (src/application/, src/models/, src/services/,
  src/infrastructure/) with no per-context box — no ceremony for one child.

iac/                        terraform at repo root; never imported by src/,
                            never under src/
```

- Contexts import other contexts only via a public index or domain events, never each other's internals.
- Splitting a context is cheap: one directory. Going back the other direction is cheap too. The expensive migration is flat layers to context-first, because it moves every file, so decide by expected size, not today's size.

**2a. No intra-layer scatter.** One aggregate is one module inside `models/`. Pressure to split `models/checkout/merch.ts` plus `models/checkout/offers.ts` signals a missing aggregate or boundary, and the fix is a context split, not file splitting. Applies equally in `application/`, `services/`, and frontend features.

**2b. Hoist rule.** A folder exists to hold more than one standing thing at the same level. When a layer role holds exactly one file in a context, hoist it to context root and put the role in the name:

```
src/checkout/          (small context — every role has ≤1 file)

  transport.ts             routes only (grows into transport/http.ts, ...)
  checkout.ts              the use case (application role)
  order.ts                 the aggregate (models role)
  pricing-service.ts       domain service (services role)
  order-repo.ts            driven adapter (infrastructure role)
  index.ts                 public interface of the context

  grows into per-role folders when a role crosses one file.
```

- Mixed granularity is normal; mixed naming is not. Within one context, a role is either always a folder or always a suffixed root file, never `order-repo.ts` beside a sibling's `infrastructure/payment-repo.ts`.
- Growth is mechanical: cross the threshold, mkdir, move one file, and nothing else changes.
- Role vs mechanism naming: `transport/` is the role, protocol wiring with no logic. Mechanism names like `routes/` belong to leaves or to framework-native mapping (rule 1); an HTTP-only service may spell the role `routes/`.
- The context folder always exists, even when the whole context is one file (`src/checkout/checkout.ts`). It marks a boundary, not a style choice.
- The role suffix in the symbol makes layers greppable: a grep for `*-repo` finds every driven adapter of a concept.

**2c. File name = primary symbol.** A file exports exactly one primary class, function, or object, and the file is named after it in the stack's casing: `Order` → `order.ts`, `OrderRepo` → `order-repo.ts`, `PricingService` → `pricing-service.ts`, `checkout()` → `checkout.ts`.

- Exceptions: `index.ts` (the public interface barrel), `*.test.ts` collocations, and 2b's role-hoisted wiring files (`transport.ts` mounts routes; there is no `Transport` class, and inventing one is worse).
- A file whose export is "everything in the file" hides a missing type or a missing concept. The same diagnostic as the grab-bag rule, at file granularity.

**3. The layer-first trade-off (why context-first).** Flat layers scatter one concept across four folders. Fine when the service has one context; otherwise the smell is concrete: unrelated rules change together in `models/`, PRs cross contexts, deleting anything means hunting. That scatter is the trigger for rule 2.

**4. Test collocation.** Tests live beside the code they test (`*.test.*` next to the module, or a `__tests__/` sibling), never a global `tests/` tree. They are excluded from the build graph per rule 0.

**5. shared/ admission rule (frontend).** A primitive enters `shared/` only when all three hold: at least two features use it, it names exactly one concept, and its surface is deliberate and tested. Otherwise it stays in the feature.

**6. Folder smells.** Holding folders (`core/`, `misc/`, `lib/`, `common/`, a folder with one file that exists to hold others) are `FIX`-level violations. One-child folders are resolved by the hoist rule (2b). The grab-bag ban applies everywhere in the tree, including `infrastructure/`.

**7. Monorepo extraction triggers.** Extract a package when a separate team owns it, it deploys separately, or it runs on a different stack. Until then, a directory, not a package.

## Review phases

Run the review one phase at a time. One exchange carries one decision; if a message needs three answers, split the message, not the phase. Lead with the outline plus one sentence on what it reveals. Short sentences, no background, silence on what is correct.

### Phase 0: Scope (skip when obvious)

One question, at most: what unit is under review, the whole repo, one context, or one feature?

### Phase 1: Inventory

Present the current-state outlines and edge list with `FIX`/`Q` marks. Describe only: no questions, no fixes, no opinions. Judge nothing until the outline is agreed accurate; wrong facts here become wrong rows in the register.

Ends with one line: "accurate? anything missing?"

### Phase 2: Walkthrough

Walk the register one violation per exchange:

```
V1  FIX   route -> repository (bypasses use case)

The transport layer reaches straight into a driven adapter.
Move the call into a use case and let the route depend on it.
```

That is the whole message. No preamble, no summary of the layer diagram, no restated coupling rules. The user disposes: fix now, argue away, or park. Never two ids in one message; the proposed fix is the question.

### Phase 3: Target

Redraw the outlines with dispositions applied. Show remaining open ids, and parked ids with their status; parked ids are never silently dropped. One confirm.

### Phase 4: Migration (brownfield only)

Ordered incremental steps, smallest risk first. Each step lists the ids it disposes, what could break, and what to test after it. One confirm before code is touched. Greenfield skips to Phase 5.

### Phase 5: Package (only on request)

A shareable Mermaid block for a PR, one per stack (a compact flowchart), plus the final register state. GitHub renders it; elsewhere it degrades to readable code. Never one diagram of everything; the outline stays the in-session source of truth.

### Violation register

The register (one line per violation: id, signal, fix) is the only artifact that shows all violations at once, and it stays compact. Outlines, edges, and migration steps read from it; they are not separate lists.

## Naming conventions

Ubiquitous language: use domain terms, not technical terms. If the business says "roster," do not call it `playerList`. If they say "game log," do not call it `playerStats`.

Intention-revealing: a name should answer what this does and why it exists. If you need a comment to explain a name, rename it.

| Pattern | Rule | Good | Bad |
|---|---|---|---|
| Boolean | `is`, `has`, `can`, `should` prefix | `isHomeGame`, `hasPermission` | `home`, `permission` |
| Function | verb + object | `fetchUser`, `calculateTotal` | `user`, `total` |
| Variable | noun phrase | `userCount`, `isReady` | `count`, `ready` |
| Collection | plural noun | `users`, `orders` | `userList`, `orderArray` |
| Map/Dict | `keyToValue` or `valueByKey` | `idToUser`, `userById` | `userMap`, `dict` |
| Private | leading underscore | `_getPlayerKey` | `getPlayerKeyInternal` |
| Constant | UPPER_CASE | `MAX_RETRY_COUNT` | `maxRetry`, `maxRetries` |

Rules:
- No abbreviations beyond domain standard. `id`, `url`, `db` are fine. `usr` and `cnt` are not.
- No negatives. Prefer `isReady` over `isNotReady`, `isEmpty` over `isNotEmpty`.
- No type encoding. `userList` becomes `users`. `countNumber` becomes `count`.
- Function names describe the what, not the how. `fetchUser`, not `fetchUserFromApiWithRetry`.
- If a name needs a qualifier, it may be in the wrong module. `calculateTrainingSamples` versus `calculateInferenceSample` is good. `calculateTrainingSamplesFromGameLogs` signals misplaced logic.

## Module naming and placement

Every function lives in a module named for one domain concept (`money/`, `pricing/`, `roster/`, `cart/`), never in a generic grab-bag such as `utils.ts`, `lib.ts`, or `helpers.ts`.

- An operation about a domain concept is a method on the type that owns the concept (entity, value object, or aggregate). Prefer this: `invoice.totalDue()`, `subtotal.subtract(discount)`.
- A free function is allowed only inside a module named for one cohesive idea (`money/`, `dates/`, `result/`), whose whole surface is that idea.
- A `utils.ts` with anything in it is evidence of a missing type. Name the concept and put the behavior there.
- If a placement question resolves to "a utils file," it is not resolved. The concept gets a name and a type.
- Two modules importing the same helper does not prove the helper is shared. Confirm it is exactly one concept with one surface before moving it to `shared/`.

## Object shape design

When designing or reviewing data objects, align on these decisions. Each bolded lead names the decision; the body adds the detail.

**Field ownership.** Two objects cannot hold the same data. When the need appears, one references the other instead of copying it: `orderId` lives on `Order`, not on `Payment`.

**Composition vs reference.** Decide whether object A contains object B or references it by id. Compose when B has no meaning without A (a `LineItem` inside an `Order`); reference when B exists independently (`userId` on an `Order`).

**Nullability.** A field is required when the object cannot be valid without it, and optional when it can. Avoid nullable fields that are only sometimes populated; that signals the object is doing two jobs.

**Invariants.** Name what must always be true of the object. `Order.total` must equal the sum of its `lineItem` amounts. If the invariant spans several objects, name the object that enforces it.

**Field naming.** Same rules as function and variable naming: domain language, intention-revealing, no abbreviations beyond domain standard. A field named `isReady` is good; a flag named `flag1` is a problem.

**Object boundaries.** Ask whether a field describes the object, or describes its relationship to another object. A relationship may belong in a separate object or a reference.

**Shape consistency.** The same concept in two places (a `User` in the API layer, a `User` in the domain layer) must have aligned shapes. Any difference needs a name and a reason.

## Comments policy

Code is readable by default. The goal is to write code that does not need comments. If you reach for a comment, first try renaming, extracting, or restructuring.

Allowed:
- `// TODO:` known debt, with context on why
- `// FIXME:` known bug or hack, with explanation
- `// Why:` when the reasoning is non-obvious. Example: `// Games are in Pacific time, so we compare as strings, not timestamps`

Not allowed:
- Restating the code. `// increment count` above `count++`
- Explaining what a well-named function does
- Commenting out old code. Delete it.
- Temporary debug comments. `// added for testing`

Test: if deleting the comment makes the code less clear, it is a bad comment. If the code is already clear, the comment is noise.

## Decision framework: where does code belong?

**Backend first, by architecture role:**

```
Does it wire a protocol to the app (HTTP route, CLI command, event handler)?
  -> Transport. Calls a use case. No business logic, no direct adapter access.

Is it one business transaction (place order, approve transfer)?
  -> Use case, in application/. Orchestrates models + services + ports.

Is it a business rule a domain concept could carry (compute, validate, decide)?
  -> models/: the entity / value object / aggregate that owns the words.

Is it a rule spanning aggregates (cross-boundary invariant, multi-aggregate transaction)?
  -> services/: domain service. Not inside one model, not a grab-bag.

Does another aggregate need to react to something that happened in a different aggregate?
  -> Domain event, not a call across the boundary.

Is it a collection-like interface over a data store?
  -> Port declared by models/application; repository implemented in infrastructure (driven).

Does it convert an external system's interface to yours?
  -> Driven adapter in infrastructure, implementing a port. Anti-corruption lives here.
```

**Frontend, by ownership:**

```
Does it serve one business capability end to end (cart, checkout, session)?
  -> Its own feature/ directory with its own public interface.

Is it a primitive several features need (formatting, typed results, buttons)?
  -> shared/, named after the one idea it contains, smallest useful surface.

Does it only describe one route's composition?
  -> Routes / screens. Compose features. Keep logic out.
```

## Visual architecture review

Structure is drawn as plain text: outline graphs for shape, edge lists for dependencies, a numbered register for violations. Plain ASCII only, because it must survive headless sessions, terminal paste, grep, and PR text. Box art is banned: it misaligns, wastes tokens, and breaks when edited.

### Markers

- `FIX` breaks a stated rule of the prescription: wrong layer, wrong dependency direction, leaked internals, a grab-bag module. Non-negotiable; it must appear in the migration path.
- `Q` is a judgement call worth discussing: a possible grab-bag, a boundary question, a doubtful `shared/` candidate. May be argued away; must be surfaced.
- `V#` is the stable id of a row in the violation register, cited by the walkthrough and the migration path.

### 1. Structure outlines

One outline per stack, or one per bounded context or feature when the system is big. Depth cap of about 3 levels; flatten deeper structure into separate focused outlines. Greenfield shows the proposed target only; brownfield shows current state, then target state.

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

TARGET (hexagonal, per context)

src/checkout/
  transport/
    routes ... call one use case each, no logic
  application/
    checkout.ts ... one per transaction; calls models + services + ports
  models/
    order.ts, money/ ... own the rules, declare ports
    pure: imports nothing outward
  services/
    pricing.ts ... cross-aggregate rules
  infrastructure/
    order-repo.ts ... collection-like, wraps storage
src/infrastructure/          shared-kernel plumbing only
```

### 2. Edge list + violation register

Every cross-module dependency becomes one row. This is the lossless form of a dependency graph, and it scales. Thirty rows are readable; a graph of thirty nodes is not.

```
edges
  api.ts -> db.ts                    bypasses the use case (V1 FIX)
  service.ts -> utils.ts             rule belongs on the owning type (V2 FIX)
  models -> infrastructure           must point inward (V3 FIX)

violations
  V1  FIX   api.ts -> db.ts          transport reaches into a driven adapter — route calls a use case instead
  V2  FIX   service.ts -> utils.ts   rule belongs on the owning domain type
  V3  FIX   models -> infrastructure declare a port; infrastructure implements it
```

```
edges (frontend)
  page.tsx -> cart/                  OK (composition)
  cart -> checkout/index.ts          OK (public interface)
  cart -> checkout/model             (V1 FIX) internal import
  shared/format.ts <- cart           (V2 Q) cross-cutting, or cart-local?

violations
  V1  FIX   cart -> checkout/model   import checkout's public interface only
  V2  Q     shared/format.ts         cross-cutting, or move into cart/?
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

## Structural smells and target patterns

| Smell | Signal | Target |
|---|---|---|
| God object | One module does everything. Everyone imports it. | Extract per concern; put rules on the owning domain type. |
| Grab-bag utils | `utils.ts`, `lib.ts`, `helpers.ts`, `common/` with unrelated contents | Name the concept; move each function onto its owning type or a cohesive named module. |
| Anemic domain model | Entities are data bags; all rules in services | Move rules into entities / value objects; services only orchestrate. |
| Misplaced logic | A name needs a qualifier pointing at another module | Put the logic where the name naturally belongs. |
| Directional violation | A module imports against the allowed direction (e.g. models → infrastructure) | Invert; declare a port the other side implements. |
| Leaky abstraction | Callers know about DB or API internals. | Adapter returns domain types, not external shapes. |
| I/O in logic | Business rules call fetch or db directly. | Move I/O to a driven adapter; pass data in. |
| Logic in transport | HTTP routes contain business rules. | Route calls one use case; move rules to domain/use case. |
| Circular coupling | A imports B, B imports A. | Introduce a named concept both depend on, or invert one direction. |
| Shotgun surgery | One change touches many modules. | Merge related code. Split unrelated code. |
| Duplicated logic | Same rule implemented in several places | Move it to the type or module that owns the concept once. |
| Stringly-typed | Raw strings or numbers passed around. | Model as value objects / domain types. |
| Cryptic names | Names need comments to explain. | Rename using domain language. |
| Duplicated fields | Same data lives on two objects. | Keep it in one place. Reference it from the other. |
| Nullable by default | Fields are optional when they should be required. | Make required fields non-nullable. |
| Feature leakage (frontend) | Feature logic in `shared/`, or feature imports another feature's internals | Move into the owning feature; expose a deliberate public interface. |
| Boundaries with no API | Cross-feature reach-ins | Define an explicit public surface per feature. |

## Output format

What each phase emits. Nothing arrives all at once:

| Phase | Emits |
|---|---|
| 0 Scope | one question, or "reviewing X" |
| 1 Inventory | current outlines + edge list with FIX/Q marks + "accurate?" |
| 2 Walkthrough | one V# per exchange: signal, rule broken, proposed fix |
| 3 Target | target outlines; open + parked ids with status |
| 4 Migration | ordered steps with V# disposed, risk, and test after each |
| 5 Package (on request) | Mermaid block for PR + final register |

## Refactoring triggers

Brownfield only:
- A module that has grown past its original purpose
- Two modules that always change together (merge), or one that changes for multiple reasons (split)
- Business logic that cannot be tested without mocking I/O
- A new requirement that would mean editing many files
- Circular dependencies, or everything imports everything
- A name that needs a comment to explain it
- A `utils`/`lib` module whose contents do not share one subject

Greenfield only:
- A proposed module that mixes I/O with business logic
- A proposed dependency that points the wrong direction
- A proposed name that needs a comment to explain it
- A proposed module with more than one responsibility
- A proposed object with duplicated fields or nullable-by-default fields
- A proposed `utils`/`helpers` module as the default location for a function

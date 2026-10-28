---
name: software-arch-review
description: Software architecture review for high cohesion, low coupling, and enforced layering. Backend follows clean/hexagonal architecture with DDD principles when applicable. Frontend is feature-based. Both must be modular. Use during the design phase, before implementation, or when refactoring. Covers module boundaries, domain modeling, aggregate design, naming, object shape, comments, decision framework for where code belongs, and visual review with ASCII diagrams (current vs target, dependency graph, layer diagram).
---

# Software architecture review

## When to use

Invoked during the design phase, whether proposing new code or reviewing existing code. Focuses on high cohesion, low coupling, and enforced layering. Produces ASCII diagrams for visual iteration.

Two modes:
- **Greenfield**: designing a new feature or system from scratch
- **Brownfield**: reviewing existing code that needs restructuring

## Architecture prescriptions

One per stack. They are the target every review judges against.

### Backend: clean / hexagonal

```
+---------------------------------------------------+
| Transport (HTTP routes, CLI, event handlers)      |
|   wires protocol to use cases. No logic.          |
+-------------------------+-v-----------------------+
                          |
                          v
+-------------------------+-------------------------+
| Application (use cases)                           |
|   one use case per business transaction.          |
|   Orchestrates domain + ports. No protocol, no UI.|
+-------------------------+-v-----------------------+
                          |
                          v
+-------------------------+-------------------------+
| Domain (entities, value objects, aggregates,     )|
| (domain services, domain events, ports declared  )|
| (here and in the application layer               )|
|   pure. No I/O. Imports nothing outward.          |
+---------------------------------------------------+
             ^                 ^
   driven adapters implement ports:
+-----------------+   +--------------------+
| Repositories    |   | External services  |
| (DB is a detail)|   | (APIs, queues, ...)|
+-----------------+   +--------------------+
```

- Dependencies point inward. Domain imports nothing from transport, application, or adapters.
- Ports are declared by the domain/application layer; driven adapters implement them from outside (dependency inversion).
- Repositories are driven adapters — collection-like interfaces over storage (`get`, `add`, `save`, `delete`), not a separate bottom tier.
- Adapter output is domain types, never raw DB rows or external SDK types (anti-corruption at the boundary).

### Frontend: feature-based, modular

```
+---------------------------------------------------+
| Routes / screens                                  |
|   compose features. Minimal logic.                |
+-------------------------v-------------------------+
| features/<capability>/                            |
+---------------------------------------------------+
|  |- UI         (components of this feature)       |
|  |- model      (state, validation, domain logic)  |
|  |- api        (the endpoints it calls)           |
|  \- index.ts   (its public interface)             |
+---------------------------------------------------+
             |
             v  ONLY via public interfaces
+---------------------------------------------------+
| shared/                                           |
|   cross-cutting primitives, typed, named, small.  |
|   NOT a dumping ground. No feature logic.         |
+---------------------------------------------------+
```

- A feature owns everything about one business capability. Features do not import each other's internals — only an exposed public interface.
- Cross-feature requests go through shared contracts/hooks, not deep imports.
- `shared/` only holds what genuinely serves multiple features and changes with them (or with everyone).

### Modularity (both stacks)

- A module is a named area of change, knowable in one sentence.
- A packed `features/`, `services/` or similar must be split by the same rule as an oversized module.
- Dependencies stay acyclic. Within a backend layer, within a frontend shared directory.

### DDD (when applicable)

Apply when the code encodes real business rules. Skip for plumbing-heavy code.

- **Entities vs value objects.** An entity has identity that persists across state changes. A value object is immutable and interchangeable — prefer value objects; they make invariants enforceable at construction.
- **Aggregate as consistency boundary.** One aggregate root per transaction; invariants are enforced inside the aggregate, not by services re-checking from outside.
- **Domain events.** When one business fact must reach other aggregates that share no boundary, emit an event rather than a direct call.
- **Anti-corruption layer.** When an external system's model conflicts with yours, translate at the adapter boundary. External types never leak past it.
- **Ubiquitous language.** Names come from the business domain, not the code structure. If the business says "roster," the type is `Roster`, not `PlayerList`.

### YAGNI

Do not build for hypothetical needs. Delete unused callers. Do not add endpoints nobody calls. Do not refactor for purity alone — accept coupling that buys compile-time safety.

## Working style

- Lead with the diagram. Show the ASCII drawing first, then one sentence about what it reveals.
- One topic at a time. Walk through a single issue or decision before moving to the next.
- Short sentences. State the problem and the proposed fix in two or three lines.
- No background. Do not recap principles or restate what the diagram shows.
- Stop after each diagram. Wait for the user to agree or redirect before continuing.
- If there are many issues, list them as a numbered set. Work through them one by one.
- Default to silence on things that are correct. Only speak up about what is wrong or needs a decision.

Example of how to present one issue:

```
!! route -> repository (bypasses use case)

The transport layer reaches straight into a driven adapter.
Move the call into a use case and let the route depend on it.
```

That is the whole message. No preamble, no summary of the layer diagram, no restating the coupling rules.

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
- Function names describe the what, not the how. `fetchUser` not `fetchUserFromApiWithRetry`.
- If a name needs a qualifier, it may be in the wrong module. `calculateTrainingSamples` versus `calculateInferenceSample` is good. `calculateTrainingSamplesFromGameLogs` signals misplaced logic.

## Module naming: objects and functions, never grab-bags

Every function lives in a **named module whose vocabulary is domain concepts** (`money`, `pricing`, `roster`, `cart`) — never a generic `utils.ts` / `lib.ts` / `helpers.ts`.

- An operation about a domain concept is a **method on the type that owns the concept** (entity, value object, aggregate). Prefer this. E.g. `invoice.totalDue()`, `subtotal.subtract(discount)`.
- A free function is acceptable only inside a **named, cohesive module** (`money/`, `dates/`, `result/`) whose whole surface is one idea.
- A `utils.ts` that has anything in it is evidence of a missing type. Name the concept and put the behavior there.

## Object shape design

When designing or reviewing data objects, align on these decisions:

**Field ownership.** Each field belongs to exactly one object. If two objects have the same field, one should reference the other, not duplicate the data. Example: `orderId` lives on `Order`, not copied onto `Payment`.

**Composition vs reference.** Decide whether object A contains object B or references it by ID. Use composition when B has no meaning without A (a `LineItem` inside an `Order`). Use reference when B exists independently (a `User` referenced by `userId` on an `Order`).

**Nullability.** A field is required if the object cannot exist without it. It is optional if the object is valid without it. Avoid nullable fields that are only sometimes populated. That signals the object is doing two jobs.

**Invariants.** State what must always be true about an object. Example: `Order.total` must equal the sum of its `lineItem` amounts. If an invariant spans multiple objects, name which object enforces it.

**Field naming.** Same rules as function and variable naming: domain language, intention-revealing, no abbreviations beyond domain standard. A field named `isReady` is good. A flag named `flag1` is a problem.

**Object boundaries.** Ask: does this field describe the object, or does it describe a relationship to another object? If it is a relationship, it may belong in a separate object or a reference.

**Shape consistency.** If two objects represent the same concept (e.g., `User` in the API layer and `User` in the domain layer), their shapes should align. If they differ intentionally, name why.

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

**Backend first — which architecture role does it play?**

```
Does it wire a protocol to the app (HTTP route, CLI command, event handler)?
  -> Transport. Calls a use case. No business logic, no direct adapter access.

Is it one business transaction (place order, approve transfer)?
  -> Use case, in application/. Orchestrates domain + ports. One per transaction.

Is it a business rule a domain concept could carry (compute, validate, decide)?
  -> Domain: the entity / value object / aggregate that owns the words. Not in a service.

Does another aggregate need to react to something that happened in a different aggregate?
  -> Domain event, not a call across the boundary.

Is it a collection-like interface over a data store?
  -> Port in the domain, repository adapter outside (driven).

Does it convert an external system's interface to yours?
  -> Driven adapter implementing a port. Anti-corruption lives here.
```

**Frontend — where does it live?**

```
Does it serve one business capability end to end (cart, checkout, session)?
  -> Its own feature/ directory with its own public interface.

Is it a primitive several features need (formatting, typed results, buttons)?
  -> shared/, named after the one idea it contains, smallest useful surface.

Does it only describe one route's composition?
  -> Routes / screens. Compose features. Keep logic out.
```

**Two hard rules before placement:**
1. If the answer was "a utils file" → wrong. Find the type the concept belongs to, or name a cohesive module for the one idea.
2. If two hosts would import it → check it is genuinely cross-cutting, not just lazily reachable.

## Visual architecture review

Produce three ASCII diagrams for every review. Iterate on these with the user before writing any code.

### 1. Current vs target structure

**Greenfield**: shows proposed target only (no current state to compare).
**Brownfield**: shows side-by-side comparison of what exists and what you are proposing.

```
BROWNFIELD (backend):
CURRENT                             TARGET (hexagonal)
-------------------------           ---------------------------
+-----------------------+           +--------------------------+
| api.ts                |           | transport/ (routes)      |
|  |- business logic    |           |  \- calls use cases      |
|  |- db calls          |           +-------------+------------+
|  |- data transform    |                         |
+-----------------------+           +-------------v------------+
                                    | application/use-cases/   |
+-----------------------+           |  |- one per transaction |
| service.ts            |           |  |- calls domain + ports |
|  |- more logic        |           |  \- no I/O, no protocol  |
|  |- db calls          |           +-------------+------------+
|  |- utils             |                         |
+-----------------------+           +-------------v------------+
                                    | domain/                  |
+-----------------------+           |  |- entities, VOs,       |
| db.ts                 |           |  |  aggregates, events   |
|  \- raw queries       |           |  |- declares ports       |
+-----------------------+           |  \- imports nothing      |
                                    +-------------^------------+
                                                  |
                                    driven adapters implement ports:
                                    +--------------------------+
                                    | adapters/ (repos, APIs)  |
                                    |  \- db wrapper, no leaks |
                                    +--------------------------+
```

### 2. Dependency graph

Modules as nodes, imports as edges. Shows coupling and direction, front and back.

```
        +----------+
        |  api.ts  |
        +----+-----+
             |
             v
        +----------+
        | Service  |
        +----+-----+
             |            +----------+
             |            |  utils   |
             v         +-->+----------+
        +----------+   |
        |  Domain  |---+
        +----+-----+
              v
        +----------+
        |  Adapters|
        +----------+

!! api.ts -> db.ts direct (bypasses use case)
!! Domain -> utils (should be a method on the owning concept)
!! Domain -> adapters (adapters must point inward, not out)
```

### 3. Layer diagram — one per stack

Backend (hexagonal enforcement):

```
+---------------------------------------------+
|  Transport (HTTP, CLI, Events)              |
|  -----------------------------------------  |
|  api.ts OK                                  |
|  !! routes contain business logic            |
+---------------------------------------------+
|  Application (use cases)                    |
|  -----------------------------------------  |
|  checkout.ts OK                             |
|  !! also does data transform (move to domain)|
+---------------------------------------------+
|  Domain                                     |
|  -----------------------------------------  |
|  order.ts OK                                |
|  !! imports from adapters (inverse direction)|
+---------------------------------------------+
v  (dependencies point inward; adapters implement ports from outside)
+---------------------------------------------+
|  Driven adapters (repos, external services) |
|  -----------------------------------------  |
|  order-repo.ts OK (collection-like)         |
|  !! returns raw db rows (wrap at boundary)   |
+---------------------------------------------+
```

Frontend (feature-based enforcement):

```
+---------------------------------------------+
|  Routes / screens                           |
|  -----------------------------------------  |
|  page.tsx OK (composes features)            |
|  !! owns cart logic (move into feature)      |
+---------------------------------------------+
|  features/<capability>/                     |
|  -----------------------------------------  |
|  cart/ OK (owns UI, model, api)             |
|  !! cart/ imports checkout/'s internals      |
|  !! model logic lives in shared/ (leakage)   |
+---------------------------------------------+
|  shared/ (cross-cutting only)               |
|  -----------------------------------------  |
|  money/ OK                                  |
|  !! utils.ts grab-bag (name the concept)     |
+---------------------------------------------+
```

### How to iterate

1. Draw current state (brownfield) or proposed state (greenfield). Map modules, imports, and layers.
2. Mark violations. Use `!!` for each smell: wrong layer, bad coupling, wrong dependency direction, leaky abstraction, grab-bag module.
3. Draw target state. Proposed modules, hexagonal/feature boundaries, correct dependency direction.
4. Walk through with user. Confirm the target makes sense before any code changes.
5. Produce migration path (brownfield only). Incremental steps from current to target.

## Architecture review checklist

Cohesion:
- [ ] Can you name each module's purpose in one sentence?
- [ ] Does each module change for only one reason?
- [ ] Are related things together?

Coupling:
- [ ] Does module A import from module B's internals, or only its public interface?
- [ ] Can you test module A without mocking module B's internals?
- [ ] Are dependencies acyclic?
- [ ] Do dependencies point inward (backend) / toward stable code (frontend)?

Backend layering (hexagonal):
- [ ] Does domain import nothing outward — no transport, app, adapter imports?
- [ ] Are ports declared by domain/application, with driven adapters implementing them?
- [ ] Is each use case one business transaction, in the application layer?
- [ ] Are transport routes logic-free, calling use cases only?
- [ ] Are repositories collection-like and flowing through a port?
- [ ] Do adapters return domain types, never raw rows or SDK types?

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
- [ ] Is an ACL at each external-system boundary — no external types leak in?
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
- [ ] Any `utils`/`lib`/`helpers`/`common` grab-bags — should be a named concept?
- [ ] Any module imported by everything else?
- [ ] Any duplicate logic across modules?

## Structural smells and target patterns

| Smell | Signal | Target |
|---|---|---|
| God object | One module does everything. Everyone imports it. | Extract per concern; put rules on the owning domain type. |
| Grab-bag utils | `utils.ts`, `lib.ts`, `helpers.ts`, `common/` with unrelated contents | Name the concept; move each function onto its owning type or a cohesive named module. |
| Anemic domain model | Entities are data bags; all rules in services | Move rules into entities / value objects; services only orchestrate. |
| Misplaced logic | A name needs a qualifier pointing at another module | Put the logic where the name naturally belongs. |
| Directional violation | A module imports against the allowed direction (e.g. domain → adapters) | Invert; declare a port the other side implements. |
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

1. Current state (brownfield) or proposed state (greenfield): ASCII diagrams with `!!` violations marked
2. Issues found: every smell tied to a file and a rule it breaks (one line each)
3. Target structure: ASCII diagrams of proposed modules, layers, dependencies
4. Migration path (brownfield only): incremental steps, each leaving the codebase working
5. Risk assessment: what could break, what to test after each step

## Refactoring triggers

Brownfield only:
- A module that has grown past its original purpose
- Two modules that always change together (merge) or one that changes for multiple reasons (split)
- Business logic that cannot be tested without mocking I/O
- A new requirement that would mean editing many files
- Circular dependencies or everything imports everything
- A name that needs a comment to explain it
- A `utils`/`lib` module whose contents do not share one subject

Greenfield only:
- A proposed module that mixes I/O with business logic
- A proposed dependency that points the wrong direction
- A proposed name that needs a comment to explain it
- A proposed module with more than one responsibility
- A proposed object with duplicated fields or nullable-by-default fields
- A proposed `utils`/`helpers` module as default resting place for a function

---
name: design-review
description: Review or design code structure and architecture for high cohesion, low coupling, and proper layering. Use during the design phase, before implementation, or when refactoring. Covers module boundaries, naming, object shape, comments, decision framework for where code belongs, and visual review with ASCII diagrams (current vs target, dependency graph, layer diagram).
---

# Design review skill

## When to use

Invoked during the design phase, whether proposing new code or reviewing existing code. Focuses on high cohesion, low coupling, and proper layering. Produces ASCII diagrams for visual iteration.

Two modes:
- **Greenfield**: designing a new feature or system from scratch
- **Brownfield**: reviewing existing code that needs restructuring

## Working style

When reviewing or aligning on architecture:

- Lead with the diagram. Show the ASCII drawing first, then one sentence about what it reveals.
- One topic at a time. Walk through a single issue or decision before moving to the next.
- Short sentences. State the problem and the proposed fix in two or three lines.
- No background. Do not recap principles or restate what the diagram shows.
- Stop after each diagram. Wait for the user to agree or redirect before continuing.
- If there are many issues, list them as a numbered set. Work through them one by one.
- Default to silence on things that are correct. Only speak up about what is wrong or needs a decision.

Example of how to present one issue:

```
!! facade -> utils coupling (should be domain -> utils)

The facade imports a utility that only the domain layer should use.
Move the import down to domain and have the facade call through domain.
```

That is the whole message. No preamble, no summary of the layer diagram, no restating the coupling rules.

## Architectural principles

1. High cohesion: code in a module changes for the same reason. If two things change independently, they do not belong together.
2. Low coupling: modules know as little as possible about each other. Dependencies point inward toward stable abstractions, not outward.
3. Single responsibility: one reason to change. If you cannot name what a module does in one sentence, it does too much.
4. Separation of concerns: I/O, business logic, and transport are separate. No fetch inside compute, no compute inside transport.
5. Dependency direction: higher layers depend on lower layers, never the reverse. Business logic never imports from transport or adapters.
6. YAGNI: do not build for hypothetical needs. Delete unused callers. Do not add endpoints nobody calls.
7. Do not refactor for purity alone. Accept coupling that buys compile-time safety.

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

```
Is it a collection-like interface over a data store?
  Yes -> repos/. Mediates between domain and storage.

Is it an interface converter (makes one interface compatible with another)?
  Yes -> adapters/. Converts interfaces. May wrap external systems or internal ones.

Is it an orchestration of an external system with business rules?
  Yes -> Domain Service or Application Service. Calls repos/ or adapters/, adds domain logic.

Is it a protocol handler (HTTP route, event handler, CLI command)?
  Yes -> Transport or Interface. Wires protocol to Application Service. No logic.

Is it a reusable, pure operation?
  Yes -> Utility. Exported, individually testable.
```

Anti-Corruption Layer: when an external system's model conflicts with your domain model, translate at the adapter boundary. Never let external types leak past the adapter.

## Visual architecture review

Produce three ASCII diagrams for every review. Iterate on these with the user before writing any code.

### 1. Current vs target structure

**Greenfield**: shows proposed target only (no current state to compare).
**Brownfield**: shows side-by-side comparison of what exists and what you are proposing.

```
BROWNFIELD:
CURRENT                         TARGET
-------------------------       -------------------------
+-----------------------+       +-----------------------+
| api.ts                |       | api.ts                |
|  |- business logic    |       |  \- calls facade      |
|  |- db calls          |       +-----------+-----------+
|  |- data transform    |                   |
+-----------------------+       +-----------v-----------+
                                | Application Service    |
+-----------------------+       |  |- fetch data        |
| service.ts            |       |  |- call domain      |
|  |- more logic        |       |  \- return result     |
|  |- db calls          |       +-----------+-----------+
|  |- utils             |                   |
+-----------------------+       +-----------v-----------+
                                | Domain                |
+-----------------------+       |  |- pure logic        |
| db.ts                 |       |  \- no I/O            |
|  \- raw queries       |       +-----------+-----------+
+-----------------------+                   |
                                +-----------v-----------+
                                | Adapter / Repository  |
                                |  \- db wrapper        |
                                +-----------------------+
```

### 2. Dependency graph

Modules as nodes, imports as edges. Shows coupling problems and circular dependencies.

```
        +----------+
        |  api.ts  |
        +----+-----+
             |
             v
        +----------+
        | Service  |--------+
        +----+-----+        |
             |              v
             v         +----------+
        +----------+   |  utils   |
        |  Domain  |   +----------+
        +----+-----+
             |
             v
        +----------+
        |  Adapters|
        +----------+

!! Service -> utils coupling (should be Domain -> utils)
!! api.ts -> db.ts direct (bypasses Service)
```

### 3. Layer diagram

Code placed in layers. Shows what is in the wrong layer.

```
+---------------------------------------------+
|  Transport (HTTP, CLI, Events)              |
|  -----------------------------------------  |
|  api.ts OK                                  |
|  !! routes contain business logic            |
+---------------------------------------------+
|  Application Service (orchestration)        |
|  -----------------------------------------  |
|  service.ts OK                              |
|  !! also does data transform (-> domain)     |
+---------------------------------------------+
|  Domain (business logic)                    |
|  -----------------------------------------  |
|  domain/ OK                                 |
|  !! imports from adapters (should be inverse)|
+---------------------------------------------+
|  Adapters (interface converters)            |
|  -----------------------------------------  |
|  adapters/ OK                               |
|  !! returns raw db rows (should wrap)       |
+---------------------------------------------+
|  Repositories (collection-like interfaces)  |
|  -----------------------------------------  |
|  repos/ OK (any data store)                 |
+---------------------------------------------+
```

### How to iterate

1. Draw current state (brownfield) or proposed state (greenfield). Map modules, imports, and layers.
2. Mark violations. Use `!!` for each smell: wrong layer, bad coupling, leaky abstraction.
3. Draw target state. Proposed modules, clean layers, correct dependency direction.
4. Walk through with user. Confirm the target makes sense before any code changes.
5. Produce migration path (brownfield only). Incremental steps from current to target.

## Design review checklist

Cohesion:
- [ ] Can you name each module's purpose in one sentence?
- [ ] Does each module change for only one reason?
- [ ] Are related things together?

Coupling:
- [ ] Does module A import from module B's internals, or only its public interface?
- [ ] Can you test module A without mocking module B's internals?
- [ ] Are dependencies acyclic?
- [ ] Do dependencies point inward toward stable code?

Layering:
- [ ] Is I/O separated from business logic?
- [ ] Does business logic ever import from transport or adapters?
- [ ] Are there clear boundaries between layers?
- [ ] Are repos/ collection-like (get, create, update, delete)?
- [ ] Are adapters/ interface converters?

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
- [ ] Any module imported by everything else?
- [ ] Any duplicate logic across modules?

## Structural smells and target patterns

| Smell | Signal | Target |
|---|---|---|
| God object | One module does everything. Everyone imports it. | Extract services per concern. Move logic to domain. |
| Leaky abstraction | Callers know about DB or API internals. | Wrap in adapter. Return domain types, not external types. |
| I/O in logic | Business rules call fetch or db directly. | Move I/O to adapter. Pass data in. |
| Logic in transport | HTTP routes contain business rules. | Extract to application service. |
| Circular coupling | A imports B, B imports A. | Extract shared logic. Invert dependency. |
| Shotgun surgery | One change touches many modules. | Merge related code. Split unrelated code. |
| Duplicated logic | Same computation in multiple places. | Extract to shared function. |
| Stringly-typed | Raw strings or numbers passed around. | Extract to constants or types. |
| Cryptic names | Names need comments to explain. | Rename using domain language. |
| Duplicated fields | Same data lives on two objects. | Keep it in one place. Reference it from the other. |
| Nullable by default | Fields are optional when they should be required. | Make required fields non-nullable. |

## Output format

1. Current state (brownfield) or proposed state (greenfield): ASCII diagrams with `!!` violations marked
2. Issues found: each smell with file references and why it is a problem
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

Greenfield only:
- A proposed module that mixes I/O with business logic
- A proposed dependency that points the wrong direction
- A proposed name that needs a comment to explain it
- A proposed module with more than one responsibility
- A proposed object with duplicated fields or nullable-by-default fields

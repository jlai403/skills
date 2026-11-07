Part of the `software-arch-review` skill. The per-stack target and placement framework; read when the core points here.

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

### Testability (blackbox/integration, not unit)

The architecture's job for testing: exercise the whole context through its public boundaries with real or fake dependencies, never mocks of the code under test.

- **Every port needs a cheap second implementation.** A port exists so tests can substitute it: an in-memory fake, or a container-backed real one (ephemeral DB, throwaway broker). A port with only one possible implementation did not invert anything; it moved the wiring, not the power. That is a `FIX`-level finding, same rule as the directional violation smell.
- **Prefer fakes and real dependencies to mocks.** A mock pins the shape of a collaborator's calls, so the test breaks on refactors that preserve behavior. A fake fulfills the port, so behavior-preserving refactors keep it green. A test builds its world with fakes and real runtimes; it never asserts call sequences on the system under test.
- **Fixtures build state through the public boundaries.** Seed a scenario by driving use cases, public interfaces, or repository ports, not by writing rows into whatever table the current implementation has. Fixtures then survive refactors, and their setup reads as business language. A fixture that must reach past a boundary is reporting a leak.
- **Fixture economics is a review criterion.** Building the scenario for one integration test should be a call site, not archaeology: a fixture/builder module per context (rule 2c applies; `order-scenario.ts` exporting `OrderScenario`). If constructing the fixture takes more lines than the test, the boundary is wrong or construction is hidden, and both join the suggestions list.

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

**2d. Monorepo top level.** When frontend and backend both exist, they are root siblings, each with its own build:

```
repo/
├── frontend/     own package.json, own build
├── backend/      own src/ with the context split (rule 2)
└── iac/          terraform; never imported by code
```

Never nest frontend and backend inside one shared `src/`. Exceptions: an explicit full-stack framework (SvelteKit, Next with API routes, Rails), or a very small project where the separation costs more than it buys. Different languages or stacks always earn separate root folders.

**3. The layer-first trade-off (why context-first).** Flat layers scatter one concept across four folders. Fine when the service has one context; otherwise the smell is concrete: unrelated rules change together in `models/`, PRs cross contexts, deleting anything means hunting. That scatter is the trigger for rule 2.

**4. Test collocation.** Tests live beside the code they test (`*.test.*` next to the module, or a `__tests__/` sibling), never a global `tests/` tree. They are excluded from the build graph per rule 0.

**5. shared/ admission rule (frontend).** A primitive enters `shared/` only when all three hold: at least two features use it, it names exactly one concept, and its surface is deliberate and tested. Otherwise it stays in the feature.

**6. Folder smells.** Holding folders (`core/`, `misc/`, `lib/`, `common/`, a folder with one file that exists to hold others) are `FIX`-level violations. One-child folders are resolved by the hoist rule (2b). The grab-bag ban applies everywhere in the tree, including `infrastructure/`.

**7. Monorepo extraction triggers.** Extract a package when a separate team owns it, it deploys separately, or it runs on a different stack. Until then, a directory, not a package.

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


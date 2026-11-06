Part of the `software-arch-review` skill. The smell catalogue and refactoring triggers; check them when a structure looks off.

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
| Mock-required boundary | Blackbox behavior is untestable without asserting call order, or a port has no second implementation | Declare the port; provide a fake or container-backed implementation; test through the seam. |

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

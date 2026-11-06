Part of the `software-arch-review` skill. Naming, module placement, object shape, and comments; read when a suggestion names or reshapes something.

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

**Nullability.** A field is required when the object cannot be valid without it, and optional when it can. Avoid nullable fields that are only sometimes populated; that signals the object is doing two jobs. A field that is nullable and never assigned anywhere is not dead code — it is the same missing-reference question (an order that doesn't know its customer). Raise it, at least as the QUESTION row, even when nothing reads the field yet.

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


# Expected findings (order-service fixture)

Scoring manifest for the `make-fixture.sh` fixture. Each seeded violation maps
to one rule in `SKILL.md`. A with-skill run scores against this list; the clean
parts are the false-positive controls.

Fixture tree (generated fresh by `make-fixture.sh` to
`/tmp/opencode/arch-review-fixture/order-service`):

```
order-service/
  README.md
  src/
    transport.ts                 V1  V2
    types.ts                     clean (Request/Response plumbed through; shared)
    application/checkout.ts      clean
    models/
      cart.ts                    clean
      order.ts                   V2  V3  V6
      customer/
        customer.ts              V5   (one-child folder)
    services/pricing-service.ts  V7  (duplicates the transport rule)
    infrastructure/
      db.ts                      clean (thin storage, where I/O belongs)
      order-repo.ts              clean (adapter returns domain types via the port)
    utils/helpers.ts             V4
```

## Seeded violations

| Id | Seeded in | Rule broken (SKILL.md) | Expected suggestions-list row |
|----|-----------|------------------------|-------------------------------|
| V1 | `transport.ts: total loop + gold discount` | Logic in transport | Business rule computed inline in transport; belongs on the aggregate |
| V2 | `transport.ts: db.customers.find / db.orders.insert` | Transport reaches into a driven adapter | One use case per route; only the application talks to ports |
| V3 | `models/order.ts: import { db }` | Directional violation — models import nothing outward | Invert; port declares `OrderRepo` (declared here but bypassed), an adapter implements it from outside |
| V4 | `utils/helpers.ts` grab-bag (`formatDate`, `clamp`, `slugify`, `retry`) | Grab-bag utils | Name the concept; move functions to owning types |
| V5 | `models/customer/customer.ts` alone in `models/customer/` | One-child folder / hoist (2b, 6) | Hoist to `models/customer.ts`; a folder marks a boundary and this one holds no second standing thing |
| V6 | `models/order.ts: customerEmail: string \| null = null` | Nullable by default | Required field (every order has a customer) left nullable — and no code path assigns it; optional-by-default hides a missing invariant |
| V7 | gold-discount logic in both `transport.ts` and `pricing-service.ts` | Duplicated logic | One rule, one owner (aggregate); bonus row — catching the duplication as part of V1 is fine, separate row is fine |

## Process findings (from absence, seeded by omission)

| Id | Missing | Rule (SKILL.md) | Expected |
|----|---------|---------------------------|----------|
| P1 | Repo has **no tests of any kind** | Brownfield Step 0: behavior lock | A `T#` row: blackbox/integration tests pin the boundary first; ranks ahead of every structural step |
| P2 | Declared port `OrderRepo` has exactly one implementation and no fake | Testability: every port needs a cheap second implementation | Legit catch, though defensible to fold into P1 (nothing to substitute *for* yet). Scorers: accept either phrasing; not a false positive |

## Clean parts — must NOT appear on the list

| Subject | Why clean |
|---|---|
| Flat layer layout (`src/application`, `models`, `services`, `infrastructure`) without a context box | README states single context, one team — the single-context exception is legal (rule 2); proposing context-first here is a false positive against the fixture's own design |
| `application/checkout.ts` | Proper use case: orchestrates model + port, no I/O |
| `infrastructure/order-repo.ts` | Driven adapter implementing the declared port, domain types in/out |
| `models/cart.ts` | Value types on the owning aggregate side |
| `infrastructure/db.ts` | Thin storage mechanics under `infrastructure/`, where I/O belongs |

## Scoring walk

1. Inventory phase must be **described** and end with the accuracy check before any judgment. Whether the outline row-level names (`←` marks) line up with the V-list above is how the inventory gets scored — wrong or missing marks are scoring misses, along with any judgment sneaking into the inventory message.
2. Every suggestions-list row must trace to a manifest row. Unlisted extras: V7 above is the only sanctioned bonus; others are correctness hits against the fixture's accuracy, not the agent's.
3. Wrap-up must account for every row (fixed / dropped / parked / superseded), with no silently vacated rows.

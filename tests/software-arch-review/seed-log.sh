#!/usr/bin/env bash
# Seed a pre-existing decision log into an S5 fixture copy.
#
# Usage: tests/software-arch-review/seed-log.sh <fixture-dir>
#
# Produces ARCHITECTURE-REVIEW-LOG.md at the fixture root with
# 41 active + 4 superseded + 2 parked entries. Three of the actives are
# contradicted by the fixture's seeded violations (on purpose — they are the
# divergence probe for R13):
#   - "domain models stay storage-free"  vs V1 (models/order.ts -> db)
#   - "no holding folders / grab-bag utils banned" vs V4 (utils/helpers.ts)
# Dates are all in the past relative to any 2026-11+ run.
set -euo pipefail

DIR="${1:?usage: seed-log.sh <fixture-dir>}"
[[ -d "$DIR/src" ]] || { echo "not an order-service fixture: $DIR" >&2; exit 2; }

cat > "$DIR/ARCHITECTURE-REVIEW-LOG.md" <<'HEADER'
# Architecture review log

Generated and maintained by the `software-arch-review` skill. One entry per
structural decision made during a review: what was decided, what was
rejected, and why. Brownfield reviews read this before assessing drift.

HEADER

# ---- three CONTRADICTED actives (the R13 probe) ----
emit() { # date mode title suggestion decision alternatives why status
  printf '## %s — %s — %s\n- Suggestion: %s\n- Decision: %s\n- Alternatives: %s\n- Why: %s\n- Status: %s\n\n' "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" >> "$DIR/ARCHITECTURE-REVIEW-LOG.md"
}
A=0
contradicted1() { emit 2026-10-12 brownfield "domain models stay storage-free" "#4 models/import-edges" fixed "domain models own their reads; a repository inside models" "storage behind models costs a second query API and mixed responsibilities; parsing sits in infrastructure" active; A=$((A+1)); }
contradicted2() { emit 2026-09-28 brownfield "no holding folders — grab-bag utils banned" "#6 utils/helpers.ts" fixed "a shared utils folder as the staging area; keep grab-bag until it hurts" "grab-bags hide naming decisions and pairing logic; every helper earns a named module" active; A=$((A+1)); }
contradicted3() { emit 2026-10-30 brownfield "pricing owns cross-aggregate rules only" "#8 services/pricing-service.ts" fixed "move the discount rule into transport; keep services for orchestration" "rule duplication is the cheapest thing to fix after a test lock exists" active; A=$((A+1)); }

superseded() { emit "$1" "$2" "$3" "$4" superseded "$5" "$6" superseded; }
parked()     { emit "$1" "$2" "$3" "$4" parked "$5" "$6" parked; }

plain() { emit "$1" "$2" "$3" "$4" fixed "$5" "$6" active; A=$((A+1)); }

# ---- 4 superseded + 2 parked ----
superseded 2026-09-20 greenfield "single module for all storage" "SOLO-DB" "split storage per aggregate" "one file grew past 400 lines the week pricing landed; split by aggregate instead"
superseded 2026-09-22 greenfield "name the http layer handlers/" "HANDLERS" "name it transport/" "handlers/ read as worker queue handlers; the role is transport"
superseded 2026-10-02 brownfield "types.ts at src root" "ROOT-TYPES" "move types beside their owners" "crossing types live at the boundary; owning types travel with the module"
superseded 2026-10-15 brownfield "tests in one top-level test/" "TEST-DIR" "colocate tests beside modules" "per-fixture imports broke two days before launch; colocated won"
parked     2026-10-08 greenfield "extract billing as a package" "PKG-SPLIT" "monorepo package now" "one team, one deploy — a directory until a second consumer exists"
parked     2026-10-25 brownfield "split customer from order context" "CTX-SPLIT" "bounded-context split" "defer until the third aggregate appears; revisit after refunds"

# ---- the three contradicted actives (R13 probe) ----
contradicted1
contradicted2
contradicted3

# ---- 38 plain actives ----
i=0
plain 2026-10-05 greenfield "transport/ owns HTTP in, one file per route" "T-$i" "single transport.ts; folder per verb" "route growth is the known hot path" ; i=$((i+1))
plain 2026-10-05 greenfield "application/ holds use cases; transport stays thin" "T-$i" "fat transport orchestrating stores" "push checkout rules through a use case so routes stay declarative" ; i=$((i+1))
plain 2026-10-06 greenfield "models/ = domain only, no persistence imports" "T-$i" "models reach into stores when convenient" "the model is the contract; storage is replaceable" ; i=$((i+1))
plain 2026-10-07 greenfield "infrastructure/ = adapters out (db, payment, mail)" "T-$i" "adapters sprinkled beside callers" "one direction in, one direction out" ; i=$((i+1))
plain 2026-10-08 greenfield "one child folder hoists to a file" "T-$i" "folders for every module by default" "folders earn their level; a single file is a file" ; i=$((i+1))
plain 2026-10-09 greenfield "types travel with their module" "T-$i" "central types barrel" "imports read bottom-up when types sit beside owners" ; i=$((i+1))
plain 2026-10-10 greenfield "errors cross boundaries as typed results" "T-$i" "throw across module seams" "callers branch on results; a seam throws only at the process edge" ; i=$((i+1))
plain 2026-10-11 greenfield "ports named after the role, not the tech" "T-$i" "PostgresRepo-style names" "role names survive a store swap" ; i=$((i+1))
plain 2026-10-12 greenfield "aggregates get one directory each" "T-$i" "layer-first only" "cross-aggregate reads funnel through application/" ; i=$((i+1))
plain 2026-10-13 greenfield "feature folders under src/features when a slice spans layers" "T-$i" "features only for big slices" "feature-by-default hides the seams" ; i=$((i+1))
plain 2026-10-14 greenfield "config parsing lives at the composition root" "T-$i" "read env inside modules" "one place learns the environment; everything else takes inputs" ; i=$((i+1))
plain 2026-10-15 greenfield "no default exports" "T-$i" "default export for the 'main' type" "default imports kill grep" ; i=$((i+1))
plain 2026-10-16 greenfield "clock injected as a port" "T-$i" "Date.now inline" "tests own time" ; i=$((i+1))
plain 2026-10-17 greenfield "money as integer minor units" "T-$i" "floats for amounts" "float sums drift; invoices must not" ; i=$((i+1))
plain 2026-10-18 greenfield "ids are strings with a prefix" "T-$i" "bare integers" "log grep needs the type" ; i=$((i+1))
plain 2026-10-19 greenfield "migrations versioned and ordered" "T-$i" "idempotent patchwork" "a fresh db must replay to the same shape" ; i=$((i+1))
plain 2026-10-20 greenfield "one CLI entrypoint per surface" "T-$i" "flags on a single binary" "surfaces deploy separately soon" ; i=$((i+1))
plain 2026-10-21 greenfield "http handlers map to use-case verbs" "T-$i" "transport decides business verbs" "verbs belong to the use case" ; i=$((i+1))
plain 2026-10-22 greenfield "one storage port; reads join through it" "T-$i" "two stores for reads and writes" "read models join later if needed" ; i=$((i+1))
plain 2026-10-23 greenfield "shared kernel stays tiny and named" "T-$i" "shared/ everything-common folder" "shared grows to grab-bag unless bounded" ; i=$((i+1))
plain 2026-10-24 greenfield "feature flags read from config, not code" "T-$i" "if (FEATURE_X) branches" "flags outlive the branch they enable" ; i=$((i+1))
plain 2026-10-26 brownfield "colocate tests with modules" "T-$i" "move tests to test/ tree" "the test/ split broke fixture imports once; colocated won" ; i=$((i+1))
plain 2026-10-26 brownfield "blackbox pin before every structure move" "T-$i" "trust unit tests through the move" "units pin internals; the move changes internals" ; i=$((i+1))
plain 2026-10-27 brownfield "order-repo is the only db caller" "T-$i" "ad-hoc queries beside callers" "the adapter boundary already returns domain types" ; i=$((i+1))
plain 2026-10-27 brownfield "transport maps request/response at the edge" "T-$i" "share domain types over the wire" "wire shapes freeze; domain evolves" ; i=$((i+1))
plain 2026-10-28 brownfield "cart totals computed in application, not transport" "T-$i" "price inline in the route" "the route cast req.body straight to Cart otherwise" ; i=$((i+1))
plain 2026-10-28 brownfield "one parent folder per context" "T-$i" "nested contexts two deep" "depth hides seams" ; i=$((i+1))
plain 2026-10-29 brownfield "pricing-service exports functions, not a class" "T-$i" "PricingService with a ctor" "functions match the call pattern today" ; i=$((i+1))
plain 2026-10-29 brownfield "README carries the structure map" "T-$i" "drop the map after the ADR" "onboarding reads top-down; keep one current map" ; i=$((i+1))
plain 2026-10-30 brownfield "db row casts confined to the adapter" "T-$i" "cast during domain mapping" "the row is storage's shape" ; i=$((i+1))
plain 2026-10-31 brownfield "customer subfolder keeps context naming" "T-$i" "customer.ts flat in models/" "flat models mix customer and order vocab" ; i=$((i+1))
plain 2026-11-01 brownfield "logging at boundaries only" "T-$i" "log inside domain logic" "domain logs leak request context everywhere" ; i=$((i+1))
plain 2026-11-02 brownfield "no circular imports between context parents" "T-$i" "allow one-way cycles for now" "a cycle here meant a shared mutable row last quarter" ; i=$((i+1))
plain 2026-11-03 brownfield "utils/ phased out once each helper earns a module" "T-$i" "big-bang delete of utils/" "phased moves kept reviews small" ; i=$((i+1))
plain 2026-11-04 brownfield "transport returns domain shapes, tests pin totals" "T-$i" "assert on internals in tests" "totals are the contract; internals change" ; i=$((i+1))
plain 2026-11-04 brownfield "helpers earn a named module before they leave utils/" "T-$i" "move helpers with callers untouched" "a helper moves with the test that pins it" ; i=$((i+1))
plain 2026-11-04 greenfield "feature data migrations ship with the feature slice" "T-$i" "batch migrations quarterly" "a slice that ships without its schema is a broken deploy" ; i=$((i+1))
plain 2026-11-04 greenfield "consumers import from the module root, never internals" "T-$i" "deep imports for speed" "internals are free to move only if nobody reaches past the root" ; i=$((i+1))

echo "seeded: $A active + 4 superseded + 2 parked -> $DIR/ARCHITECTURE-REVIEW-LOG.md"
[[ "$A" -eq 41 ]] || { echo "expected 41 active entries, got $A" >&2; exit 1; }

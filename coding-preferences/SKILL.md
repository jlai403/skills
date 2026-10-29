---
name: coding-preferences
description: Apply coding preferences before any coding implementation. Must always load when writing code.
---

# coding-preferences

Coding style for all new code in any language. Defaults target TypeScript; adapt to the language (e.g. PEP 8 snake_case in Python).

## Formatting

- A repo's formatter/linter (eslint, prettier) wins; this skill fills gaps it doesn't cover
- 2-space indent
- Function parameters on single line
- Trailing commas in multi-line objects/arrays where the language supports it
- Explicit return types on exported functions

## Control Flow

Guard clauses and early returns over nested conditionals. `continue` as loop guard.

## Naming

Types/classes/schemas: `PascalCase`. Functions/variables/modules: `camelCase`. Constants: `UPPER_CASE`. Follow the language's conventions otherwise (e.g. snake_case in Python).

## Imports (TypeScript)

Order: External → workspace packages → local relatives. Prefer `import type` for type-only imports.

## Types

Prefer `unknown` with type guards over `any`. Where Zod defines a data schema, derive its type via `z.infer` — never handwritten; use `.nullable().optional().default(null)` for optional fields.

## Functions

Extract a fragment when its intent hides behind its implementation: if you must read a body to know what it does, name a function after that "what". Aim for small, intention-revealing functions — no line-count target. Classes only when state/lifecycle warrants it.

## Errors

Fail fast with descriptive messages at boundaries. Tolerate and skip non-critical per-item failures (e.g. `continue` past a bad entry, skip a corrupted record). Don't swallow critical errors; rethrow with context across service boundaries.

## Comments

Self-documenting names first. JSDoc only on public API. Comments explain non-obvious *why*, not what. Keep them tight — one or two sentences; a header comment is a paragraph, not an essay. Don't narrate incident history, alternatives considered, or restate what the code already shows.

## Tests

Nested: Suite > Group > Case. Guard integration tests with env var. Use concrete fixture values, not just `toBeDefined()`.

## Git

Commit with the repo's own git config; never pass `-c user.name`/`-c user.email` overrides. The global identity (with SSH signing) is the correct attribution in the user's repos; overriding it silently breaks signatures and misattributes commits. Machine attribution goes in `Co-authored-by:` trailers, never author swaps.

## Tools

- Edit escalation: after two failed exact-match edits in the same region, stop retrying. Read the exact bytes once (`cat -A`/`od -c`), then use `sd` for single-word global replaces, or a small Python script with anchored regexes for structural multi-line changes.
- After bulk file moves or renames: find empty directories (`git` does not track them) and delete them; grep for stale references, placeholder files, and outdated docs left behind.
- Plans prepared for a user's confirmation are applied only on confirmation. If a decision went unanswered, either hold it or state the chosen default prominently — never silently apply.

## Authoring skills

- A skill edit is not done until its consumer verifies it: run the installer, and confirm the skill appears in the session's available list. If the consumer clones from a remote, push the fix before re-testing.
- SKILL.md frontmatter: any field whose value contains a colon must be quoted or a block scalar (`>-`). An unquoted scalar parses as a nested YAML mapping, and installers skip the skill without error.
- After a skill's first real use, mine the session transcripts (OpenCode: sqlite `~/.local/share/opencode/opencode.db`, tables `session_v2` + `session_message`) for what the skill actually rendered, and iterate on evidence.
- Slop test: delete the line; if nothing actionable disappears, the line is noise.
- Decision tables: one concrete failure mode per option, plus an honest lean. No generic pros.

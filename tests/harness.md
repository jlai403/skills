# Eval harness

Shared runtime for every skill's live evals. One skill = one directory under
`tests/<skill>/` reusing this harness — never its own runtime setup. Per
pstack's two-tier pattern: static checks run everywhere (join
`tests/skill-hygiene/`), live scenarios run pre-release, manually, here.

## Runtime contract (validated 2026-10-29, see software-arch-review/results-2026-10-29.md)

- **Environment is defined, not ambient** — the cycle-1 lesson: harness
  subagents see globally installed skills, and even hermetic controls carry
  the base model's trained-in review style. Concrete setup lives in
  `run-scenario.sh`; both arms must run through it or the run doesn't count.
  Fixture repos regenerate fresh in `/tmp/opencode/<skill>-fixture/`.
- **Three contamination vectors, all closed by the runner** (third found
  2026-10-30 mid-probe, transcript shows `→ Skill "software-arch-review"`
  loading in a "control"): (1) `~/.agents/skills` global installs, closed by
  the clean `HOME`; (2) config-level `AGENTS.md`, equally closed; (3) **cwd
  skill discovery** — `opencode run` finds skills in the working directory's
  project, and every repo skill lives at this repo's root. Runs therefore
  execute from `/tmp/opencode/eval-workdir`, a directory with no projects.
- **`opencode --standalone run`** under a clean `HOME`
  (`/tmp/opencode/eval-home`): no skills, no ambient AGENTS.md. Provider
  credentials resolve untouched (`--auto` is not accepted by `run` despite
  its help listing). `run -s <sessionID>` continues a session for multi-turn.
- **Transcripts are manual-read only**, scored against the skill's rubric;
  verbatim quotes go to the dated results file. No automated scoring.
- **Rep discipline**: 3 per variant; variance is a metric — three different
  shapes across reps means the skill wording is not binding.
- **Meta-tests** (critique of a failing transcript, not a scenario) may run
  as harness subagents — contamination-tolerant by design.

## Operational notes

- **Session ids:** `run` doesn't echo them and `session list` is
  project-scoped by the calling cwd — misleading across directories. Authoritative
  lookup, run from anywhere:
  `python3 -c "import sqlite3; print(sqlite3.connect('/tmp/opencode/eval-home/.local/share/opencode/opencode.db').execute(\"SELECT id, title FROM session_v2 WHERE directory='/tmp/opencode/eval-workdir' ORDER BY time_created DESC LIMIT 1\").fetchone())"`.
  Runner titles every run `<slug>-<HHMMSS>` so runs are traceable.
- Runner usage:
  `tests/run-scenario.sh <slug> <skill-path|-> "<prompt>"` — control arms
  pass `-`. Multi-turn: another runner call ending
  `-s <sessionID> "<reply>"`.

## Adding a skill to the harness

1. `mkdir tests/<skill>/`
2. `scenarios.md` — scenario prompts + which behaviors they discriminate.
   Anchor on an *observed* failure (probe run first: 2+2 reps to find where
   baseline differs from intent). If nothing differs, the live eval is
   documentation only — say so and stop.
3. `expected-findings.md` — if the scenario is repo-facing: a seeded fixture
   manifest, one violation per SKILL.md rule, clean parts as false-positive
   controls.
4. `rubric.md` — scoreable rules pulled from the skill's own text.
5. `results-YYYY-MM-DD.md` — one file per cycle: per-run tables, verbatim
   quotes, variance note, next-cycle queue.
6. One roll-up row per cycle in the skill's `DECISIONS.md`.
7. Update `README.md` testing section when a new skill dir lands.

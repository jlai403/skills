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

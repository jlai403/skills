#!/usr/bin/env bash
# Shared eval runner: one scenario run in the defined runtime.
# Every arm (control, with-skill) must go through this or the run doesn't count.
#
# Usage:
#   tests/run-scenario.sh <fixture-slug> <skill-path|-> "<prompt>"
#     <fixture-slug>   regenerates nothing; only names the transcript home
#                      (/tmp/opencode/<slug>-runs/), keep stable per suite
#     <skill-path>     absolute path to the SKILL.md given to the agent,
#                      or "-" for a control run (no skill preamble)
#     <prompt>         the full scenario user message
#
# Prints the session id first line, then the full transcript. Continuations
# append to the same transcript file via: run-scenario.sh <slug> - -s <sessionID> "<reply>"
set -euo pipefail

readonly EVAL_HOME="/tmp/opencode/eval-home"
usage() { echo "usage: $0 <fixture-slug> <skill-path|-> \"<prompt>\"" >&2; exit 2; }
[[ $# -ge 3 ]] || usage
slug="$1" skill="$2" prompt="$3"; shift 3

outdir="/tmp/opencode/${slug}-runs"
mkdir -p "$outdir" "$EVAL_HOME"

prelude=""
if [[ $# -ge 1 && "$1" == "-s" && $# -ge 3 ]]; then
  sid="$2"; prompt="$3"
  exec HOME="$EVAL_HOME" opencode --standalone run -s "$sid" "$prompt"
fi

if [[ "$skill" != "-" ]]; then
  [[ -f "$skill" ]] || { echo "no skill file at $skill" >&2; exit 2; }
  prelude="You have a skill available for this work. Read the complete file at $skill before starting; if it applies to the task, follow it.

"
fi

HOME="$EVAL_HOME" opencode --standalone run "${prelude}${prompt}"

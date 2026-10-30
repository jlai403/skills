#!/usr/bin/env bash
# Shared eval runner: one scenario run in the defined runtime.
# Every arm (control, with-skill) must go through this or the run doesn't count.
#
# Usage:
#   tests/run-scenario.sh <suite-slug> <skill-path|-> "<prompt>"
#     <suite-slug>     names the transcript home (/tmp/opencode/<slug>-runs/)
#     <skill-path>     absolute path to SKILL.md handed to the agent, or "-"
#                      for a control run
#   continuations (multi-turn):
#   tests/run-scenario.sh <suite-slug> - -s <sessionID> "<owner reply>"
#
# Contract: clean home, neutral cwd (no project skills discovery), fresh
# fixture dirs per suite. Sessions are titled <slug>-<HHMMSS>; ids are
# authoritative in ~/.local/share/opencode/opencode.db of the eval home —
# query by title, `session list` is project-scoped and misleading.
set -euo pipefail

readonly EVAL_HOME="/tmp/opencode/eval-home"
readonly EVAL_WORKDIR="/tmp/opencode/eval-workdir"
usage() { echo "usage: $0 <suite-slug> <skill-path|-> \"<prompt>\"  |  $0 <slug> - -s <sessionID> \"<reply>\"" >&2; exit 2; }
[[ $# -ge 3 ]] || usage

slug="$1" skill="$2" sid="" prompt="$3"
if [[ "$3" == "-s" ]]; then
  [[ $# -ge 5 ]] || usage
  sid="$4" prompt="$5"
fi
[[ "$sid" != "" ]] || { [[ "$skill" == "-" || -f "$skill" ]] || { echo "no skill file at $skill" >&2; exit 2; }; }

mkdir -p "/tmp/opencode/${slug}-runs" "$EVAL_HOME" "$EVAL_WORKDIR"
cd "$EVAL_WORKDIR"

prelude=""
if [[ "$skill" != "-" ]]; then
  prelude="You have a skill available for this work. Read the complete file at $skill before starting; if it applies to the task, follow it.

"
fi

if [[ "$sid" != "" ]]; then
  HOME="$EVAL_HOME" opencode --standalone run -s "$sid" "$prompt"
else
  HOME="$EVAL_HOME" opencode --standalone run --title "${slug}-$(date +%H%M%S)" "${prelude}${prompt}"
fi

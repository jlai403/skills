#!/usr/bin/env bash
# Shared eval runner: one scenario run in the defined runtime.
# Every arm (control, with-skill) must go through this or the run doesn't count.
#
# Usage:
#   tests/run-scenario.sh <suite-slug> <skill-path|install:<skill-path>|-> "<prompt>"
#     <suite-slug>     names the transcript home (/tmp/opencode/<slug>-runs/)
#     <skill-path>     absolute path to SKILL.md handed to the agent
#     install:<path>   copy that skill into the eval home's ~/.agents/skills
#                      and run with NO prelude — tests natural activation
#     -                control run
#   continuations (multi-turn):
#   tests/run-scenario.sh <suite-slug> - -s <sessionID> "<owner reply>"
#
# Contract: clean home, neutral cwd (no project skills discovery), fresh
# fixture dirs per suite. Sessions are titled <slug>-<HHMMSS>; ids are
# authoritative in ~/.local/share/opencode/opencode.db of the eval home —
# query by title, `session list` is project-scoped and misleading.
set -euo pipefail

readonly EVAL_HOME="/tmp/opencode/eval-home"
readonly EVAL_INSTALL_HOME="/tmp/opencode/eval-home-installed"
readonly EVAL_WORKDIR="/tmp/opencode/eval-workdir"
usage() { echo "usage: $0 <suite-slug> <skill-path|install:<skill-path>|-> \"<prompt>\"  |  $0 <slug> - -s <sessionID> \"<reply>\"" >&2; exit 2; }
[[ $# -ge 3 ]] || usage

slug="$1" skill="$2" sid="" prompt="$3"
if [[ "$3" == "-s" ]]; then
  [[ $# -ge 5 ]] || usage
  sid="$4" prompt="$5"
fi
[[ "$sid" != "" ]] || { [[ "$skill" == "-" || "$skill" == install:* || -f "$skill" ]] || { echo "no skill file at $skill" >&2; exit 2; }; }

mkdir -p "/tmp/opencode/${slug}-runs" "$EVAL_HOME" "$EVAL_WORKDIR"
cd "$EVAL_WORKDIR"

run_home="$EVAL_HOME"
prelude=""
if [[ "$skill" == install:* ]]; then
  skill_path="${skill#install:}"
  [[ -f "$skill_path" ]] || { echo "no skill file at $skill_path" >&2; exit 2; }
  skill_dir="$(dirname "$skill_path")"
  skill_name="$(basename "$skill_dir")"
  mkdir -p "$EVAL_INSTALL_HOME/.agents/skills"
  (
    flock 9
    rm -rf "$EVAL_INSTALL_HOME/.agents/skills/$skill_name"
    cp -a "$skill_dir" "$EVAL_INSTALL_HOME/.agents/skills/$skill_name"
  ) 9>"$EVAL_INSTALL_HOME/.agents/skills/.install.lock"
  run_home="$EVAL_INSTALL_HOME"
elif [[ "$skill" != "-" ]]; then
  prelude="You have a skill available for this work. Read the complete file at $skill before starting; if it applies to the task, follow it.

"
fi

if [[ "$sid" != "" ]]; then
  HOME="$run_home" opencode --standalone run -s "$sid" "$prompt"
else
  HOME="$run_home" opencode --standalone run --title "${slug}-$(date +%H%M%S)" "${prelude}${prompt}"
fi

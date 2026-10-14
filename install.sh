#!/usr/bin/env bash
set -euo pipefail

SKILLS_FILE="$(cd "$(dirname "$0")" && pwd)/skills.yml"
SKILLS_SRC="$HOME/.agents/skills"
SKILLS_VERSION="1.7.0"

# Dependency checks
if ! command -v yq &>/dev/null; then
  echo "Error: yq is required but not installed." >&2
  echo "  macOS:  brew install yq" >&2
  echo "  Linux:  yay -S yq  (or pacman -S yq)" >&2
  exit 1
fi

if ! command -v npx &>/dev/null; then
  echo "Error: npx is required but not installed." >&2
  echo "  Install Node.js: https://nodejs.org" >&2
  exit 1
fi

# Nuke all installed skills for clean state
echo "Removing all installed skills..."
npx "skills@${SKILLS_VERSION}" remove -g --all -y 2>/dev/null || true
rm -rf "$SKILLS_SRC"/* 2>/dev/null || true

# Install from config
repos=($(yq -r '.install | keys | .[]' "$SKILLS_FILE"))
for repo in "${repos[@]}"; do
  skills_val=$(yq -r ".install[\"$repo\"].skills" "$SKILLS_FILE")
  agents_raw=$(yq -r ".install[\"$repo\"].agents | join(\",\")" "$SKILLS_FILE")

  agent_flags=()
  IFS=',' read -ra agent_arr <<< "$agents_raw"
  for a in "${agent_arr[@]}"; do
    agent_flags+=(-a "$a")
  done

  skill_flags=()
  if [[ "$skills_val" == "*" ]]; then
    skill_flags=(--skill '*')
  else
    skill_names=($(yq -r ".install[\"$repo\"].skills | .[]" "$SKILLS_FILE"))
    for s in "${skill_names[@]}"; do
      skill_flags+=(--skill "$s")
    done
  fi

  echo "  Installing $repo..."
  npx "skills@${SKILLS_VERSION}" add -g -y "$repo" "${skill_flags[@]}" "${agent_flags[@]}"
done

echo "Done."

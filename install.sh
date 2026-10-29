#!/usr/bin/env bash
set -euo pipefail

SKILLS_VERSION="1.7.0"
SKILLS_SRC="$HOME/.agents/skills"
SKILLS_RAW_URL="${SKILLS_RAW_URL:-https://raw.githubusercontent.com/jlai403/skills/main}"

# Locate skills.yml. Running from a checkout uses the file next to this script;
# every other invocation (curl | bash, bash <(curl ...)) downloads it, because
# those have no script path on disk.
script_dir=""
[[ -f "${BASH_SOURCE[0]:-}" ]] && script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -n "$script_dir" && -f "$script_dir/skills.yml" ]]; then
  SKILLS_FILE="$script_dir/skills.yml"
else
  SKILLS_FILE="$(mktemp -d)/skills.yml"
  trap 'rm -rf "$(dirname "$SKILLS_FILE")"' EXIT
  echo "Downloading config from ${SKILLS_RAW_URL}/skills.yml"
  curl -fsSL "${SKILLS_RAW_URL}/skills.yml" -o "$SKILLS_FILE"
fi

# Dependency checks
if ! command -v yq &>/dev/null; then
  echo "Error: yq is required but not installed." >&2
  echo "  macOS:  brew install yq" >&2
  echo "  Linux:  yay -S yq  (or pacman -S yq)" >&2
  exit 1
fi

if ! command -v curl &>/dev/null; then
  echo "Error: curl is required but not installed." >&2
  exit 1
fi

if ! command -v npx &>/dev/null; then
  echo "Error: npx is required but not installed." >&2
  echo "  Install Node.js: https://nodejs.org" >&2
  exit 1
fi

# Validate every SKILL.md referenced by the config before installing anything:
# an invalid frontmatter gets the skill skipped silently, so fail loudly here.
if ! command -v python3 &>/dev/null; then
  echo "Warning: python3 not found; skipping SKILL.md validation." >&2
else
  # In curl|bash mode there is no checkout, so fetch the linter from the same
  # branch the config came from. Pin both to SKILLS_RAW_URL to avoid drift.
  if [[ -f "$script_dir/scripts/lint_skills.py" ]]; then
    LINT="$script_dir/scripts/lint_skills.py"
  else
    LINT="$(mktemp)"
    if ! curl -fsSL "${SKILLS_RAW_URL%/}/scripts/lint_skills.py" -o "$LINT"; then
      echo "Warning: could not fetch lint_skills.py; skipping validation." >&2
      LINT=""
    fi
  fi
  if [[ -n "$LINT" ]]; then
    lint_tmp=""
    trap 'rm -f "$LINT" ${lint_tmp:+"$lint_tmp"}' EXIT
    while IFS= read -r rel; do
      name="${rel%/*}"
      url="${SKILLS_RAW_URL%/}/${rel}"
      lint_tmp="$(mktemp)"
      if curl -fsSL "$url" -o "$lint_tmp"; then
        python3 "$LINT" "$lint_tmp" || {
          echo "SKILL.md $rel failed lint; fix it before installing. Aborting." >&2
          exit 1
        }
        echo "  lint ok: $rel"
      else
        echo "Warning: could not fetch $rel for linting." >&2
      fi
      rm -f "$lint_tmp"
      lint_tmp=""
    done < <(yq -r '.install[] | .skills[] | . + "/SKILL.md"' "$SKILLS_FILE")
  fi
fi

# Install from config. Re-running is safe: skills add overwrites existing
# installs, so no clean-slate wipe is needed.
repos=($(yq -r '.install | keys | .[]' "$SKILLS_FILE"))
for repo in "${repos[@]}"; do
  skills_val=$(yq -r ".install[\"$repo\"].skills" "$SKILLS_FILE")
  agents_raw=$(yq -r ".install[\"$repo\"].agents | join(\",\")" "$SKILLS_FILE")

  agent_flags=()
  IFS=',' read -ra agent_arr <<< "$agents_raw"
  for a in "${agent_arr[@]}"; do
    [[ -n "$a" ]] && agent_flags+=(-a "$a")
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

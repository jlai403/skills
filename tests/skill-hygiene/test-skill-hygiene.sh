#!/usr/bin/env bash
# Static hygiene checks for the skills this repo installs. No LLM, no network.
# Catches the mechanical failures that silently break skill installs, and the
# size/references drift a live eval cannot see in a single run.
#
# Checks (one concrete failure per rule):
#   1. every skill in skills.yml has its SKILL.md, and every checkout skill
#      dir is listed (a stray dir ships to nobody; a listed-but-missing skill
#      fails the installer download)
#   2. frontmatter closes; name matches its directory
#   3. name is lowercase/digits/hyphens
#   4. name/description carry no unquoted `: ` scalar (the YAML bug that makes
#      installers skip the skill without error — see coding-preferences)
#   5. description fits the agent-skills spec cap (1024 chars)
#   6. SKILL.md stays under the word ceiling (regression guard, not style:
#      set at ~1.2x the largest file at authoring time; tighten deliberately)
#   7. every backticked *.md path inside a SKILL.md resolves on disk here
#
# Usage: tests/skill-hygiene/test-skill-hygiene.sh
set -uo pipefail

WORD_CEILING=6000
DESCRIPTION_CAP=1024
ERRORS=()

fail() { ERRORS+=("$1"); }

# All skill names this repo installs from itself.
mapfile -t CONFIG_SKILLS < <(
  awk '/^  jlai403\/skills:/{flag=1; next} flag && /skills: *\[/{sub(/.*skills: */, ""); gsub(/[][ ]/, ""); n=split($0, a, ","); for (i=1; i<=n; i++) print a[i]; exit}' \
    skills.yml
)

# Every local SKILL.md this checkout carries.
mapfile -t LOCAL_SKILLS < <(find . -mindepth 2 -maxdepth 2 -name SKILL.md | sed 's|/SKILL.md||; s|^\./||' | sort)

# 1. config <-> checkout consistency
for name in "${CONFIG_SKILLS[@]}"; do
  [[ -f "$name/SKILL.md" ]] || fail "skills.yml lists '$name' but $name/SKILL.md is missing"
done
for name in "${LOCAL_SKILLS[@]}"; do
  found=false
  for listed in "${CONFIG_SKILLS[@]}"; do
    [[ "$listed" == "$name" ]] && found=true
  done
  $found || fail "directory '$name' has a SKILL.md but is not listed in skills.yml"
done

# 2..7. per-skill frontmatter and reference checks
for name in "${LOCAL_SKILLS[@]}"; do
  file="$name/SKILL.md"

  # 2. frontmatter delimiters close, then name matches the directory
  first=$(head -n1 "$file")
  [[ "$first" == "---" ]] || { fail "$file: frontmatter does not open with ---"; continue; }
  if ! tail -n +2 "$file" | grep -q '^---$'; then
    fail "$file: frontmatter never closes"
    continue
  fi
  frontmatter=$(tail -n +2 "$file" | sed '/^---$/q')
  declared=$(sed -n 's/^name: *//p; /./q' <<< "$frontmatter" | head -n1)
  [[ "$declared" == "$name" ]] || fail "$file: frontmatter name '$declared' does not match directory '$name'"

  # 3. name character set
  if ! grep -q '^name: *[a-z0-9-]*$' <<< "$frontmatter"; then
    fail "$file: name must be lowercase, digits, hyphens only"
  fi

  # 4. unquoted-colon trap: a plain single-line scalar carrying ': ' is that
  #    YAML bug - it parses as a sub-mapping and installers silently skip the
  #    skill. Only quoted ('/") or block (>/|) scalars may hold a colon.
  trap_line=$(grep -E '^(name|description): *[^>"'"'"'|].*: ' <<< "$frontmatter" | head -n1)
  [[ -z "$trap_line" ]] || fail "$file: unquoted colon scalar ($trap_line) — quote it or use a block scalar"

  # 5. description length cap (frontmatter description, block scalars flattened)
  desc_chars=$(
    awk '
      /^description:/ { inDesc = 1; sub(/^description: */, ""); printf "%s", $0; next }
      inDesc && /^  / { printf " %s", $0; next }
      inDesc { inDesc = 0 }
    ' "$file"
  )
  desc_chars=${#desc_chars}
  (( desc_chars <= DESCRIPTION_CAP )) || fail "$file: description is $desc_chars chars (cap $DESCRIPTION_CAP)"

  # 6. word ceiling
  words=$(wc -w < "$file")
  (( words <= WORD_CEILING )) || fail "$file: $words words exceeds ceiling $WORD_CEILING — trim or deliberately raise the ceiling"

  # 7. backticked *.md references resolve (relative to the skill dir, then repo root)
  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    resolved=""
    if [[ -f "$name/$target" ]]; then resolved="$name/$target"
    elif [[ -f "$target" ]]; then resolved="$target"
    fi
    [[ -n "$resolved" ]] || fail "$file: backticked reference '$target' does not resolve"
  done < <(grep -oE '`[A-Za-z0-9_./ -]+\.md`' "$file" | tr -d '`' | sort -u)
done

if (( ${#ERRORS[@]} )); then
  echo "skill-hygiene: FAIL"
  for message in "${ERRORS[@]}"; do
    echo "  - $message"
  done
  exit 1
fi
echo "skill-hygiene: PASS ($(printf '%s, ' "${LOCAL_SKILLS[@]}" | sed 's/, $//'))"

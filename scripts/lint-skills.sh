#!/usr/bin/env bash
# Validates every SKILL.md in this repo: YAML frontmatter parses, name matches
# its directory, required fields present. Exits nonzero on any failure.
# Used by install.sh --check and CI. Requires: python3 with pyyaml, or yq.
set -euo pipefail

fail=0
found=0
while IFS= read -r f; do
  found=$((found + 1))
  if ! python3 scripts/lint_skills.py "$f"; then
    echo "LINT FAIL: $f" >&2
    fail=1
  fi
done < <(find . -name "SKILL.md" -not -path "./node_modules/*")

if [[ "$found" -eq 0 ]]; then
  echo "No SKILL.md found." >&2
  exit 1
fi

exit "$fail"

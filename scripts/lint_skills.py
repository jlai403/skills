#!/usr/bin/env python3
"""Lint one SKILL.md's YAML frontmatter. Prints what is wrong and exits 1."""
import re
import sys

try:
    import yaml
except ImportError:
    print("pyyaml is required: python3 -m pip install pyyaml", file=sys.stderr)
    sys.exit(2)

def main(path):
    text = open(path).read()
    m = re.match(r"\A---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        print("no YAML frontmatter block")
        return 1
    try:
        meta = yaml.safe_load(m.group(1))
    except yaml.YAMLError as e:
        # Show the offending line, which case is the silent-skip bug seen in PR #2:
        # an unquoted scalar containing 'key: value' becomes a nested mapping.
        line_no = getattr(e, "problem_mark", None)
        point = f" (near line {getattr(line_no, 'line', '?') + 1})" if line_no else ""
        print(f"YAML parse error{point}: {e}")
        return 1

    if not isinstance(meta, dict):
        print(f"frontmatter must be a mapping, got {type(meta).__name__}")
        return 1

    missing = [k for k in ("name", "description") if k not in meta]
    if missing:
        print(f"missing keys: {', '.join(missing)}")
        return 1

    expected = sys.argv[2] if len(sys.argv) > 2 else path.split("/")[-2]
    if meta["name"] != expected:
        print(f"name mismatch: frontmatter says {meta['name']!r}, folder is {expected!r}")
        return 1

    desc = meta["description"]
    if not isinstance(desc, str) or len(desc) > 1024:
        print("description must be a string under 1024 chars")
        return 1

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))

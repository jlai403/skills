# skills

Personal agent skills, plus a config-driven installer. `skills.yml` is the single
source of truth for which skills from which repos get installed for which agents.

## Install

```bash
curl -fsSL https://github.com/jlai403/skills/raw/main/install.sh | bash
```

If a tool prompts mid-install (e.g. `npx` on a cold cache), use process
substitution instead — piping gives bash the script on stdin, so a child that
reads stdin consumes script bytes. `<(curl ...)` keeps stdin attached to your
terminal:

```bash
bash <(curl -fsSL https://github.com/jlai403/skills/raw/main/install.sh)
```

Requirements:

- `yq` — `brew install yq` / `pacman -S yq`
- Node.js with `npx` — <https://nodejs.org>
- `curl`

## What the installer does

1. Reads `skills.yml` — from this checkout if `install.sh` is run as a file,
   otherwise downloads it from the `raw.githubusercontent.com` URL above.
2. For each repo, runs `npx skills@1.7.0 add -g -y <repo> --skill ... -a ...`.
3. Skills land in `~/.agents/skills` and are linked into each agent's config
   directory (`~/.claude`, `~/.config/opencode`, `~/.gemini`).

Re-running is safe. `skills add` overwrites existing installs, so updates are just
another run.

## Config

```yaml
install:
  jlai403/skills:
    skills: [coding-preferences, design-review]   # or "*" for everything
    agents: [claude-code, opencode, gemini-cli]
```

Edit `skills.yml`, then run `./install.sh` from a checkout. When adding a local
skill, put it in `<name>/SKILL.md` and list it in `skills.yml` — but note that the
installer fetches `jlai403/skills` from GitHub, so local changes need to be pushed
before `install.sh` picks them up.

## Clean slate

Prune skills you have removed from `skills.yml`:

```bash
npx skills@1.7.0 remove -g --all -y && rm -rf ~/.agents/skills/*
```

## Uninstall

```bash
npx skills@1.7.0 remove -g --all -y && rm -rf ~/.agents/skills
```

## Overrides

- `SKILLS_RAW_URL` — base URL for the `skills.yml` download, e.g. to test a branch
  before merging:
  ```bash
  SKILLS_RAW_URL=https://raw.githubusercontent.com/jlai403/skills/my-branch \
    bash <(curl -fsSL https://raw.githubusercontent.com/jlai403/skills/my-branch/install.sh)
  ```

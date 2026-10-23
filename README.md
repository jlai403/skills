# skills

Personal agent skills and an installer that reads `skills.yml`. That file lists
which skills to install, from which repos, for which agents.

## Install

```bash
curl -fsSL jlai.ca/skills | bash
```

Piping gives bash the script on stdin, so a tool that reads stdin (npx on a cold
cache, for example) consumes script bytes instead of reading your terminal. If
that happens, use process substitution, which keeps stdin attached:

```bash
bash <(curl -fsSL jlai.ca/skills)
```

Requirements:

- `yq`, install with `brew install yq` or `pacman -S yq`
- Node.js with `npx` (<https://nodejs.org>)
- `curl`

## What the installer does

1. Reads `skills.yml` from the directory next to `install.sh` when you run the
   file. Otherwise it downloads a copy from `SKILLS_RAW_URL`, which defaults to
   `raw.githubusercontent.com`.
2. For each repo, runs `npx skills@1.7.0 add -g -y <repo> --skill ... -a ...`.
3. `npx skills` puts each skill in `~/.agents/skills` and links it into every
   agent directory (`~/.claude`, `~/.config/opencode`, `~/.gemini`).

Running it again is safe, because `skills add` overwrites existing installs.

## Config

```yaml
install:
  jlai403/skills:
    skills: [coding-preferences, design-review]   # or "*" for everything
    agents: [claude-code, opencode, gemini-cli]
```

Edit `skills.yml`, then run `./install.sh` from a checkout. To add a local skill,
put it in `<name>/SKILL.md` and list it in `skills.yml`. The installer fetches
`jlai403/skills` from GitHub, so push local changes before `install.sh` can use
them.

## Clean slate

Remove skills you deleted from `skills.yml`:

```bash
npx skills@1.7.0 remove -g --all -y && rm -rf ~/.agents/skills/*
```

## Uninstall

```bash
npx skills@1.7.0 remove -g --all -y && rm -rf ~/.agents/skills
```

## Overrides

`SKILLS_RAW_URL` sets the base URL for the `skills.yml` download. Use it to test
a branch before merging:

```bash
SKILLS_RAW_URL=https://raw.githubusercontent.com/jlai403/skills/my-branch \
  bash <(curl -fsSL https://raw.githubusercontent.com/jlai403/skills/my-branch/install.sh)
```

# Claude Code Skills

Personal Claude Code skills. Clone into `~/.claude/skills` on any machine.

## Setup

```bash
git clone --recurse-submodules git@github.com:McBrideMusings/skills.git ~/.claude/skills
```

## Adding third-party skills

```bash
cd ~/.claude/skills
git submodule add <repo-url> <skill-name>
```

## Updating submodules

```bash
git submodule update --remote
```

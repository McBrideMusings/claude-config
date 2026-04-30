---
name: audit-docs
description: "Audit, bootstrap, or migrate the project's VitePress docs site. Picks the right mode automatically based on whether docs/ exists, whether VitePress is wired, and which standard files are present."
user_invocable: true
---

# /audit-docs — VitePress Documentation Site

This command delegates to the **docs skill** at `~/.claude/skills/docs/SKILL.md`. See that file for the full procedure, including:

- Greenfield bootstrap vs. audit vs. legacy migration detection
- Standard layout (PRD / roadmap / file-map universal; api / architecture / guide / development opt-in)
- Opt-in heuristics (when does a project need `api.md`? when does it need `architecture/`?)
- Project `CLAUDE.md` integration with the update-when table
- `admin.toml` integration as a single `[commands.docs]` shell command (no sub-targets)
- The `.mts` ESM gotcha and other VitePress traps

## What this command does

Despite the name, "audit" is the umbrella for three modes:

- **Bootstrap** — no `docs/` folder. Set up the standard layout from scratch.
- **Migrate** — `docs/` has loose markdown but no VitePress, or has legacy phase/task docs that should be GitHub issues. Categorize, propose migrations, align.
- **Audit** — `docs/` is already aligned. Verify, fix mechanical drift silently, propose substantive changes with diffs.

The skill detects which mode applies and runs it. There's no separate `init-docs` command — initialization is just an audit on a project that has nothing yet.

## Critical rule

**Treat VitePress as a black box.** Don't read its `node_modules/` source. The library works; the integration points are stable. Read its config and your own markdown.

## Key decisions encoded in the skill

- `docs/roadmap.md` is a single file with sections **Now / Next / Later / Deferred** — not a folder
- `docs/api-surface.md` is renamed to `docs/api.md` if found (mechanical fix)
- `docs:build` and `docs:preview` scripts are NOT installed by default — only `docs:dev`. Build/preview are noise for local viewing; only add them if the project demonstrably deploys docs (CI workflow, gh-pages script, etc.)
- `[commands.docs]` in `admin.toml` is a **single shell command** running `npm run docs:dev` — no sub-targets
- Legacy `PHASE_*.md` / `FUTURE_FEATURES.md` / `tasks/` files migrate to GitHub issues, then get deleted

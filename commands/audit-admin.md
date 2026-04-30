---
name: audit-admin
description: "Audit, bootstrap, or regenerate the project's `./admin` task runner. Picks the right mode automatically based on whether admin.toml and ./admin exist."
user_invocable: true
---

# /audit-admin — Manifest-Driven Admin Task Runner

This command delegates to the **admin skill** at `~/.claude/skills/admin/SKILL.md`. See that file for the full procedure, including:

- Bootstrap / regenerate / audit flow
- Inline code policy and the migration playbook from inline to `admin_lib` / archetype
- Archetype composition (`archetypes = ["docker-unraid", "apple"]`)
- `[urls]`, `[commands]`, `[logs.<target>]` manifest sections
- Env var interpolation (`${VAR}`, `${VAR:-default}`) and `./admin env` discovery
- Generator provenance (`generator_commit`) and drift audit
- Standard command ordering (`build / dev / deploy / --- / test / vet / fmt / clean / docs`)
- The single-shell-command shape for `[commands.docs]` (no sub-targets)

## What this command does

Despite the name, "audit" is the umbrella for three modes:

- **Bootstrap** — no `admin.toml`. Detect stack, write a starter manifest, generate `./admin`.
- **Regenerate** — `admin.toml` exists; rewrite `./admin` to match.
- **Audit** — both exist; diff `./admin` against what `admin.toml` would produce. Report drift, inline-code complexity warnings, and required manual migrations.

The skill detects which mode applies and runs it.

## Generator binary

The generator installs to `~/.admin/init-admin` (via `install.sh` in `~/Projects/admin-project-tool`). Three modes:

```bash
~/.admin/init-admin .                          # bootstrap
~/.admin/init-admin --regenerate . --force-dirty  # regenerate
~/.admin/init-admin --audit . --force-dirty       # audit
```

## Critical rule

**Treat the generator as a black box.** Don't read source under `~/.admin/` or `~/Projects/admin-project-tool/` — run the tool and read its output. Only dig into generator internals if the user is asking you to debug the generator itself.

## Sister command

If the project also has a docs site (or should), run `/audit-docs` after this — the admin skill ensures `[commands.docs]` is wired correctly, but only the docs skill knows whether the docs themselves are aligned with the standard layout.

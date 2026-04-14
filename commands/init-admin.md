---
name: init-admin
description: "Scaffold, regenerate, or audit a Python-based `admin` task runner. Reads/writes an `admin.toml` manifest and generates a self-contained `./admin` from composable archetypes. Also audits for drift."
user_invocable: true
---

# /init-admin — Manifest-Driven Admin Task Runner (v2)

This command delegates to the **init-admin skill** at `~/.claude/skills/init-admin/SKILL.md`. See that file for the full procedure, including:

- Bootstrap / regenerate / audit flow
- Archetype composition (`archetypes = ["docker-unraid", "apple"]`)
- `[urls]`, `[commands]`, `[commands.custom]`, `[inline]` manifest sections
- `[logs.<target>]` — file-based log tailing with per-env paths, optional SSH, `--tail N` / `--all` / `--no-follow`
- Env var interpolation (`${VAR}`, `${VAR:-default}`) and `./admin env` discovery
- Generator provenance (`generator_commit`) and drift audit

## Generator binary

The generator installs to `~/.admin/init-admin` (via `install.sh` in `~/Projects/admin-project-tool`). Three modes:

```bash
~/.admin/init-admin .              # bootstrap: detect stack, write admin.toml, generate ./admin
~/.admin/init-admin --regenerate . # reload admin.toml and rewrite ./admin
~/.admin/init-admin --audit .      # diff ./admin against what admin.toml would produce (exit 2 on drift)
```

## Critical rule

**Treat the generator as a black box.** Don't read source under `~/.admin/` or `~/Projects/admin-project-tool/` — run the tool and read its output. Only dig into generator internals if the user is asking you to debug the generator itself.

## Key concepts (refresher)

- `admin.toml` is the source of truth. `./admin` is a generated artifact. Both are committed together.
- Archetypes are composable mixins; later-listed archetypes win conflicts; `[commands]` in the manifest wins over all archetypes.
- `[inline] file = "admin_inline.py"` is the escape hatch for project-specific Python the generator concatenates verbatim.
- `[logs]` adds a `./admin logs` file-tailing command (local or SSH). Default is follow-from-end; `--tail N` / `--all` for history. Handles truncation (circular-buffer files) and rotation by reopening on inode change or size shrink.
- `./admin env` lists every `${VAR}` the script references and whether it's set.

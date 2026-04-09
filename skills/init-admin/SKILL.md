---
name: init-admin
description: Scaffold, regenerate, or audit a Python-based `admin` task runner for the current project. Reads/writes an `admin.toml` manifest and generates a self-contained `./admin` script from composable archetypes. Also audits existing scripts for drift.
---

# /init-admin — Manifest-Driven Admin Task Runner

**v2 flow (manifest-driven).** The generator writes two files per project:

- **`admin.toml`** — short (~5–25 line) human-edited manifest declaring archetypes, URLs, and any project-specific commands. Committed. **The source of truth.**
- **`./admin`** — self-contained, bundled Python script generated from `admin.toml` + archetype catalog. Also committed. Should not be hand-edited; regenerate instead.

The generator tool is `~/.admin/init-admin-v2` (installed by the `admin-project-tool` repo's `install.sh`). It has three modes:

- **Bootstrap** (no args): detect project stack → write starter `admin.toml` → generate `./admin`
- **`--regenerate`**: reload `admin.toml` and rewrite `./admin` (idempotent; normal loop for adding/changing commands)
- **`--audit`**: diff the on-disk `./admin` against what would be regenerated; exit 0 on clean, 2 on drift

## Instructions

Follow these phases. Do NOT skip phases or auto-confirm on behalf of the user.

### Phase 1: Detect current state

1. Check `~/.admin/init-admin-v2` exists. If not, tell the user to run `install.sh` from `~/Projects/admin-project-tool` first.
2. Check the project for `admin.toml` and `./admin`:
   - **Neither exists** → bootstrap flow (Phase 2a)
   - **Both exist** → regenerate / audit flow (Phase 2b)
   - **Only `./admin` exists, no `admin.toml`** → this is a v1 (pre-manifest) project. Offer `--from-existing` migration (once that flag ships — tracked as an open issue). Until then, treat as bootstrap and warn the user the existing `./admin` will be overwritten.
   - **Only `admin.toml` exists, no `./admin`** → run `--regenerate`

### Phase 2a: Bootstrap (no admin.toml)

1. Run `~/.admin/init-admin-v2 .` — this detects the stack via `~/.admin/detectors/`, writes a starter `admin.toml`, and generates `./admin`.
2. Show the user the generated `admin.toml` and the detector that matched.
3. Point them at any TODO shell strings (the `simple` fallback archetype uses placeholder `echo 'TODO: …'` commands that need to be filled in).

### Phase 2b: Regenerate / Audit (admin.toml exists)

1. Run `~/.admin/init-admin-v2 --audit .` first to check for drift.
   - **Exit 0, clean** → nothing to do unless the user is explicitly asking for a change.
   - **Exit 2, drift** → the on-disk `./admin` was hand-edited, or the archetype catalog / `admin_lib` has moved since the last regen. Show the user the unified diff and ask whether they want to regenerate (throwing away the hand edits) or keep the drift.
2. To update after the user edits `admin.toml`, run `~/.admin/init-admin-v2 --regenerate .`.

### Phase 3: Env var discovery (if the manifest uses `${VAR}`)

If `admin.toml` or any generated command references `${VAR}` placeholders, run `./admin env` to list referenced vars and their current state (set / default / UNSET required). Tell the user which env vars they need to export before commands will work.

### Phase 4: Post-generation file setup

After generation succeeds:

1. **`.gitignore`** — ensure `tmp/` is ignored (the generator creates `tmp/.gitignore` automatically, which covers this)
2. **`.claude/skills/read-logs.md`** — create if missing (template below)
3. **`CLAUDE.local.md`** — create or update with the auto-reload instruction (see below)
4. **Project `CLAUDE.md`** — if it references `admin.sh` or a v1 template name, update to reference `./admin` and mention `admin.toml` is the source of truth

### Phase 5: Auto-reload documentation

Ensure the project has a `CLAUDE.local.md` (gitignored, not committed) with:

```markdown
# Local Development Workflow

## Auto-reload after code changes

When `./admin dev` is active in another terminal, run `./admin reload` after making code changes to trigger a rebuild and relaunch. Don't wait for the user to manually restart — if the app is running, reload it so they can immediately see the effect of your changes.
```

Also ensure `CLAUDE.local.md` is in `.gitignore`.

### Phase 6: Commit

Ask the user if they want to commit `admin.toml` and `./admin` together. They should always be committed in the same commit so provenance (`generator_commit` SHA) stays coherent.

---

## Key mental-model notes

- **`admin.toml` is the source of truth.** Hand-edits to `./admin` are drift. Escape hatch for project-specific Python is `[inline] file = "admin_inline.py"` in the manifest, not editing the generated script.
- **Archetypes are composable mixins.** `archetypes = ["docker-unraid", "apple"]` is valid and produces a merged command set. Later archetype wins on conflicts; manifest `[commands]` wins over all archetypes.
- **Env vars are runtime.** `${VAR}` and `${VAR:-default}` in manifest strings are passed through to the generated script as literals and resolved by `admin_lib.core.resolve_env()` when commands run. Never expand them at generation time.
- **`generator_commit` is the repo SHA of `admin-project-tool`** at the time of last regeneration. The audit compares SHAs to tell the user whether the generator itself has moved since the manifest was last regenerated.
- **Python 3.11+ required** everywhere (stdlib `tomllib`). The generated `./admin` starts with a runtime guard.

## v1 projects (no `admin.toml`)

These still exist until migrated. A v1 `./admin` is a bundled single file with a `# @bundled` header but no companion `admin.toml`. Don't hand-audit these — they predate v2 and will be migrated with `--from-existing` (not yet implemented; tracked as an open issue). Until then, regenerating a v1 project from scratch is the only option, which overwrites the existing script.

---

## read-logs.md Template

If `.claude/skills/read-logs.md` doesn't exist, create it:

```markdown
---
name: read-logs
description: Read runtime logs from the last ./admin dev or other command. Use when the user says they ran the app and something didn't work, or when you need to check what happened during the last run.
---

# Read Logs

The log file is at `tmp/run.log` in the project root. It captures all stdout/stderr from the last `./admin` run.

## Strategy

Determine whether this is a **build problem** or a **runtime/logging problem**, then read accordingly.

### Build problem (app didn't launch, crash on start)
Read from the **top** of the log file (first 80 lines). Look for:
- `error:` lines from build tools
- `BUILD FAILED` or equivalent
- Crash output immediately after launch

### Runtime / behavior bug (app launched but something went wrong)
Read from the **bottom** of the log file (last 80 lines). The user typically quits after observing the bug.

### If you need more context
- Read the full file only if the targeted read didn't give enough info
- Search for specific error patterns

### What NOT to do
- Don't read the entire log file upfront if it's large
- Don't ask the user to paste logs -- just read the file
```

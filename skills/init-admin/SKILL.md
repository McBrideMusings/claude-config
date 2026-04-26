---
name: init-admin
description: Scaffold, regenerate, or audit a Python-based `admin` task runner for the current project. Reads/writes an `admin.toml` manifest and generates a self-contained `./admin` script from composable archetypes. Also audits existing scripts for drift.
---

# /init-admin — Manifest-Driven Admin Task Runner

**v2 flow (manifest-driven).** The generator writes two files per project:

- **`admin.toml`** — short (~5–25 line) human-edited manifest declaring archetypes, URLs, and any project-specific commands. Committed. **The source of truth.**
- **`./admin`** — self-contained, bundled Python script generated from `admin.toml` + archetype catalog. Also committed. Should not be hand-edited; regenerate instead.

The generator tool is `~/.admin/init-admin` (installed by the `admin-project-tool` repo's `install.sh`). It has three modes:

- **Bootstrap** (no args): detect project stack → write starter `admin.toml` → generate `./admin`
- **`--regenerate`**: reload `admin.toml` and rewrite `./admin` (idempotent; normal loop for adding/changing commands)
- **`--audit`**: diff the on-disk `./admin` against what would be regenerated; exit 0 on clean, 2 on drift

## Critical rule: treat the generator as a black box

**Do NOT read source code under `~/.admin/`, `~/Projects/admin-project-tool/`, or any detector/archetype `.py` files.** The generator is a program — run it and read its output. You are not expected to understand its internals to use it.

The only files you should read are:
- The project's `admin.toml` (the user's manifest — you'll edit this)
- The project's generated `./admin` (only to show the user or debug a generation failure)
- This skill file

If the generator produces unexpected output or the wrong archetype match, **report the results to the user first**. Only dig into generator source code if the user explicitly asks you to investigate a bug in the generator itself.

## Instructions

Follow these phases. Do NOT skip phases or auto-confirm on behalf of the user.

### Phase 1: Detect current state

1. Check `~/.admin/init-admin` exists. If not, tell the user to run `install.sh` from `~/Projects/admin-project-tool` first.
2. Check the project for `admin.toml` and `./admin`:
   - **Neither exists** → bootstrap flow (Phase 2a)
   - **Both exist** → regenerate / audit flow (Phase 2b)
   - **Only `./admin` exists, no `admin.toml`** → this is a v1 (pre-manifest) project. Offer `--from-existing` migration (once that flag ships — tracked as an open issue). Until then, treat as bootstrap and warn the user the existing `./admin` will be overwritten.
   - **Only `admin.toml` exists, no `./admin`** → run `--regenerate`

### Phase 2a: Bootstrap (no admin.toml)

1. Run `~/.admin/init-admin .` — it detects the stack, writes `admin.toml`, and generates `./admin`. **Do not explore the project yourself to guess the archetype — the detectors do this.**
2. Read the generated `admin.toml` and show it to the user along with the detector match (printed in the generator's stdout).
3. Point them at any TODO shell strings (the `simple` fallback archetype uses placeholder `echo 'TODO: …'` commands that need to be filled in).
4. **Apply standard command ordering** (see Phase 2c below) — archetypes define their own order which is usually wrong. Always reorder after bootstrap.

### Phase 2b: Regenerate / Audit (admin.toml exists)

1. Run `~/.admin/init-admin --audit .` first to check for drift.
   - **Exit 0, clean** → nothing to do unless the user is explicitly asking for a change.
   - **Exit 2, drift** → the on-disk `./admin` was hand-edited, or the archetype catalog / `admin_lib` has moved since the last regen. Show the user the unified diff and ask whether they want to regenerate (throwing away the hand edits) or keep the drift.
2. To update after the user edits `admin.toml`, run `~/.admin/init-admin --regenerate .`.

### Phase 2c: Standard command ordering

After any bootstrap or regeneration, check `./admin --help` and ensure commands appear in this order. If they don't, explicitly define all commands in `[commands.*]` blocks in `admin.toml` (this overrides the archetype's order) and set `archetypes = []` if needed to prevent the archetype from re-imposing its order.

**Required order:**
```
build
dev
deploy

test
vet
fmt
clean
docs
```

The blank line between `deploy` and `test` is conceptual grouping (build/run/ship, then quality/docs) — not literally blank in the TOML, just the mental model for ordering.

- `dev` = run the project locally (e.g. `go run ./cmd/...`, `python app.py`, `npm run dev`)
- `docs` = view or generate docs (e.g. `go doc ./...`, `open docs/`, `npm run docs`)
- Not every project has every command — omit ones that don't apply, but keep the relative order of those that do.

**Important:** Archetype commands always render in the archetype's order, with manifest-only commands appended after. To control order, you must define all commands explicitly in `[commands.*]` blocks and use `archetypes = []`. The manifest `desc`/`run` values override the archetype's for the same command name, but order is still archetype-first.

**Adding spacers (blank rows between groups):** Use the `order` field with `"---"` as a separator token:

```toml
order = ["build", "dev", "deploy", "---", "test", "vet", "fmt", "clean", "docs"]
```

This emits `add_spacer()` calls in the generated script, producing a blank row in both the TUI menu and `--help` output. `"---"` is the only recognized separator token (not `"--"` or `"separator"`).

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

## File-based log tailing (`[logs]` section)

The manifest supports a top-level `[logs.<target>]` section that emits a `./admin logs` command for tailing log **files** (not processes). Use this when the project writes to one or more well-known log files — whether an append-only file, a rotating file, or a file that's truncated and rewritten in place ("circular-buffer" style). It does not care what produced the file.

### Manifest shape

```toml
[logs.app]
dev  = "./tmp/app.log"                                                                  # string = local path
prod = { path = "/var/log/app.log", host = "${APP_HOST}", user = "${APP_USER:-root}" }  # table = remote
default_env = "dev"                                                                     # optional; else TUI picker / --env required

[logs.worker]
local = "./tmp/worker.log"                                                              # single env auto-selected; no picker
```

Rules:
- Each env value is **either** a string (local path) **or** a table with a required `path` and optional `host` + `user`.
- `host` present = tail remotely via `ssh [-l user] host 'tail … path'`. Missing = local file.
- `${VAR}` / `${VAR:-default}` placeholders work anywhere (path, host, user) and resolve at run time.
- `default_env` is optional. Omit to require `--env` when the target has multiple envs (or let the TUI pick).
- If a manifest `[logs]` section defines `logs`, it supersedes any archetype-supplied `logs` command (e.g. `docker-unraid` has its own ssh-based `logs`). The manifest wins.

### CLI

```
./admin logs                     # TUI picker over log targets
./admin logs <target>            # follow from end, default env
./admin logs <target> --env prod # explicit env
./admin logs <target> --tail 500 # print last 500 lines, then follow
./admin logs <target> --all      # print whole file, then follow
./admin logs <target> --no-follow    # one-shot; combine with --tail or --all
```

Default behavior is **follow from end** — no history dump unless asked. Follow mode reopens the file on inode change or size shrink, so it handles both log rotation and truncation-style circular buffers. Remote tailing uses `tail -F` so the remote side handles rotation.

### When to suggest adding `[logs]`

- The user has one or more log files whose paths they can name.
- They want to stream those logs from `./admin` without remembering paths or writing shell aliases.
- They have dev vs. prod environments for the same logical log (with possibly different paths and hosts).

### What `[logs]` is **not**

- Not a log-aggregator, formatter, or filter. It's a file-streaming shortcut.
- No `--since <duration>` time-based filter. Use `--tail N` to bound output.
- Not a replacement for hooking into a live process (e.g. `docker logs -f`) — for that, an archetype shell command is still the right shape.

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

---
name: init-admin
description: Scaffold or audit a Python-based `admin` task runner with inline TUI menu for the current project. Detects project type, generates commands, and sets up log capture. Also audits existing admin scripts for missing standard features.
---

# /init-admin — Scaffold or Audit Project Admin Task Runner

Generate or audit a per-project `admin` script that imports from `admin_lib` (~/.admin/admin_lib/). Uses the `~/.admin/init-admin` bootstrap tool for generation and audit, then handles Claude Code UX (confirm, post-generation steps).

## Instructions

Follow these phases exactly. Do NOT skip phases or auto-confirm on behalf of the user.

### Phase 1: Detect and Preview

Run the init-admin tool in a dry-run fashion to show the user what will happen:

1. Check if `~/.admin/init-admin` exists. If not, tell the user to run `install.sh` from the admin-project-tool repo first.
2. Check if `./admin` already exists:
   - **If yes**: Run `~/.admin/init-admin --audit` to show the audit report. Also check if the admin script imports admin_lib at runtime (look for `sys.path.insert` pointing to `~/.admin` or `from admin_lib` without a bundled `# === admin_lib` header). If it does, **this is a critical problem** — the admin script is not self-contained and will break for anyone who doesn't have admin-project-tool installed. Tell the user: "This admin script references admin_lib at runtime instead of being bundled. It needs to be re-bundled with `~/.admin/bundle ./admin` so it's self-contained." Present results and ask if the user wants to regenerate (will require `--force`), re-bundle, make surgical fixes, or leave it.
   - **If no**: Detect the project type by checking filesystem markers:
     - `.xcodeproj` or `.xcworkspace` → apple
     - `Dockerfile` or `docker-compose.yml`/`compose.yml` → server
     - Otherwise → basic

### Phase 2: Confirm with User

Present:
1. Detected project type (or `--type` override if user specified)
2. Inferred project name (from directory basename)
3. Template that will be used
4. Key variables that will be filled in

Ask the user to confirm or adjust before generating.

### Phase 3: Generate

Run the init-admin tool to generate:

```bash
~/.admin/init-admin [--type TYPE] [--force] .
```

- Use `--type` if the user specified a type override
- Use `--force` if overwriting an existing admin file (user must have confirmed in Phase 2)

### Phase 3b: Web URL Setup (server projects with web component)

If the project has a web component (detected by `has_web_component()` in init-admin — checks for `public/`, `static/`, `index.html`, `server.js`, Express/Flask markers, etc.), the generated server template includes:

- `set_urls()` call with dev/prod URL placeholders
- `open` command for browser launching with live/down status

After generation, ask the user to update the `URLS` list in `./admin` with the correct dev and production URLs for their project. The TUI home screen and `--help` output will show URL liveness status automatically.

For audits: if the audit detects a web component but `set_urls` is missing, it warns. Suggest adding the URL config and `open` command.

### Phase 4: Post-generation

After generation succeeds:

1. **`.gitignore`** — add `tmp/` if not already present
2. **`.claude/skills/read-logs.md`** — create if missing (template below)
3. **`CLAUDE.local.md`** — create or update with auto-reload instruction (see below)
4. **Project CLAUDE.md** — if it references `admin.sh`, update to reference `admin`

### Phase 5: Auto-Reload Documentation

Ensure the project has a `CLAUDE.local.md` (gitignored, not committed) that instructs Claude to proactively reload after code changes:

```markdown
# Local Development Workflow

## Auto-reload after code changes

When `./admin dev` is active in another terminal, run `./admin reload` after making code changes to trigger a rebuild and relaunch. Don't wait for the user to manually restart — if the app is running, reload it so they can immediately see the effect of your changes.
```

Also ensure `CLAUDE.local.md` is in `.gitignore`.

### Phase 6: Commit

Ask the user if they want to commit the changes.

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

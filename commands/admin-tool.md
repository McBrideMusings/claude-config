---
name: admin-tool
description: Add a new subcommand to the project's Python `admin` task runner
user_invocable: true
args:
  - name: description
    description: "Command name and description, e.g. 'deploy -- push to production'"
    required: true
---

# /admin-tool — Add Command to Admin

Add a new subcommand to the project's `admin` task runner.

**Input:** $ARGUMENTS (e.g., `deploy -- push to production`, or just `deploy`)

## Instructions

### Phase 1: Parse Request

Extract from `$ARGUMENTS`:
- **Command name**: the first word (e.g., `deploy`)
- **Description**: everything after `--` if present, otherwise infer from the name

If the input is ambiguous or missing, ask the user to clarify.

### Phase 2: Read and Validate `admin`

1. Read the `admin` file in the project root
2. Verify it's the Python template format by checking for:
   - `@command` decorator pattern
   - `# --- Commands ---` and `# --- Inline TUI Menu ---` section markers
3. If `admin` doesn't exist or is a bash script:
   - Tell the user to run `/init-admin` first
   - Stop here

Check that the command name doesn't already exist in the registry.

### Phase 3: Design the Command

Based on the command name, project type (read CLAUDE.md and project files for context), and description:

1. Determine what shell commands the new subcommand should run
2. If ambiguous, ask the user what the command should do
3. Keep it simple -- most commands are just 1-3 shell calls via `run_cmd()`

### Phase 4: Insert the Command

1. Write a new `@command` function
2. Insert it **before** the `# --- Inline TUI Menu ---` marker
3. Follow the same style as existing commands in the file

**Simple command (no args):**
```python
@command("deploy", "Push to production")
def cmd_deploy(args):
    info("Deploying...")
    rc = run_cmd("git push origin main")
    if rc != 0:
        err("Deploy failed")
        sys.exit(1)
    ok("Deployed!")
```

**Command with options (use the standard arg parsing pattern):**
```python
@command("build", "Build the project (--release, --target TARGET)")
def cmd_build(args):
    release = False
    target = "default"

    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--release":
            release = True
        elif arg == "--target":
            i += 1
            if i >= len(args):
                err("--target requires a value")
                sys.exit(1)
            target = args[i]
        else:
            err(f"Unknown arg: {arg}")
            sys.exit(1)
        i += 1

    mode = "release" if release else "debug"
    info(f"Building {target} ({mode})...")
    rc = run_cmd(f"cargo build {'--release' if release else ''}")
    if rc != 0:
        sys.exit(1)
    ok("Build complete.")
```

**Command with background process (servers, watchers):**
```python
@command("serve", "Start dev server")
def cmd_serve(args):
    import threading

    info("Starting server on :8080...")
    proc = subprocess.Popen(
        ["python3", "-m", "http.server", "8080"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        bufsize=1, universal_newlines=True,
    )
    _children.append(proc)

    log_fh = open(LOG_FILE, "a")

    def stream():
        try:
            for line in proc.stdout:
                sys.stdout.write(line)
                sys.stdout.flush()
                log_fh.write(line)
                log_fh.flush()
        except (IOError, ValueError):
            pass

    threading.Thread(target=stream, daemon=True).start()

    info("Ctrl+C to stop")
    proc.wait()
    _children.remove(proc)
    log_fh.close()
```

### Phase 5: Verify

Run a syntax check to make sure the file is valid Python:

```bash
python3 -c "import ast; ast.parse(open('admin').read())"
```

If it fails, fix the syntax error and re-check.

Report the new command to the user. Suggest they test it with `./admin <command>`.

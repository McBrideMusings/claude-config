---
name: init-admin
description: "Scaffold or audit a Python-based `admin` task runner with inline TUI menu for the current project. Detects project type, generates commands, and sets up log capture. Also audits existing admin scripts for missing standard features."
user_invocable: true
---

# /init-admin — Scaffold or Audit Project Admin Task Runner

Generate a single-file Python `admin` script (no extension, shebang + chmod) with an inline TUI menu, ANSI-colored output, and `tmp/run.log` capture.

**If an `admin` script already exists**, this skill also serves as an **audit**: check it against the current template and report any missing standard features (SIGUSR1 reload, PID file cleanup, `reload` command, `atexit` import, etc.). Offer to bring it up to date.

## Instructions

Follow these phases exactly. Do NOT skip phases or auto-confirm on behalf of the user.

### Phase 1: Detect Project Type

Scan the repo root for these markers (multiple can match):

| Marker | Type | Default Subcommands |
|--------|------|---------------------|
| `*.xcodeproj` or `Package.swift` | Swift/Xcode | `dev`, `deploy`, `test`, `clean` |
| `Cargo.toml` | Rust | `run`, `build`, `test`, `clean`, `check`, `clippy` |
| `go.mod` | Go | `run`, `build`, `test`, `clean` |
| `docker-compose.yml` or `compose.yml` | Docker Compose | `up`, `down`, `build`, `logs`, `ps` |
| `pyproject.toml` or `setup.py` | Python | `run`, `test`, `lint`, `clean` |
| `Makefile` | Make | `build`, `test`, `clean` |
| `CMakeLists.txt` | CMake | `build`, `test`, `clean` |
| (none of above) | Generic | `help` only |

Also check:
- **Existing `admin.sh`** (bash) — read it, parse subcommands, offer to convert preserving them
- **Existing `admin`** (Python) — run the audit checklist (Phase 1b) before offering to overwrite
- **CLAUDE.md** or **README** for project name

### Phase 1b: Audit Existing Admin (if `admin` exists)

If a Python `admin` script already exists, audit it against the current template standard. Check for:

1. **`import atexit`** — required for PID file safety net
2. **`_ADMIN_PID_FILE`** constant — `/tmp/admin-run.pid`
3. **`_rebuild_requested`** flag and `_handle_rebuild_signal()` handler
4. **`_setup_reload()`** function — registers SIGUSR1 handler and writes PID file (shared across all platforms)
5. **`_poll_for_reload(is_running_fn)`** function — polls for SIGUSR1, `r` keypress, or process exit (shared across all platforms)
6. **`_cleanup_pid_file()`** function — called from `_cleanup_children` and registered with `atexit`
7. **`reload` command** — `@command("reload", ...)` that reads PID file and sends SIGUSR1
8. **`_setup_reload()` call** in ALL `dev` commands — every platform's dev function must call `_setup_reload()` on startup
9. **`_poll_for_reload()` call** in ALL `dev` commands — every platform's dev poll loop must use `_poll_for_reload(is_running_fn)` instead of a manual poll loop
10. **Rebuild loop** in ALL `dev` commands — outer `while True` that clears `_rebuild_requested`, builds, launches, polls for exit or signal

Report findings as a checklist (present/missing) and offer to add missing pieces. Do not rewrite the entire file — surgically add what's missing.

If multiple types match, combine subcommands (dedup by name).

### Phase 2: Confirm with User

Present:
1. Detected project type(s)
2. Inferred project name
3. Proposed subcommands with descriptions

Ask the user to confirm or adjust before generating.

### Phase 3: Generate `admin`

Write the file using the template structure below. Adapt subcommand implementations to the detected project type.

**For bash-to-Python conversions:** Translate each bash subcommand into an equivalent Python `@command` function that calls the same shell commands via `run_cmd()`. Preserve all behavior (arg parsing, environment variables, cleanup logic).

After writing, run: `chmod +x admin`

### Phase 4: Post-generation

1. **`.gitignore`** — add `tmp/` if not already present
2. **`.claude/skills/read-logs.md`** — create if missing (template below)
3. **Project CLAUDE.md** — if it references `admin.sh`, update to reference `admin`

Ask the user if they want to commit the changes.

---

## Design Strategy

The admin script is a **verb-first command runner** with optional sub-targets:

```
./admin <verb> [target] [flags]
```

### Naming conventions

- **Verbs are top-level commands:** `build`, `dev`, `test`, `clean`, `deploy`
- **Targets are positional args:** `./admin build web`, `./admin dev ios`, `./admin clean ios`
- **Command descriptions are terse:** `"Build Go binary: web | ios | server"` — verb phrase, then colon, then targets
- **No parenthetical help text in descriptions** — keep them scannable in the TUI
- **Env vars for deploy config** — `DEPLOY_HOST`, `DEPLOY_PORT`, etc. loaded from `.env`

### Command semantics

| Verb | Meaning |
|------|---------|
| `build` | Produce artifacts (binaries, Docker images, web bundles). No arg = default build. |
| `dev` | Build and run dev variant locally — separate bundle ID, dev icons, overlay watermark. Foreground, logs to terminal. Print clickable URLs for any services (see below). |
| `reload` | Signal a running `./admin dev` to rebuild and relaunch (SIGUSR1). Always generated alongside `dev`. |
| `test` | Run test suites. |
| `clean` | Remove build artifacts. No arg = clean all. |
| `deploy` | Build production variant + push to remote/install. No dev overrides. Print the deployed URL on success. |

### .env loading

The admin script auto-loads a `.env` file from the project root using `os.environ.setdefault` (won't override existing env vars). This keeps deploy credentials and host config out of the script. `.env` must be in `.gitignore`.

---

## Admin Template Structure

The generated `admin` file MUST follow this exact section structure with these comment markers (they enable `/admin-tool` to find insertion points):

```python
#!/usr/bin/env python3
"""admin -- project task runner. Python 3, stdlib only. Generated by /init-admin. Edit freely."""

import atexit
import glob
import os
import signal
import subprocess
import sys
from collections import OrderedDict

# --- Config ---
PROJECT_NAME = "ProjectName"
_ADMIN_PID_FILE = "/tmp/admin-run.pid"
_rebuild_requested = False


def _handle_rebuild_signal(signum, frame):
    global _rebuild_requested
    _rebuild_requested = True


def _setup_reload():
    """Register SIGUSR1 handler and write PID file. Works for all platforms."""
    signal.signal(signal.SIGUSR1, _handle_rebuild_signal)
    with open(_ADMIN_PID_FILE, "w") as f:
        f.write(str(os.getpid()))


def _poll_for_reload(is_running_fn, timeout=1):
    """Poll for reload signal, 'r' keypress, or process exit.

    Returns True if reload requested, False if process exited or Ctrl+C.
    Works for all dev loops regardless of platform.
    """
    import select
    import termios
    import tty

    global _rebuild_requested

    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)
        while True:
            if _rebuild_requested:
                return True
            if not is_running_fn():
                return False
            readable, _, _ = select.select([sys.stdin], [], [], timeout)
            if readable:
                ch = sys.stdin.read(1)
                if ch == 'r':
                    return True
    except KeyboardInterrupt:
        return False
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

# --- Utilities ---

class C:
    """ANSI color codes."""
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    RESET = "\033[0m"


def info(msg):
    print(f"{C.CYAN}{msg}{C.RESET}")

def ok(msg):
    print(f"{C.GREEN}{msg}{C.RESET}")

def warn(msg):
    print(f"{C.YELLOW}{msg}{C.RESET}", file=sys.stderr)

def err(msg):
    print(f"{C.RED}{msg}{C.RESET}", file=sys.stderr)


def _load_dotenv():
    """Load .env file from project root if it exists."""
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    if os.path.isfile(env_path):
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, val = line.partition("=")
                os.environ.setdefault(key.strip(), val.strip())

_load_dotenv()

LOG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tmp")
LOG_FILE = os.path.join(LOG_DIR, "run.log")

_children = []
_launched_process = None  # for apps launched via `open` (not a child process)


def _cleanup_pid_file():
    try:
        os.remove(_ADMIN_PID_FILE)
    except FileNotFoundError:
        pass


def _cleanup_children(signum=None, frame=None):
    if _launched_process:
        subprocess.run(["pkill", "-x", _launched_process], capture_output=True)
    for p in _children:
        try:
            p.terminate()
        except OSError:
            pass
    _cleanup_pid_file()
    if signum is not None:
        sys.exit(1)

signal.signal(signal.SIGINT, _cleanup_children)
signal.signal(signal.SIGTERM, _cleanup_children)


def run_cmd(cmd, shell=True, capture_log=True):
    """Run a command with line-buffered output, tee to tmp/run.log if capture_log is True."""
    os.makedirs(LOG_DIR, exist_ok=True)
    log_fh = None
    if capture_log:
        log_fh = open(LOG_FILE, "a")

    proc = subprocess.Popen(
        cmd, shell=shell, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        bufsize=1, universal_newlines=True,
    )
    _children.append(proc)
    try:
        for line in proc.stdout:
            sys.stdout.write(line)
            sys.stdout.flush()
            if log_fh:
                log_fh.write(line)
                log_fh.flush()
    finally:
        proc.wait()
        _children.remove(proc)
        if log_fh:
            log_fh.close()
    return proc.returncode


# --- Command Registry ---

_commands = OrderedDict()

def command(name, description):
    """Decorator to register a command."""
    def decorator(func):
        _commands[name] = {"func": func, "desc": description}
        return func
    return decorator


# --- Commands ---

# (generated commands go here, one @command function per subcommand)


@command("reload", "Signal a running './admin dev' to rebuild and relaunch")
def cmd_reload(args):
    if not os.path.exists(_ADMIN_PID_FILE):
        err("No admin run process found (no PID file at %s)" % _ADMIN_PID_FILE)
        sys.exit(1)
    with open(_ADMIN_PID_FILE) as f:
        pid = int(f.read().strip())
    try:
        os.kill(pid, signal.SIGUSR1)
    except ProcessLookupError:
        err("PID %d is not running (stale PID file)" % pid)
        os.remove(_ADMIN_PID_FILE)
        sys.exit(1)
    ok("Reload signal sent to PID %d" % pid)


# --- Inline TUI Menu ---

def _tui_menu():
    """Inline interactive menu for selecting a command."""
    if not sys.stdout.isatty():
        _print_help()
        return

    import tty
    import termios

    items = list(_commands.keys())
    sel = 0
    num = len(items)

    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)

    def read_key():
        try:
            tty.setraw(fd)
            ch = sys.stdin.read(1)
            if ch == "\x03":  # Ctrl+C
                return "quit"
            if ch == "\x1b":
                seq = sys.stdin.read(2)
                if seq == "[A": return "up"
                if seq == "[B": return "down"
                return "quit"
            return ch
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

    menu_lines = num + 1  # items + footer

    # Print header and reserve space for menu
    sys.stdout.write(f"{C.BOLD}{PROJECT_NAME}{C.RESET}\n\n")
    for _ in range(menu_lines):
        sys.stdout.write("\n")
    sys.stdout.flush()
    # Move cursor back up to start of menu area
    sys.stdout.write(f"\033[{menu_lines}A")
    sys.stdout.flush()

    def draw():
        sys.stdout.write("\033[s")  # save cursor
        for i, name in enumerate(items):
            desc = _commands[name]["desc"]
            sys.stdout.write("\033[2K")  # clear entire line
            if i == sel:
                sys.stdout.write(f"  {C.CYAN}{C.BOLD}> {name:<14}{C.RESET} {desc}")
            else:
                sys.stdout.write(f"    {C.DIM}{name:<14}{C.RESET} {desc}")
            sys.stdout.write("\n")
        sys.stdout.write("\033[2K")  # clear footer line
        sys.stdout.write(f"{C.DIM}  [arrows] navigate  [enter] run  [q] quit{C.RESET}")
        sys.stdout.write("\033[u")  # restore cursor
        sys.stdout.flush()

    try:
        while True:
            draw()
            key = read_key()
            if key in ("q", "Q", "quit"):
                sys.stdout.write(f"\033[{menu_lines}B\n")
                sys.stdout.flush()
                return
            elif key == "up":
                sel = (sel - 1) % num
            elif key == "down":
                sel = (sel + 1) % num
            elif key in ("\r", "\n"):
                # Clear menu area and run command
                for _ in range(menu_lines):
                    sys.stdout.write("\033[2K\n")
                sys.stdout.write(f"\033[{menu_lines}A")
                sys.stdout.flush()
                info(f"./admin {items[sel]}")
                print()
                os.makedirs(LOG_DIR, exist_ok=True)
                open(LOG_FILE, "w").close()
                _commands[items[sel]]["func"]([])
                return
    except (KeyboardInterrupt, EOFError):
        sys.stdout.write(f"\033[{menu_lines}B\n")
        sys.stdout.flush()
        return
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)


def _print_help():
    """Print help text (non-TTY fallback and --help)."""
    print(f"{C.BOLD}{PROJECT_NAME}{C.RESET}")
    print(f"Usage: ./admin <command> [args...]\n")
    print("Commands:")
    for name, cmd_info in _commands.items():
        print(f"  {C.CYAN}{name:<16}{C.RESET} {cmd_info['desc']}")
    print(f"\nRun {C.DIM}./admin{C.RESET} with no args for interactive menu.")


# --- Main ---

def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    if len(sys.argv) < 2:
        _tui_menu()
        return

    cmd_name = sys.argv[1]
    if cmd_name in ("-h", "--help", "help"):
        _print_help()
        return

    if cmd_name not in _commands:
        err(f"Unknown command: {cmd_name}")
        _print_help()
        sys.exit(1)

    # Clear log file for fresh run
    os.makedirs(LOG_DIR, exist_ok=True)
    open(LOG_FILE, "w").close()

    _commands[cmd_name]["func"](sys.argv[2:])


if __name__ == "__main__":
    main()
```

### Key patterns to follow:

**Inline TUI (no curses):**
- Uses `tty`/`termios` for raw keypress reading — no curses, no full-screen clear
- Pre-allocates blank lines for menu area, then uses `\033[s`/`\033[u` (save/restore cursor) + `\033[2K` (clear line) to redraw in place
- On selection: clears menu area, prints `./admin <cmd>` as a breadcrumb, then runs command
- Arrow keys to navigate, enter to run, q/Esc/Ctrl+C to quit
- Falls back to `_print_help()` in non-TTY environments (pipes, CI)

**`run_cmd()`:**
- `Popen` with line-buffered stdout, writes each line to both `sys.stdout` and `tmp/run.log`
- Returns the process exit code for callers to check
- Registers process in `_children` for signal cleanup

**`@command` decorator:**
- Registers into `_commands` OrderedDict — both TUI and CLI use it
- Every command function takes `args` (list of strings from sys.argv or empty list from TUI)
- Ordering in the file determines ordering in the menu

**Arg parsing pattern for commands with sub-targets:**
```python
@command("build", "Build Go binary: web | ios | server")
def cmd_build(args):
    target = args[0] if args else ""

    if target == "web":
        info("Building web client...")
        return run_cmd("cd web && npm run build")

    elif target == "server":
        info("Building Docker images...")
        # build steps here
        return 0

    elif target == "":
        info("Building Go binary...")
        return run_cmd("go build -o app ./cmd/app")

    else:
        err(f"Unknown build target: {target}")
        return 1
```

**Signal handling:**
- `_children` list tracks all spawned subprocesses
- `_launched_process` tracks apps launched via `open` (not child processes, so not in `_children`)
- SIGINT/SIGTERM handler kills `_launched_process` by name then terminates all children before exiting
- Long-running processes (servers, log streams) append to `_children` on spawn, remove on exit

**Launching GUI apps (macOS):**
- Always use `open <path.app>` instead of running the binary directly — required for LaunchServices registration (menu bar, dock, etc.)
- Set `global _launched_process; _launched_process = PROCESS_NAME` before `open` so signal handler can kill it
- `open` returns immediately; poll with `pgrep -x` to wait for the app to exit
- Wait for process to appear before polling (small retry loop) to avoid race condition
- Kill any existing instance before launching to ensure fresh code is tested

**Background process streaming (servers, log tails, watchers):**
```python
import threading

proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                        bufsize=1, universal_newlines=True)
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
```

**Interactive reload (for projects without hot reload):**
- ALL `dev` commands (every platform) call `_setup_reload()` on startup — registers SIGUSR1 handler and writes PID file
- ALL `dev` commands use `_poll_for_reload(is_running_fn)` for their poll loop — handles SIGUSR1, `r` keypress, and process exit detection
- The user can press `r` in the terminal to trigger a rebuild+relaunch — no need for a separate terminal
- `./admin reload` from another terminal sends SIGUSR1 via the PID file
- On reload: kill the running app, tear down log stream, rebuild, relaunch, start fresh log stream
- On natural app exit: clean up and exit admin
- PID file is removed on exit via `_cleanup_children` and `atexit` safety net
- `_rebuild_requested` is cleared at the top of each build cycle to prevent double-builds from rapid signals
- CRITICAL: every platform gets the same reload behavior — never implement reload for one platform and not others

**Printing service URLs:**
- When `dev` or `deploy` starts a web server or any network service, always print the full clickable URL (`http://localhost:PORT`) — not just "listening on port 9090"
- The app itself should print `http://localhost:PORT` in its listen callback, and the admin `dev` command should also print the URL before launching
- For `deploy`, print the remote URL on success: `http://HOST:PORT`
- URLs in terminals are clickable — use this. A bare port number is not actionable.

**Dev/deploy separation (Xcode projects):**

For Xcode projects, `dev` and `deploy` produce distinct builds that can coexist on the same device:

- **Parameterized bundle IDs:** Add a user-defined build setting `SCRATCHPAD_BUNDLE_ID_SUFFIX` (or `<PROJECT>_BUNDLE_ID_SUFFIX`) defaulting to empty string at the project level. All `PRODUCT_BUNDLE_IDENTIFIER` values append `$(…_BUNDLE_ID_SUFFIX)`. Entitlements use the same variable for KVStore IDs and app groups.
- **Dev build overrides:** The `dev` command passes extra xcodebuild settings: `<PROJECT>_BUNDLE_ID_SUFFIX=.dev INFOPLIST_KEY_CFBundleDisplayName="<Name> DEV" INFOPLIST_KEY_CFBundleName="<Name> DEV"`
- **Runtime detection:** Since SPM packages don't inherit `SWIFT_ACTIVE_COMPILATION_CONDITIONS`, use bundle ID detection at runtime: `Bundle.main.bundleIdentifier?.hasSuffix(".dev") == true`
- **Dev icon generation:** Create `scripts/generate_dev_icons.py` (requires PIL/Pillow) that adds a diagonal red "DEV" stripe across the bottom-right corner of all app icons. The `dev` command backs up production icons, generates dev icons, copies them over, builds, then restores originals in a `finally` block.
- **`--install` flag:** On macOS, `dev --install` copies the built app to `/Applications/<Name> DEV.app` so it can coexist with the production `/Applications/<Name>.app`.
- **Process management:** Dev and prod have the same process name (determined by `PRODUCT_NAME`), so use path-based matching (`pgrep -af` + checking for DerivedData or "DEV.app" in the path) instead of `pkill -x`.

**Dev icon generation snippet (`scripts/generate_dev_icons.py`):**
```python
#!/usr/bin/env python3
"""Generate dev build icons with a diagonal red 'DEV' stripe across the bottom-right corner."""
import os, sys
from PIL import Image, ImageDraw, ImageFont

def add_dev_banner(img):
    size = img.width
    canvas_size = size * 2
    banner_height = int(size * 0.22)

    banner_img = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    banner_draw = ImageDraw.Draw(banner_img)

    by1 = (canvas_size - banner_height) // 2
    by2 = by1 + banner_height
    banner_draw.rectangle([0, by1, canvas_size, by2], fill=(220, 40, 40, 240))

    font_size = int(size * 0.14)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFCompact.ttf", font_size)
    except (OSError, IOError):
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except (OSError, IOError):
            font = ImageFont.load_default()

    mid_x = canvas_size // 2
    mid_y = by1 + banner_height // 2
    banner_draw.text((mid_x, mid_y), "DEV", fill=(255, 255, 255, 255), font=font, anchor="mm")

    banner_img = banner_img.rotate(35, center=(canvas_size // 2, canvas_size // 2), resample=Image.BICUBIC)

    crop_x = (canvas_size // 2) - int(size * 0.72)
    crop_y = (canvas_size // 2) - int(size * 0.72)
    cropped = banner_img.crop((crop_x, crop_y, crop_x + size, crop_y + size))

    img.paste(cropped, (0, 0), cropped)
    return img
```

**Other conventions:**
- `os.chdir` to script directory in `main()` so paths are always relative to project root
- Log file cleared at start of each invocation (CLI and TUI)
- `info()` for status, `ok()` for success, `warn()` for warnings, `err()` for errors
- Config constants at top of file for easy customization
- No third-party dependencies — stdlib only (except `scripts/generate_dev_icons.py` which uses PIL)
- `.env` auto-loaded for deploy config (uses `setdefault`, won't override existing env vars)

## read-logs.md Template

If `.claude/skills/read-logs.md` doesn't exist, create it:

```markdown
---
name: read-logs
description: Read runtime logs from the last ./admin dev. Use when the user says they ran the app and something didn't work, or when you need to check what happened during the last run.
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

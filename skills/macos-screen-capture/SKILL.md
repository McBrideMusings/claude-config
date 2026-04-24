---
name: macos-screen-capture
description: Use on macOS when you need to take a screenshot programmatically — of the whole screen, a specific window, a region, or an app window by name. Covers the `screencapture` CLI, finding window IDs via CoreGraphics, and the Screen Recording TCC permission that will block captures until granted.
---

# macOS Screen Capture

macOS ships `screencapture` in `/usr/sbin/screencapture`. It can grab the screen, a window, a region, or open the annotation UI. All of it is scriptable.

## The TCC blocker (read this first)

Every screen-reading API on macOS goes through the **Screen Recording** privacy permission. If the calling process has not been granted it, `screencapture` exits with `could not create image from display` and writes nothing to disk. The permission is keyed on the *app that spawned the process* — usually your terminal (Ghostty, Terminal.app, iTerm) or the harness running you (Claude Code).

Grant it in: **System Settings → Privacy & Security → Screen Recording** → toggle on the relevant app. The app must be restarted after the toggle (macOS requirement, not a bug).

Check quickly whether you have permission:
```bash
screencapture -x /tmp/tcc-check.png 2>&1 && echo ok || echo blocked
```

If blocked, stop and ask the user to grant permission — trying again without that step will keep failing.

## Common invocations

Whole screen, silent (no shutter sound), no preview:
```bash
screencapture -x /tmp/out.png
```

Whole screen, hide the mouse cursor:
```bash
screencapture -C -x /tmp/out.png   # -C *shows* cursor; omit to hide
screencapture -x /tmp/out.png      # cursor hidden by default
```

A rectangular region by coordinates (x, y, width, height — in CSS-style logical points, top-left origin):
```bash
screencapture -R 100,100,800,600 -x /tmp/region.png
```

Main display only (in a multi-monitor setup):
```bash
screencapture -m -x /tmp/main.png
```

JPEG instead of PNG (smaller, lossy):
```bash
screencapture -x -t jpg /tmp/out.jpg
```

## Capturing a specific window

Two paths. The easy one is interactive, the scriptable one requires looking up a window ID.

**Interactive (user clicks the window):**
```bash
screencapture -w /tmp/window.png        # click-to-pick
screencapture -W /tmp/window.png        # space-then-click, window picker mode
```

Not useful for unattended capture.

**By window ID (scriptable):**
```bash
screencapture -l <window_id> -x /tmp/window.png
```

Finding the window ID of a known app — use CoreGraphics via a small Swift one-liner:

```bash
swift -e '
import CoreGraphics
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
for w in list {
  let owner = w[kCGWindowOwnerName as String] as? String ?? ""
  let name  = w[kCGWindowName as String] as? String ?? ""
  let id    = w[kCGWindowNumber as String] as? Int ?? 0
  if owner == "forge" { print(id, name) }
}
'
```

Swap `"forge"` for the app's process name (what you'd see in `ps` / Activity Monitor). You can also match on `name` (window title) if the app has multiple windows.

Wrap it in a shell function so calls are one-liners:

```bash
win_id_for() {
  swift -e "
import CoreGraphics
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
for w in list {
  if (w[kCGWindowOwnerName as String] as? String) == \"$1\" {
    print(w[kCGWindowNumber as String] as? Int ?? 0)
    exit(0)
  }
}
exit(1)
"
}
# usage: screencapture -l "$(win_id_for forge)" -x /tmp/forge.png
```

## Writing to stdout

`screencapture -` writes the PNG to stdout, useful for piping:
```bash
screencapture -x - > /tmp/pipe.png
```

Combined with `base64`, this is how you'd ship a capture back over a non-file channel:
```bash
screencapture -x - | base64
```

## Finding a window you just launched

If you launched an app in the background and need to wait for its window to exist before capturing:
```bash
app_name="forge"
for _ in {1..20}; do
  id=$(win_id_for "$app_name") && break
  sleep 0.1
done
screencapture -l "$id" -x /tmp/out.png
```

20 × 100ms = 2s max wait. Adjust as needed.

## Useful flags cheat sheet

| Flag | Meaning |
|---|---|
| `-x` | Silent (no shutter sound, no preview) |
| `-o` | Omit window shadow (window captures only) |
| `-a` | Include window shadow (window captures only) |
| `-c` | Copy to clipboard instead of saving |
| `-C` | Show mouse cursor in capture |
| `-l <id>` | Capture window by CGWindowID |
| `-R x,y,w,h` | Capture rectangular region |
| `-m` | Capture only main display |
| `-t png\|jpg\|pdf\|tiff\|bmp` | Output format |
| `-D <display_num>` | Capture a specific display (1-indexed) |
| `-r` | Do not add dpi meta tag |

## Reading the captured image

After `screencapture` writes a PNG, you can Read it back as an image (Claude can view PNG/JPEG directly). A typical loop:

1. `screencapture -x /tmp/out.png` (with permission granted)
2. Use the Read tool on `/tmp/out.png` to view it.

## When `screencapture` is not an option

If TCC Screen Recording cannot be granted (sandboxed environment, remote host, etc.), the alternative is to have the application itself write its framebuffer to disk on demand — no OS permissions involved. For graphical apps this means plumbing a screenshot hook into the render loop and writing a PNG via `stb_image_write` or similar. That is a different skill set, not `screencapture`.

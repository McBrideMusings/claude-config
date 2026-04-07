---
name: cmux-browser
description: Use when you need to automate browser interaction for testing, previewing, or verifying web UIs in cmux terminal. Replaces Playwright MCP — use cmux browser commands via Bash tool instead.
---

# cmux Browser Automation

cmux has built-in browser automation. Use `cmux browser` commands via the **Bash tool** instead of Playwright MCP tools.

## Surface Targeting & Tab Reuse

Every command targets a browser surface. **Always try to reuse an existing tab before opening a new one.**

```bash
# 1. List existing tabs to check for the target URL
cmux browser identify

# 2. For each surface, check its URL
cmux browser surface:N url
```

If a tab is already open on the target site (same origin), **reuse it** with `navigate` instead of `open`:
```bash
# Reuse existing tab — navigate to the desired page
cmux browser surface:N navigate http://localhost:3000/new-page --snapshot-after
```

Only use `open` when no existing tab matches:
```bash
# No matching tab found — open a new one
cmux browser open http://localhost:3000
```

Both targeting syntaxes are equivalent:
```bash
cmux browser surface:2 url
cmux browser --surface surface:2 url
```

## Workflow Pattern

```bash
# 1. Check for existing tabs first
cmux browser identify
cmux browser surface:N url              # Check if already on target site

# 2a. Reuse existing tab
cmux browser surface:N navigate http://localhost:3000 --snapshot-after

# 2b. OR open new if none exists
cmux browser open http://localhost:3000

# 3. Take a snapshot (accessibility tree — preferred for actions)
cmux browser surface:N snapshot --interactive --compact

# 4. Take a screenshot (visual check — read with Read tool to see image)
cmux browser surface:N screenshot --out /tmp/page.png

# 5. Interact
cmux browser surface:N click "#my-button" --snapshot-after
cmux browser surface:N fill "#email" --text "test@example.com"

# 6. Verify
cmux browser surface:N get text "h1"
cmux browser surface:N is visible "#success-message"
```

## Key Commands

### Navigation
```bash
cmux browser open <url>                    # Open URL in new tab
cmux browser open-split <url>              # Open in split view
cmux browser surface:N navigate <url>      # Navigate existing surface
cmux browser surface:N back/forward/reload
cmux browser surface:N url                 # Get current URL
```

### Inspection
```bash
cmux browser surface:N snapshot --interactive --compact    # Accessibility tree
cmux browser surface:N snapshot --selector "main" --max-depth 5
cmux browser surface:N screenshot --out /tmp/shot.png      # Visual screenshot
cmux browser surface:N get title
cmux browser surface:N get text "h1"
cmux browser surface:N get html "main"
cmux browser surface:N get value "#email"
cmux browser surface:N get attr "a.primary" --attr href
cmux browser surface:N get count ".row"
cmux browser surface:N get box "#checkout"
cmux browser surface:N is visible "#el"
cmux browser surface:N is enabled "button"
cmux browser surface:N is checked "#terms"
```

### Interaction
```bash
cmux browser surface:N click "selector" --snapshot-after
cmux browser surface:N dblclick "selector"
cmux browser surface:N hover "selector"
cmux browser surface:N focus "selector"
cmux browser surface:N fill "selector" --text "value"
cmux browser surface:N type "selector" "text"
cmux browser surface:N press Enter
cmux browser surface:N select "#dropdown" "option-value"
cmux browser surface:N check "#checkbox"
cmux browser surface:N uncheck "#checkbox"
cmux browser surface:N scroll --dy 800 --snapshot-after
cmux browser surface:N scroll --selector "#log" --dy 400
cmux browser surface:N scroll-into-view "#pricing"
```

### Waiting
```bash
cmux browser surface:N wait --selector "#el" --timeout-ms 10000
cmux browser surface:N wait --text "Order confirmed"
cmux browser surface:N wait --url-contains "/dashboard"
cmux browser surface:N wait --function "window.__ready === true"
cmux browser surface:N wait --load-state complete --timeout-ms 15000
```

### Finding Elements
```bash
cmux browser surface:N find role button --name "Continue"
cmux browser surface:N find text "Order confirmed"
cmux browser surface:N find label "Email"
cmux browser surface:N find placeholder "Search"
cmux browser surface:N find testid "save-btn"
cmux browser surface:N find first ".row"
cmux browser surface:N find nth 2 ".row"
```

### JavaScript
```bash
cmux browser surface:N eval "document.title"
cmux browser surface:N addscript "document.querySelector('#name')?.focus()"
cmux browser surface:N addstyle "#banner { display: none !important; }"
```

### State & Sessions
```bash
cmux browser surface:N cookies get
cmux browser surface:N cookies set session_id abc123 --domain example.com
cmux browser surface:N cookies clear --all
cmux browser surface:N storage local set theme dark
cmux browser surface:N storage local get theme
cmux browser surface:N state save /tmp/session.json
cmux browser surface:N state load /tmp/session.json
```

### Tabs
```bash
cmux browser surface:N tab list
cmux browser surface:N tab new <url>
cmux browser surface:N tab switch 1
cmux browser surface:N tab close
```

### Console & Errors
```bash
cmux browser surface:N console list
cmux browser surface:N errors list
```

### Dialogs & Frames
```bash
cmux browser surface:N dialog accept
cmux browser surface:N dialog dismiss
cmux browser surface:N frame "iframe[name='checkout']"
cmux browser surface:N frame main
```

## Tips

- **`--snapshot-after`**: Add to any mutating command for instant verification
- **Snapshot vs screenshot**: Snapshot gives the accessibility tree (actionable data). Screenshot gives a visual PNG (read it with the Read tool to see the image). Use snapshot for automation, screenshot for visual verification.
- **Selectors**: Standard CSS selectors work everywhere
- Prefer `fill` over `type` for form fields — `fill` clears first, `type` appends
- Use `wait` before interacting with dynamically loaded content

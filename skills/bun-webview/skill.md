---
name: bun-webview
description: Use Bun's built-in test runner and WebView for testing, debugging, and verifying UI changes in Bun projects (projects with a bun.lockb). Use after implementing any UI change to take a screenshot and confirm it works. Also use for ad-hoc diagnostics when something looks wrong in the browser.
---

# Bun WebView — Testing & Diagnostics

`Bun.WebView` is built into Bun — no install, no Playwright, no Puppeteer. On macOS it uses native WKWebView. Run tests with `bun test`.

## Applies to

Projects with a `bun.lockb` at the root. Check with:
```bash
ls bun.lockb
```

## When to use

- **After implementing any UI change** — take a screenshot to confirm the result looks right before reporting done.
- **Debugging** — evaluate DOM state, read console output, inspect what the page actually rendered.
- **Diagnostics** — quickly verify an endpoint or UI flow without opening a browser manually.

Do not set up a formal test suite unless explicitly asked. This is an ad-hoc tool used inline during development.

## Basic pattern

```ts
await using view = new Bun.WebView({ headless: true });
await view.navigate("http://localhost:3300");
await Bun.sleep(2000); // wait for app to settle / SSE to hydrate
const title = await view.evaluate("document.title");
await Bun.write("/tmp/screenshot.png", await view.screenshot({ format: "png" }));
// Read the file to display it inline
```

Then `Read /tmp/screenshot.png` to display the screenshot in the conversation.

## Key APIs

```ts
await view.navigate(url)               // load a page
await view.evaluate(jsExpression)      // run JS, returns JSON-serialized result
await view.click(selector)             // click an element
await view.type(selector, text)        // type into an input
await view.press(key)                  // keyboard event (e.g. "Enter", "Escape")
await view.scroll(selector, x, y)     // scroll
await Bun.sleep(ms)                    // wait between actions
await view.screenshot({ format: "png" | "jpeg" | "webp" })  // returns Blob
```

## Running as a script (ad-hoc)

Write a `.ts` file and run it directly — no test framework needed:
```bash
bun run /tmp/my-check.ts
```

## Running as a test

```ts
import { test, expect } from "bun:test";

test("page loads", async () => {
  await using view = new Bun.WebView({ headless: true });
  await view.navigate("http://localhost:3300");
  await Bun.sleep(1500);
  const title = await view.evaluate("document.title");
  expect(title).toBe("Recodarr");
});
```

```bash
bun test path/to/test.ts
```

## Notes

- `screenshot()` returns a `Blob` — use `.size` not `.byteLength`. Save with `Bun.write(path, blob)`.
- `evaluate()` returns JSON-serialized results — complex DOM objects won't serialize; extract primitives explicitly.
- Operations on the same view must be awaited sequentially — parallel calls throw `ERR_INVALID_STATE`.
- `await using` handles cleanup automatically. If not used, call `await view[Symbol.asyncDispose]()` manually.
- Wait time after `navigate()` depends on the app — SSE-driven apps need longer to hydrate (1.5–3s typical).
- The WebView is offscreen; no window appears.

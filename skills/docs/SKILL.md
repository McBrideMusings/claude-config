---
name: docs
description: "Bootstrap, audit, or migrate a VitePress documentation site that follows the standard layout (PRD / roadmap / file-map universal; api / architecture / guide / development opt-in). Wires into the admin runner, updates project CLAUDE.md, and migrates legacy docs to GitHub issues."
user_invocable: true
---

# /docs — VitePress Documentation Site

A docs site is one of three things at any given moment:

- **Greenfield** — no `docs/` folder. Bootstrap the standard layout.
- **Misshapen** — `docs/` has loose markdown but no VitePress, or has phase/task/roadmap files cluttering the root, or is missing universal files. Audit, propose migrations, and align it.
- **Aligned** — `docs/` matches the standard layout. Verify, optionally refresh stubs, and exit clean.

This skill detects which case you're in and runs the right flow.

---

## Critical rule: treat VitePress as a black box

Don't read VitePress's `node_modules/` source or its theme internals. The library works; the integration points are stable. Read its config and your own markdown — that's it. If a build error references VitePress internals, the fix is almost always a markdown gotcha or the `.mts` rename, not a deep dive into VitePress.

The only files this skill should read or write:

- The project's `package.json` (for the `docs:dev` script)
- The project's `admin.toml` (for the `[commands.docs]` entry, if admin is present)
- The project's `CLAUDE.md` (for the Documentation section)
- The project's `.gitignore`
- Files under `docs/` itself
- This skill file

---

## Standard layout

### Universal files — every project gets these

```
docs/
├── .vitepress/config.mts            # VitePress config (note .mts — ESM-only; see ESM gotcha below)
├── index.md                         # VitePress home/landing
├── PRD.md                           # What this product is. The "spec."
├── roadmap.md                       # Now / Next / Later / Deferred
└── file-map.md                      # Concise repo navigation
```

Rationale: every project has a "what" (PRD), a "where next" (roadmap), and a "where things are" (file-map). These are the three load-bearing docs that decay fastest if not maintained.

### Opt-in files — added when project shape calls for them

```
docs/
├── api.md                           # External API surface (HTTP, plugin API, GraphQL, library API, CLI)
├── architecture/                    # Multi-subsystem repos
│   ├── overview.md
│   └── <subsystem>.md ...
├── guide/                           # End-user-facing surface
│   ├── getting-started.md
│   └── <feature>.md ...
└── development/                     # Contributor-facing
    ├── setup.md
    ├── testing.md
    ├── code-style.md
    ├── troubleshooting.md
    └── deployment.md
```

### Heuristics for opt-in (any one is sufficient)

| Folder/file | Trigger |
|---|---|
| `api.md` | `package.json` declares `"main"` / `"bin"` / `"exports"` / peer/library deps; OR GraphQL / OpenAPI schema present (`*.graphql`, `openapi.{yml,yaml,json}`); OR plugin manifest pattern (`<name>.yml` next to `package.json`); OR CLI entry (`bin/`, `cmd/` for Go, shebang scripts); OR HTTP server framework imported (Express / Fastify / Hono / Axum / etc.) |
| `architecture/` | 3+ top-level source folders, OR clearly multi-subsystem (web + iOS, frontend + backend, monorepo) |
| `guide/` | User-facing surface (web app, CLI tool, end-user product — not a library) |
| `development/` | Git repo with > 1 contributor in history, OR CI configured, OR open-source (LICENSE + non-private remote) |

### Roadmap shape

`roadmap.md` is a single file with four sections:

```md
# Roadmap

> Direction, not task tracking. Promote items to GitHub issues once they're concrete enough to act on.

## Now
What's actively being worked on.

## Next
Next 1–3 things on deck.

## Later
Things we want eventually.

## Deferred / won't fix
Things we considered and decided against, or punted indefinitely. Keep these so we don't re-litigate.
```

Don't create a `docs/roadmap/` folder unless the user explicitly asks — multi-track is the exception. If you find one during audit, propose collapsing back to a single file unless the project has 3+ active long-running tracks.

---

## Project CLAUDE.md integration

Every audit / bootstrap run ensures the project's `CLAUDE.md` has a **Documentation** section like this. If missing, add it. If present but stale (different file list, no update-when table), update it.

```md
## Documentation

This project has a VitePress docs site under `docs/`. Run `./admin docs` (or `npm run docs:dev`) to read it on `http://localhost:5193`.

Keep these in sync as you work:

| File | Update when |
|---|---|
| `docs/PRD.md` | Product behavior, scope, or surface area changes |
| `docs/roadmap.md` | Direction shifts, an initiative ships, or a decision is deferred |
| `docs/file-map.md` | Major files/folders are added, removed, renamed, or moved |
| `docs/api.md` | (if exists) external API surface changes |
| `docs/architecture/*` | (if exists) subsystem behavior changes |

Don't write new top-level planning / phase / feature docs in `docs/` — file a GitHub issue instead. `roadmap.md` is the only forward-looking doc.
```

Adjust the table to drop rows whose files don't exist (e.g., omit the `api.md` row in projects that don't have one).

---

## Instructions

### Phase 1: Detect current state

Inspect the project:

1. Does `docs/` exist?
2. Does `docs/.vitepress/config.mts` (or `.ts`) exist?
3. Which universal files (`PRD.md`, `roadmap.md`, `file-map.md`, `index.md`) exist?
4. What other `docs/*.md` files exist? (For migration detection.)
5. Does `package.json` have a `docs:dev` script? Is `vitepress` in `devDependencies`?
6. Does `admin.toml` exist? Does it have `[commands.docs]`?
7. Does `CLAUDE.md` exist? Does it have a `## Documentation` section?

Decide which flow:

| State | Flow |
|---|---|
| No `docs/` | **Phase 2a — Bootstrap** |
| `docs/` exists, no `.vitepress/` | **Phase 2c — Migrate** |
| Both exist | **Phase 2b — Audit** |

### Phase 2a: Bootstrap (greenfield)

Run these in order:

1. **Install VitePress** — `npm add -D vitepress` (or `bun add`, `pnpm add`, etc. — match the project's package manager).
2. **Apply opt-in heuristics** to decide which folders/files to create. Tell the user which opt-ins matched and why.
3. **Create the universal files:**
   - `docs/.vitepress/config.mts` (note `.mts` — see ESM gotcha)
   - `docs/index.md` with `layout: home` frontmatter
   - `docs/PRD.md` — stub with H1 + intro inviting the user to fill in product spec
   - `docs/roadmap.md` — stub with the four sections (Now / Next / Later / Deferred)
   - `docs/file-map.md` — generate from a quick scan of the project's top-level structure
4. **Create opt-in scaffolds** for whichever heuristics matched. Stub each new file with H1 + a one-line "TODO: fill in" so the user has a starting point.
5. **Wire `package.json`** — add `"docs:dev": "vitepress dev docs --port {DOCS_PORT}"` (default port `5193`, or main app port + 20 if a main app port exists). **Do not add `docs:build` or `docs:preview` unless the project deploys docs** — heuristic: `.github/workflows/*` mentions Pages/Netlify/Vercel/`vitepress build`, OR `package.json` has `gh-pages` / `docs-deploy` script.
6. **Wire admin.toml if present:**
   ```toml
   [commands.docs]
   kind = "npm"
   desc = "serve VitePress docs site with hot reload on http://localhost:NNNN"
   run  = "docs:dev"
   ```
   Use `kind = "npm"` (not `kind = "shell"`) — this is the dedicated renderer that auto-detects npm vs bun (via `bun.lockb`), runs `<pkg> run <script>`, and produces standardized success/error output. The `run` field is just the npm script name, not the full `npm run ...` command.

   Add `"docs"` to the `order` array after `clean`. Note that `logs` (registered automatically via `[logs.*]`) and any logs-aliasing utility commands should NOT appear in `order` — the generator validates strictly and rejects unknown command names. Standard order shape: `["build", "dev", "deploy", "---", "test", "clean", "docs", "icons", "reload"]` (omit any of these the project doesn't have).

   Then run `~/.admin/init-admin --regenerate . --force-dirty` and verify with `./admin --help`.
7. **Update project `CLAUDE.md`** — add the Documentation section.
8. **Append to `.gitignore`** if not already present:
   ```
   docs/.vitepress/cache
   docs/.vitepress/dist
   ```
9. **Verify Phase 3.**

### Phase 2b: Audit (existing aligned setup)

Walk through this checklist. Apply mechanical fixes silently and report them in a summary; propose substantive changes with a diff.

**Mechanical (apply, then report in summary):**

1. **Config extension** — if `docs/.vitepress/config.ts` exists (not `.mts`), rename to `.mts`. The build will fail otherwise on CommonJS projects.
2. **Filename renames** — if `docs/api-surface.md` exists, rename to `docs/api.md` and update any references.
3. **Roadmap shape** — if `docs/roadmap/` is a folder with only an `index.md` (or only one or two files), collapse to single `docs/roadmap.md`. Skip if the folder has 3+ initiative files (genuine multi-track).
4. **Missing universal stubs** — create empty stubs for any of `PRD.md` / `roadmap.md` / `file-map.md` / `index.md` that don't exist.
5. **`.gitignore` entries** — add cache/dist lines if missing.
6. **VitePress install** — if not in `devDependencies`, install.
7. **`docs:dev` script** — add if missing (port `5193` or main+20).
8. **`admin.toml` `[commands.docs]`** — if `admin.toml` exists and `docs` command is missing or has sub-targets, fix it (single shell command).
9. **`CLAUDE.md` Documentation section** — add if missing.

**Substantive (propose with diff, ask before applying):**

1. **Legacy planning docs** — if you find `PHASE_*.md`, `FUTURE_FEATURES.md`, `PROJECT_PLAN.md`, `tasks/`, or any non-standard top-level `docs/*.md` that isn't part of the standard layout, propose:
   - Migration: open GitHub issues for unimplemented items not already on the issue tracker
   - Deletion of the source file
   Use the same shape as the stash-reels migration: cross-reference existing issues, only file new ones for genuinely uncovered work, present the list before bulk-creating.
2. **Opt-in changes** — if heuristics now suggest a folder that wasn't there before (e.g., project gained an HTTP server → suggest `api.md`), propose creating it.
3. **`CLAUDE.md` update-when table** — if the Documentation section exists but is missing the update-when table, propose updating it to the standard shape.

**Report a summary at the end:** what was applied mechanically, what was proposed, what's still pending.

### Phase 2c: Migrate (markdown-only, no VitePress)

Project has `docs/` with markdown files but no VitePress installed. Bootstrap VitePress on top, categorize the existing markdown into the standard layout.

1. Run Phase 2a's install + universal file creation (don't overwrite existing `PRD.md` / `roadmap.md` / `file-map.md` if they happen to exist with content).
2. **Categorize existing files** — for each loose `docs/*.md`, propose where it belongs:
   - Architectural deep-dive → `docs/architecture/<name>.md`
   - User guide → `docs/guide/<name>.md`
   - Contributor doc → `docs/development/<name>.md`
   - Anything that looks like a phase/feature/task doc → propose migration to GitHub issues
3. **Show the migration table to the user** before moving anything. Don't auto-delete originals.
4. Wire admin / CLAUDE.md / .gitignore as in Phase 2a.

### Phase 3: Verify

1. Boot the dev server briefly to confirm it starts cleanly:
   ```bash
   npm run docs:dev &
   DEV_PID=$!
   sleep 4
   kill $DEV_PID 2>/dev/null
   wait $DEV_PID 2>/dev/null
   ```
   Look for `Local: http://localhost:NNNN/` in the output.
2. **Only if the project deploys docs** (heuristic above), also run `npm run docs:build` and confirm clean.
3. **If `admin.toml` was wired**, run `./admin docs` for a few seconds and confirm it boots VitePress with HMR.

### Phase 4: Commit

After everything verifies clean, commit:

- All `docs/` files, `package.json`, `CLAUDE.md`, `.gitignore`, `admin.toml`, generated `./admin`
- One-sentence message describing the work (`Bootstrap docs site`, `Audit docs and migrate legacy phase docs to issues`, etc.)

---

## ESM gotcha (always)

VitePress is ESM-only. If `package.json` has `"type": "commonjs"` (or no `type` field on older Node), naming the config `config.ts` fails the build with:

```
"vitepress" resolved to an ESM file. ESM file cannot be loaded by `require`
```

**Always use `.mts`.** The `.mts` extension forces TypeScript to treat the file as ESM regardless of the project's module type. Works whether the project is ESM or CommonJS.

If you find a project with `config.ts` that's been working (because the project is `"type": "module"`), still rename to `.mts` for consistency — it's the standard.

## Other VitePress gotchas

- **Markdown `{{ }}`** — interpreted as Vue template syntax, even inside backticks. Wrap with `<code v-pre>{{ }}</code>` or escape the braces.
- **`outline: deep` frontmatter** — pages with H3+ headings need this to show full TOC.
- **Sidebar links omit `.md`** — use `/guide/getting-started`, not `/guide/getting-started.md`.
- **Landing page must have `layout: home` frontmatter.**

---

## What `[commands.docs]` looks like in `admin.toml`

```toml
[commands.docs]
kind = "npm"
desc = "serve VitePress docs site with hot reload on http://localhost:5193"
run  = "docs:dev"
```

`kind = "npm"` is the dedicated renderer — auto-detects npm vs bun, runs `<pkg> run <script>`, produces standardized output. **Don't** use `kind = "shell"` with `run = "npm run docs:dev"` — that bypasses the renderer's lockfile detection and consistent error reporting.

Single command. **No sub-targets.** No `docs build`, no `docs preview` — those are noise for local viewing. Add `"docs"` to the `order` array between `clean` and the utility commands (`icons`, `reload`). Then `~/.admin/init-admin --regenerate . --force-dirty`.

If the project deploys docs (rare), add separate `[commands.docs-build]` / `[commands.docs-deploy]` rather than nesting under `docs`.

### When to use an action instead

Don't, for `docs`. Actions (`[actions.X]`) are reusable building blocks for *multi-step* commands or shared infrastructure between several commands — e.g. an apple archetype's `build-ios` action that gets invoked by both `[commands.build.ios]` and `[commands.dev.ios]` sub-targets. A single npm script invocation has neither shape, so `kind = "npm"` directly on the command is correct. Only reach for an action if you find yourself wanting to call the same docs operation from multiple commands.

---

## When NOT to use this skill

- The project doesn't use Markdown for docs (e.g., Sphinx + reStructuredText, or a hosted docs platform). This skill is VitePress-specific.
- The project's docs are in a separate repo. Run this skill in that repo.
- The user explicitly wants a different docs structure. Don't fight the user — note the deviation and exit.

---

## Reference: minimal `docs/.vitepress/config.mts`

```typescript
import { defineConfig } from 'vitepress'

export default defineConfig({
  title: '{Project Name} Docs',
  description: '{One-line description}',
  cleanUrls: true,
  themeConfig: {
    nav: [
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'Architecture', link: '/architecture/overview' },
      { text: 'Development', link: '/development/setup' },
      { text: 'Reference', link: '/PRD' },
    ],
    sidebar: {
      '/guide/': [{ text: 'Guide', items: [/* ... */] }],
      '/architecture/': [{ text: 'Architecture', items: [/* ... */] }],
      '/development/': [{ text: 'Development', items: [/* ... */] }],
      '/': [
        {
          text: 'Reference',
          items: [
            { text: 'Product spec (PRD)', link: '/PRD' },
            { text: 'Roadmap', link: '/roadmap' },
            { text: 'File map', link: '/file-map' },
            // { text: 'API surface', link: '/api' },  // if exists
          ],
        },
      ],
    },
    search: { provider: 'local' },
    socialLinks: [{ icon: 'github', link: '{repo URL or omit}' }],
    editLink: {
      pattern: '{repo URL}/edit/main/docs/:path',
      text: 'Edit this page on GitHub',
    },
  },
  vite: {
    server: { host: '0.0.0.0', port: 5193 },
  },
})
```

Adjust nav / sidebar based on which opt-in folders the project has. Drop the `api`, `architecture/`, `guide/`, `development/` entries if those folders don't exist.

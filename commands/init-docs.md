# /init-docs — Initialize VitePress Documentation Site

You are setting up a VitePress documentation site for this project. Follow each step carefully, adapting content to the specific project you're working in.

## Step 1 — Analyze the Project

Read these files (skip any that don't exist, note their absence):

- `package.json` — project name, description, scripts, dependencies
- `CLAUDE.md` — architecture, commands, code style, current status
- `README.md` — overview, features, quick start
- `.gitignore` — check for existing VitePress ignores
- `.env` — check for `DEV_HOST`

Scan the project structure:
- `src/` — understand the main source layout
- `docs/` — check for existing VitePress setup or scattered docs
- `config/network.ts` — check if network utility already exists

Detect project characteristics:
- **Project type**: Node (package.json), Python (setup.py/pyproject.toml), Go (go.mod), or other
- **Main dev port**: from dev server config (vite.config.ts, webpack.config.js, etc.)
- **Git remote**: run `git remote get-url origin 2>/dev/null` to get the repo URL
- **Docker/CI**: check for Dockerfile, docker-compose*.yml, .github/workflows/
- **Existing docs**: ROADMAP.md, PHASE_*.md, TESTING.md, CONTRIBUTING.md, docs/*.md
- **Test framework**: vitest, jest, pytest, go test, etc.

Report what you found before proceeding.

## Step 2 — Determine Scope

Based on your analysis, determine which sections to create:

**Always create (Tier 1):**
- Landing page (`docs/index.md`)
- Guide section (`docs/guide/getting-started.md` + feature pages from README)
- Development section (`docs/development/setup.md`, `testing.md`, `code-style.md`, `troubleshooting.md`)

**Always create (Tier 2):**
- Architecture section (`docs/architecture/overview.md` + subsystem pages from CLAUDE.md; stub if no architecture info exists)
- Deployment page (`docs/development/deployment.md` from Docker/CI configs; stub if none exist)

**Create if roadmap/phase planning exists (Tier 3):**
- Roadmap section (`docs/roadmap/index.md` + per-phase pages) — only if ROADMAP.md, PHASE_*.md, or similar planning docs are found

**If VitePress is already set up** (`docs/.vitepress/config.ts` exists):
- Do NOT overwrite the existing config or existing pages
- Identify gaps — missing sections or pages that should exist based on project analysis
- Offer to fill those gaps only
- Report what already exists and what you'd add

Determine these values:
- **Title**: from package.json `name` field, title-cased, + " Docs" (e.g., "rpg-toolkit" → "RPG Toolkit Docs")
- **Description**: from package.json `description` or README first paragraph
- **Docs port**: main app port + 20 (e.g., 3300 → 3320). Default to 5193 if no app port found.
- **GitHub URL**: from git remote, cleaned up (remove `.git` suffix)

Report the planned scope before proceeding.

## Step 3 — Create Documentation Structure

### 3a. VitePress Config

Create `docs/.vitepress/config.ts`:

```typescript
import { defineConfig } from 'vitepress'
```

**Network URL handling** — choose ONE approach:
1. If `config/network.ts` already exists in the project: import `detectBestIP` and `customNetworkUrlPlugin` from it
2. Otherwise, if the project has a `.env` with `DEV_HOST` or uses Docker: inline a small plugin directly in the config:

```typescript
// Inline network URL plugin (only if config/network.ts doesn't exist)
function networkUrlPlugin() {
  const host = process.env.DEV_HOST
  if (!host) return { name: 'noop' }
  return {
    name: 'network-url',
    configureServer(server: any) {
      server.httpServer?.once('listening', () => {
        setTimeout(() => {
          const addr = server.httpServer?.address()
          if (addr && typeof addr === 'object') {
            console.log(`\n  \x1b[1m\x1b[32m➜\x1b[0m  \x1b[1mNetwork:\x1b[0m \x1b[36mhttp://${host}:${addr.port}/\x1b[0m`)
          }
        }, 0)
      })
    },
  }
}
```

3. If neither applies (no Docker, no DEV_HOST): omit the network plugin entirely

Config structure:
- `title`: determined in Step 2
- `description`: from package.json or README
- `themeConfig.nav`: links to each top-level section
- `themeConfig.sidebar`: grouped by section, each with items array
- `themeConfig.search.provider`: `'local'`
- `themeConfig.socialLinks`: GitHub link if available
- `themeConfig.editLink`: GitHub edit link pattern if available
- `vite.server.host`: `'0.0.0.0'`
- `vite.server.port`: determined in Step 2
- `vite.plugins`: include network plugin if applicable

Sidebar links omit the `.md` extension. Use `/roadmap/` (with trailing slash) for index pages.

### 3b. Landing Page

Create `docs/index.md` with VitePress home layout:

```yaml
---
layout: home

hero:
  name: {Project Name}
  text: {Tagline from README or package.json description}
  tagline: {Longer description}
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: {Secondary action — View Roadmap, or GitHub, etc.}
      link: {appropriate link}

features:
  - title: {Feature 1}
    details: {Description}
  # ... 3-4 features from README
---
```

### 3c. Guide Section

Create `docs/guide/getting-started.md`:
- What is this project? (from README intro)
- Requirements (from README/package.json engines)
- Quick start (clone, install, run)
- What's next (links to other guide pages)

Create additional guide pages for major features documented in README or completed phases. Each page should have:
- Clear H1 title
- Brief intro paragraph
- Structured content with code examples where relevant
- Cross-links to related pages

### 3d. Development Section

Create `docs/development/setup.md`:
- Requirements
- Install and run commands
- All commands table (from package.json scripts, grouped by category)
- Port table (dev server, test server, docs, Docker)
- Environment variables table
- Project structure tree

Create `docs/development/testing.md`:
- Test framework and how to run tests
- Single test file / single test by name
- E2E tests if applicable
- Testing conventions from CLAUDE.md

Create `docs/development/code-style.md`:
- From CLAUDE.md code style section
- Formatting rules, naming conventions, import ordering
- Quality gates (typecheck, lint, etc.)

Create `docs/development/troubleshooting.md`:
- Common issues and solutions from CLAUDE.md/README
- Port conflicts, build errors, network issues

Create `docs/development/deployment.md`:
- Docker setup if Dockerfile exists
- CI/CD pipeline if configs exist
- Production build and serve commands
- Stub with "Deployment documentation coming soon" if none of the above exist

### 3e. Architecture Section

Create `docs/architecture/overview.md`:
- High-level architecture from CLAUDE.md
- Key design decisions
- Component/module diagram (text-based)

Create additional architecture pages for subsystems documented in CLAUDE.md (e.g., store, persistence, API, file format). If CLAUDE.md has no architecture section, create just the overview with stubs.

### 3f. Roadmap Section (only if planning docs exist)

Create `docs/roadmap/index.md`:
- Vision statement
- Core principles
- Phase overview table with status and links
- Dependency diagram
- Current status summary

Create `docs/roadmap/phase-NN.md` for each phase:
- Goal statement
- Features checklist
- Technical work items
- Deliverables / "done means"
- Dependencies

Use `phase-NNx.md` naming for sub-phases (e.g., `phase-01c.md`).

For completed phases: create corresponding guide pages and have the roadmap page reference them.

## Step 4 — Migrate Existing Docs

Check for and migrate these files (DO NOT delete originals — report them for the user to clean up):

| Source | Destination |
|--------|-------------|
| `ROADMAP.md` | `docs/roadmap/index.md` (merge content) |
| `PHASE_*.md` or `docs/PHASE_*.md` | `docs/roadmap/phase-*.md` |
| `TESTING.md` or `docs/TESTING.md` | `docs/development/testing.md` (merge content) |
| `CONTRIBUTING.md` | `docs/development/code-style.md` or `docs/development/setup.md` (merge relevant parts) |
| `docs/TASKS.md` | `docs/roadmap/` (merge into phase pages) |
| `docs/tasks/*.md` | Categorize into roadmap or development |
| Other `docs/*.md` | Categorize into appropriate section |

Report all migrations performed.

## Step 5 — Integration

### package.json Scripts

For Node.js projects, add these scripts to `package.json` (skip any that already exist):

```json
{
  "docs:dev": "vitepress dev docs --port {DOCS_PORT}",
  "docs:build": "vitepress build docs",
  "docs:preview": "vitepress preview docs --port {DOCS_PORT}"
}
```

For non-Node projects, create `docs/package.json` with VitePress as a dependency and the scripts above.

### Install VitePress

Run: `npm add -D vitepress` (or equivalent for the package manager in use)

### .gitignore

Append these lines if not already present:

```
docs/.vitepress/cache
docs/.vitepress/dist
```

### CLAUDE.md

Always ensure CLAUDE.md has a "Documentation Site" section. If CLAUDE.md doesn't exist yet, create it with at minimum the documentation section (and any other project context you gathered during analysis). If it already exists, add or update the documentation section.

The documentation section should note:
- VitePress docs location (`docs/`)
- Command to run the docs site and its port (`npm run docs:dev`, port NNNN)
- Brief list of doc sections (guide, architecture, development, roadmap if applicable)

## Step 6 — Verify

Run `npm run docs:build` (or the equivalent build command) and confirm it succeeds with no errors.

If the build fails:
- Fix any VitePress markdown issues (common: `{{ }}` needs `<code v-pre>{{ }}</code>`)
- Fix any broken links
- Re-run until clean

Report the complete file tree of everything created:

```
docs/
  .vitepress/
    config.ts
  index.md
  guide/
    getting-started.md
    ...
  development/
    setup.md
    testing.md
    code-style.md
    deployment.md
    troubleshooting.md
  architecture/
    overview.md
    ...
  roadmap/          (if applicable)
    index.md
    phase-01.md
    ...
```

And list any migrations performed and any original files the user may want to delete.

## Important Notes

- **Do not overwrite existing files** without asking. If a target file exists, show the diff and ask before replacing.
- **VitePress markdown gotcha**: `{{ }}` in markdown (even in backticks) is interpreted as Vue template syntax. Escape with `<code v-pre>{{ }}</code>`.
- **Use `outline: deep`** frontmatter on pages with heading levels deeper than H2.
- **Landing page** must have `layout: home` frontmatter.
- **Sidebar links** omit the `.md` extension.
- **Adapt to the project** — don't copy RPG Toolkit specifics. Every page should reflect THIS project's actual content.
- **Keep pages concise** — prefer tables for command/port/env var references. Use code blocks for examples. Don't pad with filler text.
- **Cross-link between sections** — guide pages should link to architecture; development pages should link to testing; roadmap should link to completed feature guides.

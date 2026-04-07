# claude-config

Personal Claude Code configuration synced across machines. Only `agents/`, `skills/`, and `commands/` are tracked — everything else (sessions, plugins, cache, auth tokens, settings) stays machine-local via the allowlist `.gitignore`.

**Clone a new machine:**
```bash
cd ~/.claude
git init -b main
git remote add origin git@github.com:McBrideMusings/claude-config.git
git fetch origin main
git reset --hard origin/main
git submodule update --init --recursive
```

---

## Agents

Spawnable subagents (via the Agent tool).

| Agent | Description |
|---|---|
| [code-reviewer](agents/code-reviewer.md) | Review a completed project step against the original plan and coding standards. Categorizes issues as critical/important/suggestions with actionable fixes. |

---

## Commands

Slash commands invoked with `/<name>`.

| Command | Description |
|---|---|
| [admin-tool](commands/admin-tool.md) | Add a new subcommand to the project's Python `admin` task runner. |
| [clean-commit-history](commands/clean-commit-history.md) | Rewrite git history on the current branch to strip conventional commit prefixes from messages. |
| [cmux-browser](commands/cmux-browser.md) | Open a URL in the cmux browser and take a snapshot for inspection. |
| [code-review](commands/code-review.md) | Review uncommitted changes or branch changes against the base branch. |
| [diagnose](commands/diagnose.md) | Enter diagnostic mode — stricter rules for investigating problems until `/diagnose-done`. |
| [diagnose-done](commands/diagnose-done.md) | Exit diagnostic mode and resume normal behavior. |
| [init-admin](commands/init-admin.md) | Scaffold or audit a Python-based `admin` task runner with inline TUI menu. Detects project type and generates commands. |
| [init-docs](commands/init-docs.md) | Initialize a VitePress documentation site for the project. |
| [init-gh-issues](commands/init-gh-issues.md) | Initialize or normalize GitHub Issues labels and templates for a repo. |
| [init-tailscale-local-dev](commands/init-tailscale-local-dev.md) | Configure a dev server to bind only to localhost + Tailscale network addresses. |
| [merge-main](commands/merge-main.md) | Merge `origin/main` into the current branch and resolve any merge conflicts. |
| [optimize-permissions](commands/optimize-permissions.md) | Audit and tighten Claude Code permission rules in `settings.json`. |
| [q](commands/q.md) | The user is asking a question — answer it in chat, take no other action. |
| [update-claude-md](commands/update-claude-md.md) | Update `CLAUDE.md` to reflect changes made on the current branch. |
| [update-docs](commands/update-docs.md) | Update project documentation to reflect changes made on the current branch. |
| [wrap-up](commands/wrap-up.md) | Close out the current session — update tracking, documentation, and commit work. |

---

## Skills

Auto-loaded skills invoked by name or by the trigger phrases in each skill's description.

### Planning and design

| Skill | Description |
|---|---|
| [brainstorming](skills/brainstorming/SKILL.md) | Collaborative design skill — explore user intent, requirements, and design before implementation. Use before any creative work. |
| [write-a-prd](skills/write-a-prd/SKILL.md) | Create a PRD through user interview, codebase exploration, and module design, then submit as a GitHub issue. |
| [prd-to-plan](skills/prd-to-plan/SKILL.md) | Transform a PRD into a phased implementation plan using vertical slices. |
| [request-refactor-plan](skills/request-refactor-plan/SKILL.md) | Create a detailed refactor plan with tiny commits via user interview, then file it as a GitHub issue. |
| [design-an-interface](skills/design-an-interface/SKILL.md) | Generate multiple radically different interface designs for a module, then compare. Based on "Design It Twice" from *A Philosophy of Software Design*. |
| [grill-me](skills/grill-me/SKILL.md) | Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. |
| [answer-question](skills/answer-question/SKILL.md) | Use when the user asks a question during an active coding or editing session, especially mid-implementation or mid-plan. |

### Debugging and verification

| Skill | Description |
|---|---|
| [systematic-debugging](skills/systematic-debugging/SKILL.md) | Four-phase debugging process — find root cause before any fix. Use for any bug, test failure, or unexpected behavior. |
| [verification-before-completion](skills/verification-before-completion/SKILL.md) | Use before claiming work is complete or passing — run verification commands and confirm output before asserting success. |
| [grounded-research](skills/grounded-research/SKILL.md) | Grounded research mode that reduces hallucinations using Anthropic's three recommended techniques: admit uncertainty, extract quotes, cite sources. |
| [ios-device-logs](skills/ios-device-logs/SKILL.md) | Debug an iOS app on a physical device — read logs, diagnose connection issues, investigate crashes. |
| [check-reels-logs](skills/check-reels-logs.md) | Query the `reels_logs` SQLite table in the Stash database via GraphQL when debugging stash-reels. |

### Code quality and refactoring

| Skill | Description |
|---|---|
| [code-simplifier](skills/code-simplifier/SKILL.md) | Runs the code-simplifier agent on changes in the current branch. |
| [extract-feature](skills/extract-feature/SKILL.md) | Extract uncommitted changes for a specific feature from the current work tree onto its own branch. |

### Git and worktrees

| Skill | Description |
|---|---|
| [worktree-setup](skills/worktree-setup/SKILL.md) | Create an isolated git worktree for feature work or bug fixes, optionally creating or linking GitHub issues. |

### Project scaffolding

| Skill | Description |
|---|---|
| [init-admin](skills/init-admin/SKILL.md) | Scaffold or audit a Python-based `admin` task runner with inline TUI menu. |
| [init-tailscale-local-dev](skills/init-tailscale-local-dev.md) | Dev servers must only show local + Tailscale addresses. Apply whenever setting up or modifying a dev server. |

### Platform-specific

| Skill | Description |
|---|---|
| [mobile-ios-design](skills/mobile-ios-design/SKILL.md) | Master iOS Human Interface Guidelines and SwiftUI patterns for building native iOS apps. |
| [cmux-browser](skills/cmux-browser/SKILL.md) | Automate browser interaction in cmux terminal for testing, previewing, or verifying web UIs. Replaces Playwright MCP. |
| [caddy-unraid](skills/caddy-unraid.md) | Reference for managing the Caddy reverse proxy on Unraid — Tailnet-only service routing. |

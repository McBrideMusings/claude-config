---
name: worktree-setup
description: Use when creating isolated git worktree for feature work or bug fixes, optionally creating or linking to GitHub issues. Handles worktree creation, issue management, dependency installation, and path return.
---

# Worktree Setup

Use the `wtree` shell function. Do NOT manually run git worktree commands — `wtree` handles branch naming and directory placement automatically.

## Commands

```bash
# Simple worktree (no issue)
wtree add my-feature

# Link to existing GitHub issue
wtree add --issue 42

# Create new GitHub issue + worktree
wtree add --issue "Fix the turn timeout bug"

# List worktrees
wtree ls

# Remove worktree
wtree rm my-feature
wtree rm my-feature --force
```

## What wtree add does automatically

1. Creates worktree inside `.worktrees/<name>` within the repo
2. Branch is always prefixed with `pierce/` for repos not owned by McBrideMusings (e.g., `pierce/42-fix-turn-timeout-bug`)
3. You only provide the name/issue — the folder location is chosen automatically

## When to use which form

| User says | Command |
|-----------|---------|
| "Create worktree for feature X" | `wtree add feature-x` |
| "Create worktree for issue #42" | `wtree add --issue 42` |
| "Create worktree for fixing the bug" | `wtree add --issue "Fix the bug"` (creates GH issue) |
| "List worktrees" | `wtree ls` |
| "Remove/clean up worktree" | `wtree rm <name>` |

## Important

- Always run `wtree` from inside the git repo
- The worktree is placed at `.worktrees/<name>` — do not specify the path manually
- Report the worktree path and branch name back to the user when done

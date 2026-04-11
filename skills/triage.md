---
name: triage
description: Fetch and triage GitHub issues from a milestone, label filter, or repo URL. Groups related issues, identifies priority, and implements chosen work via worktree.
---

# Triage GitHub Issues

Fetch issues from a GitHub URL, group related ones, score by priority, present choices, then set up a worktree and implement.

## Input

The user passes a GitHub URL as an argument. Supported formats:

| URL pattern | What to fetch |
|-------------|---------------|
| `github.com/owner/repo/milestone/N` | Issues in milestone N |
| `github.com/owner/repo/issues?labels=X` | Issues matching label filter |
| `github.com/owner/repo/issues?q=...` | Issues matching search query |
| `github.com/owner/repo/issues` | All open issues |
| `github.com/owner/repo` | All open issues |
| `github.com/orgs/owner/projects/N` | Items from project board N |

If no URL is provided, ask the user for one.

## Procedure

### 1. Parse the URL

Extract `owner`, `repo`, and any filter parameters from the URL.

- Strip `https://` prefix if present
- Split the path to get `owner/repo`
- Detect the URL type from the path and query string
- For milestone URLs, extract the milestone number
- For filtered URLs, parse query params (`labels`, `q`, `milestone`, `assignee`)

### 2. Fetch issues

Build and run the appropriate `gh` command:

- **Milestone**: `gh issue list --repo owner/repo --milestone <N> --state open --json number,title,labels,body,createdAt,comments,assignees --limit 100`
- **Label filter**: `gh issue list --repo owner/repo --label <label> --state open --json number,title,labels,body,createdAt,comments,assignees --limit 100`
- **Search query**: `gh issue list --repo owner/repo --search "<query>" --json number,title,labels,body,createdAt,comments,assignees --limit 100`
- **All open**: `gh issue list --repo owner/repo --state open --json number,title,labels,body,createdAt,comments,assignees --limit 100`
- **Project board**: `gh project item-list <N> --owner <owner> --format json --limit 100`

If the command fails (auth error, repo not found), report the error and stop.

If zero issues are returned, report that and stop.

### 3. Group related issues

Apply these heuristics in order to cluster issues:

**Label clusters** — Find issues that share the same area/component labels (ignore generic labels like `bug`, `enhancement`, `good-first-issue`). Group issues with 2+ shared specific labels.

**Title prefixes** — Look for common prefixes before `:`, `—`, or `-` in titles (e.g., "Dashboard: fix X" and "Dashboard: add Y" both belong to the "Dashboard" group).

**Cross-references** — Scan issue bodies for `#N` mentions. If issue A references issue B and both are in the set, group them together.

**Merge overlapping groups** — If two groups share 50%+ of their issues, merge them.

**Ungrouped** — Issues that don't cluster into any group are presented individually, sorted by priority score.

### 4. Score and rank

Score each issue:

| Signal | Points |
|--------|--------|
| `priority:critical` or `priority:high` label | +3 |
| `bug` label | +2 |
| Age > 30 days | +1 |
| Active discussion (>3 comments) | +1 |
| `good-first-issue` label | -1 |

Sum scores per group (total of member scores). Sort groups descending by total score.

### 5. Present triage summary

Display a structured summary:

```
## Triage: owner/repo (N open issues)

### Group 1: <Group Name> — Priority: HIGH (score: N)
Issues: #12 "Title", #15 "Title", #18 "Title"
Labels: [area:X] [bug]
Scope: ~N issues, estimated N hours

### Group 2: <Group Name> — Priority: MEDIUM (score: N)
Issues: #30 "Title", #31 "Title"
Labels: [area:Y] [enhancement]
Scope: ~N issues, estimated N hours

### Ungrouped high-priority
- #45 "Title" (score: N) [bug] [priority:high]
- #67 "Title" (score: N) [bug]

---

Recommendation: Group 1 is highest priority — N related bugs in <area>.

Which group or issue(s) would you like to work on?
```

Scope estimate heuristic: ~30-60 min per issue for bugs, ~1-2 hours per issue for features. Cap display at "6+ hours" for large groups.

Wait for the user to choose.

### 6. Set up worktree

After the user picks:

- **Single issue**: run `wtree add --issue <number>` from inside the repo
- **Group of issues**: use the highest-priority issue as the primary — run `wtree add --issue <primary-number>`. Note the other issue numbers; they'll go in the PR description later.

Report the worktree path and branch name back to the user.

`cd` into the worktree directory.

### 7. Begin implementation

- Read the chosen issue(s) in full: `gh issue view <N>` for each
- Explore the relevant areas of the codebase
- If the group has 4+ issues or the scope estimate exceeds 4 hours, ask the user if they want a plan drafted first (write to `~/.claude/plans/`)
- Otherwise, start implementing directly

When working on a group, mention all related issue numbers in commit messages (e.g., "Relates to #12, #15, #18") so the PR links them.

## Rules

- Always use `wtree` for worktree creation — never run `git worktree` manually
- Never commit automatically — ask before committing
- If the repo is not checked out locally, stop and tell the user
- If `gh` auth fails, suggest the user run `gh auth login`
- Don't attempt to implement all issues from a large milestone — the whole point is to pick a focused subset

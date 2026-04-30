# Summarize Branch

Generate a concise, pasteable PR-ready summary of what was built on the current branch.

## When to use

When the user asks to "summarize branch", "summarize the branch", "write a branch summary", or wants a PR description summary.

## Output format

A Markdown unordered list (`-` bullets). Each bullet:
- Starts with `- **Bold Category Label** —`
- Followed by a plain-English explanation of what was built, naming the key files/components
- One bullet per logical area of work (not per commit, not per file)
- Aim for 5–12 bullets total
- No headers, no sections, no markdown beyond the `- **Label** —` pattern

Example shape:
```
- **CLI** — bin/entry.mjs + src/orchestrator/ supervises the three subprocesses with wait-for-file and wait-for-TCP gates so the client never proxies into a not-yet-ready backend.
- **Mocks** — mock-server.ts, mock-redis.ts, mock-realtime.ts. Ships both in-memory and real-Redis variants; full Redis API parity including transactions.
```

## Procedure

1. Gather context — run these in parallel:
   - `git log --oneline origin/main..HEAD` — commits on branch
   - `git diff origin/main --stat` — files changed
   - `git diff origin/main -- '*.md' '*.json'` (limited) — scan CLAUDE.md, package.json for orientation
   - Check if a followups file exists at `~/.claude/followups/<project>.md` and skim the most recent session section for this branch

2. Read a representative sample of the changed files — focus on entry points, new modules, key types. Don't read every file; use the stat output to identify clusters.

3. Write the summary — group changes by logical area (CLI, mocks, UI, extension system, config, tooling, etc.). Name real file paths. Explain the *what and why*, not just the *what*. Make it useful to a reviewer who hasn't seen the branch.

4. Write output to `/tmp/branch-summary.txt` (overwrite if exists).

5. Print the full summary to chat so the user can copy-paste it.

6. Report: "Written to /tmp/branch-summary.txt"

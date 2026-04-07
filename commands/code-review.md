---
description: Review uncommitted changes or branch changes against base branch
---

Review code changes for bugs, quality issues, and CLAUDE.md compliance. Works in two modes:

- **Uncommitted changes**: If there are unstaged/staged changes, review those
- **Branch changes**: If working tree is clean, review all commits on the current branch vs its base (main/master)

## Steps

1. Determine what to review:
   - Run `git status` and `git diff` to check for uncommitted changes
   - If uncommitted changes exist, that's the diff to review
   - If working tree is clean, find the base branch: check for `main` or `master`, then run `git log --oneline $(git merge-base HEAD origin/main)..HEAD` and `git diff $(git merge-base HEAD origin/main)..HEAD` to get the branch diff
   - If there are no changes anywhere, say so and stop

2. Use a Haiku agent to find relevant CLAUDE.md files: the root CLAUDE.md and any CLAUDE.md files in directories whose files were changed

3. Launch 4 parallel Sonnet agents to independently review the diff. Each agent gets the full diff and list of CLAUDE.md file paths. Each returns a list of issues with severity and reasoning:
   a. **Agent 1 — CLAUDE.md compliance**: Audit changes against CLAUDE.md rules. Only flag violations of specific, stated rules.
   b. **Agent 2 — Bug scan**: Read the diff for obvious bugs. Focus on logic errors, off-by-ones, null/nil issues, race conditions, resource leaks. Ignore style and nitpicks.
   c. **Agent 3 — Historical context**: Read git blame and recent history of modified files. Flag changes that contradict established patterns or revert previous fixes.
   d. **Agent 4 — Code comments and contracts**: Read code comments in modified files. Flag changes that violate documented contracts, TODOs that should be addressed, or stale comments.

4. For each issue found, launch a parallel Haiku agent to score confidence (0-100):
   - 0: False positive, doesn't hold up to scrutiny, or pre-existing issue
   - 25: Might be real, might be false positive. Stylistic issues not in CLAUDE.md.
   - 50: Real but minor. Nitpick or unlikely to matter in practice.
   - 75: Verified real issue. Will impact functionality or violates explicit CLAUDE.md rule.
   - 100: Confirmed real issue. Will happen frequently. Evidence directly confirms it.

5. Filter to issues scoring 75+. Report results.

## Output format

Print directly to the conversation (not to a file):

```
## Code Review

Reviewed: [uncommitted changes | N commits on branch-name vs main]

### Issues (N found)

1. **[severity: high/medium]** Brief description
   File: path/to/file.ext:LINE
   Why: explanation with evidence

2. ...

### No issues found
(if all scored below 75)
```

## What counts as a false positive (give this to scoring agents)

- Pre-existing issues not introduced by these changes
- Things a linter/compiler/typechecker would catch
- General quality issues (missing tests, docs) unless CLAUDE.md requires them
- Issues on lines the user didn't modify
- Intentional functionality changes related to the broader change
- Pedantic nitpicks a senior engineer wouldn't flag

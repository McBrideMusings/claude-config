Rewrite git history on the current branch to remove conventional commit prefixes from commit messages.

1. Run `git log --oneline` to find all commits with conventional commit prefixes (patterns like `type:`, `type(scope):` — e.g. `feat:`, `fix(cli):`, `chore:`, `test:`, `docs:`, `refactor:`, `perf:`, `ci:`, `build:`).

2. Show the user a table of commits that will be rewritten (current message → new message). The new message should strip the prefix and capitalize the first letter of the remaining text.

3. Wait for user confirmation before proceeding.

4. Use `git filter-branch --msg-filter` (or `git filter-repo` if available) to rewrite only the affected commit messages. Do not alter commits that already have plain messages.

5. After rewriting, show `git log --oneline` so the user can verify the result.

6. Ask before force-pushing.

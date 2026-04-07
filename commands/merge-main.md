Merge origin/main down into the current branch, then resolve any merge conflicts.

1. Run `git fetch origin main` to get the latest.

2. Run `git merge origin/main --no-edit`. If the merge completes cleanly, report that and stop.

3. If there are conflicts, list all conflicted files and read each one.

4. For each conflict, analyze both sides and resolve by keeping the intent of both changes (prefer accepting incoming additions alongside local changes). Use the Edit tool to remove conflict markers.

5. After resolving all conflicts, run `git diff --check` to verify no conflict markers remain.

6. Ask the user before committing. Commit message: "Merge origin/main into <branch-name>".

7. After committing, push the branch: `git push origin <branch-name>`.

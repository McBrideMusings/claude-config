---
name: merge-main
description: Merge or rebase a branch with origin/main, intelligently choosing strategy based on branch complexity and resolving any conflicts.
---

# Merge Main

Bring a branch up to date with `origin/main`. Automatically choose merge vs rebase based on branch complexity, and resolve conflicts.

## Input

The user may specify a branch name as an argument. If omitted, use the current branch.

If the user specifies a branch that is not currently checked out, check it out first.

## Procedure

### 1. Setup

- Run `git fetch origin main`
- Determine the target branch (argument or current branch)
- If the target branch is `main`, stop and tell the user — nothing to merge

### 2. Analyze divergence

Run these to understand the branch shape:

- `git log --oneline origin/main..HEAD` — commits on the branch not in main
- `git log --oneline HEAD..origin/main` — commits on main not in the branch
- `git log --merges --oneline origin/main..HEAD` — merge commits on the branch

Count the results. You need three numbers:
- **branch_commits**: commits ahead of main
- **main_commits**: commits main is ahead of the branch
- **merge_commits**: merge commits on the branch

If `main_commits` is 0, the branch is already up to date. Report that and stop.

### 3. Choose strategy

Use **rebase** when ALL of these are true:
- `branch_commits` <= 10
- `merge_commits` == 0 (no merge commits — rebase would flatten them)
- No shared/pushed merge commits that other people depend on

Use **merge** otherwise. Merge is the safe default.

Tell the user which strategy you chose and why, then proceed.

### 4. Attempt the merge/rebase

**Rebase path:**
```
git rebase origin/main
```

**Merge path:**
```
git merge origin/main --no-edit
```

If it completes cleanly, report success and skip to step 6.

If conflicts occur, **do not resolve yet**. Proceed to step 5.

### 5. Conflict resolution plan (present before acting)

When conflicts are detected:

1. List all conflicted files with `git diff --name-only --diff-filter=U`
2. Read each conflicted file in full
3. For each conflict, analyze both sides:
   - What does the **branch** side intend? (Read the branch's version between `<<<<<<<` and `=======`)
   - What does **main** side intend? (Read main's version between `=======` and `>>>>>>>`)
   - What is the surrounding context — does one side's change depend on the other?

4. **Present a conflict resolution plan to the user.** Format:

   ```
   ## Conflict Resolution Plan

   ### <filename> (N conflicts)

   **Conflict 1** (lines X-Y)
   - Branch side: <what the branch changed and why>
   - Main side: <what main changed and why>
   - Recommendation: <how to resolve — keep both, prefer one side, combine>
   - Confidence: <high / medium / low>

   **Conflict 2** ...

   ### <next filename> ...
   ```

   For low-confidence resolutions, explicitly flag them and explain the ambiguity.

5. **Wait for the user to approve the plan** (or adjust individual resolutions).

6. Once approved, execute the resolutions:
   - Use the Edit tool to remove conflict markers and apply the agreed resolution
   - `git add <resolved-files>`
   - For rebase: `git rebase --continue` (repeat steps 1-6 if more conflicts appear on subsequent commits)
   - For merge: `git diff --check` to verify no markers remain, then ask the user before committing. Commit message: `Merge origin/main into <branch-name>`

### 6. Verify

- Run `git diff --check` to confirm no conflict markers remain
- Run `git log --oneline -5` to show the result

### 7. Push

After the merge/rebase is complete, push the branch:

- For **merge**: `git push origin <branch-name>`
- For **rebase**: `git push origin <branch-name> --force-with-lease` (rebase rewrites history, so force is required — but use `--force-with-lease` for safety)

Ask the user before force-pushing on rebase.

## Conflict resolution principles

- **Additive changes on both sides**: Keep both additions. If main added lines and the branch added different lines nearby, include all of them in logical order.
- **Same code modified differently**: If main refactored a function and the branch also changed it, prefer main's structural changes and re-apply the branch's behavioral intent on top.
- **Deleted on one side, modified on the other**: If main deleted code that the branch modified, the branch's intent probably still matters — ask the user.
- **Package lock / generated files**: Accept main's version, then regenerate if needed.
- **Ambiguous**: When in doubt, ask. Don't guess on conflicts where both sides have legitimate competing changes to the same logic.

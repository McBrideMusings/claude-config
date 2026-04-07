---
name: extract-feature
description: Extract uncommitted changes for a specific feature from the current work tree onto its own branch, then remove those changes from the current branch. Use when the user wants to split out unrelated work-in-progress into a separate branch.
---

# Extract Feature to Branch

Isolate a subset of working tree changes onto a new branch (off origin/main), commit them there, then remove them from the current work tree.

## Procedure

1. **Identify files** — determine which modified/untracked files belong to the feature being extracted. If a file has mixed changes (feature + other work), prepare a selective patch.

2. **Save patches** — `git diff -- <files>` to a temp file. Copy any new (untracked) files to `/tmp/`.

3. **Stash current work** — `git stash push -m "wip-<current-branch-context>"` so the checkout succeeds.

4. **Create the branch and set correct upstream**:
   ```bash
   git branch <branch-name> origin/main --no-track
   ```
   **NEVER** use `git branch <name> origin/main` without `--no-track`. That sets the upstream to `origin/main`, which means `git push` targets main.

   After creating, if an `origin` remote exists, configure push tracking so `git push` works seamlessly later:
   ```bash
   git config branch.<branch-name>.remote origin
   git config branch.<branch-name>.merge refs/heads/<branch-name>
   ```
   This sets the upstream to `origin/<branch-name>` (matching its own name) without requiring the remote branch to exist yet. First push will create it automatically.

5. **Switch to the new branch** — `git checkout <branch-name>`. If the branch is already checked out in another worktree, use `git -C <other-worktree-path>` to operate there instead.

6. **Apply changes** — `git apply <patch>`, copy untracked files, make any manual edits for mixed-change files.

7. **Stage and COMMIT** — this is critical. Unstaged changes vanish when you switch branches. Always commit:
   ```bash
   git add <files>
   git commit -m "<descriptive message>"
   ```

8. **Verify the commit exists**:
   ```bash
   git log --oneline -2 <branch-name>
   ```

9. **Switch back** to the original branch: `git checkout <original-branch>`.

10. **Pop stash** — `git stash pop`.

11. **Remove extracted changes** from the work tree:
    - `git checkout -- <files>` for modified files
    - `rm <file>` for untracked files that were copied
    - For mixed files, remove only the extracted parts via Edit tool

12. **Verify final state** — `git diff --name-only` should no longer show the extracted files.

## Rules

- **Always commit on the new branch.** Never leave changes unstaged/uncommitted — they will be lost on checkout.
- **Never set upstream to a different branch name.** Use `--no-track` when creating from origin/main. The upstream gets set correctly later when the user pushes with `git push -u origin <branch-name>`.
- **Handle mixed files carefully.** If a file has both feature changes and other changes, patch only the feature parts. Use the Edit tool to surgically remove only the extracted portions from the current work tree.
- **Preserve the original branch state.** Stash before switching, pop after returning. Verify the work tree is correct at the end.

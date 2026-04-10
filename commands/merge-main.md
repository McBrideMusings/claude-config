---
description: Merge or rebase origin/main into the current (or specified) branch, resolving conflicts
allowed-tools: Bash, Read, Edit, Grep, Glob, Agent
argument: Optional branch name to operate on (default: current branch)
---

Merge origin/main down into the current branch (or the branch specified as $ARGUMENTS), then resolve any merge conflicts. Choose rebase for simple branches, merge for complex ones.

Follow the full procedure in the `merge-main` skill.

Target branch: $ARGUMENTS (if empty, use whatever branch is currently checked out)

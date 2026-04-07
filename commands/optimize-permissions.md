# Optimize Permissions

Analyze the full conversation context and all permission configurations to consolidate, simplify, and optimize the permission structure across global and project scopes.

## Procedure

### 1. Audit Conversation Context

Scan the entire conversation history for every instance where you:

- Asked the user for permission to run a command
- Were denied or had to retry a command due to permissions
- The user approved something globally or locally
- The user expressed frustration at being asked

For each instance, record:

- What tool/command/site was involved
- Whether it was approved, denied, or ignored
- Whether the user approved it globally or per-instance
- How many times the same or similar permission was requested

### 2. Read Current Permission Files

Read both permission files:

- **Global**: `~/.claude/settings.json`
- **Project**: `.claude/settings.json` (in the current project root)

Parse the `allowedTools` / `allow` / `deny` arrays from each.

### 3. Analyze and Classify

For every permission pattern found (both from conversation history and existing config), classify it:

| Category            | Examples                         |
| ------------------- | -------------------------------- |
| **Bash commands**   | `Bash(git *)`, `Bash(npm run *)` |
| **Web access**      | `WebFetch(*)`, specific domains  |
| **File operations** | `Read`, `Write`, path-scoped     |
| **MCP tools**       | Any MCP server tool permissions  |

Flag the following problems:

- **Redundant**: Multiple fine-grained permissions that could be a single wildcard (e.g., `Bash(git status)`, `Bash(git add *)`, `Bash(git commit *)` → `Bash(git *)`)
- **Repeated asks**: Commands the user approved 3+ times that still aren't in any settings file
- **Misplaced scope**: Project-specific permissions sitting in global config, or universally useful permissions stuck in a single project
- **Overly narrow**: Path-specific or argument-specific permissions for tools used broadly (e.g., allowing `ls` only on specific directories when it's used everywhere)
- **Missing entirely**: Frequently used commands with no permission entry at all

### 4. Propose Changes

Output a table with columns:

- **Permission pattern**
- **Current scope** (global / project / none)
- **Recommended scope** (global / project / remove)
- **Recommended pattern** (the actual string, possibly widened)
- **Reason** (1-line justification)

Rules for scope assignment:

- If a permission is useful across multiple projects or is a general dev tool (git, docker, npm, ls, cat, grep, find, curl, etc.) → **global**
- If a permission is specific to this project's stack, build system, or scripts → **project**
- If a permission is dangerous or highly specific and rarely used → leave narrow or remove

Rules for pattern widening:

- 3+ similar fine-grained entries for the same CLI tool → collapse to `Bash(toolname *)`
- Multiple subdomains of the same site → collapse to the base domain or use wildcard
- Path-scoped permissions where the user accesses many paths → widen or remove path constraint
- Do NOT widen permissions for destructive operations (rm -rf, DROP TABLE, etc.) unless the user has a clear pattern of using them safely

### 5. Apply Changes

After presenting the proposal, write the updated permission files:

- Merge consolidated permissions into the appropriate scope
- Remove redundant entries from both files
- Preserve any deny rules untouched
- Preserve any permissions not covered by this analysis

Write the files back. Show a diff of what changed in each file.

### 6. Summary

Output:

- Total permission asks found in conversation
- Number of consolidations performed
- Number of scope migrations (project→global or global→project)
- Number of new permissions added
- Any permissions you recommend the user review manually (high-risk wildcards, broad Bash access, etc.)

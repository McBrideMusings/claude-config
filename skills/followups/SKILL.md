Use this skill when the user mentions "follow-ups", "followups", or asks to view, add to, or act on items in the followups document for the current project.

## Where followups live

`~/.claude/followups/<project>.md` — one file per project, where `<project>` is the name of the folder on this machine containing the root git repo (not the remote repo name). Derive it from any directory in the repo tree with:

```bash
basename "$(dirname "$(realpath "$(git rev-parse --git-common-dir)")")"
```

This works correctly from worktrees — it always resolves to the main repo folder name.

## File format

Each session appends a new section at the bottom:

```markdown
## <branch-name> — YYYY-MM-DD-HH-MM

- **Title** — One sentence description.
- **Title** — One sentence description.
```

Sections are never edited after the fact. New items are always appended as a new dated section.

## What to do with this skill

**Viewing:** Read `~/.claude/followups/<project>.md` and summarize or display the contents. If the file doesn't exist, say so.

**Adding items:** Append a new dated section with the current branch and timestamp. Before writing, read the existing file and skip any item whose title or core idea already appears — no duplicates.

**Acting on items:** If the user says "let's work on the followups" or picks items to address, read the file, present the list, and help them prioritize or start on whichever items they choose. Do not delete or modify existing entries — the file is append-only.

**Cleanup (only if explicitly asked):** If the user asks to clean up or archive resolved items, move completed ones to a `## Resolved` section at the bottom rather than deleting them.

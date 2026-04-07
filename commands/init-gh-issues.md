# Initialize / Normalize GitHub Issues

Set up GitHub Issues as the single source of truth for project tracking. On first run, this converts existing roadmap and ticket markdown files into GitHub issues with labels and milestones. On subsequent runs, it normalizes — syncing labels, fixing milestone associations, and cleaning up drift.

This command is idempotent. Run it on any project to bring its GitHub Issues into a consistent shape.

---

## Phase 1: Detect Project State

### Repository

Run `gh repo view --json nameWithOwner -q .nameWithOwner` to get the current repo. Stop if not in a GitHub-connected repo.

### CLAUDE.md

Read the project's CLAUDE.md (check both root and `.claude/CLAUDE.md`). Extract:
- **Labels**: from the Workflow section (e.g., `bug`, `chore`, `docs`, `feature`, `spec`, `spike`)
- **Branch naming**: convention for branch names
- **Commit style**: how commits reference issues
- **Milestone/phase structure**: any roadmap phases or milestones mentioned

If no labels are defined in CLAUDE.md, stop and tell the user to add a Labels line to their Workflow section first.

### Existing GitHub State

Run in parallel:
- `gh label list --repo <repo> --limit 100`
- `gh milestone list --repo <repo> --state all`
- `gh issue list --repo <repo> --state all --limit 200`

### Existing Markdown Tracking

Scan for files that might contain issues or roadmap items:
- `docs/tickets/*.md`, `docs/issues/*.md`
- `docs/specs/*.md`
- `ROADMAP.md`, `docs/roadmap.md`, `docs/roadmap/*.md`
- `TODO.md`, `TASKS.md`, `docs/TASKS.md`
- Any `PHASE_*.md` or `docs/PHASE_*.md`

Report what was found before proceeding.

---

## Phase 2: Normalize Labels

Compare current GitHub labels against what CLAUDE.md defines.

**Delete** any labels not in the expected set — this includes:
- Old prefixed labels (`status:*`, `priority:*`, `type:*`)
- GitHub default labels not in the expected set (`enhancement`, `good first issue`, `help wanted`, `invalid`, `question`, `wontfix`, `duplicate`, `documentation`)

**Create** any missing labels with these default colors (override if CLAUDE.md specifies colors):
- `bug` → `E11D48` (red)
- `feature` → `1D76DB` (blue)
- `chore` → `BFD4F2` (light blue)
- `docs` → `0075CA` (dark blue)
- `spec` → `D876E3` (purple)
- `spike` → `FBCA04` (yellow)

For any label not in the defaults above, pick a distinct color that doesn't collide.

**Skip** labels that already exist and match.

Present the label diff to the user and apply after confirmation.

---

## Phase 3: Set Up Milestones

If the project has roadmap/phase documentation (from Phase 1 scan), propose milestones.

Read each roadmap or phase file and extract:
- Phase name or number → milestone title
- Goal or description → milestone description
- Completion status → open or closed

**If milestones already exist on GitHub:**
- Match existing milestones to roadmap phases by name
- Report any that are missing or misnamed
- Propose creating missing ones, closing completed ones

**If no roadmap files exist:**
- Check if milestones already exist on GitHub — if so, leave them alone
- If nothing exists, skip this phase entirely

Create milestones with: `gh api repos/<repo>/milestones -f title="<name>" -f description="<desc>" -f state="<open|closed>"`

---

## Phase 4: Convert Markdown Issues

If markdown tracking files were found in Phase 1, convert them to GitHub issues.

For each file:
1. Read the file and extract individual issues/tasks/items
2. For each item, determine:
   - **Title**: the task or issue name
   - **Body**: description, acceptance criteria, technical notes — reference the original file path
   - **Label**: best match from the project's label set
   - **Milestone**: best match from available milestones (if applicable)
   - **State**: if clearly marked done/complete, the issue should be created then closed

**Before creating anything**, present the full list to the user:
- Issue title, label, milestone, open/closed
- Total count

Only proceed after user confirmation.

Create issues with:
```
gh issue create --title "<title>" --body "<body>" --label "<label>" --milestone "<milestone>" --repo <repo>
```

Close completed issues with:
```
gh issue close <number> --comment "Migrated from <file> — already completed" --repo <repo>
```

**If issues already exist on GitHub** (from a previous run or manual creation):
- Match by title similarity to avoid duplicates
- Report potential duplicates and skip them
- Only create genuinely new issues

---

## Phase 5: Normalize Existing Issues

For issues that already exist on GitHub:

**Labels**: Check each open issue's labels against the expected set.
- If an issue has old-style labels (`type:feature`, `status:todo`, etc.), replace them with the new equivalents
- If an issue has no label, flag it for the user

**Milestones**: If milestones were set up, check that issues are associated with the right milestone based on their content or original tracking file.

Apply label changes with:
```
gh issue edit <number> --remove-label "<old>" --add-label "<new>" --repo <repo>
```

---

## Phase 6: Clean Up

After everything is migrated and normalized:

1. Report the final state:
   - Total labels (created / deleted / unchanged)
   - Total milestones (created / closed / unchanged)
   - Total issues (created / closed / skipped as duplicate / relabeled)

2. If markdown files were converted, note which files are now redundant:
   - Don't delete them — just list them so the user can archive or remove them
   - Mention that CLAUDE.md should note these files as archived if it references them

3. Confirm the project's CLAUDE.md Workflow section is consistent with the current GitHub state. If it references old label formats or tracking files, suggest updates.

---

## Notes

- **Idempotent**: Running this again on a project that's already set up should be fast — it detects what's in sync and only fixes drift.
- **Non-destructive on issues**: Never deletes issues. Only creates, closes, or relabels.
- **User confirmation**: Every destructive or bulk action (label deletion, issue creation, milestone changes) requires explicit user approval before executing.
- **Pairs with wrap-up**: The `/wrap-up` command expects `gh issue close` with comments and milestone management. This command sets up the structure that wrap-up operates on.

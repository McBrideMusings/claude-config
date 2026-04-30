Close out the current session by updating tracking, documentation, and committing work.

Work through each phase below. Skip any phase that doesn't apply to this project — never create files, tracking systems, or documentation that doesn't already exist.

---

## Phase 1: Assess what was done

Summarize the work completed this session by reviewing:
- Recent conversation history
- `git diff` and `git status` for uncommitted changes
- Recent commits on the current branch (`git log --oneline -20`)

**Multiple repos:** If the session touched more than one repository, run a full wrap-up for each repo — separate commits, separate tracking updates, and separate follow-up lists per repo. Do not bundle cross-repo follow-ups together.

---

## Phase 2: Update project tracking

Check for and update ANY of these tracking mechanisms that exist. Do not create any that don't exist.

### GitHub Issues and Milestones
- Run `gh issue list --state open` to find resolved issues; close with `gh issue close NUMBER --comment "reason"`
- **Milestones** — `gh` has no `milestone` subcommand. Use the API:
  - List: `gh api repos/{owner}/{repo}/milestones --jq '.[] | "\(.number) \(.title) \(.open_issues)/\(.open_issues + .closed_issues)"'`
  - Close (when 0 open issues remain): `gh api repos/{owner}/{repo}/milestones/NUMBER -X PATCH -f state=closed`
- **Always** check milestones after closing issues — if a milestone has 0 open issues, close it immediately

### Roadmap / TODO documents
- Check for roadmap or TODO files: `ROADMAP.md`, `TODO.md`, `docs/roadmap.md`, or similar
- If found: mark completed items, update status, add notes on what was accomplished

### CLAUDE.md task tracking
- If CLAUDE.md contains a roadmap, milestone list, or task tracking section: update it to reflect completed work

### In-repo issue tracking
- Check for `.github/`, `docs/issues/`, or any other in-repo tracking
- Update as appropriate

---

## Phase 3: Update documentation

Update documentation files ONLY if they already exist and the session's changes affect them.

### Standard docs site (PRD / roadmap / file-map)

If the project has the standard layout (`docs/PRD.md`, `docs/roadmap.md`, `docs/file-map.md` — set up by the `/docs` skill), check session work against the update-when table from the project's CLAUDE.md.

Split changes into **mechanical** (apply silently, report in summary) and **substantive** (show diff, ask before applying):

**Mechanical — auto-apply, then report:**
- `docs/file-map.md` — when top-level files/folders were added, removed, renamed, or moved. Detect via `git diff --name-status` for the session's commits or working-tree changes. Update entries inline; don't restructure the file.
- `CLAUDE.md` "Documentation" section — when a new standard doc was created (e.g., `docs/api.md` didn't exist before, now it does → add the row to the update-when table).

**Substantive — propose with diff, ask before applying:**
- `docs/PRD.md` — any product behavior, scope, or surface-area change
- `docs/roadmap.md` — direction shifts, completed initiatives (move from Now → previous milestone or just remove), newly deferred items
- `docs/api.md` (if exists) — external API surface change
- `docs/architecture/*` (if exists) — subsystem behavior change

Print a "**Mechanical doc updates applied:**" summary listing what was changed without prompt. Then list each substantive proposal with a diff and ask before applying.

If `docs/` doesn't exist or doesn't follow the standard layout, skip this section silently.

### Other documentation

- **CLAUDE.md** (top-level) — update to reflect new features, changed architecture, new keyboard shortcuts, new configuration. Stay under 40k chars (`wc -m CLAUDE.md`). Don't duplicate code.
- **README.md** — update if session changes affect user-facing setup or features.
- **CONTRIBUTING.md, etc.** — update if session changes affect them.

---

## Phase 4: Code quality check

Before committing, run two parallel quality checks on the session's changes:

1. **Launch both in parallel using the Agent tool** (two agents in a single message):
   - A **code-simplifier agent** (subagent_type: "code-simplifier") to simplify and refine changed code
   - A **code-review agent** (subagent_type: "general-purpose") with the full contents of the /code-review command prompt, reviewing uncommitted changes for bugs and CLAUDE.md compliance

2. Wait for both agents to complete
3. Apply any simplifications from the code-simplifier agent
4. Address any issues scored 75+ from the code review — fix them before committing
5. If either agent found nothing actionable, proceed to Phase 5

---

## Phase 5: Commit and finalize

1. Stage and commit all remaining changes (documentation updates, tracking updates, quality fixes, any straggling code changes)
   - Use the project's commit message conventions (check CLAUDE.md for rules)
   - If no conventions exist: one short sentence describing what changed
2. Confirm the final state: `git status` should be clean
3. Push to origin if a remote exists: `git push origin $(git branch --show-current)`
4. If working on a feature branch: mention whether it's ready to merge (but don't merge without being asked)

---

## Phase 6: Session summary and follow-ups

Give a brief summary of:
- What was accomplished this session
- What tracking/docs were updated

Then invoke the `suggest-followups` skill using the Skill tool to generate, present, and file follow-up items.

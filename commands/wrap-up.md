Close out the current session by updating tracking, documentation, and committing work.

Work through each phase below. Skip any phase that doesn't apply to this project — never create files, tracking systems, or documentation that doesn't already exist.

---

## Phase 1: Assess what was done

Summarize the work completed this session by reviewing:
- Recent conversation history
- `git diff` and `git status` for uncommitted changes
- Recent commits on the current branch (`git log --oneline -20`)

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

### CLAUDE.md
- Update to reflect new features, changed architecture, new files, new keyboard shortcuts, new configuration, etc.
- Stay under the 40k character limit (`wc -m CLAUDE.md`). Trim verbose sections if needed.
- Do not duplicate information that's obvious from the code.

### README.md
- Update if session changes affect user-facing documentation — new features, setup steps, configuration, or usage.

### docs/ folder
- If a documentation site exists (VitePress, Docusaurus, etc.): update files covering areas affected by session changes.

### Other documentation
- Check for and update any other documentation files that exist and are affected (CONTRIBUTING.md, API docs, etc.)

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

## Phase 6: Session summary

Give a brief summary of:
- What was accomplished this session
- What tracking/docs were updated

Then compile a numbered list of **5-10 actionable follow-up items** discovered during the session. These should include anything worth addressing later — not just blockers, but also:
- Code smells or cleanup opportunities
- Architectural improvements
- UX/UI refinements noticed while working
- Performance or efficiency wins
- Feature ideas that came up naturally
- Bugs or edge cases spotted but not fixed
- Test coverage gaps

For each item, write a one-line title and a brief description (1-2 sentences explaining the issue and why it matters).

After presenting the list, ask the user: **"Which of these should I file as GitHub issues?"** — accept numbers, ranges, "all", or "none". Then file the selected items using `gh issue create`.

Generate a list of follow-up suggestions from the current session, present them to the user, and file the selected ones in the appropriate destination.

## Step 1: Build context (if not already known)

If this skill is invoked standalone (not from wrap-up), quickly orient yourself:
- `git log --oneline -20` to see recent commits
- Scan the current conversation for what was built, changed, or discussed this session

## Step 2: Compile suggestions

Generate a numbered list of **5-10 actionable follow-up items** discovered during the session. Include anything worth addressing later — not just blockers, but also:
- Code smells or cleanup opportunities
- Architectural improvements
- UX/UI refinements noticed while working
- Performance or efficiency wins
- Feature ideas that came up naturally
- Bugs or edge cases spotted but not fixed
- Test coverage gaps

For each item, write a one-line title and a brief description (1-2 sentences explaining the issue and why it matters).

**If the session touched multiple repos, present a separate follow-up list per repo and ask which items to persist for each repo independently.**

## Step 3: Determine destination

**Destination decision — this is the only choice this skill makes. Everything else is delegated.**

GitHub issues are ONLY an available destination when a remote is owned by `McBrideMusings` (case-insensitive). No other owner qualifies — not orgs, not repos with push access, not upstream repos being contributed to. Only `McBrideMusings`-owned remotes.

Use a two-pass check:

**Pass 1 — default remote:**
```
cd <project_dir> && gh repo view --json owner --jq '.owner.login'
```
If this returns `McBrideMusings` (case-insensitive), use this repo. Done.

**Pass 2 — all remotes (run only if Pass 1 didn't match):**
```
git remote -v
```
Parse each remote URL for `github.com`. For any remote URL containing `github.com`, extract the `OWNER/REPO` slug (works for both `git@github.com:OWNER/REPO.git` and `https://github.com/OWNER/REPO`). For each unique slug, check:
```
gh repo view OWNER/REPO --json owner --jq '.owner.login'
```
If any remote resolves to `McBrideMusings`, use that repo (`OWNER/REPO`) as the target. Prefer a remote named `mine` over others if multiple match.

**Filing:**
- **McBrideMusings repo found (either pass):** file via `gh issue create --repo OWNER/REPO` (one issue per selected follow-up). Before filing, run `gh issue list --repo OWNER/REPO --state all --limit 50` and skip items whose core idea already appears as an open or recently-closed issue.
- **No McBrideMusings remote found anywhere:** use the `followups` skill. Invoke it via the Skill tool; it owns the file format, path, and dedupe logic. Do NOT offer GitHub issues. Do NOT hand-write to `~/.claude/followups/` yourself.

When in doubt, use the followups skill.

## Step 4: Ask and file

Ask the user exactly one question, naming the single determined destination — e.g. **"Which of these should I file as GitHub issues? (numbers, ranges, 'all', or 'none')"** (McBrideMusings repo) or **"Which of these should I save via the followups skill? (numbers, ranges, 'all', or 'none')"** (every other case). Never offer both.

If the user says "none", write nothing. Do not split items across destinations. Do not infer intent from silence.

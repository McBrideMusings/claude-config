#!/usr/bin/env bash
# SessionStart hook: keep local repos current with origin.
# Syncs both the session cwd's repo and ~/.claude (if it's a separate repo).
# Silent on success / non-repo / no-network. Notifies via additionalContext only
# when the user needs to do something (divergence, dirty tree, pulled commits).
# Always exits 0 so a hook bug never blocks session start.

set -u

input=$(cat 2>/dev/null || true)

cwd="$PWD"
if [ -n "$input" ] && command -v jq >/dev/null 2>&1; then
    hook_cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
    [ -n "$hook_cwd" ] && cwd="$hook_cwd"
fi

# Pick a timeout wrapper if one is available; otherwise fetch without one.
# `timeout` is GNU coreutils — present on Linux and on Macs with `brew install
# coreutils` (as `gtimeout`), but not on stock macOS. Without it, a slow or
# captive network can hang session start; with it, a hung fetch gets killed
# and sync_repo bails silently.
if command -v timeout >/dev/null 2>&1; then
    fetch_timeout=(timeout 5)
elif command -v gtimeout >/dev/null 2>&1; then
    fetch_timeout=(gtimeout 5)
else
    fetch_timeout=()
fi

messages=()

# Run sync logic in a subshell so cd and any local state stays scoped.
# Emits zero or more lines to stdout — caller appends them to $messages.
sync_repo() (
    local repo_dir="$1"
    local label="$2"
    local pull_suffix="${3:-}"

    [ -d "$repo_dir" ] || return 0
    cd "$repo_dir" 2>/dev/null || return 0
    git rev-parse --git-dir >/dev/null 2>&1 || return 0
    # bash 3.2 errors on "${arr[@]}" when arr is empty under `set -u`,
    # so use the ${arr[@]+...} guard form.
    ${fetch_timeout[@]+"${fetch_timeout[@]}"} git fetch --quiet origin 2>/dev/null || return 0

    local current_branch
    current_branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")

    # Keep local main current with origin/main when we're not on main.
    # `git fetch . origin/main:main` fast-forwards main if possible;
    # if main has diverged it fails silently and we report the divergence.
    if [ "$current_branch" != "main" ] \
       && git show-ref --verify --quiet refs/heads/main \
       && git show-ref --verify --quiet refs/remotes/origin/main; then
        git fetch . origin/main:main 2>/dev/null || true
        local a b
        a=$(git rev-list --count origin/main..main 2>/dev/null || echo 0)
        b=$(git rev-list --count main..origin/main 2>/dev/null || echo 0)
        if [ "$a" -gt 0 ] && [ "$b" -gt 0 ]; then
            echo "[${label}] Local 'main' has diverged from origin/main (${a} local, ${b} remote). Did not auto-merge."
        fi
    fi

    # Sync the current branch with its upstream.
    [ -n "$current_branch" ] || return 0
    local upstream
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
    [ -n "$upstream" ] || return 0

    local ahead behind
    ahead=$(git rev-list --count "${upstream}..HEAD" 2>/dev/null || echo 0)
    behind=$(git rev-list --count "HEAD..${upstream}" 2>/dev/null || echo 0)

    if [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then
        echo "[${label}] ${current_branch} has diverged from ${upstream} (${ahead} local, ${behind} remote). Manual reconciliation needed."
    elif [ "$behind" -gt 0 ]; then
        if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
            echo "[${label}] ${current_branch} is ${behind} commit(s) behind ${upstream}. Working tree dirty — skipped auto-pull."
        elif git merge --ff-only --quiet "$upstream" 2>/dev/null; then
            echo "[${label}] Pulled ${behind} commit(s) from ${upstream} into ${current_branch}.${pull_suffix}"
        else
            echo "[${label}] ${current_branch} is ${behind} commit(s) behind ${upstream} but auto fast-forward failed."
        fi
    fi
)

collect() {
    local line
    while IFS= read -r line; do
        [ -n "$line" ] && messages+=("$line")
    done < <(sync_repo "$@")
}

collect "$cwd" "session repo"

claude_dir="${HOME}/.claude"
if [ -d "$claude_dir" ]; then
    cwd_real=$(cd "$cwd" 2>/dev/null && pwd -P || echo "")
    claude_real=$(cd "$claude_dir" 2>/dev/null && pwd -P || echo "")
    if [ -n "$claude_real" ] && [ "$cwd_real" != "$claude_real" ]; then
        collect "$claude_dir" "~/.claude config" " Reload this session to pick up the changes."
    fi
fi

if [ ${#messages[@]} -gt 0 ]; then
    text=$(printf '%s\n' "${messages[@]}")
    if command -v jq >/dev/null 2>&1; then
        jq -n --arg ctx "$text" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
    else
        escaped=$(printf '%s' "$text" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))' 2>/dev/null)
        if [ -n "$escaped" ]; then
            printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$escaped"
        fi
    fi
fi

exit 0

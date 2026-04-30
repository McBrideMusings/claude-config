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

messages=()

sync_repo() {
    local repo_dir="$1"
    local label="$2"
    local pull_suffix="${3:-}"

    [ -d "$repo_dir" ] || return 0
    cd "$repo_dir" 2>/dev/null || return 0
    git rev-parse --git-dir >/dev/null 2>&1 || return 0
    git fetch --quiet origin 2>/dev/null || return 0

    local current_branch
    current_branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")

    if git show-ref --verify --quiet refs/heads/main \
       && git show-ref --verify --quiet refs/remotes/origin/main \
       && [ "$current_branch" != "main" ]; then
        git fetch . origin/main:main 2>/dev/null || true
        local lm rm
        lm=$(git rev-parse main 2>/dev/null || echo "")
        rm=$(git rev-parse origin/main 2>/dev/null || echo "")
        if [ -n "$lm" ] && [ -n "$rm" ] && [ "$lm" != "$rm" ]; then
            local a b
            a=$(git rev-list --count origin/main..main 2>/dev/null || echo 0)
            b=$(git rev-list --count main..origin/main 2>/dev/null || echo 0)
            if [ "$b" -gt 0 ] && [ "$a" -gt 0 ]; then
                messages+=("[${label}] Local 'main' has diverged from origin/main (${a} local, ${b} remote). Did not auto-merge.")
            fi
        fi
    fi

    if [ -n "$current_branch" ]; then
        local upstream
        upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
        if [ -n "$upstream" ]; then
            local local_sha remote_sha
            local_sha=$(git rev-parse HEAD 2>/dev/null || echo "")
            remote_sha=$(git rev-parse "$upstream" 2>/dev/null || echo "")
            if [ -n "$local_sha" ] && [ -n "$remote_sha" ] && [ "$local_sha" != "$remote_sha" ]; then
                local ahead behind
                ahead=$(git rev-list --count "${upstream}..HEAD" 2>/dev/null || echo 0)
                behind=$(git rev-list --count "HEAD..${upstream}" 2>/dev/null || echo 0)
                if [ "$behind" -gt 0 ] && [ "$ahead" -eq 0 ]; then
                    if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
                        if git merge --ff-only --quiet "$upstream" 2>/dev/null; then
                            messages+=("[${label}] Pulled ${behind} commit(s) from ${upstream} into ${current_branch}.${pull_suffix}")
                        else
                            messages+=("[${label}] ${current_branch} is ${behind} commit(s) behind ${upstream} but auto fast-forward failed.")
                        fi
                    else
                        messages+=("[${label}] ${current_branch} is ${behind} commit(s) behind ${upstream}. Working tree dirty — skipped auto-pull.")
                    fi
                elif [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then
                    messages+=("[${label}] ${current_branch} has diverged from ${upstream} (${ahead} local, ${behind} remote). Manual reconciliation needed.")
                fi
            fi
        fi
    fi
}

sync_repo "$cwd" "session repo"

claude_dir="${HOME}/.claude"
if [ -d "$claude_dir" ]; then
    cwd_real=$(cd "$cwd" 2>/dev/null && pwd -P || echo "")
    claude_real=$(cd "$claude_dir" 2>/dev/null && pwd -P || echo "")
    if [ -n "$claude_real" ] && [ "$cwd_real" != "$claude_real" ]; then
        sync_repo "$claude_dir" "~/.claude config" " Reload this session to pick up the changes."
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

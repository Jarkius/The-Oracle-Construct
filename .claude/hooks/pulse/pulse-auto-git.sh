#!/usr/bin/env bash
set -euo pipefail
#
# File: .claude/hooks/pulse-auto-git.sh
#
# Phase J: Auto Git Ops
#
# Monitors task completions and git state to suggest/create PRs,
# detect uncommitted work, and manage branch hygiene.
#
# Usage:
#   bash pulse-auto-git.sh check         # Check git state + suggest actions
#   bash pulse-auto-git.sh pr-ready      # Check if current branch is PR-ready
#   bash pulse-auto-git.sh suggest-pr    # Generate PR title/body from commits
#   bash pulse-auto-git.sh stale         # Find stale branches
#   bash pulse-auto-git.sh uncommitted   # Warn about uncommitted changes
#

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EVENT_WRITER="$PROJECT_ROOT/.claude/hooks/pulse/pulse-event-writer.sh"

ACTION="${1:-help}"
shift || true

case "$ACTION" in

# ─── CHECK: Full git state analysis ──────────────────────────
check)
    cd "$PROJECT_ROOT"
    echo "[git-ops] Analyzing git state..."
    echo ""

    # Current branch
    BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
    echo "  Branch: $BRANCH"

    # Uncommitted changes
    CHANGES=$(git status --short 2>/dev/null | wc -l | tr -d '[:space:]')
    if [ "$CHANGES" -gt 0 ]; then
        echo "  Uncommitted: $CHANGES file(s)"
        echo "    Action: Commit or stash before switching context"
    else
        echo "  Working tree: clean"
    fi

    # Ahead/behind remote
    if git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
        AHEAD=$(git rev-list --count "origin/$BRANCH..$BRANCH" 2>/dev/null || echo "0")
        BEHIND=$(git rev-list --count "$BRANCH..origin/$BRANCH" 2>/dev/null || echo "0")
        [ "$AHEAD" -gt 0 ] && echo "  Ahead of remote: $AHEAD commit(s) — needs push"
        [ "$BEHIND" -gt 0 ] && echo "  Behind remote: $BEHIND commit(s) — needs pull"
        [ "$AHEAD" -eq 0 ] && [ "$BEHIND" -eq 0 ] && echo "  Remote: up to date"
    else
        echo "  Remote: no tracking branch"
    fi

    # Commits since main
    MAIN_BRANCH="main"
    git rev-parse --verify "$MAIN_BRANCH" >/dev/null 2>&1 || MAIN_BRANCH="master"
    if [ "$BRANCH" != "$MAIN_BRANCH" ] && git rev-parse --verify "$MAIN_BRANCH" >/dev/null 2>&1; then
        COMMITS_AHEAD=$(git rev-list --count "$MAIN_BRANCH..$BRANCH" 2>/dev/null || echo "0")
        echo "  Commits since $MAIN_BRANCH: $COMMITS_AHEAD"
        if [ "$COMMITS_AHEAD" -gt 5 ]; then
            echo "    Action: Consider creating a PR"
        fi
    fi

    echo ""
    ;;

# ─── PR-READY: Check if branch is ready for PR ──────────────
pr-ready)
    cd "$PROJECT_ROOT"
    BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
    MAIN_BRANCH="main"
    git rev-parse --verify "$MAIN_BRANCH" >/dev/null 2>&1 || MAIN_BRANCH="master"

    echo "[git-ops] PR Readiness Check"
    echo ""

    READY=true

    # Check: not on main
    if [ "$BRANCH" = "$MAIN_BRANCH" ]; then
        echo "  [FAIL] On $MAIN_BRANCH — need a feature branch"
        READY=false
    else
        echo "  [OK] On feature branch: $BRANCH"
    fi

    # Check: no uncommitted changes
    CHANGES=$(git status --short 2>/dev/null | wc -l | tr -d '[:space:]')
    if [ "$CHANGES" -gt 0 ]; then
        echo "  [FAIL] $CHANGES uncommitted file(s)"
        READY=false
    else
        echo "  [OK] Working tree clean"
    fi

    # Check: has commits ahead of main
    if [ "$BRANCH" != "$MAIN_BRANCH" ]; then
        COMMITS_AHEAD=$(git rev-list --count "$MAIN_BRANCH..$BRANCH" 2>/dev/null || echo "0")
        if [ "$COMMITS_AHEAD" -eq 0 ]; then
            echo "  [FAIL] No commits ahead of $MAIN_BRANCH"
            READY=false
        else
            echo "  [OK] $COMMITS_AHEAD commit(s) ahead of $MAIN_BRANCH"
        fi
    fi

    # Check: pushed to remote
    if git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
        UNPUSHED=$(git rev-list --count "origin/$BRANCH..$BRANCH" 2>/dev/null || echo "0")
        if [ "$UNPUSHED" -gt 0 ]; then
            echo "  [WARN] $UNPUSHED unpushed commit(s)"
        else
            echo "  [OK] All commits pushed"
        fi
    else
        echo "  [WARN] Branch not pushed to remote"
    fi

    echo ""
    if [ "$READY" = "true" ]; then
        echo "  VERDICT: Ready for PR"
    else
        echo "  VERDICT: Not ready — fix issues above"
    fi
    ;;

# ─── SUGGEST-PR: Generate PR title/body ─────────────────────
suggest-pr)
    cd "$PROJECT_ROOT"
    BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
    MAIN_BRANCH="main"
    git rev-parse --verify "$MAIN_BRANCH" >/dev/null 2>&1 || MAIN_BRANCH="master"

    if [ "$BRANCH" = "$MAIN_BRANCH" ]; then
        echo "[git-ops] Can't suggest PR from $MAIN_BRANCH"
        exit 1
    fi

    COMMITS=$(git log --oneline "$MAIN_BRANCH..$BRANCH" 2>/dev/null)
    COMMIT_COUNT=$(echo "$COMMITS" | wc -l | tr -d '[:space:]')
    FILES_CHANGED=$(git diff --name-only "$MAIN_BRANCH..$BRANCH" 2>/dev/null | wc -l | tr -d '[:space:]')
    DIFF_STAT=$(git diff --stat "$MAIN_BRANCH..$BRANCH" 2>/dev/null | tail -1)

    echo "## Suggested PR"
    echo ""
    echo "**Branch**: $BRANCH → $MAIN_BRANCH"
    echo "**Commits**: $COMMIT_COUNT"
    echo "**Files changed**: $FILES_CHANGED"
    echo "**Stats**: $DIFF_STAT"
    echo ""
    echo "### Title"

    # Extract title from branch name or first commit
    TITLE=$(echo "$BRANCH" | sed 's/^claude\///' | sed 's/-/ /g' | sed 's/[A-Za-z0-9]*$//' | sed 's/ $//')
    echo "$TITLE"

    echo ""
    echo "### Commits"
    echo "$COMMITS"

    echo ""
    echo "### Changed Files"
    git diff --name-only "$MAIN_BRANCH..$BRANCH" 2>/dev/null | head -20
    ;;

# ─── STALE: Find stale branches ─────────────────────────────
stale)
    cd "$PROJECT_ROOT"
    echo "[git-ops] Stale Branch Check"
    echo ""

    STALE_DAYS="${1:-14}"
    CUTOFF=$(date -u -d "-${STALE_DAYS} days" '+%Y-%m-%d' 2>/dev/null || date -u -v-${STALE_DAYS}d '+%Y-%m-%d' 2>/dev/null || echo "2026-01-01")

    git for-each-ref --sort=-committerdate refs/heads/ --format='%(committerdate:short) %(refname:short)' 2>/dev/null | while read -r date branch; do
        if [ "$date" \< "$CUTOFF" ]; then
            echo "  [stale] $branch (last commit: $date)"
        fi
    done || echo "  No stale branches (or date parsing unavailable)"
    ;;

# ─── UNCOMMITTED: Warn about uncommitted work ───────────────
uncommitted)
    cd "$PROJECT_ROOT"
    CHANGES=$(git status --short 2>/dev/null)
    if [ -n "$CHANGES" ]; then
        COUNT=$(echo "$CHANGES" | wc -l | tr -d '[:space:]')
        echo "[git-ops] WARNING: $COUNT uncommitted file(s):"
        echo "$CHANGES" | head -10
        if [ "$COUNT" -gt 10 ]; then
            echo "  ... and $((COUNT - 10)) more"
        fi
    else
        echo "[git-ops] Working tree clean"
    fi
    ;;

# ─── HELP ────────────────────────────────────────────────────
*)
    echo "Auto Git Ops — Phase J"
    echo ""
    echo "Usage:"
    echo "  check         Full git state analysis"
    echo "  pr-ready      Check if branch is PR-ready"
    echo "  suggest-pr    Generate PR title/body from commits"
    echo "  stale [days]  Find stale branches (default: 14 days)"
    echo "  uncommitted   Warn about uncommitted changes"
    ;;

esac

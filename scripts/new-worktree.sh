#!/usr/bin/env bash
# Create a detached git worktree for a task. Keeps the user's main checkout clean.
# Usage: ./scripts/new-worktree.sh <repo-name> <TICKET>-<kebab-summary>
#
# Creates: ~/Workspace/.factory-worktrees/<repo-name>-<TICKET>-<kebab-summary>
# Branches from the repo's default remote branch.
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <repo-name> <branch-name>" >&2
  exit 1
fi

REPO_NAME="$1"
BRANCH="$2"
REPO_DIR="$HOME/Workspace/$REPO_NAME"
WORKTREE_ROOT="$HOME/Workspace/.factory-worktrees"
WORKTREE_DIR="$WORKTREE_ROOT/$REPO_NAME-$BRANCH"

[ -d "$REPO_DIR/.git" ] || { echo "Not a git repo: $REPO_DIR" >&2; exit 1; }

mkdir -p "$WORKTREE_ROOT"
cd "$REPO_DIR"
git fetch origin
DEFAULT="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"
DEFAULT="${DEFAULT:-main}"

git worktree add -b "$BRANCH" "$WORKTREE_DIR" "origin/$DEFAULT"
echo "Worktree ready: $WORKTREE_DIR (branch $BRANCH from origin/$DEFAULT)"
echo "To remove when done:"
echo "  git -C $REPO_DIR worktree remove $WORKTREE_DIR"

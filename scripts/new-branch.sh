#!/usr/bin/env bash
# Create a feature branch in a target repo from its default branch.
# Usage: ./scripts/new-branch.sh <repo-name> <branch-name>
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <repo-name> <branch-name>" >&2
  exit 1
fi

REPO_DIR="$HOME/Workspace/$1"
BRANCH="$2"

[ -d "$REPO_DIR/.git" ] || { echo "Not a git repo: $REPO_DIR" >&2; exit 1; }

cd "$REPO_DIR"
DEFAULT="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"
DEFAULT="${DEFAULT:-main}"

git fetch origin
git checkout "$DEFAULT"
git pull --ff-only
git checkout -b "$BRANCH"
echo "Ready: $REPO_DIR on $BRANCH (from $DEFAULT)"

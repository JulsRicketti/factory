#!/usr/bin/env bash
# List sibling repos under ~/Workspace that look like git checkouts.
set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$HOME/Workspace}"

for dir in "$WORKSPACE_ROOT"/*/; do
  name="$(basename "$dir")"
  if [ -d "$dir/.git" ]; then
    branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
    printf "%-40s  %s\n" "$name" "$branch"
  fi
done

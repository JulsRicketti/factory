#!/usr/bin/env bash
# Watch a PR's checks and recent comments.
# Usage: ./scripts/watch-pr.sh <owner>/<repo> <pr-number>
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <owner>/<repo> <pr-number>" >&2
  exit 1
fi

REPO="$1"
PR="$2"

command -v gh >/dev/null || { echo "gh CLI required" >&2; exit 1; }

while true; do
  clear
  echo "=== PR $REPO#$PR @ $(date '+%H:%M:%S') ==="
  gh pr view "$PR" --repo "$REPO" --json state,mergeStateStatus,reviewDecision,statusCheckRollup \
    --template '{{.state}}  merge:{{.mergeStateStatus}}  review:{{.reviewDecision}}
{{range .statusCheckRollup}}  - {{.name}}: {{.conclusion}}{{"\n"}}{{end}}' || true
  echo
  echo "--- recent comments ---"
  gh pr view "$PR" --repo "$REPO" --comments | tail -40 || true
  sleep 30
done

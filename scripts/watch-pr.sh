#!/usr/bin/env bash
# Watch a PR with a "blocker fingerprint" — a hash of
#   (unresolved review comment ids + check-run conclusions + merge state).
# When the fingerprint changes, print the new state. Optionally run a hook.
#
export GH_PAGER=cat
# Usage: ./scripts/watch-pr.sh <owner>/<repo> <pr-number> [--on-change "<cmd>"] [--fix-on-start]
#
# --fix-on-start: also run the --on-change hook for the initial fingerprint,
#   so any pending review feedback at startup is processed once.
#
# Examples:
#   ./scripts/watch-pr.sh qlik-trial/hub-parcels 4521
#   ./scripts/watch-pr.sh qlik-trial/hub-parcels 4521 --on-change \
#     'copilot --add-dir ~/Workspace --allow-all-tools -p "Respond to review on hub-parcels#4521"'
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <owner>/<repo> <pr-number> [--on-change '<cmd>']" >&2
  exit 1
fi

REPO="$1"
PR="$2"
shift 2
ON_CHANGE=""
FIX_ON_START=0
while [ $# -gt 0 ]; do
  case "$1" in
    --on-change) ON_CHANGE="${2:-}"; shift 2 ;;
    --fix-on-start) FIX_ON_START=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

command -v gh >/dev/null   || { echo "gh CLI required" >&2; exit 1; }
command -v jq >/dev/null   || { echo "jq required"     >&2; exit 1; }

INTERVAL="${FACTORY_WATCH_INTERVAL:-30}"
LAST_FP=""

fingerprint() {
  # unresolved inline review comment ids
  local comments
  comments=$(gh api "repos/$REPO/pulls/$PR/comments" --paginate \
    --jq '[.[] | select(.in_reply_to_id == null) | .id] | sort | join(",")' 2>/dev/null || echo "")
  # issue comments (top-level PR conversation)
  local issue_comments
  issue_comments=$(gh api "repos/$REPO/issues/$PR/comments" --paginate \
    --jq '[.[] | .id] | sort | join(",")' 2>/dev/null || echo "")
  # review submissions (review bodies — these are NOT in /pulls/.../comments)
  local reviews
  reviews=$(gh api "repos/$REPO/pulls/$PR/reviews" --paginate \
    --jq '[.[] | select((.body // "") != "" or .state == "CHANGES_REQUESTED" or .state == "APPROVED") | "\(.id):\(.state)"] | sort | join(",")' 2>/dev/null || echo "")
  # check-run conclusions for HEAD
  local sha
  sha=$(gh pr view "$PR" --repo "$REPO" --json headRefOid --jq .headRefOid 2>/dev/null || echo "")
  local checks=""
  if [ -n "$sha" ]; then
    checks=$(gh api "repos/$REPO/commits/$sha/check-runs" \
      --jq '[.check_runs[] | "\(.name):\(.conclusion // .status)"] | sort | join(",")' 2>/dev/null || echo "")
  fi
  # merge + review state
  local meta
  meta=$(gh pr view "$PR" --repo "$REPO" \
    --json mergeStateStatus,reviewDecision,isDraft,state \
    --jq '"\(.state)|\(.isDraft)|\(.mergeStateStatus)|\(.reviewDecision)"' 2>/dev/null || echo "")

  printf "%s|%s|%s|%s|%s" "$comments" "$issue_comments" "$reviews" "$checks" "$meta" | shasum | awk '{print $1}'
}

print_state() {
  echo "=== PR $REPO#$PR @ $(date '+%Y-%m-%d %H:%M:%S') ==="
  gh pr view "$PR" --repo "$REPO" \
    --json state,isDraft,mergeStateStatus,reviewDecision,url,headRefName \
    --template '  branch: {{.headRefName}}
  state:  {{.state}}  draft:{{.isDraft}}  merge:{{.mergeStateStatus}}  review:{{.reviewDecision}}
  url:    {{.url}}
' || true
  echo "  checks:"
  local sha
  sha=$(gh pr view "$PR" --repo "$REPO" --json headRefOid --jq .headRefOid 2>/dev/null || echo "")
  [ -n "$sha" ] && gh api "repos/$REPO/commits/$sha/check-runs" \
    --jq '.check_runs[] | "    - \(.name): \(.conclusion // .status)"' 2>/dev/null || true
  echo
}

trap 'echo; echo "watch stopped."; exit 0' INT TERM

while true; do
  FP=$(fingerprint || echo "")
  if [ "$FP" != "$LAST_FP" ]; then
    clear
    print_state
    echo "  fingerprint: $FP  (was: ${LAST_FP:-<initial>})"
    if [ -n "$ON_CHANGE" ] && { [ -n "$LAST_FP" ] || [ "$FIX_ON_START" = "1" ]; }; then
      echo
      echo "--- running --on-change hook ---"
      bash -c "$ON_CHANGE" || echo "(hook exited non-zero)"
    fi
    LAST_FP="$FP"
  fi
  sleep "$INTERVAL"
done

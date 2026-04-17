#!/usr/bin/env bash
# Dump structured PR feedback for agent consumption.
# Usage: ./scripts/fetch-pr-feedback.sh <owner>/<repo> <pr-number>
#
# Emits JSON with: reviews, review_comments (inline), issue_comments, check_runs.
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <owner>/<repo> <pr-number>" >&2
  exit 1
fi

REPO="$1"
PR="$2"

command -v gh >/dev/null || { echo "gh CLI required" >&2; exit 1; }

echo "=== PR $REPO#$PR ==="

echo
echo "--- Overview ---"
gh pr view "$PR" --repo "$REPO" \
  --json number,title,state,isDraft,headRefName,baseRefName,mergeStateStatus,reviewDecision,url

echo
echo "--- Reviews (approve / changes / comment) ---"
gh api "repos/$REPO/pulls/$PR/reviews" \
  --jq '[.[] | {id, user: .user.login, state, submitted_at, body}]'

echo
echo "--- Inline review comments ---"
gh api "repos/$REPO/pulls/$PR/comments" --paginate \
  --jq '[.[] | {
    id,
    in_reply_to_id,
    user: .user.login,
    path,
    line: (.line // .original_line),
    side,
    commit_id,
    diff_hunk,
    body,
    html_url
  }]'

echo
echo "--- Issue comments (PR conversation) ---"
gh api "repos/$REPO/issues/$PR/comments" --paginate \
  --jq '[.[] | {id, user: .user.login, created_at, body, html_url}]'

echo
echo "--- Check runs (latest) ---"
HEAD_SHA="$(gh pr view "$PR" --repo "$REPO" --json headRefOid --jq .headRefOid)"
gh api "repos/$REPO/commits/$HEAD_SHA/check-runs" \
  --jq '[.check_runs[] | {name, status, conclusion, html_url, output_summary: .output.summary}]'

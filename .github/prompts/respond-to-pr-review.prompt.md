---
mode: agent
description: Fetch unresolved PR review comments, address them with code changes, push fixes, and reply to each comment.
---

Preconditions:

- A PR number + repo (e.g. `hub-parcels#4521`). If not supplied, ask.
- Matching local repo checked out under `~/Workspace/` on the PR branch.

Steps:

1. Run `./scripts/fetch-pr-feedback.sh <owner>/<repo> <pr-number>` from this factory repo to dump structured feedback (review comments, issue comments, review states, CI failures).
2. For each **unresolved** review comment:
   - Classify: _actionable change_, _question_, _nit_, _won't-fix_, _already addressed_.
   - For actionable items, open the referenced file/line in the target repo.
   - Apply the minimum change that addresses the comment.
3. Run the target repo's `lint` script (blocking). If tests must be run, run them in **background mode** (`isBackground: true` / `mode: async`) so they don't block the conversation — tail the output via `get_terminal_output` when you need the result. Fix regressions.
4. Commit with a message like `fix: address review comments (<TICKET>)`. Use separate commits per logical concern when practical.
5. `git push` to the PR branch. Never force-push unless the user approves.
6. Reply to each review thread via the GitHub MCP:
   - For actioned items: short reply referencing the commit SHA.
   - For won't-fix / questions: explain reasoning and ask for confirmation.
   - Mark resolved only when the author's intent is clearly satisfied.
7. If CI is failing, analyse the failure from the fetched feedback and fix it.
8. After pushing, call the **learn-from-pr** prompt to capture any lessons into memory.

Output to user:

- List of comments addressed (with commit SHAs)
- List of comments left unresolved (with reasoning)
- New CI status

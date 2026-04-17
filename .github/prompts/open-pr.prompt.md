---
mode: agent
description: Open a PR for the current branch in the active target repo and link it back to its Jira ticket.
---

Preconditions:
- `cwd` is a target repo under `~/Workspace/` with a pushed feature branch.
- Branch name contains the Jira ticket key.

Steps:

1. Confirm current branch and remote: `git rev-parse --abbrev-ref HEAD` and `git remote -v`.
2. Ensure the branch is pushed: `git push -u origin <branch>` if needed.
3. Extract the Jira key from the branch name.
4. `mcp_jira_get_issue` to fetch ticket title + description for the PR body.
5. Open the PR via the GitHub MCP as a **draft** with:
   - Title: Conventional Commits with the Jira ticket as the scope, e.g. `fix(HUB-12345): short summary` (or `feat(...)`, `chore(...)`, `refactor(...)`, etc.).
   - Body:
     - Jira link
     - Summary
     - Test plan
     - Checklist (lint, tests, translations if applicable)
6. Immediately after opening the PR, post a `#devbuild-test` comment on it to trigger the dev build pipeline.
7. Comment on the Jira ticket with the PR URL.
8. Fetch valid transitions and move the ticket to _In Review_.
9. Return PR URL + Jira URL.

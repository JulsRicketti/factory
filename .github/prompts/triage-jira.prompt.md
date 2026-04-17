---
mode: agent
description: Triage a Jira ticket — read it, assess scope, identify target repo + files, and produce an implementation plan without writing code.
---

Read-only planning pass. Do not modify any code.

1. `mcp_jira_get_issue` for the ticket key.
2. Identify likely target repo(s) under `~/Workspace/`.
3. Use workspace search to find likely files/components touched.
4. Produce an implementation plan:
   - Target repo + branch name suggestion
   - Files to change (with links)
   - Risks / open questions for the user
   - Estimated PR size (S/M/L)

Return the plan to the user. Wait for approval before implementing.

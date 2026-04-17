---
mode: agent
description: Take a Jira ticket end-to-end — read it, implement it in the correct local repo, and open a PR.
---

You are running the **factory** workflow. Follow [AGENTS.md](../../AGENTS.md) exactly.

Inputs expected from the user:
- A Jira ticket key (e.g. `HUB-12345`)
- Optional: target repo override

Steps:

1. Call `mcp_jira_get_issue` with the ticket key. Summarise: title, acceptance criteria, linked issues.
2. Decide the target repo under `~/Workspace/`. If ambiguous, ask the user.
3. Prepare the repo:
   ```bash
   cd ~/Workspace/<target-repo>
   git fetch origin
   git checkout <default-branch>
   git pull --ff-only
   git checkout -b <TICKET>-<kebab-summary>
   ```
4. Load the target repo's `AGENTS.md` and instruction files. Implement the change following its conventions.
5. Run the repo's `test` and `lint` scripts. Fix failures.
6. Commit: `feat(<scope>): <summary> (<TICKET>)`.
7. Push and open a PR via the GitHub MCP as a **draft**. Title uses Conventional Commits with the Jira ticket as the scope, e.g. `fix(HUB-12345): short summary` (or `feat(...)`, `chore(...)`, `refactor(...)`, etc. — pick the type that matches the change). Body must include the Jira link, change summary, and test plan.
8. Immediately after opening the PR, post a comment containing `#devbuild-test` to trigger the dev build pipeline. This is mandatory for every PR the factory creates.
9. Add a comment on the Jira ticket with the PR URL. Fetch valid transitions and move the ticket to _In Review_.
10. Return to the user: branch name, PR URL, Jira URL.

Do **not**:
- Commit to `main`.
- Force-push.
- Modify files in `~/Workspace/factory` as part of the implementation.
- Merge the PR unless the user explicitly asks.

# Copilot instructions: factory

This workspace is a **control repo**, not a product repo. See [AGENTS.md](../AGENTS.md) for the full agent contract.

## Hard rules

1. **Do not modify code in this repo** to implement a Jira ticket. Switch `cwd` to the target sibling repo under `~/Workspace/` first.
2. When operating in a target repo, load and follow **that** repo's `AGENTS.md`, `.github/copilot-instructions.md`, and `.github/instructions/`.
3. Use MCP tools in this order of preference:
   - Jira operations → `mcp_jira_*`
   - GitHub operations → `mcp_github_*`
   - Fall back to `gh` CLI only if an MCP call is unavailable.
4. Always create a feature branch from the target repo's default branch. Never commit to `main`.
5. Link the PR back on the Jira ticket and transition the ticket after opening the PR.

## Typical flow

> "Take HUB-12345 and implement it."

1. `mcp_jira_get_issue` → read ticket
2. `cd` into the target repo under `~/Workspace/`
3. Branch, implement, test, commit, push
4. Open PR via GitHub MCP
5. Comment Jira with PR link + transition to _In Review_
6. Return PR URL to the user

## Clarification thresholds

Ask before:
- Selecting a target repo when ambiguous
- Force-pushing or rewriting history
- Closing or resolving Jira tickets
- Merging PRs

# factory

A lightweight control repo that connects Copilot / agents to **Jira** and **GitHub** MCPs and drives a repeatable workflow:

> **Jira ticket → local implementation in the target repo → commit → PR → watch.**

This repo does **not** contain product code. It contains:

- MCP server configuration (`.vscode/mcp.json`)
- Copilot instructions (`.github/copilot-instructions.md`, [AGENTS.md](AGENTS.md))
- Reusable prompts (`.github/prompts/`)
- A dedicated chat mode (`.github/chatmodes/factory.chatmode.md`)
- Helper scripts (`scripts/`)

## Target repos

Sibling folders under `~/Workspace/` — e.g. `hub-parcels`, `hub`, `hub-common`, `mc-parcels`, etc. The factory agent operates on whichever repo a Jira ticket points to.

## Quick start

1. Open this folder in VS Code.
2. Accept the MCP server startup prompts (Jira + GitHub).
3. Open the **Factory** chat mode and say something like:

   > Take `HUB-12345` and implement it.

4. The agent will:
   - Read the Jira ticket (`mcp_jira_get_issue`)
   - Pick the right local repo under `~/Workspace/`
   - Create a branch, implement, run tests/lint
   - Commit and open a PR (via GitHub MCP or `gh`)
   - Link the PR back on the Jira ticket
   - Transition the ticket to _In Review_

## Commands

| Task                            | Command                                            |
| ------------------------------- | -------------------------------------------------- |
| Watch a PR's checks/comments    | `./scripts/watch-pr.sh <owner>/<repo> <pr-number>` |
| List repos under `~/Workspace/` | `./scripts/list-repos.sh`                          |

See [AGENTS.md](AGENTS.md) for the full agent contract.

# factory

A lightweight control repo that connects Copilot (CLI + VS Code) to **Jira** and **GitHub** MCPs and drives a repeatable 9-stage loop:

> **INGEST → UNDERSTAND → PLAN → PREPARE → IMPLEMENT → VERIFY → SUBMIT → WATCH → FIX/LEARN**

This is your **autonomous development loop**. See [AGENTS.md](AGENTS.md) for the full agent contract.

This repo does **not** contain product code. It contains:

- MCP server configuration for VS Code (`.vscode/mcp.json`) and Copilot CLI (`.mcp.json`)
- The agent contract ([AGENTS.md](AGENTS.md)) and Copilot instructions (`.github/copilot-instructions.md`)
- Reusable prompts (`.github/prompts/`) — starter, triage, PR open, review response, learning
- A VS Code chat mode (`.github/chatmodes/Factory.chatmode.md`)
- Helper scripts (`scripts/`) — worktree, watch loop with blocker fingerprint, PR feedback dump
- Learned lessons seed (`.factory/lessons.md`)

## Target repos

Sibling folders under `~/Workspace/` — e.g. `hub-parcels`, `hub`, `hub-common`, `mc-parcels`. The agent operates on whichever repo a Jira ticket points to, always via a **git worktree** so your main checkout stays clean.

## Pre-flight checklist

Verify each of these before running the factory for the first time.

| Tool                       | Install                                                                       | Verify                                     |
| -------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------ |
| GitHub CLI                 | `brew install gh && gh auth login`                                            | `gh auth status`                           |
| Copilot CLI                | `npm install -g @github/copilot`                                              | `copilot --version`                        |
| `jq` (used by watch loop)  | `brew install jq`                                                             | `jq --version`                             |
| GitHub token for scripts   | [Create PAT](https://github.com/settings/tokens) (scopes: `repo`, `read:org`) | `echo $GITHUB_TOKEN`                       |
| MCP servers in VS Code     | Accept the startup prompt from `.vscode/mcp.json`                             | Chat 🔧 → see `mcp_github_*`, `mcp_jira_*` |
| MCP servers in Copilot CLI | Already declared in `.mcp.json` at repo root                                  | `copilot mcp list`                         |

> ⚠️ **VS Code MCP config does NOT carry over to the CLI.** They're different files (`.vscode/mcp.json` vs `.mcp.json` / `~/.copilot/mcp-config.json`). Both are already set up here.

## Quick start — one command, zero questions

```bash
~/Workspace/factory/scripts/factory HUB-12345
```

That's it. The agent picks the target repo, creates a worktree, implements, lints, pushes, opens a **draft** PR, comments Jira, and prints the PR URL. No questions, no approval prompts.

Add the autopilot loop (watch + auto-fix on every review comment / CI change):

```bash
~/Workspace/factory/scripts/factory HUB-12345 --watch
```

### Attach to an existing PR

Someone reviewed an older PR — attach a watch loop to it (auto-fix on every blocker change):

```bash
factory-watch https://github.com/qlik-trial/hub-parcels/pull/4521
factory-watch qlik-trial/hub-parcels#4521
factory-watch qlik-trial/hub-parcels 4521

# From inside the repo's checkout — infers the owner/repo from `gh`:
cd ~/Workspace/hub-parcels && factory-watch 4521

# Watch only, don't auto-fix (just print state changes):
factory-watch 4521 --no-auto-fix
```

### Put it on your `PATH`

So you can type `factory` / `factory-watch` from anywhere:

```bash
echo 'export PATH="$HOME/Workspace/factory/scripts:$PATH"' >> ~/.zshrc
source ~/.zshrc
factory HUB-12345
factory-watch 4521
```

### Environment overrides

- `FACTORY_MODEL=claude-opus-4.7` — pin a specific model
- `FACTORY_DRY_RUN=1` — print the `copilot` command without running
- `FACTORY_WATCH_INTERVAL=30` — seconds between PR polls

## Quick start — VS Code (interactive)

If you want to watch the agent work and steer it:

1. `code ~/Workspace/factory`
2. Accept the MCP startup prompts (GitHub + Atlassian).
3. Open Chat, pick the **Factory** mode, say:
   > Take HUB-12345 and implement it.

## Under the hood — Copilot CLI

`scripts/factory` is a thin wrapper around:

```bash
copilot --add-dir ~/Workspace --allow-all-tools \
  -p "$(cat .github/prompts/autopilot.prompt.md)\n\nTICKET = HUB-12345"
```

Read [.github/prompts/autopilot.prompt.md](.github/prompts/autopilot.prompt.md) — that file is the full contract. Edit it to change how the factory decides things.

## The 9 stages

| #   | Stage       | Owner         | What happens                                                           |
| --- | ----------- | ------------- | ---------------------------------------------------------------------- |
| 1   | INGEST      | agent         | Fetch Jira ticket + all comments (raw, unfiltered)                     |
| 2   | UNDERSTAND  | agent         | Read target repo's AGENTS.md, workflows, sample files                  |
| 3   | PLAN        | agent → human | Trace full user path, produce a plan, get approval                     |
| 4   | PREPARE     | glue          | `scripts/new-worktree.sh` — branch from default in a worktree          |
| 5   | IMPLEMENT   | agent         | Write code + tests, wire into UI                                       |
| 6   | VERIFY      | agent         | Run `lint` locally; trust CI for tests                                 |
| 7   | SUBMIT      | agent         | Open **draft** PR, comment Jira, transition to In Review               |
| 8   | WATCH       | glue          | `scripts/watch-pr.sh` — polls, computes blocker fingerprint            |
| 9   | FIX + LEARN | agent         | When fingerprint changes: address comments, push fixes, record lessons |

## Commands

Top-level entry points (use these day-to-day):

| Task | Command |
| --- | --- |
| Ticket → draft PR (autopilot, no questions) | `factory <TICKET>` |
| Same, then watch + auto-fix until merged | `factory <TICKET> --watch` |
| Same, but don't auto-fix — just watch | `factory <TICKET> --watch --no-auto-fix` |
| Attach watch+auto-fix to an existing PR | `factory-watch <pr-url \| owner/repo#num \| num>` |
| Watch existing PR, no auto-fix | `factory-watch <pr> --no-auto-fix` |
| Print the `copilot` command without running | `FACTORY_DRY_RUN=1 factory <TICKET>` |

Low-level helpers (the entry points above compose these):

| Task | Command |
| --- | --- |
| Create a worktree for a task | `./scripts/new-worktree.sh <repo> <TICKET>-<summary>` |
| Raw watch loop (custom on-change hook) | `./scripts/watch-pr.sh <owner>/<repo> <pr-number> [--on-change '<cmd>']` |
| Dump raw PR feedback for inspection | `./scripts/fetch-pr-feedback.sh <owner>/<repo> <pr-number>` |
| Create a branch (no worktree) | `./scripts/new-branch.sh <repo> <branch>` |
| List repos under `~/Workspace/` | `./scripts/list-repos.sh` |

### End-to-end autonomous loop

```bash
# Terminal A — ticket to draft PR to merged, all in one
factory HUB-12345 --watch

# Terminal B — separately, babysit an older PR that's getting reviewed now
factory-watch qlik-trial/hub-parcels#4500
```

## Prompts

- [autopilot](.github/prompts/autopilot.prompt.md) — **used by `factory <TICKET>`**; zero questions, zero approvals
- [starter](.github/prompts/starter.prompt.md) — interactive 9-stage loop (shows plan, waits for approval)
- [triage-jira](.github/prompts/triage-jira.prompt.md) — read-only scoping + plan
- [take-jira-ticket](.github/prompts/take-jira-ticket.prompt.md) — implement to draft PR
- [open-pr](.github/prompts/open-pr.prompt.md) — PR-only step for a pushed branch
- [respond-to-pr-review](.github/prompts/respond-to-pr-review.prompt.md) — **used by `factory-watch`**; address comments, push, reply
- [learn-from-pr](.github/prompts/learn-from-pr.prompt.md) — distill lessons into memory

## Learning — the config IS the memory

Every PR teaches the factory. After each fix cycle, lessons are classified:

- **Repo-specific rules** → `~/Workspace/<repo>/.factory/lessons.md` (committed, shared with team) or `/memories/repo/<repo>.md` (local Copilot memory)
- **User-wide preferences** → `/memories/<topic>.md` (auto-loaded into every conversation)
- **One-offs** → discarded

See [.factory/lessons.md](.factory/lessons.md) for the seed template and [learn-from-pr](.github/prompts/learn-from-pr.prompt.md) for the classification rules.

## Mindset

- **Sloppy first.** Throughput over polish — you refine the prompts as you learn.
- **Every interaction is training data.** PR comments, CI failures, clarifications — capture them.
- **You're a PM now.** You set intent; the agent writes; you review the diff.
- **The PR is the interface.** Leave a review comment, the factory reacts.
- **Motion over architecture.** Run it on a real ticket.

## Non-negotiables

1. Never edit code in this factory repo to implement a ticket — always the target repo.
2. Never commit to `main`. Always a feature branch in a worktree.
3. Open PRs as **draft**. Humans decide when they're ready.
4. Never silence a failing check. Fix it or surface it.
5. Don't filter PR comments/CI logs before the agent sees them — raw data only.
6. If stuck, exit non-zero. Don't loop forever.

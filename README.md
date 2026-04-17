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

## First-time setup

Run these once on a new machine. Every step is idempotent.

### 1. Install prerequisites

```bash
# macOS — Homebrew
brew install gh jq
npm install -g @github/copilot
```

| Tool        | Verify              |
| ----------- | ------------------- |
| GitHub CLI  | `gh --version`      |
| Copilot CLI | `copilot --version` |
| `jq`        | `jq --version`      |

### 2. Authenticate

```bash
gh auth login                              # browser flow, pick GitHub.com + HTTPS
gh auth status                             # confirm
```

Create a [GitHub PAT](https://github.com/settings/tokens) (scopes: `repo`, `read:org`) and export it — some helper scripts use it directly:

```bash
echo 'export GITHUB_TOKEN=ghp_xxx' >> ~/.zshrc
source ~/.zshrc
```

### 3. Clone the factory next to your target repos

```bash
mkdir -p ~/Workspace && cd ~/Workspace
gh repo clone <your-org>/factory         # or: git clone <url> factory
```

Your layout should look like:

```
~/Workspace/
├── factory/          # ← this repo (control plane)
├── hub-parcels/      # ← target repos (where code lands)
├── hub/
└── …
```

### 4. Put the factory on your PATH

```bash
echo 'export PATH="$HOME/Workspace/factory/scripts:$PATH"' >> ~/.zshrc
source ~/.zshrc
command -v factory                         # → /Users/you/Workspace/factory/scripts/factory
```

Now `factory` and `factory-watch` work from any directory.

### 5. Register MCP servers

**Copilot CLI** — already declared in [.mcp.json](.mcp.json). Verify:

```bash
cd ~/Workspace/factory
copilot mcp list                           # must show: github + atlassian
```

On first use, Copilot CLI will prompt you to authenticate each MCP server in a browser (Jira/Atlassian OAuth, GitHub OAuth). Approve them.

**VS Code** (optional, for the interactive chat mode) — already declared in [.vscode/mcp.json](.vscode/mcp.json). Open the folder in VS Code and accept the startup prompts:

```bash
code ~/Workspace/factory
```

Then in Chat, click 🔧 and confirm `mcp_github_*` and `mcp_jira_*` tools are listed.

> ⚠️ **VS Code and CLI read different MCP config files** (`.vscode/mcp.json` vs `.mcp.json`). Both are already set up here — you just need to authenticate each side once.

### 6. Smoke test

```bash
FACTORY_DRY_RUN=1 factory HUB-0       # prints the copilot command without running
```

If it prints a `copilot --add-dir … -p …` line, you're ready.

## Quick start — one command, zero questions

```bash
factory HUB-12345
```

That's it. The agent picks the target repo, creates a worktree, implements, lints, pushes, opens a **draft** PR, comments Jira, and prints the PR URL. No questions, no approval prompts.

Add the autopilot loop (watch + auto-fix on every review comment / CI change):

```bash
factory HUB-12345 --watch
```

Attach an autopilot loop to a **PR that already exists**:

```bash
factory-watch https://github.com/qlik-trial/hub-parcels/pull/4521
# or
factory-watch qlik-trial/hub-parcels#4521
# or (run from inside the repo)
cd ~/Workspace/hub-parcels && factory-watch 4521
```

Environment overrides:

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

The two you'll use daily:

| Task                                | Command                                    |
| ----------------------------------- | ------------------------------------------ |
| Ticket → draft PR (fire-and-forget) | `factory <TICKET>`                         |
| Ticket → draft PR + autopilot watch | `factory <TICKET> --watch`                 |
| Attach autopilot to an existing PR  | `factory-watch <pr-url \| owner/repo#num>` |
| Watch an existing PR (no auto-fix)  | `factory-watch <pr-ref> --no-auto-fix`     |

Lower-level helpers (called by the above, usable standalone):

| Task                                 | Command                                                      |
| ------------------------------------ | ------------------------------------------------------------ |
| Create a worktree for a task         | `new-worktree.sh <repo> <TICKET>-<summary>`                  |
| Raw watch loop (blocker fingerprint) | `watch-pr.sh <owner>/<repo> <pr-number>`                     |
| Raw watch loop + custom hook         | `watch-pr.sh <owner>/<repo> <pr-number> --on-change '<cmd>'` |
| Dump raw PR feedback for the agent   | `fetch-pr-feedback.sh <owner>/<repo> <pr-number>`            |
| Create a branch (no worktree)        | `new-branch.sh <repo> <branch>`                              |
| List repos under `~/Workspace/`      | `list-repos.sh`                                              |

### End-to-end autonomous loop

```bash
# Morning — new ticket, walk away
factory HUB-12345 --watch

# Later — someone reviewed an older PR, attach autopilot to it
factory-watch qlik-trial/hub-parcels#4500
```

Equivalent without the wrappers (what they run under the hood):

```bash
# 1. Kick off: ticket → draft PR
copilot --add-dir ~/Workspace --allow-all-tools \
  -p "$(cat .github/prompts/autopilot.prompt.md)

TICKET = HUB-12345"

# 2. Watch loop with auto-fix hook
./scripts/watch-pr.sh qlik-trial/hub-parcels 4521 --on-change \
  'copilot --add-dir ~/Workspace --allow-all-tools \
     -p "Follow AGENTS.md stage 9. Respond to review on hub-parcels#4521 and learn from it."'
```

## Prompts

- [autopilot](.github/prompts/autopilot.prompt.md) — **default**: zero-questions ticket → draft PR (used by `factory`)
- [starter](.github/prompts/starter.prompt.md) — interactive 9-stage loop (shows plan, waits for approval)
- [triage-jira](.github/prompts/triage-jira.prompt.md) — read-only scoping + plan
- [take-jira-ticket](.github/prompts/take-jira-ticket.prompt.md) — implement to draft PR (interactive)
- [open-pr](.github/prompts/open-pr.prompt.md) — PR-only step for a pushed branch
- [respond-to-pr-review](.github/prompts/respond-to-pr-review.prompt.md) — address comments, push, reply
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

# Factory lessons (seed)

Short, imperative, transferable rules. Never secrets, names, or PR-specific details.
This file is a _template_ — copy it to `~/Workspace/<target-repo>/.factory/lessons.md`
(committed) or mirror the rules into `/memories/repo/<target-repo>.md` (Copilot memory).

## Universal (apply to any repo)

- Give the agent raw data. Don't filter PR comments or CI logs in bash before handing them over.
- Open draft PRs only. Never mark ready — humans decide.
- Never silence a failing check to unblock. Fix the check, or surface the failure.
- Run `lint` locally; let CI run the full test suite. Browser-mode vitest hangs locally.
- Always use a git worktree, never pollute the user's main checkout.
- When stuck on the same blocker twice, exit non-zero instead of looping.

## Process hygiene

- Compute a blocker fingerprint = hash(unresolved-comment-ids + check-conclusions + mergeable-state). Only dispatch a fix when it changes.
- Check "branch behind base" — a yellow PR won't go green until you rebase/merge.
- Macos `sed` needs `sed -E` for extended regex; pipe delimiters break without `-E`.
- Never spawn nested watch loops — infinite recursion.

## Populate these per-repo

- `<repo>` CI triggers: which workflows run on push, on PR, on label.
- `<repo>` test command: e.g. `pnpm test --run` (the `--run` flag is the detail that bites).
- `<repo>` style rules the reviewers actually enforce (they're often stricter than the linter).
- `<repo>` renamed/deprecated modules — e.g. `SpaceDetails` → `WorkspaceDetailsPanel`.
- `<repo>` required checks that the PR won't merge without.

## Jira: Never use curl — use MCP tools
**Lesson**: Do NOT read credentials from `~/Library/Application Support/Code/User/mcp.json` or any credential file to build curl/node HTTP requests to Jira. This prints API tokens in plaintext in terminal history and chat logs.
**Rule**: Always use `mcp_jira_*` MCP tools (e.g. `mcp_jira_get_issue`, `mcp_jira_add_comment`, `mcp_jira_transition_issue`) for all Jira operations. These tools handle auth internally with no credential exposure.

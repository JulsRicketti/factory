---
mode: agent
description: Distill lessons from PR review feedback into persistent memory so the agent improves over time.
---

Use this after responding to PR comments, or after a PR is merged/closed.

Inputs:

- PR number + repo, OR a pasted batch of review comments.

Steps:

1. Collect all review feedback on the PR (use `./scripts/fetch-pr-feedback.sh` if not already run).
2. For each comment that represents a **correction or preference**, classify:
   - **Repo-specific convention** → goes into `/memories/repo/<target-repo>.md`
   - **Cross-repo / personal preference** of the user → goes into `/memories/<topic>.md` (user scope)
   - **One-off / noise** → discard, do not record
3. Before writing, `view` existing memory files to avoid duplicates. Update existing entries rather than creating new files when possible.
4. Write entries as short, concrete rules — not prose. Examples:
   - `- Never use Material UI; use Sprout + classNames()` (repo)
   - `- Prefer \`const x = ...\` over function declarations in React components` (user)
   - `- Always add data-testid to new interactive elements` (repo)
5. Record **both** what to do and what to avoid when the reviewer flagged a mistake.
6. Never record secrets, author names, or PR-specific details — only the transferable rule.

Output to user:

- List of memory files updated, with the bullets added.
- List of comments deliberately NOT captured (with reasoning).

Anti-patterns:

- Don't capture every comment. Only recurring or principled ones.
- Don't write long paragraphs — user memory is auto-loaded into context, so brevity matters.
- Don't duplicate rules that already exist in the target repo's `AGENTS.md` or instruction files — those are already loaded automatically.

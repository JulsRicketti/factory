---
mode: agent
description: Distill lessons from PR review feedback into persistent memory so the agent improves over time.
---

Use this after responding to PR comments, or after a PR is merged/closed.

Inputs:

- PR number + repo, OR a pasted batch of review comments.

## 🔒 Branch isolation — read first

**Never commit lesson updates onto the active feature/fix branch.** Lessons leak across unrelated PRs when this happens and pollute the diff. Strictly enforce:

1. Stash or set aside any uncommitted lesson edits before switching context.
2. From the target repo, check out a **fresh branch off the default branch** (not off the current feature branch) named `factory/lessons-<YYYYMMDD>-<short-slug>` (e.g. `factory/lessons-20260515-mui-classnames`). If a matching factory/lessons branch already exists and is unmerged, reuse it.
3. Apply the lesson edits only on that branch.
4. Commit with a Conventional Commit message like `chore(factory): record lesson on <topic>` — no Jira scope.
5. Push and open a **separate draft PR** for the lesson update. Title: `chore(factory): lessons update <short-slug>`. Body explains which PR/comment the lesson came from. Label it `agentic-loop`.
6. Switch back to the original branch you were working on so subsequent fix-cycle work continues unaffected.

If you are unable to create the dedicated branch (e.g. you are not currently in the target repo's worktree), emit `FACTORY_BLOCKED: cannot-isolate-lessons` and exit — do **not** fall back to committing on the active branch.

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

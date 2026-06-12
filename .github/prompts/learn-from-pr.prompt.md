---
mode: agent
description: Distill lessons from PR review feedback into persistent memory so the agent improves over time.
---

Use this after responding to PR comments, or after a PR is merged/closed.

Inputs:

- PR number + repo, OR a pasted batch of review comments.

## 🔒 Hard rules — read first

These are non-negotiable. Violations break the user's workflow.

1. **NEVER open a standalone PR for lesson updates.** No `factory/lessons-*` branches, no `chore(factory): lessons update` PRs. Lessons piggyback on the active PR's fix commit or they do not get written at all.
2. **Lessons come EXCLUSIVELY from PR review feedback on the agent's own PR.** Never derive lessons from the task itself, from your own implementation choices, from CI failures you caused, or from anything the user did not flag in a review comment.
3. **Only the agent triggers `learn-from-pr`.** If the user opened the PR, do not run this prompt against it.
4. **Lessons must be general-purpose, transferable rules.** A lesson is something that would apply to *any future PR in this repo*. Example of a real lesson: "Never sign a locale string." Example of NOT a lesson: "In CreatePageModal, the description field needs a fallback to empty string." Anything tied to a specific file, ticket, component, feature, refactor, or one-time decision is **not** a lesson — discard it.
5. **Most comments are not lessons.** When in doubt, discard. Recording noise pollutes the repo's `.factory/config.md` and erodes trust. Better to skip a borderline comment than to add a weak rule.

If a comment passes all four filters (review-only, agent-authored PR, general-purpose, recurring/principled), include the lesson update as part of the **same commit** that addresses the review feedback on the active branch. No extra commit, no extra PR.

Steps:

1. Confirm the PR was opened by the factory agent. If not, exit immediately — do not record lessons against user-authored PRs.
2. Collect all review feedback on the PR (use `./scripts/fetch-pr-feedback.sh` if not already run). Ignore your own automated replies and CI bot comments.
3. For each remaining comment, apply the **lesson filter**. A comment qualifies only if it is **all** of:
   - A correction or stated preference from a human reviewer (not a question, not praise, not "nit").
   - **General-purpose**: the rule would apply across any future PR in this repo, not just this file/feature/ticket.
   - **Principled or recurring**: the reviewer is articulating a standard, not a one-off taste call.
   Borderline? Discard. The bar is "would I be embarrassed if this rule were violated in another PR six months from now?" — if no, it is not a lesson.
4. For each qualifying comment, classify:
   - **Repo-specific convention** → goes into `<target-repo>/.factory/config.md` (committed) or `/memories/repo/<target-repo>.md`
   - **Cross-repo / personal preference** of the user → goes into `/memories/<topic>.md` (user scope)
   - Everything else → discard, do not record
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

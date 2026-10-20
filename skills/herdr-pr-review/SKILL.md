---
name: herdr-pr-review
description: Full PR review with two reviewers in one Herdr worktree workspace - a Claude agent runs /review-pr and starts a Codex agent in a pane to its right, the two debate and verify each other's findings, then Claude reports the critical, high and medium comments (no low). Use whenever Yoni asks to review a PR with an agent, a worktree, Herdr, or Codex, or says "full review" / "double review".
---

# Herdr PR review

One PR = one Herdr worktree workspace (`review · PR <n>`, branch `review/pr-<n>` at the PR head) with a Claude agent `review-<n>`. That agent starts Codex (`review-<n>-codex`) in a pane to its right. Claude runs `/review-pr`, Codex reviews independently, the two discuss and verify each other's findings over up to two rounds, and Claude writes the critical, high and medium comments (plus a one-line count of what was set aside and a short rejected list) to `/tmp/review-pr-<n>.md`. Everything stays local: no GitHub comments, no push.

## Steps

1. For each PR the user named, run:
   ```bash
   ~/.claude/skills/herdr-pr-review/start-review.sh <pr-number-or-url>
   ```
   Done when it prints `workspace=… agent=…`. It refuses to run outside Herdr and when `review/pr-<n>` already exists; on that refusal, show the user the existing worktree (`git worktree list | grep pr-<n>`) and ask whether to reuse it or remove it. Removing it is the user's call.
2. Confirm the agent picked up the work: `herdr agent get review-<n>` shows `working`.
3. Report to the user, per PR: workspace id, agent names, worktree path, PR head, report path, and timing: the full review in 15–30 minutes.

Add `--dry-run` to print the rendered prompt without creating anything.

## Changing the review

The instructions sent to the agent live in `review-prompt.md` (placeholders like `{{PR_URL}}` are filled by the script). Edit that file to change what the review covers or how the report reads.

## Checking on a review

`herdr agent get review-<n>` for status; `herdr agent read review-<n> --source recent-unwrapped --lines 120` for output; the finished report is at `/tmp/review-pr-<n>.md`.

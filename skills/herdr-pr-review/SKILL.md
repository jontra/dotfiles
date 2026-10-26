---
name: herdr-pr-review
description: Full PR review by a Codex agent in its own Herdr worktree workspace - the agent runs the repo's review-pr skill, verifies every finding against the code, then reports the critical, high and medium comments (no low) to a local report. Use whenever Yoni asks to review a PR with an agent, a worktree, Herdr, or Codex, or says "full review" / "codex review".
---

# Herdr PR review

One PR = one Herdr worktree workspace (`review · PR <n>`, branch `review/pr-<n>` at the PR head) with a Codex agent `review-<n>` (ACT Foundry model, high effort). The agent runs the repo's `review-pr` skill, verifies each finding against the code, and writes the critical, high and medium comments (plus a one-line count of what was set aside and a short rejected list) to `/tmp/review-pr-<n>.md`. Everything stays local: no GitHub comments, no push.

## Steps

1. For each PR the user named, run:
   ```bash
   ~/.claude/skills/herdr-pr-review/start-review.sh <pr-number-or-url>
   ```
   Done when it prints `workspace=… agent=…`. It refuses to run outside Herdr and when `review/pr-<n>` already exists; on that refusal, show the user the existing worktree (`git worktree list | grep pr-<n>`) and ask whether to reuse it or remove it. Removing it is the user's call.
2. Confirm the agent picked up the work: `herdr agent get review-<n>` shows `working`. If it shows `blocked`, read the pane: Codex may be asking to trust the repo's Stop hook (`herdr agent send-keys review-<n> t`, then `esc` until idle, then re-send the prompt from `--dry-run`).
3. Report to the user, per PR: workspace id, agent name, worktree path, PR head, report path, and timing: 10–20 minutes.

Add `--dry-run` to print the rendered prompt without creating anything. `REVIEW_CODEX_MODEL` and `REVIEW_CODEX_EFFORT` override the model (default `act-foundry/gpt-6-astra`, `high`).

## Changing the review

The instructions sent to the agent live in `review-prompt.md` (placeholders like `{{PR_URL}}` are filled by the script). Edit that file to change what the review covers or how the report reads.

## Checking on a review

`herdr agent get review-<n>` for status; `herdr agent read review-<n> --source recent-unwrapped --lines 120` for output; the finished report is at `/tmp/review-pr-<n>.md`.

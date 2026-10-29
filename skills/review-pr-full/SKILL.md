---
name: review-pr-full
description: Full PR review by a Claude and a Codex agent side by side in one Herdr worktree - each runs the repo's review-pr skill, they discuss until they agree on findings and severity, and Claude writes a local report of the confirmed findings. Use whenever Yoni asks to review a PR with agents, a worktree, Herdr, Claude and Codex, or says "full review".
---

# Full PR review

One PR = one Herdr worktree workspace (`review · PR <n>`, branch `review/pr-<n>` at the PR head) with two agents side by side:

- left: Claude `review-<n>-claude` (`claude-fable-5-1`, high effort), which leads;
- right: Codex `review-<n>-codex` (`act-foundry/gpt-6-astra`, high effort).

Both run `/review-pr` in parallel, and neither reads the other's findings until its own are written. Claude then merges both lists and runs up to three discussion rounds with Codex until they agree on each finding and its severity. Claude writes the confirmed findings (critical, high, medium), the disputed ones with both positions, and the counts of dropped and low items to `/tmp/review-pr-<n>.md`. Hand-offs go through files in `/tmp/review-pr-<n>/`. Everything stays local: no GitHub comments, no push.

## Steps

1. For each PR the user named, run:
   ```bash
   ~/.claude/skills/review-pr-full/start-review.sh <pr-number-or-url>
   ```
   Done when it prints `workspace=…`, `claude=…` and `codex=…`. It refuses to run outside Herdr, and when `review/pr-<n>` or `/tmp/review-pr-<n>/` already exists; on that refusal, show the user the existing worktree (`git worktree list | grep pr-<n>`) and ask whether to reuse or remove it. Removing it is the user's call.
2. Confirm both agents picked up the work: `herdr agent get review-<n>-claude` and `herdr agent get review-<n>-codex` both show `working`. If either shows `blocked`, read its pane: Codex may still be asking to trust the repo's Stop hook (`herdr agent send-keys review-<n>-codex t`, then `esc` until idle); Claude may be asking to trust the folder (`herdr agent send-keys review-<n>-claude Enter`). Then re-send that agent's prompt: `Read and follow /tmp/review-pr-<n>/<claude|codex>-prompt.md`.
3. Report to the user, per PR: workspace id, both agent names, worktree path, PR head, report path, and timing: 20–40 minutes (both reviews in parallel, then the discussion).

Add `--dry-run` to print both rendered prompts without creating anything. `REVIEW_CLAUDE_MODEL`, `REVIEW_CLAUDE_EFFORT`, `REVIEW_CODEX_MODEL` and `REVIEW_CODEX_EFFORT` override the models.

## Changing the review

The instructions live in `claude-prompt.md` (Claude's review, the hand-off, the discussion and the report) and `codex-prompt.md` (Codex's review and how it answers discussion rounds). The script fills placeholders like `{{PR_URL}}` and writes the rendered copies to `/tmp/review-pr-<n>/`.

## Checking on a review

`herdr agent get review-<n>-claude` for status; `herdr pane read <pane> --source visible` while an agent works. Progress shows as files in `/tmp/review-pr-<n>/`: `claude-findings.md`, `codex-findings.md`, then `round-<k>-claude.md` / `round-<k>-codex.md`. The finished report is `/tmp/review-pr-<n>.md`.

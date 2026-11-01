Review {{PR_URL}} ("{{TITLE}}"). This worktree is already checked out at the PR head ({{SHORT_SHA}}, local branch {{BRANCH}}); diff it against its merge-base with origin/{{BASE}}. A Claude agent ({{CLAUDE_AGENT}}) in the pane beside you reviews the same PR in parallel; once both reviews are done it will message you to discuss the findings.

## Full review

1. Follow `{{DIR}}/context-prompt.md`: the PR's purpose and its related PRs.
2. Run the repo's `review-pr` skill on this worktree: `.agents/skills/review-pr/SKILL.md`, with `.agents/runtimes.md` mapping its vocabulary onto your runtime. If you have no skill mechanism, read the skill file and the references it points to and follow them inline. Keep every finding at any severity in your notes; the filtering happens at the end.
3. On top of the skill, check: correctness bugs, edge cases, race conditions and data integrity, migration and schema safety, security, tests, consistency with repo conventions (AGENTS.md and coding guidelines), and whether the change fully reaches its purpose.
4. Verify each finding against the code before keeping it: open the file, trace the call path, and write down the concrete failure scenario. Drop anything you cannot make fail.
5. Write, in this order: the purpose; the related PRs; your findings, as below; the alternatives; the follow-ups. **Critical, high and medium** severity only. No low, no nits, no style. A finding earns high when it can produce wrong data, a crash, a security hole, a broken deploy or rollback, or a silent failure in production; medium when it is a real defect or missing safeguard that hurts under plausible but less common conditions, or a test gap that leaves such a path uncovered. Group the list by severity, critical first. For each finding:
   - severity, file:line
   - what's wrong, in plain words a non-expert can follow, and what actually breaks
   - the concrete failure scenario you verified
   - the suggested fix
   Then one line: how many low items were set aside (not listed). Then a short "rejected" list: findings you raised and dropped during verification, with the reason, one line each.

Done when the findings are written to `{{DIR}}/codex-findings.md`. Write it to `{{DIR}}/codex-findings.md.tmp` first, then rename it: Claude starts reading the moment the final file appears.

## Discussion

Claude will send you rounds of the form "read `{{DIR}}/round-<k>-claude.md`". For each finding in it, re-check the code and answer: **agree**, **severity should be X** or **not a real defect**, with the evidence (file:line, the trace) for anything other than agree. Round 1 also carries the merged purpose, related PRs, alternatives (A1…) and follow-ups (U1…): answer **keep** or **drop** for each alternative and follow-up, with the reason for a drop, and correct the purpose or add a related PR where you see it differently. Hold a position only on evidence; concede when the code shows you were wrong. Write the answer to `{{DIR}}/round-<k>-codex.md.tmp`, then rename it to `{{DIR}}/round-<k>-codex.md`.

Keep everything local: do not post comments, reviews, or approvals to GitHub, do not push, and do not edit the worktree.

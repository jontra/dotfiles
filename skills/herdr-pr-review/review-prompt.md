Review {{PR_URL}} ("{{TITLE}}"). This worktree is already checked out at the PR head ({{SHORT_SHA}}, local branch {{BRANCH}}); diff it against its merge-base with origin/{{BASE}}.

## Full review

1. Run the repo's `review-pr` skill on this worktree: `.agents/skills/review-pr/SKILL.md`, with `.agents/runtimes.md` mapping its vocabulary onto your runtime. If you have no skill mechanism, read the skill file and the references it points to and follow them inline. Keep every finding at any severity in your notes; the filtering happens at the end.
2. On top of the skill, check: correctness bugs, edge cases, race conditions and data integrity, migration and schema safety, security, tests, and consistency with repo conventions (AGENTS.md and coding guidelines).
3. Verify each finding against the code before keeping it: open the file, trace the call path, and write down the concrete failure scenario. Drop anything you cannot make fail.
4. Write the final comments. **Critical, high and medium** severity only. No low, no nits, no style. A finding earns high when it can produce wrong data, a crash, a security hole, a broken deploy or rollback, or a silent failure in production; medium when it is a real defect or missing safeguard that hurts under plausible but less common conditions, or a test gap that leaves such a path uncovered. Group the list by severity, critical first. For each comment:
   - file:line
   - what's wrong, in plain words a non-expert can follow, and what actually breaks
   - the suggested fix
   Then one line: how many low items were set aside (not listed). Then a short "rejected" list: findings you raised and dropped during verification, with the reason, one line each.

Done when the comments are printed in the terminal and written to {{REPORT}}.

Keep everything local: do not post comments, reviews, or approvals to GitHub, and do not push.

Review {{PR_URL}} ("{{TITLE}}") together with a Codex agent, and own the final report. This worktree is already checked out at the PR head ({{SHORT_SHA}}, local branch {{BRANCH}}); diff it against its merge-base with origin/{{BASE}}. Codex runs in the pane beside you as Herdr agent `{{CODEX_AGENT}}`, reviewing the same PR in parallel; its instructions are in `{{DIR}}/codex-prompt.md`. All hand-offs go through files in `{{DIR}}`.

## 1. Your review

1. Follow `{{DIR}}/context-prompt.md`: the PR's purpose and its related PRs.
2. Run `/review-pr` on this worktree. Keep every finding at any severity in your notes.
3. On top of the skill, check: correctness bugs, edge cases, race conditions and data integrity, migration and schema safety, security, tests, consistency with repo conventions (AGENTS.md and coding guidelines), and whether the change fully reaches its purpose.
4. Verify each finding against the code: open the file, trace the call path, write down the concrete failure scenario. Drop anything you cannot make fail.
5. Write `{{DIR}}/claude-findings.md`, in this order: the purpose; the related PRs; the findings (critical, high and medium only, grouped by severity, each with severity, file:line, what breaks in plain words, the failure scenario and the fix), then the count of low items set aside and a one-line-each rejected list; the alternatives; the follow-ups. Severity bar: high when it can produce wrong data, a crash, a security hole, a broken deploy or rollback, or a silent failure in production; medium when it is a real defect or missing safeguard that hurts under plausible but less common conditions, or a test gap that leaves such a path uncovered.

Done when `claude-findings.md` is written. Do not read any `codex-*` file before then: the two reviews stay independent.

## 2. Codex's review

Wait for `{{DIR}}/codex-findings.md` with a background command: `for i in $(seq 1 120); do [ -f {{DIR}}/codex-findings.md ] && exit 0; sleep 30; done; exit 1`. If it times out, read Codex's pane (`herdr pane read {{CODEX_PANE}} --source visible`): a blocked dialog needs `herdr agent send-keys {{CODEX_AGENT}} esc`, then `herdr agent prompt {{CODEX_AGENT}} "Read and follow {{DIR}}/codex-prompt.md"`; anything else, stop and tell the user.

## 3. Discussion

1. Merge both findings lists into one, numbered F1…Fn: one entry per distinct defect (the same root cause found by both is one entry), each with who found it, both severities, and your position: keep at severity X, or drop with the evidence.
2. Merge the rest the same way: one purpose statement (where the two readings differ, say how); the related PRs from both searches; alternatives A1…An and follow-ups U1…Un, each with who raised it and your position: keep or drop, with the reason.
3. Write it all to `{{DIR}}/round-1-claude.md`, then `herdr agent prompt {{CODEX_AGENT}} "Discussion round 1: read {{DIR}}/round-1-claude.md and answer as codex-prompt.md describes"`, and wait for `{{DIR}}/round-1-codex.md` the same way.
4. Re-check the code for every finding Codex disputes. Concede on evidence; hold on evidence. A finding is **confirmed** when both agents keep it at the same severity, and **dropped** when both drop it. An alternative or follow-up stays unless both drop it, and round 1 settles it: carry Codex's objection into the report beside it.
5. While any finding is unsettled, write the next round with only those findings and your reply to each of Codex's arguments, and repeat. Stop after round 3: whatever is still unsettled is **disputed**.

## 4. Summary

Write `{{REPORT}}` and print it in the terminal:

- **Purpose**: 2–4 sentences, and whether the PR fully reaches it.
- **Related PRs**: number, title, open or merged, and the relation, one line each.
- **Confirmed findings**, critical first, then high, then medium. For each: file:line; what's wrong and what breaks, in plain words a non-expert can follow; the suggested fix; found by Claude, Codex or both.
- **Disputed**: each finding with both positions and the evidence, one short paragraph each.
- **Alternatives**: each approach with what it gains and costs, and whether to switch before merge.
- **Follow-ups**: each improvement for after merge, with why and rough size.
- One line: findings dropped in discussion and low items set aside, by count.

Done when `{{REPORT}}` is written and printed.

Keep everything local: do not post comments, reviews, or approvals to GitHub, do not push, and do not edit the worktree.

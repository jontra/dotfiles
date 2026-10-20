Review {{PR_URL}} ("{{TITLE}}"). This worktree is already checked out at the PR head ({{SHORT_SHA}}, local branch {{BRANCH}}); diff it against its merge-base with origin/{{BASE}}.

## Full review, two reviewers, one conversation

1. Start a second reviewer with Herdr, a Codex agent:
   - Split your own pane: `herdr pane split --current --direction right --cwd "$PWD" --no-focus`.
   - `~/.zshrc` runs `cd ~/dev/act` in every new shell. So before starting the agent, run `cd {{WORKTREE}}` in the new pane and confirm its cwd with `herdr pane get`.
   - Start it: `herdr agent start {{CODEX_AGENT}} --kind codex --pane <new pane id> -- -m {{CODEX_MODEL}} -c model_reasoning_effort={{CODEX_EFFORT}}`.
   - If Codex blocks on the repo's Stop-hook trust dialog ("Hook 1 · new"), `herdr agent send-keys {{CODEX_AGENT}} t`, then `esc` three times, then prompt again.
   - Prompt it (write the prompt to a file first and pass `"$(cat file)"`; inline backticks get mangled) to do a full code review of the same PR in this worktree: correctness bugs, edge cases, race conditions and data integrity, migration/schema safety, security, tests, and consistency with repo conventions (AGENTS.md and coding guidelines). Each finding: file:line, severity (critical / high / medium / low), a concrete failure scenario, and the suggested fix. Ask it to write the findings to {{REPORT}}.codex.md as well as print them.
2. While Codex works, do your own full independent review by running the repo's `/review-pr` skill on this worktree. Keep every finding at any severity in your notes; the filtering happens at the end.
3. Discuss. This is a conversation between two reviewers, not two monologues:
   - `herdr agent wait {{CODEX_AGENT}}`, then read its findings (`herdr agent read {{CODEX_AGENT}} --source recent-unwrapped --lines 300`, or the file).
   - Verify each Codex finding against the code yourself. For every one you disagree with, or that needs a sharper failure scenario, prompt Codex with your reasoning and the exact code and ask it to defend, refine, or withdraw.
   - Send Codex your own critical, high and medium findings (not the low ones) and ask it to challenge them: is the scenario real, is the severity right, is there a simpler fix.
   - Run up to two rounds of this. Stop earlier when nothing changes. Note who conceded what; a finding both of you still back after a round carries more weight than one only one of you holds.
4. Write the final comments. **Critical, high and medium** severity only. No low, no nits, no style. A finding earns high when it can produce wrong data, a crash, a security hole, a broken deploy or rollback, or a silent failure in production; medium when it is a real defect or missing safeguard that hurts under plausible but less common conditions, or a test gap that leaves such a path uncovered. Group the list by severity, critical first. For each comment:
   - file:line
   - what's wrong, in plain words a non-expert can follow, and what actually breaks
   - the suggested fix
   - source: Claude, Codex, or both, and whether the other reviewer agreed after discussion
   Then one line: how many low items were set aside (not listed). Then a short "rejected" list: findings either reviewer raised that did not survive verification, with the reason, one line each.

Done when the comments are printed in the terminal and written to {{REPORT}}. Leave the Codex pane open; the user may want to continue the conversation there.

Keep everything local: do not post comments, reviews, or approvals to GitHub, and do not push.

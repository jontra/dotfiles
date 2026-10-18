---
name: herdr-cleanup
description: Tear down the Herdr worktree workspace this agent runs in — closes the workspace and every agent in it, removes the worktree, deletes its branch.
disable-model-invocation: true
---

# Herdr cleanup

Ends this session: the workspace close kills this agent and every other pane in the workspace (a Codex reviewer included). Do any final reporting before step 2.

1. Preview:
   ```bash
   ~/.claude/skills/herdr-cleanup/cleanup.sh --dry-run
   ```
   It refuses outside a Herdr pane and in any workspace that is not a linked worktree (the main checkout is never touched). It reports `blocked:` for uncommitted changes or commits that exist nowhere on origin.
   - Blocked: show the user exactly what would be lost and stop. Re-run with `--force` only when the user says to discard it.
2. Run it for real (adding `--force` only per step 1):
   ```bash
   ~/.claude/skills/herdr-cleanup/cleanup.sh
   ```
   Done when it prints `cleanup scheduled`. Reply with one line: what is being removed and the log path. The workspace closes about 3 seconds later; a Herdr notification reports the result, and the log is in `~/.local/state/herdr-cleanup/`.

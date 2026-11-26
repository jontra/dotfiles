# Links

When you mention a GitHub pull request, write it as a Markdown link to the PR, never as a bare number:
[#12076](https://github.com/act-security/act/pull/12076). Use the repository the PR belongs to
(act-security/act unless the context names another, such as act-security/gitops or
act-security/infrastructure). The same goes for an issue: link it the same way.

# New Herdr workspaces and worktrees

Before creating a Herdr workspace or worktree, run `git fetch origin main` in the repository, and branch the
new worktree from the fetched head: `herdr worktree create … --base origin/main`. Never start new work from a
local `main` that may be behind.

# Numbering the agents you launch

When you launch a new agent in a Herdr worktree, give it the next free number N, so the user can say "ask agent #N":

1. Run `herdr agent list` and `herdr workspace list`, and find the highest number in use among the live agents'
   names (`a<N>-…`) and the workspace labels (`#<N> …`). N is that number plus 1, or 1 when none is in use.
2. Name the agent `a<N>-<short-topic>` (Herdr names are lowercase letters, digits, `-` and `_`, at most 32
   characters), and label its workspace `#<N> <topic>` (`herdr workspace rename`).
3. Tell the user the number when you report the launch ("started agent #4 on RD-15753").

A number belongs to one live agent at a time: never reuse a number that a running agent still holds.

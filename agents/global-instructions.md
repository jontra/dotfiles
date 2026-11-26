# Links

When you mention a GitHub pull request, write it as a Markdown link to the PR, never as a bare number:
[#12076](https://github.com/act-security/act/pull/12076). Use the repository the PR belongs to
(act-security/act unless the context names another, such as act-security/gitops or
act-security/infrastructure). The same goes for an issue: link it the same way.

# New Herdr workspaces and worktrees

Before creating a Herdr workspace or worktree, run `git fetch origin main` in the repository, and branch the
new worktree from the fetched head: `herdr worktree create … --base origin/main`. Never start new work from a
local `main` that may be behind.

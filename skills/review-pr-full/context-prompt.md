# PR context

Do this before the line-by-line review. A finding reads differently once you know what the PR is for and what else is changing around it.

## Purpose

1. Read the PR body, its commits and its ticket: `gh pr view {{PR_URL}} --json body,commits,closingIssuesReferences,author`. A Linear id (`RD-1234`) in the title, branch or body names the ticket; read it, and its parent issue, with the Linear tools when you have them.
2. Write the **purpose** in 2–4 sentences: the problem, who hits it, and the outcome the PR should produce. Mark what the author states and what you inferred from the code.

Done when you can name the behaviour that should be true after merge.

## Related PRs

Search open and merged PRs from the last six months that work on the same problem:

- the ticket, its parent and sibling tickets: `gh pr list --state all --search "<ticket id>"`;
- each core file in the diff: `git log --format='%h %ad %s' --date=short -n 20 origin/{{BASE}} -- <file>` (merge subjects end in `(#<n>)`), and `gh pr list --state open --search "<file name or key symbol>"`;
- the stack: PRs whose base is this PR's branch, and this PR's own base when it is not `{{BASE}}`;
- the author's other open PRs: `gh pr list --author <login> --state open`.

Keep each related PR with one line naming the relation: **prior work** (this builds on it), **overlap** (an open PR changing the same code: conflict or diverging behaviour), **earlier attempt** (a closed or reverted try at the same goal), **follow-up** (an already-planned next step) or **dependency**. Leave out PRs that share a file by coincidence.

Done when the ticket and every core file have been searched. No related PRs is a valid result; say so.

## Feeding the review

Hold the change against its purpose while you review. A path the purpose implies but the diff leaves untouched, so the goal is only partly met, is a finding with a severity like any other. So is an open related PR that this one would conflict with or break.

## Alternatives and follow-ups

Besides findings, write two short lists:

- **Alternatives**: a materially different way to reach the same purpose: a simpler design, an existing helper in the repo, a change at another layer, or the approach a related PR took. For each: the approach, what it gains, what it costs, and whether you recommend switching before merge. List only alternatives you would defend to the author.
- **Follow-ups**: improvements to make after merge, outside this PR's scope: generalising the fix to the other places with the same pattern, cleaning up what the PR leaves behind, tests or monitoring, the next step toward the purpose. For each: what, why, and rough size (hours or days).

Either list may be empty.

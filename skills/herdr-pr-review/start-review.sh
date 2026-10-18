#!/usr/bin/env bash
# Usage: start-review.sh <pr-number-or-url> [--dry-run]
# Creates a Herdr worktree workspace at the PR head, starts a Claude agent in it,
# and sends it review-prompt.md (Claude + Codex unified review, kept local).
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PR_ARG="${1:?usage: start-review.sh <pr-number-or-url> [--dry-run]}"
DRY_RUN="${2:-}"

[ "${HERDR_ENV:-}" = 1 ] || { echo "error: not running inside a Herdr pane" >&2; exit 1; }

PR="${PR_ARG##*/pull/}"; PR="${PR%%/*}"
[[ "$PR" =~ ^[0-9]+$ ]] || { echo "error: cannot parse PR number from '$PR_ARG'" >&2; exit 1; }

REPO_ROOT="$(git worktree list --porcelain | awk 'NR==1 {print $2}')"
cd "$REPO_ROOT"

PR_JSON="$(gh pr view "$PR" --json title,headRefOid,baseRefName,url)"
field() { python3 -c 'import json,sys; print(json.loads(sys.argv[1])[sys.argv[2]])' "$PR_JSON" "$1"; }
TITLE="$(field title)"; SHA="$(field headRefOid)"; BASE="$(field baseRefName)"; URL="$(field url)"

BRANCH="review/pr-$PR"
AGENT="review-$PR"
REPORT="/tmp/review-pr-$PR.md"
# Reviewer models. Override per run with env vars.
CLAUDE_MODEL="${REVIEW_CLAUDE_MODEL:-claude-fable-5-1[1m]}"
CLAUDE_EFFORT="${REVIEW_CLAUDE_EFFORT:-high}"
CODEX_MODEL="${REVIEW_CODEX_MODEL:-act-foundry/gpt-6-astra}"
CODEX_EFFORT="${REVIEW_CODEX_EFFORT:-high}"

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "error: branch $BRANCH already exists (an earlier review?). See: git worktree list | grep pr-$PR" >&2
  exit 1
fi

git fetch --quiet origin "pull/$PR/head" "$BASE"
[ "$(git rev-parse FETCH_HEAD)" = "$SHA" ] || { echo "error: fetched head does not match PR head $SHA" >&2; exit 1; }

render_prompt() {
  python3 - "$SKILL_DIR/review-prompt.md" "$@" <<'PY'
import sys
text = open(sys.argv[1]).read()
for pair in sys.argv[2:]:
    key, value = pair.split("=", 1)
    text = text.replace("{{" + key + "}}", value)
print(text, end="")
PY
}

if [ "$DRY_RUN" = "--dry-run" ]; then
  WORKTREE="<worktree path>"
  echo "would create worktree branch=$BRANCH base=$SHA label='review · PR $PR', start agent $AGENT (claude $CLAUDE_MODEL/$CLAUDE_EFFORT, codex $CODEX_MODEL/$CODEX_EFFORT)"
  echo "--- prompt ---"
  render_prompt PR_URL="$URL" TITLE="$TITLE" SHORT_SHA="${SHA:0:8}" BRANCH="$BRANCH" BASE="$BASE" \
    WORKTREE="$WORKTREE" CODEX_AGENT="$AGENT-codex" REPORT="$REPORT" CODEX_MODEL="$CODEX_MODEL" CODEX_EFFORT="$CODEX_EFFORT"
  exit 0
fi

CREATE_JSON="$(herdr worktree create --cwd "$REPO_ROOT" --branch "$BRANCH" --base "$SHA" \
  --label "review · PR $PR" --no-focus)"
read -r WORKSPACE PANE WORKTREE < <(python3 -c '
import json,sys; r=json.loads(sys.argv[1])["result"]
print(r["workspace"]["workspace_id"], r["root_pane"]["pane_id"], r["worktree"]["path"])' "$CREATE_JSON")

# ~/.zshrc cds every new shell to ~/dev/act; move the pane back into the worktree.
herdr pane run "$PANE" "cd '$WORKTREE'" >/dev/null
for _ in $(seq 1 30); do
  herdr pane get "$PANE" | grep -q "\"cwd\":\"$WORKTREE\"" && break
  sleep 1
done
herdr pane get "$PANE" | grep -q "\"cwd\":\"$WORKTREE\"" || { echo "error: pane $PANE never reached $WORKTREE" >&2; exit 1; }

herdr agent start "$AGENT" --kind claude --pane "$PANE" --timeout 60000 -- --model "$CLAUDE_MODEL" --effort "$CLAUDE_EFFORT" >/dev/null

PROMPT="$(render_prompt PR_URL="$URL" TITLE="$TITLE" SHORT_SHA="${SHA:0:8}" BRANCH="$BRANCH" BASE="$BASE" \
  WORKTREE="$WORKTREE" CODEX_AGENT="$AGENT-codex" REPORT="$REPORT" CODEX_MODEL="$CODEX_MODEL" CODEX_EFFORT="$CODEX_EFFORT")"
herdr agent prompt "$AGENT" "$PROMPT" >/dev/null

echo "pr=$PR title=\"$TITLE\""
echo "workspace=$WORKSPACE pane=$PANE agent=$AGENT codex_agent=$AGENT-codex"
echo "worktree=$WORKTREE branch=$BRANCH head=${SHA:0:8}"
echo "report=$REPORT"

#!/usr/bin/env bash
# Usage: start-review.sh <pr-number-or-url> [--dry-run]
# Creates a Herdr worktree workspace at the PR head with a Claude agent (left pane) and a Codex
# agent (right pane), renders the prompts into /tmp/review-pr-<n>/, and starts both reviews in
# parallel. Claude then leads the discussion and writes the final report.
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
CLAUDE_AGENT="review-$PR-claude"
CODEX_AGENT="review-$PR-codex"
DIR="/tmp/review-pr-$PR"
REPORT="/tmp/review-pr-$PR.md"
# Reviewer models. Override per run with env vars.
CLAUDE_MODEL="${REVIEW_CLAUDE_MODEL:-claude-fable-5-1}"
CLAUDE_EFFORT="${REVIEW_CLAUDE_EFFORT:-high}"
CODEX_MODEL="${REVIEW_CODEX_MODEL:-act-foundry/gpt-6-astra}"
CODEX_EFFORT="${REVIEW_CODEX_EFFORT:-high}"

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "error: branch $BRANCH already exists (an earlier review?). See: git worktree list | grep pr-$PR" >&2
  exit 1
fi
if [ -e "$DIR" ] && [ "$DRY_RUN" != "--dry-run" ]; then
  echo "error: $DIR already exists (an earlier review?). Move or remove it first." >&2
  exit 1
fi

git fetch --quiet origin "pull/$PR/head" "$BASE"
[ "$(git rev-parse FETCH_HEAD)" = "$SHA" ] || { echo "error: fetched head does not match PR head $SHA" >&2; exit 1; }

# Renders a prompt file from the skill dir, filling every {{KEY}} placeholder.
render() {
  python3 - "$SKILL_DIR/$1" PR_URL="$URL" TITLE="$TITLE" SHORT_SHA="${SHA:0:8}" BRANCH="$BRANCH" \
    BASE="$BASE" DIR="$DIR" REPORT="$REPORT" CLAUDE_AGENT="$CLAUDE_AGENT" CODEX_AGENT="$CODEX_AGENT" \
    CODEX_PANE="$CODEX_PANE" <<'PY'
import sys
text = open(sys.argv[1]).read()
for pair in sys.argv[2:]:
    key, value = pair.split("=", 1)
    text = text.replace("{{" + key + "}}", value)
print(text, end="")
PY
}

if [ "$DRY_RUN" = "--dry-run" ]; then
  CODEX_PANE="<codex pane>"
  echo "would create worktree branch=$BRANCH base=$SHA label='review · PR $PR'"
  echo "left pane:  $CLAUDE_AGENT (claude $CLAUDE_MODEL/$CLAUDE_EFFORT)"
  echo "right pane: $CODEX_AGENT (codex $CODEX_MODEL/$CODEX_EFFORT)"
  for f in claude-prompt.md codex-prompt.md; do
    echo "--- $f ---"
    render "$f"
  done
  exit 0
fi

CREATE_JSON="$(herdr worktree create --cwd "$REPO_ROOT" --branch "$BRANCH" --base "$SHA" \
  --label "review · PR $PR" --no-focus)"
read -r WORKSPACE CLAUDE_PANE WORKTREE < <(python3 -c '
import json,sys; r=json.loads(sys.argv[1])["result"]
print(r["workspace"]["workspace_id"], r["root_pane"]["pane_id"], r["worktree"]["path"])' "$CREATE_JSON")

SPLIT_JSON="$(herdr pane split "$CLAUDE_PANE" --direction right --cwd "$WORKTREE" --no-focus)"
CODEX_PANE="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["result"]["pane"]["pane_id"])' "$SPLIT_JSON")"

# ~/.zshrc cds every new shell to ~/dev/act; move each pane back into the worktree.
for PANE in "$CLAUDE_PANE" "$CODEX_PANE"; do
  herdr pane run "$PANE" "cd '$WORKTREE'" >/dev/null
  for _ in $(seq 1 30); do
    herdr pane get "$PANE" | grep -q "\"cwd\":\"$WORKTREE\"" && break
    sleep 1
  done
  herdr pane get "$PANE" | grep -q "\"cwd\":\"$WORKTREE\"" || { echo "error: pane $PANE never reached $WORKTREE" >&2; exit 1; }
done

mkdir -p "$DIR"
for f in claude-prompt.md codex-prompt.md; do
  render "$f" > "$DIR/$f"
done

herdr agent start "$CODEX_AGENT" --kind codex --pane "$CODEX_PANE" --timeout 60000 -- \
  -m "$CODEX_MODEL" -c "model_reasoning_effort=$CODEX_EFFORT" >/dev/null
# The repo's .codex/config.toml declares a Stop hook; a fresh worktree makes Codex ask to trust it
# ("Hook 1 · new"), and an "Update available" dialog can also block startup. Trust and close them
# so the review prompt lands on an idle agent.
if herdr agent get "$CODEX_AGENT" | grep -q '"agent_status":"blocked"'; then
  herdr agent send-keys "$CODEX_AGENT" t >/dev/null
  for _ in 1 2 3; do herdr agent send-keys "$CODEX_AGENT" esc >/dev/null; sleep 1; done
fi

herdr agent start "$CLAUDE_AGENT" --kind claude --pane "$CLAUDE_PANE" --timeout 60000 -- \
  --model "$CLAUDE_MODEL" --effort "$CLAUDE_EFFORT" >/dev/null

herdr agent prompt "$CODEX_AGENT" "Read and follow $DIR/codex-prompt.md" >/dev/null
herdr agent prompt "$CLAUDE_AGENT" "Read and follow $DIR/claude-prompt.md" >/dev/null

echo "pr=$PR title=\"$TITLE\""
echo "workspace=$WORKSPACE"
echo "claude=$CLAUDE_AGENT pane=$CLAUDE_PANE ($CLAUDE_MODEL/$CLAUDE_EFFORT)"
echo "codex=$CODEX_AGENT pane=$CODEX_PANE ($CODEX_MODEL/$CODEX_EFFORT)"
echo "worktree=$WORKTREE branch=$BRANCH head=${SHA:0:8}"
echo "dir=$DIR report=$REPORT"

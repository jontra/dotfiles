#!/usr/bin/env bash
# Usage: cleanup.sh [--force] [--dry-run]
# Run from inside a Herdr pane whose workspace is a linked git worktree. Verifies nothing
# would be lost, then a detached process closes the workspace (ending every agent in it),
# removes the worktree, and deletes its branch.
#   --force    proceed despite uncommitted changes or commits that exist nowhere on origin
#   --dry-run  report what would be removed and exit
set -euo pipefail

FORCE=""; DRY_RUN=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    *) echo "error: unknown argument $arg" >&2; exit 2 ;;
  esac
done

[ "${HERDR_ENV:-}" = 1 ] && [ -n "${HERDR_WORKSPACE_ID:-}" ] || {
  echo "error: not running inside a Herdr pane" >&2; exit 1; }
WS="$HERDR_WORKSPACE_ID"

WS_JSON="$(herdr workspace get "$WS")"
read -r IS_LINKED WORKTREE REPO_ROOT LABEL < <(python3 -c '
import json,sys; w=json.loads(sys.argv[1])["result"]["workspace"]; t=w.get("worktree") or {}
print(str(t.get("is_linked_worktree", False)).lower(), t.get("checkout_path","-"), t.get("repo_root","-"), w.get("label") or "-")' "$WS_JSON")

[ "$IS_LINKED" = true ] || {
  echo "error: workspace $WS ($LABEL) is not a linked worktree workspace; refusing to clean up" >&2; exit 1; }
[ "$WORKTREE" != "$REPO_ROOT" ] || { echo "error: $WORKTREE is the main checkout" >&2; exit 1; }

BRANCH="$(git -C "$WORKTREE" branch --show-current)"
HEAD_SHA="$(git -C "$WORKTREE" rev-parse HEAD)"

problems=()
dirty="$(git -C "$WORKTREE" status --porcelain)"
[ -z "$dirty" ] || problems+=("uncommitted changes:"$'\n'"$dirty")

# Commits are safe when every one is reachable from a remote-tracking ref, or HEAD itself is
# a ref on origin (a PR head fetched by refs/pull/N/head has no remote-tracking ref).
unpushed="$(git -C "$WORKTREE" rev-list --count HEAD --not --remotes)"
if [ "$unpushed" != 0 ] && ! grep -q "^$HEAD_SHA" <<<"$(git -C "$WORKTREE" ls-remote origin)"; then
  problems+=("$unpushed commit(s) on ${BRANCH:-detached HEAD} exist nowhere on origin")
fi

PANES="$(herdr pane list --workspace "$WS" | python3 -c '
import json,sys
for p in json.load(sys.stdin)["result"]["panes"]:
    print(" ", p["pane_id"], p.get("agent") or "shell", p.get("agent_status",""))')"

echo "workspace: $WS ($LABEL) — closing it ends every pane below:"
echo "$PANES"
echo "worktree:  $WORKTREE"
echo "branch:    ${BRANCH:-<detached HEAD, nothing to delete>} at ${HEAD_SHA:0:8}"

if [ ${#problems[@]} -gt 0 ]; then
  printf 'blocked: %s\n' "${problems[@]}"
  [ -n "$FORCE" ] || { echo "re-run with --force to discard these" >&2; exit 1; }
  echo "--force given: discarding them"
fi

[ -z "$DRY_RUN" ] || { echo "dry run: nothing removed"; exit 0; }

LOG_DIR="$HOME/.local/state/herdr-cleanup"; mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/$(date +%Y%m%d-%H%M%S)-$WS.log"
FORCE_FLAG="${FORCE:+--force}"

# The workspace close kills this pane's process tree, so the removal runs in its own session.
python3 - "$LOG" bash -c '
  set -u
  WS="$1"; WORKTREE="$2"; REPO_ROOT="$3"; BRANCH="$4"; FORCE_FLAG="$5"; LABEL="$6"
  sleep 3
  cd "$REPO_ROOT"
  status=ok
  herdr worktree remove --workspace "$WS" $FORCE_FLAG || status="worktree remove failed"
  git worktree prune
  if [ "$status" = ok ] && [ -n "$BRANCH" ]; then
    git branch -D "$BRANCH" || status="branch delete failed"
  fi
  [ -e "$WORKTREE" ] && status="$status; $WORKTREE still exists"
  echo "result: $status"
  herdr notification show "cleanup: $LABEL" --body "$status (log: $0)" --sound done >/dev/null 2>&1 || true
' "$LOG" "$WS" "$WORKTREE" "$REPO_ROOT" "$BRANCH" "$FORCE_FLAG" "$LABEL" <<'PY'
import os, sys
log, argv = sys.argv[1], sys.argv[2:]
if os.fork(): sys.exit(0)
os.setsid()
if os.fork(): os._exit(0)
fd = os.open(log, os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o644)
os.dup2(fd, 1); os.dup2(fd, 2)
os.dup2(os.open(os.devnull, os.O_RDONLY), 0)
os.execvp(argv[0], argv)
PY

echo "cleanup scheduled: this workspace closes in ~3s. Log: $LOG"

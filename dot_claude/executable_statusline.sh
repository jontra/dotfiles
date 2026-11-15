#!/usr/bin/env bash
# Claude Code status line: model/effort · PR and CI · context · 5h limit · weekly limit.
# Reads the JSON Claude Code sends on stdin. The PR state comes from a per-branch cache that a detached
# `statusline.sh --pr-refresh` rewrites at most every 2 minutes, so a refresh never waits on GitHub.
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"

if [ "$1" = "--pr-refresh" ]; then
  # One line per PR, "<number> <url> <state> [<count>]", from the bottom of the stack up to the
  # checked-out branch: each PR's base branch is followed down while it has a PR of its own.
  dir=$2 file=$3 b=$4 lines= seen=
  for _ in 1 2 3 4 5 6 7 8; do
    case " $seen " in *" $b "*) break ;; esac
    seen="$seen $b"
    json=$(cd "$dir" && gh pr view "$b" --json number,url,state,isDraft,baseRefName,statusCheckRollup 2>/dev/null) || break
    [ -n "$json" ] || break
    line=$(printf '%s' "$json" | jq -r '
      def bad: IN("FAILURE","TIMED_OUT","CANCELLED","ACTION_REQUIRED","STARTUP_FAILURE","ERROR");
      "\(.number) \(.url)" as $n
      | [.statusCheckRollup[]? | (.conclusion // .state // "") as $c | (.status // "COMPLETED") as $s
         | if ($c | bad) then "fail" elif $s != "COMPLETED" or ($c | IN("", "PENDING", "EXPECTED")) then "run" else "ok" end] as $r
      | ($r | map(select(. == "fail")) | length) as $f
      | ($r | map(select(. == "run")) | length) as $p
      | if .state == "MERGED" then "\($n) merged"
        elif .state == "CLOSED" then "\($n) closed"
        elif $f > 0 then "\($n) fail \($f)"
        elif $p > 0 then "\($n) run \($p)"
        elif .isDraft then "\($n) draft"
        elif ($r | length) == 0 then "\($n) none"
        else "\($n) pass" end')
    lines="$line${lines:+
$lines}"
    b=$(printf '%s' "$json" | jq -r '.baseRefName')
    { [ "$b" = main ] || [ "$b" = master ] || [ -z "$b" ]; } && break
  done
  printf '%s\n' "${lines:-none}" > "$file.tmp" && mv "$file.tmp" "$file"
  rmdir "$file.lock" 2>/dev/null
  exit 0
fi

input=$(cat)
j() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'

# Colored percentage (rounded): green <50, yellow 50-80, red >80
pct() {
  local n
  n=$(printf '%.0f' "$1")
  local c=$GREEN
  if [ "$n" -gt 80 ]; then c=$RED; elif [ "$n" -ge 50 ]; then c=$YELLOW; fi
  printf '%s%s%%%s' "$c" "$n" "$RESET"
}

# Token count: 420k, 1M, 1.5M
tok() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) { v = n / 1000000; s = sprintf("%.1f", v); sub(/\.0$/, "", s); print s "M" }
    else if (n >= 1000) printf "%.0fk\n", n / 1000
    else printf "%d\n", n
  }'
}

parts=()

model=$(j '.model.display_name')
effort=$(j '.effort.level')
head="$model"
if [ -n "$effort" ]; then
  if [ -n "$head" ]; then head="$head/$effort"; else head="$effort"; fi
fi
[ -n "$head" ] && parts+=("$head")

# PR and CI for the branch checked out in the session's directory, with the PRs it stacks on to its left:
# #10734 ✓ › #10735 draft › #10742 ⏳2. A single PR shows alone: #9525 ✓, #9525 ✗2.
cwd=$(j '.workspace.current_dir')
branch=$([ -n "$cwd" ] && git -C "$cwd" symbolic-ref --short -q HEAD 2>/dev/null)
if [ -n "$branch" ] && [ "$branch" != main ] && [ "$branch" != master ] && command -v gh >/dev/null; then
  top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
  mkdir -p "$cache_dir"
  file="$cache_dir/$(printf '%s' "$top#$branch" | tr -c 'A-Za-z0-9._-' '_').v3"
  find "$cache_dir" -maxdepth 1 -name '*.lock' -mmin +5 -exec rmdir {} + 2>/dev/null
  find "$cache_dir" -maxdepth 1 -type f ! -name '*.v3' -mmin +10 -delete 2>/dev/null
  if [ -z "$(find "$file" -mmin -2 2>/dev/null)" ] && mkdir "$file.lock" 2>/dev/null; then
    nohup bash "$0" --pr-refresh "$top" "$file" "$branch" </dev/null >/dev/null 2>&1 &
  fi
  stack=
  if [ -f "$file" ]; then
    while read -r num url st cnt; do
      [ -n "$num" ] && [ "$num" != none ] || continue
      # OSC 8 hyperlink: terminals that support it make the PR clickable; the rest show plain text.
      link=$(printf '\033]8;;%s\033\\#%s\033]8;;\033\\' "$url" "$num")
      case $st in
        pass)   pr="${GREEN}$link ✓${RESET}" ;;
        fail)   pr="${RED}$link ✗$cnt${RESET}" ;;
        run)    pr="${YELLOW}$link ⏳$cnt${RESET}" ;;
        merged) pr="$link merged" ;;
        *)      pr="$link $st" ;;
      esac
      stack="${stack:+$stack › }$pr"
    done < "$file"
  fi
  [ -n "$stack" ] && parts+=("$stack")
fi

used=$(j '.context_window.used_percentage')
if [ -n "$used" ]; then
  s="ctx $(pct "$used")"
  total=$(j '.context_window.total_input_tokens')
  size=$(j '.context_window.context_window_size')
  if [ -n "$total" ] && [ -n "$size" ]; then
    s="$s ($(tok "$total")/$(tok "$size"))"
  fi
  parts+=("$s")
fi

now=$(date +%s)

five=$(j '.rate_limits.five_hour.used_percentage')
if [ -n "$five" ]; then
  s="5h $(pct "$five")"
  r=$(j '.rate_limits.five_hour.resets_at')
  if [ -n "$r" ]; then
    d=$(( ${r%.*} - now ))
    [ "$d" -lt 0 ] && d=0
    s="$s (resets $((d / 3600))h$(printf '%02d' $(( (d % 3600) / 60 )))m)"
  fi
  parts+=("$s")
fi

week=$(j '.rate_limits.seven_day.used_percentage')
if [ -n "$week" ]; then
  s="week $(pct "$week")"
  r=$(j '.rate_limits.seven_day.resets_at')
  if [ -n "$r" ]; then
    day=$(date -d "@${r%.*}" +%a 2>/dev/null || date -r "${r%.*}" +%a)
    s="$s (resets $day)"
  fi
  parts+=("$s")
fi

out=""
for p in "${parts[@]}"; do
  [ -n "$out" ] && out="$out · "
  out="$out$p"
done
printf '%s\n' "$out"

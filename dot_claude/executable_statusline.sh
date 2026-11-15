#!/usr/bin/env bash
# Claude Code status line: model/effort · context · 5h limit · weekly limit. Reads the JSON Claude Code sends on stdin.
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

#!/usr/bin/env bash
# Runs after chezmoi applied the dotfiles (bootstrap.sh), on the laptop and on Podium workspaces.
# Links what chezmoi does not manage: Claude skills, Herdr plugins. Safe to re-run.
set -euo pipefail

conf="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() { printf '\033[32m>\033[0m %s\n' "$*"; }

# zshrc, gitconfig, vimrc and the zsh theme are managed by chezmoi (bootstrap.sh runs it first).

# Claude Code skills: link every skill directory in skills/ into ~/.claude/skills.
mkdir -p "$HOME/.claude/skills"
for skill_dir in "$conf"/skills/*/; do
  name="$(basename "$skill_dir")"
  ln -sfn "${skill_dir%/}" "$HOME/.claude/skills/$name"
  log "skill: $name"
done
# Drop links to skills that were removed from this repo; other links in ~/.claude/skills are left alone.
for link in "$HOME/.claude/skills"/*; do
  [ -L "$link" ] && [ ! -e "$link" ] && [[ "$(readlink "$link")" == "$conf/skills/"* ]] || continue
  rm "$link" && log "removed stale skill: $(basename "$link")"
done

# Herdr plugins (the image ships herdr; `herdr plugin link` only needs the binary, not a running server).
if command -v herdr >/dev/null 2>&1; then
  for plugin_dir in "$conf"/herdr/plugins/*/; do
    herdr plugin list 2>/dev/null | grep -q "local:${plugin_dir%/}\]" && continue
    herdr plugin link "${plugin_dir%/}" >/dev/null 2>&1 && log "herdr plugin: $(basename "$plugin_dir")"
  done
fi

log "done"

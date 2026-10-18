#!/usr/bin/env bash
# Runs ON a Podium workspace, after chezmoi applied the dotfiles (bootstrap.sh). Installs what
# chezmoi does not manage yet: Azure CLI, skills, Herdr plugins. Safe to re-run.
set -euo pipefail

conf="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() { printf '\033[32m>\033[0m %s\n' "$*"; }

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    log "linked: $dst"
    return
  fi
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.orig"
    log "backed up: $dst -> $dst.orig"
  fi
  ln -sfn "$src" "$dst"
  log "linked: $dst -> $src"
}

# zshrc, gitconfig, vimrc and the zsh theme are managed by chezmoi (bootstrap.sh runs it first).

# Azure CLI: Codex providers authenticate with `az`. Installed into $HOME (persists across pod restarts;
# apt would not, and mise disables pipx:azure-cli on Podium).
# `command -v az` is not enough: the image leaves a dead mise shim for the disabled pipx:azure-cli.
if ! az version >/dev/null 2>&1 && [ ! -x "$HOME/.local/az-venv/bin/az" ]; then
  log "az: installing azure-cli into ~/.local/az-venv (takes a minute)"
  (cd /workspace/act && eval "$(mise activate bash)" && python3 -m venv "$HOME/.local/az-venv" \
    && "$HOME/.local/az-venv/bin/pip" install -q azure-cli) >/dev/null 2>&1 || log "az: install failed (non-fatal)"
fi
[ -x "$HOME/.local/az-venv/bin/az" ] && ln -sf "$HOME/.local/az-venv/bin/az" "$HOME/.local/bin/az"
log "az: $("$HOME/.local/bin/az" version --query '"azure-cli"' -o tsv 2>/dev/null || echo missing) at $HOME/.local/bin/az"


# Claude Code skills: link every skill directory in skills/ into ~/.claude/skills.
# podium-new-workspace is laptop-only (it drives dx ws and the Mac Keychain), so it is skipped here.
mkdir -p "$HOME/.claude/skills"
for skill_dir in "$conf"/skills/*/; do
  name="$(basename "$skill_dir")"
  [ "$name" = podium-new-workspace ] && continue
  ln -sfn "${skill_dir%/}" "$HOME/.claude/skills/$name"
  log "skill: $name"
done


# Herdr plugins (the image ships herdr; `herdr plugin link` only needs the binary, not a running server).
if command -v herdr >/dev/null 2>&1; then
  for plugin_dir in "$conf"/herdr/plugins/*/; do
    herdr plugin list 2>/dev/null | grep -q "local:${plugin_dir%/}\]" && continue
    herdr plugin link "${plugin_dir%/}" >/dev/null 2>&1 && log "herdr plugin: $(basename "$plugin_dir")"
  done
fi

log "done"

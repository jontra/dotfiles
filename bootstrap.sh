#!/usr/bin/env bash
# Entry point for both machines. Podium runs it on every boot (dx ws dotfiles set <repo>); on the
# laptop run it once after cloning to ~/conf. Installs chezmoi if missing, applies the dotfiles from
# this checkout, then runs the per-OS script for what chezmoi does not manage yet.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v chezmoi >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/chezmoi" ]; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi
export PATH="$HOME/.local/bin:$PATH"

# Remember this checkout as the source, so plain `chezmoi apply|diff|edit` work afterwards.
mkdir -p "$HOME/.config/chezmoi"
printf 'sourceDir = "%s"\n' "$here" > "$HOME/.config/chezmoi/chezmoi.toml"
chezmoi apply --source "$here"

case "$(uname -s)" in
  Darwin) bash "$here/install.sh" ;;
  *)      bash "$here/remote-install.sh" ;;
esac

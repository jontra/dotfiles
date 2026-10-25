#!/usr/bin/env bash
# Entry point for both machines. Podium runs it on every boot (dx ws dotfiles set <repo>) from the
# clone at ~/.dotfiles; on the laptop run it once after cloning to ~/dotfiles. Installs chezmoi if
# missing, applies the dotfiles from this checkout, links skills and Herdr plugins (extras.sh), and on
# the laptop runs the private ~/conf/install.sh for what is not public.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v chezmoi >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/chezmoi" ]; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi
export PATH="$HOME/.local/bin:$PATH"

# Remember this checkout as the source, so plain `chezmoi apply|diff|edit` work afterwards.
mkdir -p "$HOME/.config/chezmoi"
printf 'sourceDir = "%s"\n' "$here" > "$HOME/.config/chezmoi/chezmoi.toml"
# On Podium there is no terminal to answer chezmoi's "changed since chezmoi last wrote it" prompt, and boot
# steps after this one edit managed files (dx completion install rewrites .zshrc). The repo is the source
# of truth there, so overwrite; on the laptop keep the prompt.
if [ "${PODIUM:-}" = true ]; then
  chezmoi apply --source "$here" --force
else
  chezmoi apply --source "$here"
fi

bash "$here/extras.sh"
if [ "$(uname -s)" = Darwin ] && [ -f "$HOME/conf/install.sh" ]; then
  bash "$HOME/conf/install.sh"
fi

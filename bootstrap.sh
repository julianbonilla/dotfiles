#!/usr/bin/env bash
#
# dotfiles bootstrap — clone the repo, run this, done.
#   git clone https://github.com/julianbonilla/dotfiles.git ~/dotfiles
#   ~/dotfiles/bootstrap.sh
#
# Idempotent: safe to re-run to pick up new packages / configs.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Homebrew ---------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "→ Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 2. Packages ---------------------------------------------------------------
echo "→ brew bundle (this takes a while on first run)…"
brew bundle --file="$DOTFILES/Brewfile" --no-lock

# 3. Symlink configs into place ---------------------------------------------
echo "→ Linking configs…"
mkdir -p ~/.config
ln -sfn "$DOTFILES/.config/fish" ~/.config/fish
ln -sfn "$DOTFILES/.config/ghostty" ~/.config/ghostty
ln -sfn "$DOTFILES/Brewfile" ~/Brewfile   # keeps `brew bundle --global` working, your old habit

# 4. Fish as the default shell ----------------------------------------------
FISH="$(brew --prefix)/bin/fish"
if ! grep -qx "$FISH" /etc/shells 2>/dev/null; then
  echo "→ Adding fish to /etc/shells (needs sudo)…"
  echo "$FISH" | sudo tee -a /etc/shells >/dev/null
fi
if [ "${SHELL:-}" != "$FISH" ]; then
  echo "→ Setting fish as default shell…"
  chsh -s "$FISH"
fi

# 5. Fisher + Tide prompt ----------------------------------------------------
# Plugins are declared in .config/fish/fish_plugins; `fisher update` installs them.
echo "→ Installing fisher + plugins…"
"$FISH" -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source; and fisher install jorgebucaran/fisher; and fisher update"

# 6. LazyVim starter (only if no nvim config exists — never clobbers) -----------
if [ ! -d ~/.config/nvim ]; then
  echo "→ Installing LazyVim starter…"
  git clone --quiet https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git
fi

echo ""
echo "Done. Next steps:"
echo "  1. Open a new terminal (Ghostty) — you should be in fish."
echo "  2. Run: tide configure   (pick the same style as your work laptop)"
echo "     Tip: to copy the exact prompt, copy ~/.config/fish/fish_variables"
echo "     from your work laptop instead — that's where tide saves its config."

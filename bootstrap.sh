#!/usr/bin/env bash
#
# dotfiles bootstrap — clone the repo, run this, done.
#   git clone https://github.com/julianbonilla/dotfiles.git ~/dotfiles
#   ~/dotfiles/bootstrap.sh
#
# Idempotent: safe to re-run to pick up new packages / configs.
#
# Env flags:
#   DOTFILES_SKIP_PACKAGES=1   skip `brew bundle` (used by CI)
#   CI=true                    skip chsh (needs a password)

set -euo pipefail

[[ "$(uname)" == "Darwin" ]] || { echo "This bootstrap is macOS-only." >&2; exit 1; }

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# link SRC DEST — symlink SRC at DEST. No-op if already correct; a real
# file/dir already at DEST is moved to DEST.bak.<timestamp>, never clobbered
# (and never nested, which is what `ln -sfn` does with a real directory).
link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    [ "$(readlink "$dest")" = "$src" ] && return 0
    ln -sfn "$src" "$dest"
    return
  fi
  if [ -e "$dest" ]; then
    local backup
    backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    echo "  ! $dest exists, moving to $backup"
    mv "$dest" "$backup"
  fi
  ln -s "$src" "$dest"
}

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
if [ -z "${DOTFILES_SKIP_PACKAGES:-}" ]; then
  echo "→ brew bundle (this takes a while on first run)…"
  brew bundle --file="$DOTFILES/Brewfile"
else
  echo "→ Skipping brew bundle (DOTFILES_SKIP_PACKAGES set)"
fi

# 3. Symlink configs into place ---------------------------------------------
echo "→ Linking configs…"
mkdir -p ~/.config
link "$DOTFILES/.config/fish"    ~/.config/fish
link "$DOTFILES/.config/ghostty" ~/.config/ghostty
link "$DOTFILES/Brewfile"        ~/.Brewfile   # `brew bundle --global` reads ~/.Brewfile

# 4. Fish as the default shell ----------------------------------------------
FISH="$(brew --prefix)/bin/fish"
if ! grep -qx "$FISH" /etc/shells 2>/dev/null; then
  echo "→ Adding fish to /etc/shells (needs sudo)…"
  echo "$FISH" | sudo tee -a /etc/shells >/dev/null
fi
if [ "${SHELL:-}" != "$FISH" ] && [ -z "${CI:-}" ]; then
  echo "→ Setting fish as default shell…"
  chsh -s "$FISH"
fi

# 5. Fisher + Tide prompt ----------------------------------------------------
# Plugins are declared in .config/fish/fish_plugins; `fisher update` installs them.
echo "→ Installing fisher + plugins…"
"$FISH" -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source; and fisher install jorgebucaran/fisher; and fisher update"

# 6. LazyVim starter (only if no nvim config exists — never clobbers) ---------
if [ ! -d ~/.config/nvim ]; then
  echo "→ Installing LazyVim starter…"
  git clone --quiet https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git
fi

echo ""
echo "Done. Next steps:"
echo "  1. Open a new terminal (Ghostty) — you should be in fish."
echo "  2. Run: tide configure"
echo "     Tip: to copy an existing prompt, copy ~/.config/fish/fish_variables"
echo "     from another machine instead."

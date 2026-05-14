#!/usr/bin/env bash
# install.sh — bootstrap seandmoore/draftworks dotfiles
# Usage: curl -fsSL https://raw.githubusercontent.com/seandmoore/draftworks/main/install.sh | bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
REPO="https://github.com/seandmoore/draftworks.git"

GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RESET="\033[0m"
info()  { echo -e "${GREEN}==>${RESET} $*"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $*"; }

# ── Clone or update ────────────────────────────────────────────────────────────
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    info "Updating existing dotfiles at $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" pull --ff-only
else
    info "Cloning dotfiles to $DOTFILES_DIR"
    git clone "$REPO" "$DOTFILES_DIR"
fi

# ── Helper: symlink with backup ────────────────────────────────────────────────
link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        warn "Backing up existing $dst → $dst.bak"
        mv "$dst" "$dst.bak"
    fi
    ln -sfn "$src" "$dst"
    info "Linked $dst"
}

# ── Hyprland ───────────────────────────────────────────────────────────────────
link "$DOTFILES_DIR/hypr/hyprland.lua"   "$HOME/.config/hypr/hyprland.lua"
link "$DOTFILES_DIR/hypr/hyprpaper.conf" "$HOME/.config/hypr/hyprpaper.conf"
link "$DOTFILES_DIR/hypr/hyprlock.conf"  "$HOME/.config/hypr/hyprlock.conf"
link "$DOTFILES_DIR/hypr/hypridle.conf"  "$HOME/.config/hypr/hypridle.conf"

# ── Quickshell ─────────────────────────────────────────────────────────────────
link "$DOTFILES_DIR/quickshell" "$HOME/.config/quickshell/config"

# Copy theme sync script (needs to be writable at runtime, not a symlink)
mkdir -p "$HOME/.config/quickshell/scripts"
cp "$DOTFILES_DIR/scripts/sync-theme.sh" "$HOME/.config/quickshell/scripts/sync-theme.sh"
chmod +x "$HOME/.config/quickshell/scripts/sync-theme.sh"
info "Installed sync-theme.sh"

# ── Kitty ──────────────────────────────────────────────────────────────────────
link "$DOTFILES_DIR/kitty/kitty.conf"       "$HOME/.config/kitty/kitty.conf"
link "$DOTFILES_DIR/kitty/colors-mocha.conf" "$HOME/.config/kitty/colors-mocha.conf"
link "$DOTFILES_DIR/kitty/colors-latte.conf" "$HOME/.config/kitty/colors-latte.conf"

# Bootstrap active colors (Mocha by default unless Latte was previously saved)
CACHED_MODE="$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/catppuccin-mode" 2>/dev/null || echo mocha)"
cp "$DOTFILES_DIR/kitty/colors-${CACHED_MODE}.conf" "$HOME/.config/kitty/active-colors.conf"
info "Kitty colors set to Catppuccin ${CACHED_MODE^}"

# ── Neovim ─────────────────────────────────────────────────────────────────────
link "$DOTFILES_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
link "$DOTFILES_DIR/nvim/lua"      "$HOME/.config/nvim/lua"

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
info "Done! Dotfiles installed at $DOTFILES_DIR"
echo ""
echo "  Next steps:"
echo "  1. Set your wallpaper path in ~/.config/hypr/hyprpaper.conf"
echo "  2. Log into Hyprland — Quickshell starts automatically"
echo "  3. Click the moon/sun icon in the bar to toggle Mocha ↔ Latte"
echo "  4. Open Neovim — lazy.nvim will install plugins on first launch"
echo ""
warn "Prerequisites: hyprland quickshell hyprlock hypridle kitty neovim"
warn "               brightnessctl pactl playerctl grimblast hyprpaper"
warn "               JetBrainsMono Nerd Font"

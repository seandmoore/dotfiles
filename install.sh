#!/usr/bin/env bash
# install.sh — Arch Linux Hyprland dotfiles setup
# Run with: bash <(curl -fsSL https://raw.githubusercontent.com/seandmoore/dotfiles/main/install.sh)

set -euo pipefail

REPO_URL="https://github.com/seandmoore/dotfiles.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# ── Helpers ────────────────────────────────────────────────────────────────────

info()  { printf '\e[34m[info]\e[0m  %s\n' "$*"; }
ok()    { printf '\e[32m[ ok ]\e[0m  %s\n' "$*"; }
warn()  { printf '\e[33m[warn]\e[0m  %s\n' "$*"; }
die()   { printf '\e[31m[fail]\e[0m  %s\n' "$*" >&2; exit 1; }

# Create parent dirs and symlink source → dest.
# Warns and skips if dest is a real (non-symlink) directory to avoid nesting.
make_link() {
    local src="$1" dest="$2"
    if [[ -d "$dest" && ! -L "$dest" ]]; then
        warn "Skipping $dest: real directory already exists. Remove it manually to symlink."
        return
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    ok "Linked $dest -> $src"
}

# Copy a default into place only if dest isn't already a real file. For files that
# become local runtime state (e.g. hyprpaper.conf records the current wallpaper), so
# they must NOT be symlinks into the repo (writing them would dirty git).
seed_file() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [[ -f "$dest" && ! -L "$dest" ]]; then
        ok "Kept existing $dest"
    else
        [[ -L "$dest" ]] && rm -f "$dest"   # replace a stale symlink from older installs
        cp "$src" "$dest"
        ok "Seeded $dest <- $src"
    fi
}

# ── Arch Linux detection ───────────────────────────────────────────────────────

[[ -f /etc/arch-release ]] || die "This script requires Arch Linux (/etc/arch-release not found)."

# ── Git check ─────────────────────────────────────────────────────────────────

command -v git &>/dev/null || die "git is required. Install it with: sudo pacman -S git"

# ── Clone or update repo ───────────────────────────────────────────────────────

if [[ -d "$DOTFILES_DIR/.git" ]]; then
    info "Updating existing dotfiles at $DOTFILES_DIR ..."
    git -C "$DOTFILES_DIR" pull --ff-only origin main
else
    info "Cloning dotfiles to $DOTFILES_DIR ..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi
ok "Dotfiles ready at $DOTFILES_DIR"

# ── pacman packages ────────────────────────────────────────────────────────────

PACMAN_PKGS=(
    hyprland
    hyprpaper
    hyprlock
    hypridle
    hyprpolkitagent
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xorg-xwayland
    kitty
    neovim
    wl-clipboard
    grim
    slurp
    brightnessctl
    playerctl
    pavucontrol
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    blueman
    nautilus
    nwg-look
    xsettingsd
    uwsm
    pipewire
    wireplumber
    pipewire-pulse
    inotify-tools
    qt5-wayland
    qt6-wayland
    qt5ct
    qt6ct
    kvantum
    nautilus
    xdg-user-dirs
    flatpak
    noto-fonts
    noto-fonts-emoji
    ttf-jetbrains-mono-nerd
)

info "Checking pacman packages ..."
TO_INSTALL=()
for pkg in "${PACMAN_PKGS[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        ok "Already installed: $pkg"
    else
        TO_INSTALL+=("$pkg")
    fi
done

if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
    info "Installing: ${TO_INSTALL[*]}"
    sudo pacman -S --needed --noconfirm "${TO_INSTALL[@]}" \
        || die "pacman failed — see error above"
    ok "pacman packages installed"
fi

# ── AUR helper (yay) ──────────────────────────────────────────────────────────

if ! command -v yay &>/dev/null; then
    warn "yay (AUR helper) not found."
    # stdin may be a pipe when run via curl — default safely to N
    if [[ -t 0 ]]; then
        read -r -p "Install yay from AUR now? [y/N] " reply
    else
        warn "Non-interactive shell detected; skipping yay install. Re-run the script directly to install AUR packages."
        reply="n"
    fi
    if [[ "${reply,,}" == "y" ]]; then
        info "Installing yay ..."
        sudo pacman -S --needed --noconfirm git base-devel
        TMP_YAY="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay.git "$TMP_YAY/yay"
        (cd "$TMP_YAY/yay" && makepkg -si --noconfirm)
        rm -rf "$TMP_YAY"
        ok "yay installed"
    else
        warn "Skipping yay. AUR packages (quickshell, grimblast) must be installed manually."
    fi
fi

# ── AUR packages ──────────────────────────────────────────────────────────────

AUR_PKGS=(
    quickshell-git
    grimblast-git
    kvantum-theme-catppuccin-git
    catppuccin-gtk-theme-mocha
    catppuccin-gtk-theme-latte
    catppuccin-cursors-mocha
    catppuccin-cursors-latte
)

if command -v yay &>/dev/null; then
    info "Checking AUR packages ..."
    for pkg in "${AUR_PKGS[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            ok "Already installed (AUR): $pkg"
        else
            yay -S --needed --noconfirm "$pkg" \
                || warn "Failed to install AUR package: $pkg (continuing)"
        fi
    done
else
    warn "yay not available — skipping AUR packages: ${AUR_PKGS[*]}"
    warn "Install them manually: yay -S ${AUR_PKGS[*]}"
fi

# ── Catppuccin Latte GTK theme (prebuilt fallback) ─────────────────────────────
# The AUR package catppuccin-gtk-theme-latte (above) installs to /usr/share/themes
# but can fail to build. Fall back to the official prebuilt release into the user
# theme dir (no sudo/AUR). sync-theme.sh reads ~/.local/share/themes for light mode.
LATTE_USR="/usr/share/themes/catppuccin-latte-mauve-standard+default/gtk-4.0/gtk.css"
LATTE_LOCAL="$HOME/.local/share/themes/catppuccin-latte-mauve-standard+default/gtk-4.0/gtk.css"
if grep -q '@define-color' "$LATTE_USR" 2>/dev/null || grep -q '@define-color' "$LATTE_LOCAL" 2>/dev/null; then
    ok "Catppuccin Latte GTK theme already present"
else
    info "Fetching Catppuccin Latte GTK theme (prebuilt) ..."
    _latte_tmp=$(mktemp -d)
    if curl -fsSL -o "$_latte_tmp/latte.zip" \
        "https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-latte-mauve-standard+default.zip"; then
        mkdir -p "$HOME/.local/share/themes"
        # Extract only the main variant (skip -hdpi/-xhdpi). unzip is often absent; use python.
        python3 -c "import zipfile; z=zipfile.ZipFile('$_latte_tmp/latte.zip'); z.extractall('$HOME/.local/share/themes/', [n for n in z.namelist() if n.startswith('catppuccin-latte-mauve-standard+default/')])" \
            && ok "Catppuccin Latte GTK theme installed to ~/.local/share/themes" \
            || warn "Could not extract Catppuccin Latte theme (python3 missing?)"
    else
        warn "Could not download Catppuccin Latte theme; light-mode GTK widgets may be unthemed"
    fi
    rm -rf "$_latte_tmp"
fi

# ── Flatpak / Flathub ─────────────────────────────────────────────────────────

if command -v flatpak &>/dev/null; then
    info "Configuring Flatpak ..."
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
        || warn "Could not add Flathub remote (continuing)"
    ok "Flathub remote ready"

    info "Installing Zen Browser ..."
    flatpak install --user --noninteractive flathub app.zen_browser.zen \
        || warn "Could not install Zen Browser (continuing)"
    ok "Zen Browser installed"

    info "Applying Flatpak Catppuccin theme overrides ..."
    # Default to mocha (dark); sync-theme.sh flips env + portal on a light/dark switch.
    # :ro grants let sandboxes READ the host theme/icons/cursors; env picks the flavor
    # for non-libadwaita GTK apps (libadwaita follows the portal + gtk.css :root).
    flatpak override --user \
        --env=GTK_THEME=catppuccin-mocha-mauve-standard+default \
        --env=ICON_THEME=Papirus-Dark \
        --filesystem=xdg-config/gtk-3.0:ro \
        --filesystem=xdg-config/gtk-4.0:ro \
        --filesystem=xdg-data/themes:ro \
        --filesystem=xdg-data/icons:ro \
        --filesystem=~/.icons:ro
    ok "Flatpak theme overrides applied"
fi

# ── Symlinks ───────────────────────────────────────────────────────────────────

info "Creating config symlinks ..."

# Hyprland
make_link "$DOTFILES_DIR/hypr/hyprland.lua"   "$HOME/.config/hypr/hyprland.lua"
seed_file "$DOTFILES_DIR/hypr/hyprpaper.conf"  "$HOME/.config/hypr/hyprpaper.conf"   # local runtime state (current wallpaper)
make_link "$DOTFILES_DIR/hypr/hyprlock.conf"   "$HOME/.config/hypr/hyprlock.conf"
make_link "$DOTFILES_DIR/hypr/hypridle.conf"   "$HOME/.config/hypr/hypridle.conf"

# Quickshell config tree
make_link "$DOTFILES_DIR/quickshell" "$HOME/.config/quickshell/config"

# Quickshell scripts — shell.qml hard-codes ~/.config/quickshell/scripts/sync-theme.sh
# but scripts/ lives at the repo root, not inside quickshell/
make_link "$DOTFILES_DIR/scripts" "$HOME/.config/quickshell/scripts"

# Kitty
make_link "$DOTFILES_DIR/kitty/kitty.conf"        "$HOME/.config/kitty/kitty.conf"
make_link "$DOTFILES_DIR/kitty/colors-mocha.conf"  "$HOME/.config/kitty/colors-mocha.conf"
make_link "$DOTFILES_DIR/kitty/colors-latte.conf"  "$HOME/.config/kitty/colors-latte.conf"

# Neovim
make_link "$DOTFILES_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
make_link "$DOTFILES_DIR/nvim/lua"      "$HOME/.config/nvim/lua"

# Qt theming (shortcut underlines off, Kvantum style, Papirus-Dark icons)
make_link "$DOTFILES_DIR/qt5ct/qt5ct.conf" "$HOME/.config/qt5ct/qt5ct.conf"
make_link "$DOTFILES_DIR/qt6ct/qt6ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"

# XDG desktop portal — routes Settings portal to gtk so libadwaita apps get the correct color scheme
make_link "$DOTFILES_DIR/xdg-desktop-portal/hyprland-portals.conf" "$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"

# GTK4 / libadwaita CSS — must be a real file (Flatpak blocks symlinks outside whitelisted paths)
# sync-theme.sh overwrites this file when switching mocha <-> latte
mkdir -p "$HOME/.config/gtk-4.0"
cp "$DOTFILES_DIR/gtk-4.0/gtk-mocha-mauve.css" "$HOME/.config/gtk-4.0/gtk.css"
ok "Wrote ~/.config/gtk-4.0/gtk.css (Catppuccin Mocha default)"

# ── Bootstrap xsettingsd config ───────────────────────────────────────────────
# xsettingsd is started by hyprland.lua on startup; sync-theme.sh updates it on
# theme switch. We only write the file if it doesn't already exist.
XSETTINGSD_CONF="$HOME/.config/xsettingsd/xsettingsd.conf"
if [[ ! -f "$XSETTINGSD_CONF" ]]; then
    mkdir -p "$(dirname "$XSETTINGSD_CONF")"
    cat > "$XSETTINGSD_CONF" << 'XEOF'
Net/ThemeName "catppuccin-mocha-mauve-standard+default"
Net/IconThemeName "Papirus-Dark"
Gtk/CursorThemeName "catppuccin-mocha-mauve-cursors"
Net/EnableEventSounds 1
EnableInputFeedbackSounds 1
Xft/Antialias 1
Xft/Hinting 1
Xft/HintStyle "hintfull"
Xft/RGBA "rgb"
XEOF
    ok "Created $XSETTINGSD_CONF (Catppuccin Mocha default)"
else
    ok "xsettingsd.conf already exists — leaving it untouched"
fi

# ── Bootstrap kitty active-colors.conf ────────────────────────────────────────
# kitty.conf includes active-colors.conf at startup; sync-theme.sh manages it
# at runtime by overwriting it. Must be a plain file, not a symlink.
ACTIVE_COLORS="$HOME/.config/kitty/active-colors.conf"
if [[ ! -f "$ACTIVE_COLORS" ]]; then
    cp "$DOTFILES_DIR/kitty/colors-mocha.conf" "$ACTIVE_COLORS"
    ok "Created $ACTIVE_COLORS (Catppuccin Mocha default)"
else
    ok "active-colors.conf already exists — leaving it untouched"
fi

# ── XDG user directories ─────────────────────────────────────────────────────

info "Setting up home folders ..."
xdg-user-dirs-update
ok "Home folders ready (Documents, Downloads, Music, Pictures, Videos, etc.)"

# ── Systemd user services ─────────────────────────────────────────────────────

info "Enabling systemd user services ..."
systemctl --user enable --now pipewire wireplumber pipewire-pulse \
    || warn "Could not enable PipeWire services (may need an active user session)"
systemctl --user enable --now xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    || warn "Could not enable XDG portal services"
ok "Systemd user services enabled"

# Enable bluetooth system service
info "Enabling bluetooth ..."
sudo systemctl enable --now bluetooth \
    || warn "Could not enable bluetooth service"
ok "Bluetooth enabled"

# ── Font cache ────────────────────────────────────────────────────────────────

info "Refreshing font cache ..."
fc-cache -fv &>/dev/null
ok "Font cache refreshed"

# ── Done ──────────────────────────────────────────────────────────────────────

printf '\n'
ok "Dotfiles installed successfully!"
printf '\n'
printf '  Next steps:\n'
printf '  1. Place a wallpaper in ~/Pictures/ and update\n'
printf '     ~/dotfiles/hypr/hyprpaper.conf with its path\n'
printf '  2. Run: Hyprland  (or log in via your display manager)\n'
printf '  3. Use the theme toggle in the bar to switch Mocha <-> Latte\n'
printf '     or press SUPER+G to open nwg-look for GTK theme fine-tuning\n'
printf '  4. Press SUPER+H to open the keybind cheat sheet\n'
printf '\n'

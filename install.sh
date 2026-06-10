#!/usr/bin/env bash
# install.sh — Arch Linux Hyprland dotfiles setup
#
# Full setup (everything, including hardware-specific extras):
#   bash <(curl -fsSL https://raw.githubusercontent.com/seandmoore/dotfiles/main/install.sh)
# Minimal setup (just the desktop — recommended on machines that aren't mine):
#   bash <(curl -fsSL https://raw.githubusercontent.com/seandmoore/dotfiles/main/install.sh) --minimal

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

# ── Install profile ────────────────────────────────────────────────────────────
# full    — everything, including hardware-/workflow-specific extras: ROCm (AMD
#           GPU compute), VRAM foreground boosting (dmemcg + Steam launcher),
#           the Ollama ROCm drop-in, AI-CLI aliases, Rust PATH wiring, and the
#           Zen second browser.
# minimal — the complete desktop without those extras: Hyprland + the quickshell
#           bar/launcher/notifications, full Catppuccin theming (GTK/Qt/SDDM),
#           Kitty, Neovim, Starship, audio, screenshots, Firefox. The right
#           starting point for anyone who isn't me.
# Pick with --minimal / --full, the DOTFILES_PROFILE env var, or the prompt below.
PROFILE="${DOTFILES_PROFILE:-}"
for arg in "$@"; do
    case "$arg" in
        --minimal) PROFILE="minimal" ;;
        --full)    PROFILE="full" ;;
        -h|--help)
            printf 'usage: install.sh [--minimal|--full]\n'
            printf '  --minimal  core desktop only (skips ROCm, VRAM boosting, AI/dev extras)\n'
            printf '  --full     everything (default)\n'
            exit 0 ;;
        *) die "Unknown option: $arg (use --minimal or --full)" ;;
    esac
done
if [[ -z "$PROFILE" ]]; then
    # stdin may be a pipe when run via curl — default safely to full (matches
    # the historical behaviour of this script).
    if [[ -t 0 ]]; then
        printf '\nChoose an install profile:\n'
        printf '  [1] full    — everything, incl. ROCm (AMD), VRAM foreground boosting,\n'
        printf '                Ollama/AI-CLI extras (default)\n'
        printf '  [2] minimal — just the desktop: Hyprland, bar, theming, terminal, editor\n'
        read -r -p 'Profile [1/2]: ' reply
        if [[ "$reply" == "2" ]]; then PROFILE="minimal"; else PROFILE="full"; fi
    else
        PROFILE="full"
    fi
fi
[[ "$PROFILE" == "full" || "$PROFILE" == "minimal" ]] \
    || die "Invalid DOTFILES_PROFILE: $PROFILE (use full or minimal)"
is_full() { [[ "$PROFILE" == "full" ]]; }
info "Install profile: $PROFILE"

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

# ── Git pre-commit hook ─────────────────────────────────────────────────────────
# Lint staged files (scripts/verify.sh --staged) before each commit. The hook
# lives in the tracked .githooks/ dir; point git at it so fresh clones pick it up.
info "Activating the pre-commit hook ..."
git -C "$DOTFILES_DIR" config core.hooksPath .githooks
ok "Pre-commit hook active (.githooks/pre-commit)"

# ── pacman packages ────────────────────────────────────────────────────────────

PACMAN_PKGS=(
    hyprland
    hyprpaper
    hyprlock
    hypridle
    hyprpolkitagent
    hyprsunset
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xorg-xwayland
    kitty
    neovim
    lua-language-server
    stylua
    starship
    fzf
    atuin
    bash-preexec
    wl-clipboard
    unzip
    grim
    slurp
    ffmpeg
    jq
    libnotify
    pacman-contrib
    brightnessctl
    playerctl
    pavucontrol
    cava
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    blueman
    nautilus
    nwg-look
    xsettingsd
    papirus-icon-theme
    sddm
    uwsm
    pipewire
    wireplumber
    pipewire-pulse
    inotify-tools
    quickshell
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
        warn "Skipping yay. AUR packages (grimblast, themes) must be installed manually."
    fi
fi

# ── AUR packages ──────────────────────────────────────────────────────────────

AUR_PKGS=(
    grimblast-git
    kvantum-theme-catppuccin-git
    catppuccin-gtk-theme-mocha
    catppuccin-gtk-theme-latte
    catppuccin-cursors-mocha
    catppuccin-cursors-latte
)
# dmemcg-booster underpins VRAM foreground boosting (full profile only).
is_full && AUR_PKGS+=(dmemcg-booster)

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

    if is_full; then
        info "Installing browsers (Firefox + Zen) ..."
    else
        info "Installing browser (Firefox) ..."
    fi
    flatpak install --user --noninteractive flathub org.mozilla.firefox \
        || warn "Could not install Firefox (continuing)"
    if is_full; then
        flatpak install --user --noninteractive flathub app.zen_browser.zen \
            || warn "Could not install Zen Browser (continuing)"
    fi
    ok "Browser(s) installed"

    # Firefox (flatpak) is the default browser; SUPER+B in hyprland.lua launches it too.
    info "Setting Firefox as the default web browser ..."
    xdg-settings set default-web-browser org.mozilla.firefox.desktop 2>/dev/null \
        && xdg-mime default org.mozilla.firefox.desktop \
            x-scheme-handler/http x-scheme-handler/https text/html 2>/dev/null \
        && ok "Firefox set as default browser" \
        || warn "Could not set default browser (continuing)"

    # Firefox UI styling is intentionally left at Firefox's default — we use the
    # Catppuccin browser theme EXTENSION (from addons.mozilla.org) instead of a
    # manual userChrome.css. (Removed the old firefox-theme.sh userChrome deploy.)

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

# Starship prompt — seeded (not symlinked): sync-theme.sh rewrites the active
# `palette` line on every light/dark toggle, which would otherwise dirty the repo.
seed_file "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# Initialise Starship in interactive shells (append once; idempotent).
for rc in "$HOME/.bashrc:bash" "$HOME/.zshrc:zsh"; do
    rc_file="${rc%%:*}"; rc_shell="${rc##*:}"
    if [[ -f "$rc_file" ]] && ! grep -qF 'starship init' "$rc_file"; then
        printf '\n# Starship prompt (managed by dotfiles)\neval "$(starship init %s)"\n' "$rc_shell" >> "$rc_file"
        ok "Wired Starship into $rc_file"
    fi
done

# Neovim
make_link "$DOTFILES_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
make_link "$DOTFILES_DIR/nvim/lua"      "$HOME/.config/nvim/lua"

if is_full; then
    # OpenCode — full-auto 'yolo' agent used by the `ocd` alias
    make_link "$DOTFILES_DIR/opencode/agent/yolo.md" "$HOME/.config/opencode/agent/yolo.md"

    # VRAM foreground boosting (dmemcg) — see vram/README.md. The Hyprland counterpart to
    # KDE's plasma-foreground-booster; needs AUR dmemcg-booster + CONFIG_CGROUP_DMEM kernel.
    make_link "$DOTFILES_DIR/vram/hypr-dmemcg-foreground"         "$HOME/.local/bin/hypr-dmemcg-foreground"
    make_link "$DOTFILES_DIR/vram/hypr-dmemcg-foreground.service" "$HOME/.config/systemd/user/hypr-dmemcg-foreground.service"
    # Launch Steam directly under app.slice (the dmem-protected branch) so the boost applies.
    make_link "$DOTFILES_DIR/vram/steam.desktop"                  "$HOME/.local/share/applications/steam.desktop"
fi

# Qt theming (shortcut underlines off, Kvantum style, Papirus-Dark icons)
make_link "$DOTFILES_DIR/qt5ct/qt5ct.conf" "$HOME/.config/qt5ct/qt5ct.conf"
make_link "$DOTFILES_DIR/qt6ct/qt6ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"

# XDG desktop portal — routes Settings portal to gtk so libadwaita apps get the correct color scheme
make_link "$DOTFILES_DIR/xdg-desktop-portal/hyprland-portals.conf" "$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"

# GTK4 / libadwaita CSS — must be a real file (Flatpak blocks symlinks outside whitelisted paths).
# The contents (theme @import + flavor :root block + chrome overrides) are generated by the
# sync-theme.sh call near the end of this script — the same path the Mocha<->Latte toggle uses,
# so there's a single source of truth and no stale hand-maintained copy to drift.
mkdir -p "$HOME/.config/gtk-4.0"

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

# kitty's active-colors.conf (included by kitty.conf at startup) is generated by the
# sync-theme.sh call near the end of this script, from the symlinked colors-<mode>.conf —
# no separate bootstrap needed.

if is_full; then
    # ── ROCm (AMD GPU compute) ─────────────────────────────────────────────────
    # Exposes ROCm to the graphical session (environment.d) and interactive shells,
    # and hides the unsupported Raphael iGPU so compute only sees the discrete GPU.
    info "Configuring ROCm ..."

    # GUI apps launched from the uwsm/Hyprland session inherit this.
    make_link "$DOTFILES_DIR/environment.d/rocm.conf" "$HOME/.config/environment.d/rocm.conf"

    # GPU device access. /dev/kfd and /dev/dri/renderD* are owned by the render/video
    # groups; without membership ROCm only works while udev happens to leave the nodes
    # world-accessible, which is fragile across kernel/udev updates. Add the user once
    # (takes effect on next login). Idempotent: skips if already a member.
    for grp in render video; do
        if getent group "$grp" >/dev/null && ! id -nG "$USER" | grep -qw "$grp"; then
            sudo usermod -aG "$grp" "$USER" && ok "Added $USER to '$grp' (re-login required)" \
                || warn "Could not add $USER to '$grp'"
        else
            ok "$USER already in '$grp' (or group absent)"
        fi
    done

    # Interactive shells source shell/rocm.sh (covers bare TTY/SSH logins). Append the
    # source line once per rc file; the grep guard keeps re-runs idempotent.
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc" ]] && ! grep -qF 'dotfiles/shell/rocm.sh' "$rc"; then
            printf '\n# ROCm (managed by dotfiles)\n[[ -f "$HOME/dotfiles/shell/rocm.sh" ]] && . "$HOME/dotfiles/shell/rocm.sh"\n' >> "$rc"
            ok "Wired ROCm into $rc"
        else
            ok "ROCm already wired into $rc (or rc absent)"
        fi
    done

    # ── Shell aliases (cc/ccd Claude Code, oc/ocd OpenCode) ────────────────────
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc" ]] && ! grep -qF 'dotfiles/shell/aliases.sh' "$rc"; then
            printf '\n# Aliases (managed by dotfiles)\n[[ -f "$HOME/dotfiles/shell/aliases.sh" ]] && . "$HOME/dotfiles/shell/aliases.sh"\n' >> "$rc"
            ok "Wired aliases into $rc"
        else
            ok "Aliases already wired into $rc (or rc absent)"
        fi
    done

    # ── History + fzf menu (Ctrl+R) ────────────────────────────────────────────
    # Bash-only: shell/history.sh uses shopt/PROMPT_COMMAND and fzf's bash bindings.
    if [[ -f "$HOME/.bashrc" ]] && ! grep -qF 'dotfiles/shell/history.sh' "$HOME/.bashrc"; then
        printf '\n# History + fzf menu (managed by dotfiles)\n[[ -f "$HOME/dotfiles/shell/history.sh" ]] && . "$HOME/dotfiles/shell/history.sh"\n' >> "$HOME/.bashrc"
        ok "Wired history/fzf into $HOME/.bashrc"
    else
        ok "History/fzf already wired into $HOME/.bashrc (or rc absent)"
    fi

    # ── Rust (rustup) PATH ─────────────────────────────────────────────────────
    # rustup installs proxies under ~/.cargo/bin; shell/rust.sh sources ~/.cargo/env so
    # they're on PATH in interactive shells. (Install rustup with: pacman -S rustup &&
    # rustup default stable — or the official rustup-init.)
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc" ]] && ! grep -qF 'dotfiles/shell/rust.sh' "$rc"; then
            printf '\n# Rust (managed by dotfiles)\n[[ -f "$HOME/dotfiles/shell/rust.sh" ]] && . "$HOME/dotfiles/shell/rust.sh"\n' >> "$rc"
            ok "Wired Rust into $rc"
        else
            ok "Rust already wired into $rc (or rc absent)"
        fi
    done

    # Ollama: hide the iGPU from GPU discovery (bundled rocBLAS crashes probing gfx1036).
    if command -v ollama &>/dev/null; then
        if sudo install -Dm644 "$DOTFILES_DIR/etc/systemd/system/ollama.service.d/rocm.conf" \
                /etc/systemd/system/ollama.service.d/rocm.conf \
            && sudo systemctl daemon-reload \
            && sudo systemctl try-restart ollama; then
            ok "Installed Ollama ROCm drop-in"
        else
            warn "Could not install Ollama ROCm drop-in"
        fi
    fi

    # ── VRAM patch (dmem cgroup) kernel-check hook ─────────────────────────────
    # Verify CONFIG_CGROUP_DMEM ("Valve's VRAM patch") stays enabled across kernel
    # updates. Advisory pacman hook; the helper exits 0 so it never blocks an upgrade.
    info "Installing dmem (VRAM patch) kernel-check pacman hook ..."
    if sudo install -Dm755 "$DOTFILES_DIR/scripts/check-dmem-config.sh" /usr/local/bin/check-dmem-config.sh \
        && sudo install -Dm644 "$DOTFILES_DIR/etc/pacman.d/hooks/95-vram-dmem-check.hook" /etc/pacman.d/hooks/95-vram-dmem-check.hook; then
        ok "Installed dmem kernel-check hook"
    else
        warn "Could not install dmem kernel-check hook"
    fi
else
    info "Minimal profile: skipping ROCm, AI-CLI aliases, Rust wiring, Ollama and VRAM extras"
fi

# ── SDDM login theme (Catppuccin) ──────────────────────────────────────────────
# Installs the Catppuccin Mocha + Latte SDDM themes, the sddm-set-theme helper and a
# NOPASSWD sudoers rule so the Mocha<->Latte toggle (sync-theme.sh) also flips the
# login screen. Idempotent; needs root for /usr/share, /usr/local/bin and /etc.
info "Configuring SDDM Catppuccin theme ..."
if sudo bash "$DOTFILES_DIR/scripts/sddm-install.sh"; then
    ok "SDDM Catppuccin theme installed"
else
    warn "Could not configure SDDM Catppuccin theme (continuing)"
fi

# ── Seed the active theme ───────────────────────────────────────────────────────
# Generate the initial theme state through sync-theme.sh — the SAME path the bar's
# Mocha<->Latte toggle uses — so install and runtime share one source of truth. This
# writes the libadwaita gtk.css (theme @import + flavor :root + chrome overrides),
# kitty active-colors, the Starship palette, Kvantum/Qt icon themes and gsettings.
# Honour an already-chosen flavor on re-runs; default to Mocha on a fresh install.
# Runs after the GTK themes, symlinks and SDDM helper are in place; its live-apply
# bits (hyprctl, flatpak, sddm-set-theme) no-op safely outside a graphical session.
info "Seeding the active Catppuccin theme ..."
SEED_MODE="$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/catppuccin-mode" 2>/dev/null || echo mocha)"
if bash "$DOTFILES_DIR/scripts/sync-theme.sh" "$SEED_MODE"; then
    ok "Theme seeded ($SEED_MODE) — gtk.css, kitty, starship, Qt/Kvantum"
else
    warn "sync-theme.sh reported an error while seeding the theme (continuing)"
fi

# ── XDG user directories ─────────────────────────────────────────────────────

info "Setting up home folders ..."
xdg-user-dirs-update
# Screenshots land here (see scripts/screenshot-*.sh); create it up front so it
# exists on a fresh install before the first screenshot.
mkdir -p "$HOME/Pictures/Screenshots"
ok "Home folders ready (Documents, Downloads, Music, Pictures, Pictures/Screenshots, Videos, etc.)"

# ── Systemd user services ─────────────────────────────────────────────────────

info "Enabling systemd user services ..."
systemctl --user enable --now pipewire wireplumber pipewire-pulse \
    || warn "Could not enable PipeWire services (may need an active user session)"
systemctl --user enable --now xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    || warn "Could not enable XDG portal services"

# Hyprland session daemons. These ship WantedBy=graphical-session.target but are
# disabled by default — without enabling them the target never pulls them in, so the
# desktop comes up with no wallpaper (hyprpaper), no idle/lock (hypridle) and no
# polkit auth prompts (hyprpolkitagent). hyprland.lua assumes systemd starts them.
# Enable only (no --now): they're session-bound (ConditionEnvironment=WAYLAND_DISPLAY)
# and get started at the next login; starting them outside a graphical session no-ops.
systemctl --user enable hyprpaper.service hypridle.service hyprpolkitagent.service \
    || warn "Could not enable Hyprland session services"

# VRAM foreground booster (requires AUR dmemcg-booster, whose own system+user
# services are enabled by its package). Enable the Hyprland focus daemon here.
if is_full; then
    systemctl --user enable hypr-dmemcg-foreground.service \
        || warn "Could not enable hypr-dmemcg-foreground (is AUR dmemcg-booster installed?)"
fi

# Notifications are served by quickshell's own org.freedesktop.Notifications
# implementation (quickshell/notifications/NotificationServer.qml). dunst and mako
# both ship D-Bus activation files (SystemdService=dunst/mako.service) that would
# otherwise race quickshell for that bus name. Mask their user units so D-Bus can
# never auto-start them, leaving the name free for quickshell to claim on launch.
# (Masking a unit that isn't installed is harmless and still blocks future activation.)
systemctl --user mask dunst.service mako.service \
    || warn "Could not mask dunst/mako (quickshell may not own notifications)"
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
ok "Dotfiles installed successfully! (profile: $PROFILE)"
if ! is_full; then
    info "Skipped (full profile only): ROCm, VRAM foreground boosting, Ollama drop-in,"
    info "AI-CLI aliases, Rust wiring, Zen Browser. Re-run with --full to add them."
fi
printf '\n'
printf '  Next steps:\n'
printf '  1. Place a wallpaper in ~/Pictures/ and update\n'
printf '     ~/dotfiles/hypr/hyprpaper.conf with its path\n'
printf '  2. Run: Hyprland  (or log in via your display manager)\n'
printf '  3. Use the theme toggle in the bar to switch Mocha <-> Latte\n'
printf '     or press SUPER+G to open nwg-look for GTK theme fine-tuning\n'
printf '  4. Press SUPER+H to open the keybind cheat sheet\n'
printf '  5. On an HDR monitor, DP-1 boots in HDR + vibrant mode (sdrsaturation 1.35,\n'
printf '     tuned to match KDE Plasma'"'"'s "SDR Color Intensity" slider at 100%%);\n'
printf '     toggle via SUPER+SHIFT+D / SUPER+SHIFT+A or the bar'"'"'s Display menu\n'
printf '\n'

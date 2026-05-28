#!/usr/bin/env bash
# sync-theme.sh — propagate Catppuccin theme switch to all apps
# Usage: sync-theme.sh [mocha|latte]

MODE="${1:-mocha}"
echo "$(date): sync-theme.sh $MODE caller=$0" >> /tmp/sync-theme.log

if [[ "$MODE" == "latte" ]]; then
    ACTIVE_BORDER="rgba(8839efff)"
    INACTIVE_BORDER="rgba(bcc0ccff)"
    SHADOW_COLOR="rgba(dce0e8aa)"
    GTK_THEME="catppuccin-latte-mauve-standard+default"
    KVANTUM_THEME="catppuccin-latte-mauve"
    ICON_THEME="Papirus"
    CURSOR_THEME="catppuccin-latte-mauve-cursors"
    PREFER_DARK="0"
else
    ACTIVE_BORDER="rgba(cba6f7ff)"
    INACTIVE_BORDER="rgba(45475aff)"
    SHADOW_COLOR="rgba(11111bcc)"
    GTK_THEME="catppuccin-mocha-mauve-standard+default"
    KVANTUM_THEME="catppuccin-mocha-mauve"
    ICON_THEME="Papirus-Dark"
    CURSOR_THEME="catppuccin-mocha-mauve-cursors"
    PREFER_DARK="1"
fi

# ── Persist selection (before Hyprland reload so Lua reads the new value) ──────
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
echo "$MODE" > "${XDG_CACHE_HOME:-$HOME/.cache}/catppuccin-mode"

# ── Hyprland — reload so Lua config re-reads the cache file ────────────────────
hyprctl reload 2>/dev/null || true

# ── Kitty ──────────────────────────────────────────────────────────────────────
KITTY_COLORS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
if [[ -f "$KITTY_COLORS_DIR/colors-$MODE.conf" ]]; then
    cp "$KITTY_COLORS_DIR/colors-$MODE.conf" "$KITTY_COLORS_DIR/active-colors.conf"
    pkill -SIGUSR1 -x kitty 2>/dev/null || true
fi

# ── GTK3 settings ──────────────────────────────────────────────────────────────
GTK3_SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
sed -i "s/^gtk-theme-name = .*/gtk-theme-name = $GTK_THEME/" "$GTK3_SETTINGS"
sed -i "s/^gtk-icon-theme-name = .*/gtk-icon-theme-name = $ICON_THEME/" "$GTK3_SETTINGS"
sed -i "s/^gtk-cursor-theme-name = .*/gtk-cursor-theme-name = $CURSOR_THEME/" "$GTK3_SETTINGS"
sed -i "s/^gtk-application-prefer-dark-theme = .*/gtk-application-prefer-dark-theme = $PREFER_DARK/" "$GTK3_SETTINGS"

# ── GTK4 settings ──────────────────────────────────────────────────────────────
GTK4_SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/settings.ini"
sed -i "s/^gtk-theme-name = .*/gtk-theme-name = $GTK_THEME/" "$GTK4_SETTINGS"
sed -i "s/^gtk-icon-theme-name = .*/gtk-icon-theme-name = $ICON_THEME/" "$GTK4_SETTINGS"
sed -i "s/^gtk-cursor-theme-name = .*/gtk-cursor-theme-name = $CURSOR_THEME/" "$GTK4_SETTINGS"
sed -i "s/^gtk-application-prefer-dark-theme = .*/gtk-application-prefer-dark-theme = $PREFER_DARK/" "$GTK4_SETTINGS"

# ── GTK4 / libadwaita CSS ──────────────────────────────────────────────────────
GTK4_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
THEME_DIR="/usr/share/themes/${GTK_THEME}/gtk-4.0"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
LOCAL_THEME_DIR="$HOME/.local/share/themes/${GTK_THEME}/gtk-4.0"

# Update local user theme (~/.local/share/themes/) — this is what Flatpak sandboxes
# read via xdg-data/themes:ro permission. When gsettings gtk-theme changes, GTK4
# reloads the theme live in all running apps via the Settings portal.
mkdir -p "$LOCAL_THEME_DIR"
cp "$DOTFILES_DIR/gtk-4.0/gtk-${MODE}-mauve.css" "$LOCAL_THEME_DIR/gtk.css"
cp "$DOTFILES_DIR/gtk-4.0/gtk-${MODE}-mauve.css" "$LOCAL_THEME_DIR/gtk-dark.css"

# Update ~/.config/gtk-4.0/gtk.css for native (non-Flatpak) GTK4 apps.
# Flatpak apps get the colors from the local theme above.
cp "$DOTFILES_DIR/gtk-4.0/gtk-${MODE}-mauve.css" "$GTK4_DIR/gtk.css"

# Keep assets symlink for native GTK4 apps that use the system theme path
if [[ -d "$THEME_DIR/assets" ]]; then
    rm -rf "$GTK4_DIR/assets"
    ln -sf "$THEME_DIR/assets" "$GTK4_DIR/assets"
fi

# ── gsettings (running GNOME/GTK apps pick this up live) ───────────────────────
gsettings set org.gnome.desktop.interface gtk-theme        "$GTK_THEME"     2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme       "$ICON_THEME"    2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme     "$CURSOR_THEME"  2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme     \
    "$([ "$MODE" = "latte" ] && echo prefer-light || echo prefer-dark)" 2>/dev/null || true

# ── Wayland cursor theme (XCURSOR_THEME env var) ────────────────────────────────
export XCURSOR_THEME="$CURSOR_THEME"
export XCURSOR_SIZE=24

# Update user-level default cursor theme (~/.local/share/icons/default/index.theme)
# This takes precedence over system defaults and doesn't require sudo
mkdir -p "$HOME/.local/share/icons/default"
cat > "$HOME/.local/share/icons/default/index.theme" << CURSOREOF
[Icon Theme]
Inherits=$CURSOR_THEME
CURSOREOF

# ── Kvantum ────────────────────────────────────────────────────────────────────
KVANTUM_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/Kvantum/kvantum.kvconfig"
sed -i "s/^theme=.*/theme=$KVANTUM_THEME/" "$KVANTUM_CFG"

# ── kdeglobals (Qt icon theme) ─────────────────────────────────────────────────
KDEGLOBALS="${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals"
sed -i "s/^Theme=.*/Theme=$ICON_THEME/" "$KDEGLOBALS" 2>/dev/null || true

# ── qt5ct / qt6ct icon theme ───────────────────────────────────────────────────
for cfg in "${XDG_CONFIG_HOME:-$HOME/.config}/qt5ct/qt5ct.conf" \
           "${XDG_CONFIG_HOME:-$HOME/.config}/qt6ct/qt6ct.conf"; do
    [[ -f "$cfg" ]] && sed -i "s/^icon_theme=.*/icon_theme=$ICON_THEME/" "$cfg"
done

# ── Flatpak — restart running libadwaita apps ──────────────────────────────────
# ADW_DEBUG_COLOR_SCHEME permanently overrides the portal for the process lifetime,
# preventing live dark/light switching. We rely on the portal instead (no env var).
# The @define-color palette in gtk.css only takes effect at launch, so running
# libadwaita Flatpak apps must be restarted to pick up the new theme.
flatpak list --app --columns=application 2>/dev/null | while read -r app; do
    # Check if any process for this app is running
    if pgrep -f "$app" > /dev/null 2>&1; then
        pkill -f "$app" 2>/dev/null || true
        sleep 0.5
        flatpak run "$app" &>/dev/null &
        disown
    fi
done


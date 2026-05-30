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
    SDDM_THEME="catppuccin-latte-mauve"
else
    ACTIVE_BORDER="rgba(cba6f7ff)"
    INACTIVE_BORDER="rgba(45475aff)"
    SHADOW_COLOR="rgba(11111bcc)"
    GTK_THEME="catppuccin-mocha-mauve-standard+default"
    KVANTUM_THEME="catppuccin-mocha-mauve"
    ICON_THEME="Papirus-Dark"
    CURSOR_THEME="catppuccin-mocha-mauve-cursors"
    PREFER_DARK="1"
    SDDM_THEME="catppuccin-mocha-mauve"
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

# ── GTK3 / GTK4 settings ───────────────────────────────────────────────────────
# If the user saved a per-mode snapshot via nwg-look-sync.sh, restore it wholesale
# so all their nwg-look choices (font, cursor, widget variant, etc.) are preserved.
# Fall back to sed-based updates when no snapshot exists yet.
SNAP_DIR="$HOME/.local/share/catppuccin"
GTK3_SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
GTK4_SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/settings.ini"

if [[ -f "$SNAP_DIR/gtk-3.0-${MODE}.ini" ]]; then
    cp "$SNAP_DIR/gtk-3.0-${MODE}.ini" "$GTK3_SETTINGS"
else
    sed -i "s/^gtk-theme-name[[:space:]]*=[[:space:]]*.*/gtk-theme-name=$GTK_THEME/" "$GTK3_SETTINGS"
    sed -i "s/^gtk-icon-theme-name[[:space:]]*=[[:space:]]*.*/gtk-icon-theme-name=$ICON_THEME/" "$GTK3_SETTINGS"
    sed -i "s/^gtk-cursor-theme-name[[:space:]]*=[[:space:]]*.*/gtk-cursor-theme-name=$CURSOR_THEME/" "$GTK3_SETTINGS"
    sed -i "s/^gtk-application-prefer-dark-theme[[:space:]]*=[[:space:]]*.*/gtk-application-prefer-dark-theme=$PREFER_DARK/" "$GTK3_SETTINGS"
fi

if [[ -f "$SNAP_DIR/gtk-4.0-${MODE}.ini" ]]; then
    cp "$SNAP_DIR/gtk-4.0-${MODE}.ini" "$GTK4_SETTINGS"
else
    sed -i "s/^gtk-theme-name[[:space:]]*=[[:space:]]*.*/gtk-theme-name=$GTK_THEME/" "$GTK4_SETTINGS"
    sed -i "s/^gtk-icon-theme-name[[:space:]]*=[[:space:]]*.*/gtk-icon-theme-name=$ICON_THEME/" "$GTK4_SETTINGS"
    sed -i "s/^gtk-cursor-theme-name[[:space:]]*=[[:space:]]*.*/gtk-cursor-theme-name=$CURSOR_THEME/" "$GTK4_SETTINGS"
    sed -i "s/^gtk-application-prefer-dark-theme[[:space:]]*=[[:space:]]*.*/gtk-application-prefer-dark-theme=$PREFER_DARK/" "$GTK4_SETTINGS"
fi

# ── GTK4 / libadwaita CSS ──────────────────────────────────────────────────────
GTK4_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
THEME_DIR="/usr/share/themes/${GTK_THEME}/gtk-4.0"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
LOCAL_THEME_DIR="$HOME/.local/share/themes/${GTK_THEME}/gtk-4.0"

# Update local user theme (~/.local/share/themes/) — this is what Flatpak sandboxes
# read via xdg-data/themes:ro permission. When gsettings gtk-theme changes, GTK4
# reloads the theme live in all running apps via the Settings portal.
mkdir -p "$LOCAL_THEME_DIR"
cp "$THEME_DIR/gtk.css"      "$LOCAL_THEME_DIR/gtk.css"
cp "$THEME_DIR/gtk-dark.css" "$LOCAL_THEME_DIR/gtk-dark.css" 2>/dev/null || cp "$THEME_DIR/gtk.css" "$LOCAL_THEME_DIR/gtk-dark.css"

# Update ~/.config/gtk-4.0/gtk.css for native (non-Flatpak) GTK4 apps.
cp "$THEME_DIR/gtk.css" "$GTK4_DIR/gtk.css"

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

# ── xsettingsd (broadcasts theme to XWayland/X11 GTK apps live) ───────────────
XSETTINGSD_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/xsettingsd/xsettingsd.conf"
if [[ -f "$XSETTINGSD_CONF" ]]; then
    sed -i "s|^Net/ThemeName .*|Net/ThemeName \"$GTK_THEME\"|"      "$XSETTINGSD_CONF"
    sed -i "s|^Net/IconThemeName .*|Net/IconThemeName \"$ICON_THEME\"|" "$XSETTINGSD_CONF"
    sed -i "s|^Gtk/CursorThemeName .*|Gtk/CursorThemeName \"$CURSOR_THEME\"|" "$XSETTINGSD_CONF"
    pkill -HUP xsettingsd 2>/dev/null || true
fi

# ── Wayland cursor theme (XCURSOR_THEME env var) ────────────────────────────────
export XCURSOR_THEME="$CURSOR_THEME"
export XCURSOR_SIZE=24

# Update default cursor theme in both lookup locations.
# ~/.icons/default takes precedence over ~/.local/share/icons/default for XWayland
# apps; nwg-look writes the former so we must keep both in sync.
for cursor_dir in "$HOME/.icons/default" "$HOME/.local/share/icons/default"; do
    mkdir -p "$cursor_dir"
    cat > "$cursor_dir/index.theme" << CURSOREOF
[Icon Theme]
Inherits=$CURSOR_THEME
CURSOREOF
done

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

# ── Flatpak — update GTK_THEME override ───────────────────────────────────────
if command -v flatpak &>/dev/null; then
    sudo flatpak override --system --env=GTK_THEME="$GTK_THEME" 2>/dev/null || true
fi

# ── Flatpak — restart running libadwaita apps ──────────────────────────────────
# ADW_DEBUG_COLOR_SCHEME permanently overrides the portal for the process lifetime,
# preventing live dark/light switching. We rely on the portal instead (no env var).
# The @define-color palette in gtk.css only takes effect at launch, so running
# libadwaita Flatpak apps must be restarted to pick up the new theme.
flatpak list --app --system --columns=application 2>/dev/null | while read -r app; do
    if pgrep -f "$app" > /dev/null 2>&1; then
        pkill -f "$app" 2>/dev/null || true
        sleep 0.5
        flatpak run "$app" &>/dev/null &
        disown
    fi
done

# ── Cursor theme — apply live to compositor and new processes ─────────────────
systemctl --user set-environment \
    XCURSOR_THEME="$CURSOR_THEME" \
    XCURSOR_SIZE=24 \
    HYPRCURSOR_THEME="$CURSOR_THEME" \
    HYPRCURSOR_SIZE=24 2>/dev/null || true
hyprctl setcursor "$CURSOR_THEME" 24 2>/dev/null || true

# ── SDDM theme ────────────────────────────────────────────────────────────────
if command -v sddm-set-theme &>/dev/null; then
    sudo sddm-set-theme "$SDDM_THEME" 2>/dev/null || true
fi


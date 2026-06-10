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

# ── Starship prompt ─────────────────────────────────────────────────────────────
# Flip the active Catppuccin palette. starship re-reads its config on every prompt,
# so this takes effect live in all open shells on the next prompt.
STARSHIP_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
if [[ -f "$STARSHIP_CFG" ]]; then
    sed -i "s/^palette = .*/palette = 'catppuccin_${MODE}'/" "$STARSHIP_CFG"
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

# ── Mirror themes for Flatpak sandboxes ────────────────────────────────────────
# Sandboxes can't read /usr/share/themes; they only see ~/.local/share/themes via
# the xdg-data/themes:ro grant. Mirror BOTH flavors IN FULL — gtk-3.0, gtk-4.0 and
# their assets/ — not just gtk-4.0/gtk.css: GTK3 Flatpaks (e.g. Firefox) need
# gtk-3.0/ to render the theme at all, and the css references assets/ relatively.
# Mirroring the inactive flavor too means the next toggle's theme is already in
# place when an app launches right after switching. Skip when /usr lacks a flavor
# (e.g. install.sh's prebuilt fallback already populated the local copy in full).
for _flavor in latte mocha; do
    _name="catppuccin-${_flavor}-mauve-standard+default"
    _src="/usr/share/themes/$_name"
    _dst="$HOME/.local/share/themes/$_name"
    if [[ -f "$_src/gtk-4.0/gtk.css" ]]; then
        rm -rf "$_dst"
        mkdir -p "$_dst"
        cp -r --no-preserve=ownership "$_src/gtk-3.0" "$_src/gtk-4.0" "$_dst/" 2>/dev/null || true
        cp --no-preserve=ownership "$_src/index.theme" "$_dst/" 2>/dev/null || true
    fi
done

# ── GTK4 / libadwaita CSS ──────────────────────────────────────────────────────
GTK4_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
THEME_DIR="/usr/share/themes/${GTK_THEME}/gtk-4.0"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
LOCAL_THEME_DIR="$HOME/.local/share/themes/${GTK_THEME}/gtk-4.0"

# ~/.config/gtk-4.0/gtk.css is the USER css read by native GTK4 apps AND bind-mounted
# into every Flatpak sandbox (xdg-config/gtk-4.0:ro). libadwaita recolors its OWN
# widgets ONLY through :root custom properties — it IGNORES @define-color — so we
# @import the flavor's full theme, then append that flavor's :root block (kept as a
# version-controlled file so the colours are easy to edit: gtk/adw-root-<mode>.css).
# DO NOT replace this with a plain `cp` of the theme css: that drops the :root block
# and greys out every libadwaita headerbar.
{
    echo "/* generated by sync-theme.sh ($MODE) — do not edit by hand */"
    echo "@import url(\"file://$LOCAL_THEME_DIR/gtk.css\");"
    ADW_ROOT="$DOTFILES_DIR/gtk/adw-root-${MODE}.css"
    if [[ -f "$ADW_ROOT" ]]; then
        echo ""
        cat "$ADW_ROOT"
    fi
    # Flavor-independent chrome overrides (uses the :root vars above) so the
    # libadwaita headerbar tracks Catppuccin instead of falling back to default.
    ADW_CHROME="$DOTFILES_DIR/gtk/adw-chrome.css"
    if [[ -f "$ADW_CHROME" ]]; then
        echo ""
        cat "$ADW_CHROME"
    fi
} > "$GTK4_DIR/gtk.css"

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

# Mirror the active cursor theme into ~/.local/share/icons so Flatpak sandboxes
# (which can't read /usr) can resolve it through the `default` indirection below.
if [[ ! -d "$HOME/.local/share/icons/$CURSOR_THEME" && -d "/usr/share/icons/$CURSOR_THEME" ]]; then
    cp -a --no-preserve=ownership "/usr/share/icons/$CURSOR_THEME" "$HOME/.local/share/icons/" 2>/dev/null || true
fi

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
# Kvantum (the Qt style behind qt5ct/qt6ct's style=kvantum) reads its active theme from
# here. Update the theme= line in place if present, otherwise create the file — a plain
# `sed -i` silently no-ops on a missing/empty config, which left Qt apps unthemed.
KVANTUM_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/Kvantum/kvantum.kvconfig"
mkdir -p "$(dirname "$KVANTUM_CFG")"
if [[ -f "$KVANTUM_CFG" ]] && grep -q '^theme=' "$KVANTUM_CFG"; then
    sed -i "s/^theme=.*/theme=$KVANTUM_THEME/" "$KVANTUM_CFG"
else
    printf '[General]\ntheme=%s\n' "$KVANTUM_THEME" > "$KVANTUM_CFG"
fi

# ── kdeglobals (Qt icon theme) ─────────────────────────────────────────────────
KDEGLOBALS="${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals"
sed -i "s/^Theme=.*/Theme=$ICON_THEME/" "$KDEGLOBALS" 2>/dev/null || true

# ── qt5ct / qt6ct icon theme ───────────────────────────────────────────────────
for cfg in "${XDG_CONFIG_HOME:-$HOME/.config}/qt5ct/qt5ct.conf" \
           "${XDG_CONFIG_HOME:-$HOME/.config}/qt6ct/qt6ct.conf"; do
    [[ -f "$cfg" ]] && sed -i "s/^icon_theme=.*/icon_theme=$ICON_THEME/" "$cfg"
done

# ── Flatpak — make sandboxes use THIS flavor (user override; no sudo) ─────────
if command -v flatpak &>/dev/null; then
    # libadwaita apps follow the portal color-scheme (set via gsettings above) + the
    # :root in the bind-mounted gtk.css; GTK_THEME/ICON_THEME cover non-libadwaita GTK
    # apps and icons. The USER override WINS over any --system override, so set the env
    # here (also avoids a sudo prompt on every toggle) and re-assert the read-only
    # grants that let sandboxes SEE the theme/icons/cursors (silently wiped before,
    # e.g. via Flatseal, which greys out every app despite GTK_THEME being set).
    flatpak override --user \
        --env=GTK_THEME="$GTK_THEME" \
        --env=ICON_THEME="$ICON_THEME" \
        --filesystem=xdg-config/gtk-3.0:ro \
        --filesystem=xdg-config/gtk-4.0:ro \
        --filesystem=xdg-data/themes:ro \
        --filesystem=xdg-data/icons:ro \
        --filesystem=~/.icons:ro 2>/dev/null || true
fi

# ── Flatpak — restart running windowed apps so they match the new flavor ──────
# GTK cannot live-reload theme css inside a sandbox: GTK_THEME and the imported
# gtk.css are read once at launch, so a running app keeps the OLD flavor forever.
# The only way running apps switch "live" is a relaunch, so kill + relaunch each
# running app that has a mapped Hyprland window (class == flatpak app id). Apps
# WITHOUT a window are left alone — they're background daemons (e.g. Bazaar) and
# `flatpak run` would pop a window up on every toggle. Exclusions, where a forced
# restart is harmful or useless:
#   - Discord: self-themed (ignores GTK), and a restart drops active calls
#   - Bottles: may be supervising running Windows apps/games
#   - Firefox: chrome follows the portal color-scheme live already; a restart
#     would reshuffle the whole session for marginal widget gains
FLATPAK_RESTART_EXCLUDE="com.discordapp.Discord com.usebottles.bottles org.mozilla.firefox"
if command -v flatpak &>/dev/null; then
    window_classes=$(hyprctl clients -j 2>/dev/null | jq -r '.[].class' 2>/dev/null | sort -u || true)
    restarted=""
    manual=""
    while IFS= read -r app; do
        [[ -z "$app" ]] && continue
        if [[ " $FLATPAK_RESTART_EXCLUDE " == *" $app "* ]]; then
            manual+="• $app (excluded)"$'\n'
            continue
        fi
        if ! grep -qxF "$app" <<< "$window_classes"; then
            manual+="• $app (no window — daemon?)"$'\n'
            continue
        fi
        flatpak kill "$app" 2>/dev/null || true
        # Detach the relaunch so it survives this script (and its caller) exiting.
        (sleep 0.5; exec nohup flatpak run "$app" >/dev/null 2>&1) &
        disown
        restarted+="• $app"$'\n'
    done <<< "$(flatpak ps --columns=application 2>/dev/null | sort -u)"
    body=""
    [[ -n "$restarted" ]] && body+="Restarted to apply $MODE:"$'\n'"$restarted"
    [[ -n "$manual" ]] && body+="Still on the old flavor (restart manually if needed):"$'\n'"$manual"
    if [[ -n "$body" ]]; then
        notify-send -a "Theme" "Theme switched to $MODE" "$body" 2>/dev/null || true
    fi
fi

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


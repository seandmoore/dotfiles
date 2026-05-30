#!/usr/bin/env bash
# Launch nwg-look, then save a per-mode snapshot and propagate changes everywhere.
nwg-look "$@"

THEME=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")

if [[ "$THEME" == *latte* ]]; then
    MODE=latte
else
    MODE=mocha
fi

# Save full settings as a mode snapshot so sync-theme.sh can restore them on switch.
SNAP_DIR="$HOME/.local/share/catppuccin"
mkdir -p "$SNAP_DIR"
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini" ]] && \
    cp "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini" "$SNAP_DIR/gtk-3.0-${MODE}.ini"
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/settings.ini" ]] && \
    cp "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/settings.ini" "$SNAP_DIR/gtk-4.0-${MODE}.ini"

exec "$(dirname "$(realpath "$0")")/sync-theme.sh" "$MODE"

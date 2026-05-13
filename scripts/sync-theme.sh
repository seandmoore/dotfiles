#!/usr/bin/env bash
# sync-theme.sh — propagate Catppuccin theme switch to external apps
# Usage: sync-theme.sh [mocha|latte]

MODE="${1:-mocha}"

if [[ "$MODE" == "latte" ]]; then
    ACTIVE_BORDER="rgba(8839efff)"
    INACTIVE_BORDER="rgba(bcc0ccff)"
    SHADOW_COLOR="rgba(dce0e8aa)"
else
    ACTIVE_BORDER="rgba(cba6f7ff)"
    INACTIVE_BORDER="rgba(45475aff)"
    SHADOW_COLOR="rgba(11111bcc)"
fi

# ── Hyprland — update colors live ─────────────────────────────────────────────
hyprctl keyword general:col.active_border   "$ACTIVE_BORDER"   2>/dev/null
hyprctl keyword general:col.inactive_border "$INACTIVE_BORDER" 2>/dev/null
hyprctl keyword decoration:col.shadow       "$SHADOW_COLOR"    2>/dev/null

# ── Kitty — write active color file and reload all instances ──────────────────
KITTY_COLORS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
ACTIVE_COLORS="$KITTY_COLORS_DIR/active-colors.conf"

if [[ -f "$KITTY_COLORS_DIR/colors-$MODE.conf" ]]; then
    cp "$KITTY_COLORS_DIR/colors-$MODE.conf" "$ACTIVE_COLORS"
    # SIGUSR1 causes kitty to reload its config
    pkill -SIGUSR1 -x kitty 2>/dev/null || true
fi

# ── Persist selection ─────────────────────────────────────────────────────────
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
echo "$MODE" > "${XDG_CACHE_HOME:-$HOME/.cache}/catppuccin-mode"

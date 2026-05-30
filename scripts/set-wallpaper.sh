#!/usr/bin/env bash
# set-wallpaper.sh <image> — set the wallpaper live via hyprpaper AND persist it so
# the next Hyprland boot restores it.
#
# The old quickshell switcher &&-chained the live set with the persistence write and
# wrote into the dotfiles repo (dirtying git). This script always persists — to a real
# local ~/.config/hypr/hyprpaper.conf — and uses the one IPC verb this hyprpaper build
# accepts: `wallpaper` (it auto-preloads; `preload`/`unload` return "invalid request"
# on v0.8.4).
set -euo pipefail

wp="${1:?usage: set-wallpaper.sh <image>}"
wp="$(readlink -f -- "$wp")"
[[ -f "$wp" ]] || { printf 'set-wallpaper: not a file: %s\n' "$wp" >&2; exit 1; }

# ── Apply live (best-effort; hyprpaper may not be up yet if called early at boot) ──
command -v hyprctl >/dev/null 2>&1 && hyprctl hyprpaper wallpaper ",$wp" >/dev/null 2>&1 || true

# ── Persist: hyprpaper reads ~/.config/hypr/hyprpaper.conf on startup ──────────
conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprpaper.conf"
mkdir -p "$(dirname "$conf")"
# If it's still a symlink into the dotfiles repo, replace it with a real local file so
# wallpaper changes are runtime state and don't dirty git.
[[ -L "$conf" ]] && rm -f "$conf"
printf 'preload = %s\nwallpaper = ,%s\nsplash = false\n' "$wp" "$wp" > "$conf"

# Plain-text breadcrumb of the current choice (handy for other scripts).
state="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
mkdir -p "$state"
printf '%s\n' "$wp" > "$state/wallpaper"

#!/usr/bin/env bash
# hdr-toggle.sh [hdr|sdr|toggle] — switch DP-1 between HDR10 and SDR (sRGB) at runtime.
#
# The Lua config parser (Hyprland 0.55+) rejects `hyprctl keyword`, so we drive the
# same hl.monitor() API the config uses, via `hyprctl eval`. The two calls below mirror
# the DP-1 block in hypr/hyprland.lua and differ only in colour management: HDR10 uses
# BT.2020+PQ at 10-bit with the brighter SDR-in-HDR tone; SDR is plain 8-bit sRGB (the
# SDR tone multipliers don't apply outside an HDR container). Keep these in sync with
# hyprland.lua if DP-1's mode/position/scale change.
#
# Default action is `toggle`, resolved from the live colorManagementPreset.
set -euo pipefail

out="DP-1"
hdr_lua="hl.monitor({ output=\"$out\", mode=\"2560x1440@240\", position=\"0x0\", scale=1, bitdepth=10, cm=\"hdr\", sdrbrightness=1.2, sdrsaturation=1.1 })"
sdr_lua="hl.monitor({ output=\"$out\", mode=\"2560x1440@240\", position=\"0x0\", scale=1, bitdepth=8, cm=\"srgb\" })"

action="${1:-toggle}"
if [[ "$action" == "toggle" ]]; then
    cur="$(hyprctl monitors all -j | jq -r --arg o "$out" \
        '.[] | select(.name==$o) | .colorManagementPreset // "srgb"')"
    [[ "$cur" == "hdr" ]] && action="sdr" || action="hdr"
fi

case "$action" in
    hdr) hyprctl eval "$hdr_lua" ;;
    sdr) hyprctl eval "$sdr_lua" ;;
    *)   printf 'usage: hdr-toggle.sh [hdr|sdr|toggle]\n' >&2; exit 1 ;;
esac

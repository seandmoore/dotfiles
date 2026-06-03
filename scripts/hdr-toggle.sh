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
# Keep in sync with the DP-1 block in hypr/hyprland.lua.
# All five SDR-in-HDR params must be present here; omitting any reverts it to Hyprland's
# built-in default (e.g. sdrMaxLuminance drops to 80, max_luminance loses the 1000-nit cap).
hdr_lua="hl.monitor({ output=\"$out\", mode=\"2560x1440@240\", position=\"0x0\", scale=1, bitdepth=10, cm=\"hdr\", sdrbrightness=1.0, sdrsaturation=1.3, sdr_min_luminance=0, sdr_max_luminance=600, max_luminance=1000 })"
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

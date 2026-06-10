#!/usr/bin/env bash
# display-color.sh — single source of truth for DP-1's colour mode.
#
# Two independent axes, each persisted under ~/.cache/hypr so the bar, the keybinds
# and HDR on/off all agree:
#   color-hdr      : hdr | sdr        (default hdr)
#   color-vibrant  : vibrant | standard (default vibrant)
#
# The 2x2 matrix:
#   HDR + vibrant  -> cm=hdr,  sdrsaturation 1.35  (≈ KDE "SDR Color Intensity" @ 100%)
#   HDR + standard -> cm=hdr,  sdrsaturation 1.0   (true sRGB inside HDR)
#   SDR + vibrant  -> cm=wide                      (native wide gamut, punchy SDR)
#   SDR + standard -> cm=srgb                      (accurate sRGB)
#
# The Lua config parser (Hyprland 0.55+) rejects `hyprctl keyword`, so we drive the
# same hl.monitor() API the config uses via `hyprctl eval`. Keep the HDR-vibrant rule
# below in sync with the DP-1 block in hypr/hyprland.lua (the login default).
#
# Usage:
#   display-color.sh apply                      re-apply the current persisted mode
#   display-color.sh set <hdr|sdr> <vibrant|standard>
#   display-color.sh hdr | sdr                  set the HDR axis only, then apply
#   display-color.sh vibrant | standard         set the vibrant axis only, then apply
#   display-color.sh toggle-hdr | toggle-vibrant
set -euo pipefail

out="DP-1"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
hdr_state="$cache/color-hdr"
vib_state="$cache/color-vibrant"
mkdir -p "$cache"

read_state() { cat "$1" 2>/dev/null || true; }

hdr="$(read_state "$hdr_state")";  hdr="${hdr:-hdr}"
vib="$(read_state "$vib_state")";  vib="${vib:-vibrant}"

apply() {
    local rule
    if [[ "$hdr" == "hdr" ]]; then
        # 1.35 ≈ KDE Plasma's "SDR Color Intensity" maxed (100%): KDE at max stretches sRGB
        # fully to BT.2020 (panel-clipped to native ~P3); 1.35 is the least-error fit of
        # Hyprland's PQ-space saturation to that target on this QD-OLED.
        local sat=1.0; [[ "$vib" == "vibrant" ]] && sat=1.35
        rule="hl.monitor({ output=\"$out\", mode=\"2560x1440@240\", position=\"0x0\", scale=1, bitdepth=10, cm=\"hdr\", sdrbrightness=1.0, sdrsaturation=${sat}, sdr_min_luminance=0, sdr_max_luminance=600, max_luminance=1000 })"
    else
        if [[ "$vib" == "vibrant" ]]; then
            # Wide-gamut SDR: native primaries, 10-bit to avoid banding across the bigger gamut.
            rule="hl.monitor({ output=\"$out\", mode=\"2560x1440@240\", position=\"0x0\", scale=1, bitdepth=10, cm=\"wide\" })"
        else
            rule="hl.monitor({ output=\"$out\", mode=\"2560x1440@240\", position=\"0x0\", scale=1, bitdepth=8, cm=\"srgb\" })"
        fi
    fi
    hyprctl eval "$rule" >/dev/null
}

case "${1:-apply}" in
    apply) : ;;
    hdr|sdr)            hdr="$1" ;;
    vibrant|standard)   vib="$1" ;;
    toggle-hdr)         [[ "$hdr" == "hdr" ]] && hdr="sdr" || hdr="hdr" ;;
    toggle-vibrant)     [[ "$vib" == "vibrant" ]] && vib="standard" || vib="vibrant" ;;
    set)
        case "${2:-}" in hdr|sdr) hdr="$2" ;; *) echo "set: arg2 must be hdr|sdr" >&2; exit 1 ;; esac
        case "${3:-}" in vibrant|standard) vib="$3" ;; *) echo "set: arg3 must be vibrant|standard" >&2; exit 1 ;; esac
        ;;
    *) printf 'usage: display-color.sh [apply|set <hdr|sdr> <vibrant|standard>|hdr|sdr|vibrant|standard|toggle-hdr|toggle-vibrant]\n' >&2; exit 1 ;;
esac

printf '%s\n' "$hdr" > "$hdr_state"
printf '%s\n' "$vib" > "$vib_state"
apply
printf 'DP-1 -> %s / %s\n' "$hdr" "$vib"

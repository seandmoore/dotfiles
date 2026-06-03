#!/usr/bin/env bash
# color-accuracy-toggle.sh [vibrant|standard|toggle] — flip DP-1 between vibrant and
# standard (accurate) colour. Thin wrapper around display-color.sh; the vibrant axis
# means saturation 1.3 vs 1.0 in HDR, and cm=wide vs cm=srgb in SDR. Default: toggle.
#
# HDR/wide-gamut content stays vivid AND accurate either way (it's authored in P3/2020);
# this only changes how sRGB/desktop content is rendered.
set -euo pipefail
dir="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
case "${1:-toggle}" in
    vibrant)  exec "$dir/display-color.sh" vibrant ;;
    standard) exec "$dir/display-color.sh" standard ;;
    toggle)   exec "$dir/display-color.sh" toggle-vibrant ;;
    *) printf 'usage: color-accuracy-toggle.sh [vibrant|standard|toggle]\n' >&2; exit 1 ;;
esac

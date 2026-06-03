#!/usr/bin/env bash
# hdr-toggle.sh [hdr|sdr|toggle] — switch DP-1 between HDR10 and SDR at runtime.
# Thin wrapper around display-color.sh (the single source of truth for DP-1's colour
# mode); the vibrant/standard axis is preserved across the switch. Default: toggle.
set -euo pipefail
dir="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
case "${1:-toggle}" in
    hdr)    exec "$dir/display-color.sh" hdr ;;
    sdr)    exec "$dir/display-color.sh" sdr ;;
    toggle) exec "$dir/display-color.sh" toggle-hdr ;;
    *) printf 'usage: hdr-toggle.sh [hdr|sdr|toggle]\n' >&2; exit 1 ;;
esac

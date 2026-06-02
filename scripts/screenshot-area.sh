#!/usr/bin/env bash
# screenshot-area.sh — select a region, save it to ~/Pictures/Screenshots AND copy to clipboard.
# HDR-safe: grim writes blank/corrupted PNGs directly on HDR (PQ) outputs, so we
# capture the selected region to PPM first (raw pixels preserved) and convert to PNG
# with ffmpeg — the same workaround screenshot-all.sh uses for full-monitor grabs.
set -euo pipefail

dir="${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
mkdir -p "$dir"
stamp=$(date +%Y%m%d_%H%M%S)
png="$dir/screenshot_${stamp}.png"

# Select a region; exit quietly if the selection is cancelled (Esc / right-click).
geom=$(slurp) || exit 0

ppm=$(mktemp /tmp/screenshot-XXXXXX.ppm)
trap 'rm -f "$ppm"' EXIT
grim -g "$geom" -t ppm "$ppm"
ffmpeg -y -hide_banner -loglevel error -i "$ppm" "$png"

# Copy the PNG to the clipboard, then notify.
wl-copy --type image/png < "$png"
notify-send "Screenshot saved" "$png"

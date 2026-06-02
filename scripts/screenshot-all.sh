#!/usr/bin/env bash
set -euo pipefail

dir="${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
mkdir -p "$dir"
stamp=$(date +%Y%m%d_%H%M%S)

# Capture each monitor individually
outs=$(hyprctl monitors -j | jq -r '.[].name')
files=()
for out in $outs; do
	png="$dir/${out}_${stamp}.png"
	# grim produces blank/corrupted PNGs on HDR (PQ) outputs, so we
	# capture to PPM first (raw pixels preserved) and convert to PNG.
	# This gives correct colors on SDR outputs and at least has the
	# correct content on HDR (just with PQ-encoded pixels interpreted
	# as sRGB — a future grim/libpng fix should eliminate this step).
	ppm=$(mktemp /tmp/screenshot-XXXXXX.ppm)
	grim -o "$out" -t ppm "$ppm"
	ffmpeg -y -hide_banner -loglevel error -i "$ppm" "$png"
	rm -f "$ppm"
	files+=("$png")
done

# Send notification
if [ ${#files[@]} -eq 1 ]; then
	notify-send "Screenshot saved" "${files[0]}"
else
	notify-send "Screenshots saved" "${#files[@]} files in $dir"
fi

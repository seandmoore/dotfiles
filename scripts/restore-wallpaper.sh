#!/usr/bin/env bash
# restore-wallpaper.sh — re-apply the last-used wallpaper once Hyprland's outputs are
# live. hyprpaper is launched by its own systemd user service, which routinely wins the
# race against output creation: the `wallpaper=` line in hyprpaper.conf then applies to
# zero monitors and silently no-ops, leaving the desktop blank at login. (Confirmed:
# `hyprctl hyprpaper listactive` is empty after boot until a wallpaper is pushed over
# IPC.) So we resolve the persisted choice and push it ourselves, retrying until at
# least one output reports it active. Idempotent; safe to run any time.
#
# Wallpaper changes are persisted by set-wallpaper.sh (live set + ~/.config/hypr/
# hyprpaper.conf + the state breadcrumb below); this script is the boot-time restore.
set -uo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/wallpaper"
conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprpaper.conf"

# Resolve the wallpaper path: state breadcrumb first, then the hyprpaper.conf line.
wp=""
[[ -r "$state" ]] && IFS= read -r wp < "$state"
if [[ -z "$wp" && -r "$conf" ]]; then
    # line: `wallpaper = ,/path/to/img`  →  strip up to and including the comma
    wp="$(sed -n 's/^wallpaper *= *,*//p' "$conf" | head -n1)"
fi
[[ -n "$wp" && -f "$wp" ]] || { echo "restore-wallpaper: no usable wallpaper [$wp]" >&2; exit 0; }

base="${wp##*/}"

# Retry until hyprpaper applies it to an output (~12s budget absorbs a slow service
# start + output hotplug). `wallpaper` auto-preloads on this hyprpaper build (v0.8.4).
for _ in $(seq 1 60); do
    hyprctl hyprpaper wallpaper ",$wp" >/dev/null 2>&1
    if hyprctl hyprpaper listactive 2>/dev/null | grep -qF "$base"; then
        exit 0
    fi
    sleep 0.2
done

echo "restore-wallpaper: gave up applying $wp after retries" >&2
exit 0

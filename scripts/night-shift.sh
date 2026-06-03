#!/usr/bin/env bash
# night-shift.sh — blue-light / colour-temperature control for the session, via
# hyprsunset (Hyprland's native gamma tool). Warmer = lower Kelvin.
#
# State persisted under ~/.cache/hypr:
#   nightshift-on    : 1 | 0   (default 0 = off)
#   nightshift-temp  : Kelvin  (default 4000; remembered while off so the slider/
#                                toggle restore the last warmth)
#
# Usage:
#   night-shift.sh on            enable at the remembered temperature
#   night-shift.sh off           disable (neutral 6500K)
#   night-shift.sh toggle        flip on/off
#   night-shift.sh temp <K>      set temperature (clamped 2500-6500) and enable
#   night-shift.sh status        print "<on> <temp>"  e.g. "1 4000" / "0 4000"
set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
on_state="$cache/nightshift-on"
temp_state="$cache/nightshift-temp"
mkdir -p "$cache"
NEUTRAL=6500
DEFAULT=4000
MIN=2500
MAX=6500

on="$(cat "$on_state" 2>/dev/null || true)";   on="${on:-0}"
temp="$(cat "$temp_state" 2>/dev/null || true)"; temp="${temp:-$DEFAULT}"

sock() { printf '%s/hypr/%s/.hyprsunset.sock' "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" "${HYPRLAND_INSTANCE_SIGNATURE:-}"; }

ensure_daemon() {
    [[ -S "$(sock)" ]] && return 0
    command -v hyprsunset >/dev/null 2>&1 || { echo "hyprsunset not installed (sudo pacman -S hyprsunset)" >&2; return 1; }
    setsid hyprsunset -t 6500 >/dev/null 2>&1 &   # start neutral (6500K); controlled over IPC below
    for _ in $(seq 1 30); do [[ -S "$(sock)" ]] && return 0; sleep 0.1; done
    return 0   # proceed even if the socket check raced; the IPC call has its own fallback
}

# Apply a temperature via IPC; if that fails (older hyprsunset), relaunch at that temp.
apply_temp() {
    local k="$1"
    ensure_daemon || return 1
    if ! hyprctl hyprsunset temperature "$k" >/dev/null 2>&1; then
        pkill -x hyprsunset 2>/dev/null || true
        setsid hyprsunset -t "$k" >/dev/null 2>&1 &
    fi
}

apply_off() {
    if [[ -S "$(sock)" ]]; then
        hyprctl hyprsunset identity >/dev/null 2>&1 || hyprctl hyprsunset temperature "$NEUTRAL" >/dev/null 2>&1 || true
    fi
}

clamp() { local v="$1"; (( v < MIN )) && v=$MIN; (( v > MAX )) && v=$MAX; printf '%s' "$v"; }

case "${1:-status}" in
    on)     on=1 ;;
    off)    on=0 ;;
    toggle) [[ "$on" == "1" ]] && on=0 || on=1 ;;
    temp)
        [[ "${2:-}" =~ ^[0-9]+$ ]] || { echo "temp: need a Kelvin integer" >&2; exit 1; }
        temp="$(clamp "$2")"; on=1 ;;
    status) printf '%s %s\n' "$on" "$temp"; exit 0 ;;
    *) printf 'usage: night-shift.sh [on|off|toggle|temp <K>|status]\n' >&2; exit 1 ;;
esac

printf '%s\n' "$on"   > "$on_state"
printf '%s\n' "$temp" > "$temp_state"

if [[ "$on" == "1" ]]; then apply_temp "$temp"; else apply_off; fi
printf 'night shift: %s @ %sK\n' "$([[ "$on" == 1 ]] && echo on || echo off)" "$temp"

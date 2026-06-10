#!/usr/bin/env bash
# night-shift.sh — blue-light / colour-temperature control for the session, via
# hyprsunset (Hyprland's native gamma tool). Warmer = lower Kelvin.
#
# Manual on/off/temp, plus an automatic sunset→sunrise mode. Auto needs no
# external service: the sun's altitude is computed locally with python from a
# cached lat/lon (auto-detected once over IP, or set by hand).
#
# State persisted under ~/.cache/hypr:
#   nightshift-on    : 1 | 0     currently shifted?            (default 0)
#   nightshift-temp  : Kelvin    remembered warmth            (default 4000)
#   nightshift-auto  : 1 | 0     auto sunset→sunrise on?       (default 0)
#   nightshift-loc   : "lat lon" cached location for the calc
#   nightshift-auto.pid          running auto-daemon pid
#
# Usage:
#   night-shift.sh on|off|toggle          manual control (drops out of auto)
#   night-shift.sh temp <K>               set warmth, clamped 2500-6500 (drops out of auto)
#   night-shift.sh auto on|off|toggle     automatic sunset→sunrise scheduling
#   night-shift.sh auto-resume            start the auto daemon iff it was left on (for login)
#   night-shift.sh location <lat> <lon>   set the location used for the sun calc
#   night-shift.sh status                 print "<on> <temp>"  e.g. "1 4000" / "0 4000"
set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
on_state="$cache/nightshift-on"
temp_state="$cache/nightshift-temp"
auto_state="$cache/nightshift-auto"
loc_state="$cache/nightshift-loc"
pidfile="$cache/nightshift-auto.pid"
mkdir -p "$cache"
NEUTRAL=6500
DEFAULT=4000
MIN=2500
MAX=6500
HORIZON=-0.833      # official sunrise/sunset sun altitude (refraction + solar radius)
POLL=120            # seconds between auto re-evaluations

read_on()   { local v; v="$(cat "$on_state"   2>/dev/null || true)"; printf '%s' "${v:-0}"; }
read_temp() { local v; v="$(cat "$temp_state" 2>/dev/null || true)"; printf '%s' "${v:-$DEFAULT}"; }
read_auto() { local v; v="$(cat "$auto_state" 2>/dev/null || true)"; printf '%s' "${v:-0}"; }

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

# Write the on/off state and drive hyprsunset to match. Does NOT touch auto —
# both the manual commands and the auto daemon funnel through here.
set_on() {
    local val="$1" temp; temp="$(read_temp)"
    printf '%s\n' "$val" > "$on_state"
    if [[ "$val" == "1" ]]; then apply_temp "$temp"; else apply_off; fi
}

# Turn auto off and stop its daemon, quietly. Called when the user takes manual
# control (toggle/slider), so a manual choice isn't reverted on the next tick.
auto_off_silent() {
    if [[ "$(read_auto)" == "1" ]]; then printf '0\n' > "$auto_state"; auto_stop; fi
}

auto_stop() {
    local pid; pid="$(cat "$pidfile" 2>/dev/null || true)"
    [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
    rm -f "$pidfile"
}

auto_start() {
    # already running? leave it be.
    if [[ -f "$pidfile" ]] && kill -0 "$(cat "$pidfile" 2>/dev/null || echo -1)" 2>/dev/null; then return 0; fi
    setsid bash "$0" auto-run >/dev/null 2>&1 &
}

# Echo "lat lon". Explicit cache wins; otherwise geolocate once over IP and cache it.
resolve_location() {
    if [[ -s "$loc_state" ]]; then cat "$loc_state"; return 0; fi
    local loc
    loc="$(curl -fsS --max-time 5 https://ipinfo.io/loc 2>/dev/null | tr ',' ' ')" || true
    if [[ "$loc" =~ ^-?[0-9.]+[[:space:]]+-?[0-9.]+$ ]]; then
        printf '%s\n' "$loc" > "$loc_state"; printf '%s\n' "$loc"; return 0
    fi
    return 1
}

# Current solar altitude in degrees for a lat/lon (low-precision NOAA formula).
sun_altitude() {
    python3 - "$1" "$2" <<'PY'
import sys, math, time
lat = float(sys.argv[1]); lon = float(sys.argv[2])
n = time.time()/86400.0 + 2440587.5 - 2451545.0      # days from J2000.0 (UTC)
L   = (280.460 + 0.9856474*n) % 360                  # mean longitude (deg)
g   = math.radians((357.528 + 0.9856003*n) % 360)    # mean anomaly
lam = math.radians((L + 1.915*math.sin(g) + 0.020*math.sin(2*g)) % 360)  # ecliptic longitude
eps = math.radians(23.439 - 0.0000004*n)             # obliquity
decl = math.asin(math.sin(eps)*math.sin(lam))
ra   = math.atan2(math.cos(eps)*math.sin(lam), math.cos(lam))
gmst = (280.46061837 + 360.98564736629*n) % 360      # Greenwich mean sidereal time (deg)
H    = math.radians((gmst + lon) % 360) - ra         # local hour angle
phi  = math.radians(lat)
alt  = math.asin(math.sin(phi)*math.sin(decl) + math.cos(phi)*math.cos(decl)*math.cos(H))
print(round(math.degrees(alt), 3))
PY
}

# The auto daemon: re-evaluate the sun every POLL seconds and shift on below the
# horizon, off above it. Recomputing each tick keeps it correct across midnight,
# DST, and suspend/resume without any scheduling math.
auto_loop() {
    echo $$ > "$pidfile"
    trap 'rm -f "$pidfile"' EXIT
    local loc lat lon alt desired
    while [[ "$(read_auto)" == "1" ]]; do
        if loc="$(resolve_location)"; then
            read -r lat lon <<< "$loc"
            if alt="$(sun_altitude "$lat" "$lon" 2>/dev/null)" && [[ -n "$alt" ]]; then
                if awk "BEGIN{exit !($alt < $HORIZON)}"; then desired=1; else desired=0; fi
                [[ "$(read_on)" != "$desired" ]] && set_on "$desired"
            fi
        fi
        sleep "$POLL"
    done
}

case "${1:-status}" in
    on)     auto_off_silent; set_on 1 ;;
    off)    auto_off_silent; set_on 0 ;;
    toggle) auto_off_silent; [[ "$(read_on)" == "1" ]] && set_on 0 || set_on 1 ;;
    temp)
        [[ "${2:-}" =~ ^[0-9]+$ ]] || { echo "temp: need a Kelvin integer" >&2; exit 1; }
        auto_off_silent
        printf '%s\n' "$(clamp "$2")" > "$temp_state"; set_on 1 ;;
    auto)
        case "${2:-toggle}" in
            on)     a=1 ;;
            off)    a=0 ;;
            toggle) [[ "$(read_auto)" == "1" ]] && a=0 || a=1 ;;
            *) echo "auto: on|off|toggle" >&2; exit 1 ;;
        esac
        printf '%s\n' "$a" > "$auto_state"
        if [[ "$a" == "1" ]]; then
            resolve_location >/dev/null 2>&1 \
                || echo "night-shift: couldn't determine location; set it with: night-shift.sh location <lat> <lon>" >&2
            auto_start
            echo "night shift: auto on (sunset→sunrise)"
        else
            auto_stop
            set_on 0          # auto off returns to neutral — no lingering shift
            echo "night shift: auto off"
        fi
        exit 0 ;;
    auto-run)    auto_loop; exit 0 ;;
    auto-resume) [[ "$(read_auto)" == "1" ]] && auto_start; exit 0 ;;
    location)
        [[ "${2:-}" =~ ^-?[0-9.]+$ && "${3:-}" =~ ^-?[0-9.]+$ ]] || { echo "location: need <lat> <lon>" >&2; exit 1; }
        printf '%s %s\n' "$2" "$3" > "$loc_state"
        echo "night shift: location set to $2 $3"; exit 0 ;;
    status) printf '%s %s\n' "$(read_on)" "$(read_temp)"; exit 0 ;;
    *) printf 'usage: night-shift.sh [on|off|toggle|temp <K>|auto on|off|toggle|location <lat> <lon>|status]\n' >&2; exit 1 ;;
esac

printf 'night shift: %s @ %sK\n' "$([[ "$(read_on)" == 1 ]] && echo on || echo off)" "$(read_temp)"

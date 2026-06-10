pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared transparency helper for every Quickshell surface, plus DP-1's live colour
// state (HDR/SDR, vibrant/standard, night shift) for the bar's Display menu/indicator.
// The desktop uses a flat clear-transparent look (no blur), so glass() returns the
// alpha unchanged. Polls DP-1 + the ~/.cache/hypr state files every 2s so the bar
// stays in sync even when colour is changed via keybinds outside the bar.
QtObject {
    id: frost

    // colorManagementPreset: "hdr" => HDR; "wide" => vibrant SDR; else accurate SDR.
    property bool hdrOn: true
    // vibrant axis (saturation 1.35 ≈ KDE "SDR Color Intensity" @ 100% vs 1.0 in HDR;
    // cm=wide vs srgb in SDR).
    property bool vibrant: true
    // Night shift (hyprsunset).
    property bool nightOn: false
    property int  nightTemp: 4000
    // Auto sunset→sunrise scheduling on? (night-shift.sh auto)
    property bool nightAuto: false

    function glass(a) { return 1.0 }

    function refresh() { pollProc.running = true }

    property Timer poll: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
    }

    // One shot reads DP-1's preset plus the vibrant/night state files, emitting a
    // single "preset|vibrant|on|temp|auto" line for the parser below.
    property Process pollProc: Process {
        id: pollProc
        command: ["bash", "-c",
            "c=\"${XDG_CACHE_HOME:-$HOME/.cache}/hypr\"; " +
            "p=$(hyprctl monitors all -j | jq -r '.[]|select(.name==\"DP-1\")|.colorManagementPreset // \"srgb\"'); " +
            "v=$(cat \"$c/color-vibrant\" 2>/dev/null || echo vibrant); " +
            "n=$(cat \"$c/nightshift-on\" 2>/dev/null || echo 0); " +
            "t=$(cat \"$c/nightshift-temp\" 2>/dev/null || echo 4000); " +
            "a=$(cat \"$c/nightshift-auto\" 2>/dev/null || echo 0); " +
            "echo \"$p|$v|$n|$t|$a\""]
        stdout: SplitParser {
            onRead: line => {
                const p = line.trim().split("|")
                if (p.length < 5) return
                frost.hdrOn = (p[0] === "hdr")
                frost.vibrant = (p[1] === "vibrant")
                frost.nightOn = (p[2] === "1")
                const t = parseInt(p[3]); if (!isNaN(t)) frost.nightTemp = t
                frost.nightAuto = (p[4] === "1")
            }
        }
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared transparency helper for every Quickshell surface, plus DP-1's HDR state for
// the bar's HDR indicator. The desktop uses a flat clear-transparent look (no blur),
// so glass() returns the alpha unchanged — the result is identical in HDR and SDR
// (Hyprland can't blur a colour-managed HDR output anyway, so there's nothing to
// compensate for). Still polls DP-1 every 2s so the bar's HDR toggle icon stays live.
QtObject {
    id: frost

    property bool hdrOn: true

    // Base alpha for a surface. Surfaces pass their own alpha, but this single knob
    // overrides them all — currently forced to 1.0 so every Quickshell panel is fully
    // opaque (matched to Nautilus/GTK apps) for maximum legibility of text and icons.
    // To restore the clear-transparent glass look, return `a` instead of 1.0. Usage:
    //   color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Frost.glass(0.48))
    function glass(a) { return 1.0 }

    function refresh() { pollProc.running = true }

    property Timer poll: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
    }

    property Process pollProc: Process {
        id: pollProc
        command: ["bash", "-c",
            "hyprctl monitors all -j | jq -r '.[]|select(.name==\"DP-1\")|.colorManagementPreset // \"srgb\"'"]
        stdout: SplitParser {
            onRead: line => {
                const v = line.trim()
                if (v === "hdr") frost.hdrOn = true
                else if (v !== "") frost.hdrOn = false
            }
        }
    }
}

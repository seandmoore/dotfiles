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

    // Base alpha for a translucent surface. Flat (mode-independent) so the look is
    // consistent across HDR/SDR. One knob per surface. Usage:
    //   color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Frost.glass(0.48))
    function glass(a) { return a }

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

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Current desktop wallpaper path, so glass panels can render a blurred copy of it.
// hyprpaper paints the real wallpaper; GlassSurface just samples the SAME image file
// and blurs it behind each panel (this is what makes "frosted glass" work on the HDR
// output, where the compositor can't blur). set-wallpaper.sh writes the chosen path to
// $XDG_STATE_HOME/hypr/wallpaper; we read that breadcrumb and re-poll so the glass
// follows wallpaper changes. Falls back to parsing hyprpaper.conf if the breadcrumb is
// missing (e.g. a wallpaper set outside the switcher).
QtObject {
    id: wall

    // Absolute path of the current wallpaper ("" until first read).
    property string path: ""
    // file:// URL form for Image.source (empty string while unknown).
    readonly property string source: path === "" ? "" : "file://" + path

    function refresh() { readProc.running = true }

    // Lightweight `cat` poll (mirrors Surface.qml's polling idiom). The wallpaper
    // changes rarely, so a few-second interval keeps the glass in sync with set-
    // wallpaper.sh without any IPC wiring.
    property Timer poll: Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: readProc.running = true
    }

    property Process readProc: Process {
        id: readProc
        command: ["bash", "-c",
            "s=\"${XDG_STATE_HOME:-$HOME/.local/state}/hypr/wallpaper\"; " +
            "if [ -r \"$s\" ]; then cat \"$s\"; else " +
            "grep -m1 '^wallpaper' \"${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprpaper.conf\" 2>/dev/null | sed 's/^[^,]*,//'; fi"]
        stdout: SplitParser {
            onRead: line => {
                const p = line.trim()
                if (p !== "" && p !== wall.path) wall.path = p
            }
        }
    }
}

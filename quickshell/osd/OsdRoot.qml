import QtQuick
import Quickshell
import Quickshell.Io

// Listens to pactl and brightnessctl changes and shows OSD overlays.
Item {
    id: root

    required property VolumeOsd volumeOsd
    required property BrightnessOsd brightnessOsd

    // Last-known audio state, so we only flash the OSD on a real change.
    // pactl emits "change on sink" for many reasons (state RUNNING/IDLE/
    // SUSPENDED when audio starts/stops, default-sink switches, etc.) — those
    // must NOT pop the OSD, only actual volume/mute changes should.
    property int  lastVolume: -1
    property bool lastMuted: false
    property bool baselineReady: false

    // Watch pactl for volume changes — only react to the default *device* sink
    // (note: "on sink #" excludes "on sink-input #", which is per-app streams).
    Process {
        id: pactlWatcher
        command: ["pactl", "subscribe"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                if (line.includes("'change'") && line.includes("on sink #"))
                    volumeQuery.running = true
            }
        }
    }

    // Capture the current volume at startup without flashing the OSD.
    Component.onCompleted: volumeQuery.running = true

    // One-shot pactl query for current volume
    Process {
        id: volumeQuery
        command: ["bash", "-c",
            "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -1;" +
            "pactl get-sink-mute   @DEFAULT_SINK@ | grep -oP '(?<=Mute: )\\S+'"]
        running: false

        property var lines: []

        stdout: SplitParser {
            onRead: line => {
                volumeQuery.lines.push(line.trim())
                if (volumeQuery.lines.length >= 2) {
                    const vol   = parseInt(volumeQuery.lines[0]) || 0
                    const muted = volumeQuery.lines[1] === "yes"
                    volumeQuery.lines = []

                    const changed = vol !== root.lastVolume || muted !== root.lastMuted
                    root.lastVolume = vol
                    root.lastMuted  = muted

                    // Suppress the very first reading (startup baseline) and any
                    // event that didn't actually move the volume or mute state.
                    if (root.baselineReady && changed)
                        volumeOsd.show(vol, muted)
                    root.baselineReady = true
                }
            }
        }
    }

    // Watch brightnessctl for brightness changes
    Process {
        id: brightnessWatcher
        command: ["bash", "-c", "inotifywait -m -e modify /sys/class/backlight/*/brightness 2>/dev/null"]
        running: true

        stdout: SplitParser {
            onRead: _ => brightnessQuery.running = true
        }
    }

    Process {
        id: brightnessQuery
        command: ["bash", "-c",
            "val=$(brightnessctl g); max=$(brightnessctl m); echo $((val * 100 / max))"]
        running: false

        stdout: SplitParser {
            onRead: line => {
                const pct = parseInt(line.trim())
                if (!isNaN(pct)) brightnessOsd.show(pct)
            }
        }
    }
}

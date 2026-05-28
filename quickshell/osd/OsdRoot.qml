import QtQuick
import Quickshell
import Quickshell.Io

// Listens to pactl and brightnessctl changes and shows OSD overlays.
Item {
    id: root

    required property VolumeOsd volumeOsd
    required property BrightnessOsd brightnessOsd

    // Watch pactl for volume changes
    Process {
        id: pactlWatcher
        command: ["pactl", "subscribe"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                if (line.includes("sink") && line.includes("change")) {
                    volumeQuery.running = true
                }
            }
        }
    }

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
                    const vol  = parseInt(volumeQuery.lines[0]) || 0
                    const muted = volumeQuery.lines[1] === "yes"
                    volumeOsd.show(vol, muted)
                    volumeQuery.lines = []
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

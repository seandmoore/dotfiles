import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "./bar"
import "./notifications"
import "./osd"
import "./launcher"
import "./theme"

// Entry point — Quickshell loads this file automatically.
ShellRoot {
    // One bar per screen
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    // Notification daemon (singleton — one per compositor session)
    NotificationServer {}

    // OSD windows (must live at ShellRoot level as PanelWindows)
    VolumeOsd    { id: volumeOsd }
    BrightnessOsd { id: brightnessOsd }

    // OSD listeners (singleton) — receives window refs to call show()
    OsdRoot {
        volumeOsd:    volumeOsd
        brightnessOsd: brightnessOsd
    }

    // App launcher (fullscreen overlay, hidden by default)
    Launcher {}

    // ── Theme sync ─────────────────────────────────────────────────────────────

    // Restore last saved theme on startup
    Process {
        command: ["bash", "-c",
            "cat \"${XDG_CACHE_HOME:-$HOME/.cache}/catppuccin-mode\" 2>/dev/null || echo mocha"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.trim() === "latte") Colors.darkMode = false
            }
        }
    }

    // Propagate theme changes to Hyprland + Kitty
    Connections {
        target: Colors
        function onDarkModeChanged() {
            themeSync.command = ["bash", "-c",
                "~/.config/quickshell/scripts/sync-theme.sh " +
                (Colors.darkMode ? "mocha" : "latte")]
            themeSync.running = true
        }
    }

    Process {
        id: themeSync
        running: false
    }
}

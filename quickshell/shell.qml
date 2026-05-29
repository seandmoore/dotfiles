import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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

    // IPC: switch theme externally
    //   quickshell ipc -i <id> call theme setMocha
    //   quickshell ipc -i <id> call theme setLatte
    IpcHandler {
        target: "theme"
        function setMocha() { Colors.darkMode = true;  ipcSyncMocha.running = true }
        function setLatte() { Colors.darkMode = false; ipcSyncLatte.running = true }
    }

    // IPC-triggered syncs run sync-theme.sh directly
    Process {
        id: ipcSyncMocha
        command: ["bash", "-c", "/home/seanmoore/dotfiles/scripts/sync-theme.sh mocha"]
    }
    Process {
        id: ipcSyncLatte
        command: ["bash", "-c", "/home/seanmoore/dotfiles/scripts/sync-theme.sh latte"]
    }
}

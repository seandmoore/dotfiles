import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "./bar"
import "./notifications"
import "./osd"
import "./launcher"
import "./wallpaper"
import "./cheatsheet"
import "./theme"
import "./services"

// Entry point — Quickshell loads this file automatically.
ShellRoot {
    id: shell

    // The bar lives on the primary monitor only (DP-1). If it isn't connected,
    // fall back to the first available screen so there's always a bar somewhere.
    property string primaryMonitor: "DP-1"

    Variants {
        model: {
            const pri = Quickshell.screens.filter(s => s.name === shell.primaryMonitor)
            return pri.length ? pri : Quickshell.screens.slice(0, 1)
        }

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

    // Wallpaper switcher (fullscreen overlay, hidden by default)
    WallpaperSwitcher {}

    // Keybind cheat sheet (fullscreen overlay, hidden by default)
    KeybindCheatsheet {}


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
        function setMocha() { Colors.darkMode = true;  themeTransition.show(); ipcSyncMocha.running = true }
        function setLatte() { Colors.darkMode = false; themeTransition.show(); ipcSyncLatte.running = true }
    }

    // IPC: rescan installed apps without restarting the shell. AppList scans
    // desktop files once at startup and caches for the session; this forces a
    // fresh scan so newly installed/removed apps show up in the launcher and bar.
    //   quickshell -c config ipc call apps rescan
    IpcHandler {
        target: "apps"
        function rescan() { AppList.reload() }
    }

    // Brief "applying theme" hint that covers the Flatpak app relaunch
    ThemeTransition { id: themeTransition }

    // IPC-triggered syncs run sync-theme.sh directly
    Process {
        id: ipcSyncMocha
        command: ["bash", "-c", "\"$HOME/dotfiles/scripts/sync-theme.sh\" mocha"]
    }
    Process {
        id: ipcSyncLatte
        command: ["bash", "-c", "\"$HOME/dotfiles/scripts/sync-theme.sh\" latte"]
    }
}

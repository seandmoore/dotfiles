pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tracks available system updates (official repos, AUR, Flatpak) and runs the
// upgrade in a terminal. Counts are gathered WITHOUT sudo so they can refresh on
// a timer; the actual upgrade opens an interactive terminal (for the sudo prompt
// and review). Uses yay or paru — whichever is installed.
QtObject {
    id: svc

    property int repo: 0
    property int aur: 0
    property int flatpak: 0
    readonly property int total: repo + aur + flatpak
    property bool checking: false
    property bool updating: false
    property string helper: ""          // "yay" | "paru" | "" (none)
    property double lastChecked: 0

    function check() {
        if (checking) return
        checking = true
        checkProc.running = true
    }

    function update() {
        if (updating) return
        const upgrade = helper !== "" ? (helper + " -Syu") : "sudo pacman -Syu"
        let s = "echo ':: System update — official repos + AUR'; " + upgrade + "; echo; "
        s += "if command -v flatpak >/dev/null 2>&1; then echo ':: Flatpak'; flatpak update; fi; "
        s += "echo; echo 'Done — press Enter to close.'; read"
        updating = true
        updateProc.command = ["kitty", "-e", "bash", "-lc", s]
        updateProc.running = true
    }

    // ── Count check (no sudo) ────────────────────────────────────────────────
    property Process checkProc: Process {
        command: ["bash", "-c",
            "h=''; for x in yay paru; do command -v \"$x\" >/dev/null 2>&1 && { h=$x; break; }; done; " +
            "aur=0; repo=0; flat=0; " +
            "[ -n \"$h\" ] && aur=$(\"$h\" -Qua 2>/dev/null | wc -l); " +
            "if command -v checkupdates >/dev/null 2>&1; then " +
            "  repo=$(checkupdates 2>/dev/null | wc -l); " +
            "elif [ -n \"$h\" ]; then " +
            "  tot=$(\"$h\" -Qu 2>/dev/null | wc -l); repo=$((tot - aur)); [ \"$repo\" -lt 0 ] && repo=0; " +
            "else repo=$(pacman -Qu 2>/dev/null | wc -l); fi; " +
            "command -v flatpak >/dev/null 2>&1 && flat=$(flatpak remote-ls --updates 2>/dev/null | wc -l); " +
            "echo \"${repo}|${aur}|${flat}|${h}\""
        ]
        stdout: SplitParser {
            onRead: line => {
                const p = line.split("|")
                if (p.length >= 4) {
                    svc.repo = parseInt(p[0]) || 0
                    svc.aur = parseInt(p[1]) || 0
                    svc.flatpak = parseInt(p[2]) || 0
                    svc.helper = p[3] || ""
                }
            }
        }
        onRunningChanged: {
            if (!running) { svc.checking = false; svc.lastChecked = Date.now() }
        }
    }

    // ── Interactive upgrade (terminal); re-check once it closes ──────────────
    property Process updateProc: Process {
        onRunningChanged: { if (!running) { svc.updating = false; svc.check() } }
    }

    // Refresh on startup and every 30 minutes.
    property Timer poll: Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: svc.check()
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../theme"
import "../services"

// Quick Settings control center — the single bar dropdown for theme, display,
// Do-Not-Disturb, volume, brightness, wallpaper, and power. Built on the Qs* widget
// kit (QsTile/QsToggle/QsSlider/QsRipple) for a modern, progressive-disclosure layout:
// a compact grid of instant toggles up top, then expandable tiles (Display, Wallpaper,
// Power) that reveal detail only on demand — so the default surface stays uncluttered.
// Self-contained (own IPC / Process / Pipewire); reads live state from the Colors /
// Surface / Notifications singletons so every control reflects reality and re-tints.
ColumnLayout {
    id: qs
    Layout.fillWidth: true
    spacing: 12

    // Bar root — set from Bar.qml so actions can dismiss the dropdown afterwards.
    property var ctrl: null
    function close() { if (ctrl) ctrl.openMenu = "" }

    // Accordion: at most one expandable tile (Display / Wallpaper / Power) open at a
    // time, so the panel stays compact. Reset whenever the dropdown reopens.
    property string openTile: ""
    onVisibleChanged: if (!visible) openTile = ""
    function toggleTile(n) { openTile = (openTile === n ? "" : n) }

    // ── audio (Pipewire) ───────────────────────────────────────────────────────
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var  audioSink: Pipewire.defaultAudioSink
    readonly property var  audioNode: audioSink ? audioSink.audio : null
    readonly property real volume:    audioNode ? audioNode.volume : 0
    readonly property bool muted:     audioNode ? audioNode.muted  : false
    readonly property string volumeIcon: muted ? "󰖁" : volume <= 0 ? "󰕿" : volume < 0.5 ? "󰖀" : "󰕾"
    function setVolume(v) { if (audioNode) audioNode.volume = Math.max(0, Math.min(1, v)) }
    function toggleMute() { if (audioNode) audioNode.muted = !audioNode.muted }

    // ── command runners ────────────────────────────────────────────────────────
    Process { id: themeProc }
    Process { id: wallProc }
    Process { id: powerProc }
    Process { id: nightProc; onRunningChanged: if (!running) Surface.refresh() }
    Process { id: hdrProc;   onRunningChanged: if (!running) Surface.refresh() }
    Process { id: brightSetProc; onRunningChanged: if (!running) brightPoll.running = true }

    function setTheme(dark) {
        themeProc.command = ["quickshell", "-c", "config", "ipc", "call", "theme", dark ? "setMocha" : "setLatte"]
        themeProc.running = true
    }
    // Quick on/off toggles for the grid; the finer controls (temperature, vibrant,
    // auto schedule) live in the Display tile's DisplayMenu.
    function toggleNight() {
        nightProc.command = ["bash", "-c", "\"$HOME/dotfiles/scripts/night-shift.sh\" toggle"]
        nightProc.running = true
    }
    function toggleHdr() {
        hdrProc.command = ["bash", "-c", "\"$HOME/dotfiles/scripts/hdr-toggle.sh\" " + (Surface.hdrOn ? "sdr" : "hdr")]
        hdrProc.running = true
    }
    function browseWallpaper() {
        wallProc.command = ["quickshell", "-c", "config", "ipc", "call", "wallpaper", "toggle"]
        wallProc.running = true
        close()
    }
    function randomWallpaper() {
        wallProc.command = ["bash", "-c",
            "f=$(find \"$HOME/Pictures\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' " +
            "-o -iname '*.png' -o -iname '*.webp' \\) | shuf -n1); " +
            "[ -n \"$f\" ] && exec \"$HOME/dotfiles/scripts/set-wallpaper.sh\" \"$f\""]
        wallProc.running = true
        close()
    }
    function runPower(cmd) { close(); powerProc.command = cmd; powerProc.running = true }
    function setBrightness(pct) {
        brightSetProc.command = ["bash", "-c", "brightnessctl set " + Math.round(pct) + "% >/dev/null 2>&1"]
        brightSetProc.running = true
    }

    // ── brightness (laptop backlight — row hides when there's no backlight) ──────
    property int brightness: -1
    readonly property bool hasBacklight: brightness >= 0
    Process {
        id: brightPoll
        command: ["bash", "-c", "brightnessctl -m -c backlight 2>/dev/null | head -1 | cut -d, -f4 | tr -d '%'"]
        running: false
        stdout: SplitParser {
            onRead: line => { const p = parseInt(line.trim()); if (!isNaN(p)) qs.brightness = p }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: brightPoll.running = true }

    // ── reusable action row (wallpaper / power expansions) ──────────────────────
    component ActionRow: Rectangle {
        id: ar
        property string icon: ""
        property string label: ""
        property color accent: Colors.text
        signal activated()

        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: 10
        clip: true
        color: arMa.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.16) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 10
            Text {
                text: ar.icon; color: ar.accent
                font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 16
            }
            Text {
                text: ar.label; color: Colors.text; Layout.fillWidth: true
                font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 13
            }
        }

        QsRipple { id: arRip; color: ar.accent }

        MouseArea {
            id: arMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: (m) => arRip.ripple(m.x, m.y)
            onClicked: ar.activated()
        }
    }

    // ── HEADER ──────────────────────────────────────────────────────────────────
    Text {
        text: "Quick Settings"
        color: Colors.subtext0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 13; font.weight: Font.Bold
    }

    // ── QUICK TOGGLES (instant on/off) ──────────────────────────────────────────
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        QsTile {
            toggle: true
            icon: Colors.darkMode ? "󰖔" : "󰖨"
            label: Colors.darkMode ? "Dark" : "Light"
            on: Colors.darkMode
            accent: Colors.lavender
            onToggled: qs.setTheme(!Colors.darkMode)
        }
        QsTile {
            toggle: true
            icon: Notifications.dnd ? "󰂛" : "󰂚"
            label: "DND"
            on: Notifications.dnd
            accent: Colors.red
            onToggled: Notifications.toggleDnd()
        }
        QsTile {
            toggle: true
            icon: "󰖔"
            label: "Night"
            on: Surface.nightOn
            accent: Colors.peach
            onToggled: qs.toggleNight()
        }
        QsTile {
            toggle: true
            icon: "󰍹"
            label: Surface.hdrOn ? "HDR" : "SDR"
            on: Surface.hdrOn
            accent: Colors.peach
            onToggled: qs.toggleHdr()
        }
    }

    // ── DISPLAY (expandable: vibrant, auto night, temperature) ──────────────────
    QsTile {
        expandable: true
        expanded: qs.openTile === "display"
        onToggled: qs.toggleTile("display")
        icon: "󰍹"
        label: "Display"
        accent: Colors.peach

        // DisplayMenu is a ColumnLayout; wrap in an Item so the nested layout gets
        // clean width negotiation inside the tile's body ColumnLayout.
        Item {
            Layout.fillWidth: true
            implicitHeight: disp.implicitHeight
            DisplayMenu {
                id: disp
                anchors { left: parent.left; right: parent.right; top: parent.top }
            }
        }
    }

    // ── VOLUME + BRIGHTNESS ─────────────────────────────────────────────────────
    QsSlider {
        icon: qs.volumeIcon
        tint: qs.muted ? Colors.red : Colors.blue
        value: qs.volume
        valueText: Math.round(qs.volume * 100) + "%"
        onMoved: (f) => qs.setVolume(f)
        onIconTapped: qs.toggleMute()
    }
    Text {
        Layout.fillWidth: true
        text: qs.audioSink
            ? (qs.audioSink.description || qs.audioSink.nickname || qs.audioSink.name || "Output")
            : "No output device"
        color: Colors.overlay1
        font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 11
        elide: Text.ElideRight
    }
    QsSlider {
        visible: qs.hasBacklight
        icon: qs.brightness >= 70 ? "󰃠" : qs.brightness >= 30 ? "󰃟" : "󰃞"
        tint: Colors.yellow
        value: qs.brightness / 100
        valueText: qs.brightness + "%"
        onMoved: (f) => qs.setBrightness(f * 100)
    }

    // ── WALLPAPER (expandable) ──────────────────────────────────────────────────
    QsTile {
        expandable: true
        expanded: qs.openTile === "wallpaper"
        onToggled: qs.toggleTile("wallpaper")
        icon: "󰋩"
        label: "Wallpaper"
        accent: Colors.sky

        ActionRow { icon: "󰋩"; label: "Browse all"; accent: Colors.sky; onActivated: qs.browseWallpaper() }
        ActionRow { icon: "󰒝"; label: "Random";     accent: Colors.sky; onActivated: qs.randomWallpaper() }
    }

    // ── POWER (expandable) ──────────────────────────────────────────────────────
    QsTile {
        expandable: true
        expanded: qs.openTile === "power"
        onToggled: qs.toggleTile("power")
        icon: "⏻"
        label: "Power"
        accent: Colors.red

        ActionRow { icon: "󰌾"; label: "Lock";     accent: Colors.teal;   onActivated: qs.runPower(["loginctl", "lock-session"]) }
        ActionRow { icon: "󰒲"; label: "Sleep";    accent: Colors.blue;   onActivated: qs.runPower(["systemctl", "suspend"]) }
        ActionRow { icon: "󰍃"; label: "Logout";   accent: Colors.yellow; onActivated: qs.runPower(["uwsm", "stop"]) }
        ActionRow { icon: "󰜉"; label: "Restart";  accent: Colors.green;  onActivated: qs.runPower(["systemctl", "reboot"]) }
        ActionRow { icon: "⏻";  label: "Shutdown"; accent: Colors.red;    onActivated: qs.runPower(["systemctl", "poweroff"]) }
    }
}

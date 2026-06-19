import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../theme"
import "../services"

// Consolidated "Quick Settings" control center — theme, display (HDR / vibrant /
// night shift), Do-Not-Disturb, volume, brightness, wallpaper, and power, all in
// one dropdown under the bar. Self-contained (its own IPC / Process / Pipewire)
// like the other standalone menus, and reads live state from the Colors / Surface
// / Notifications singletons so every control reflects reality and re-tints with
// the Mocha/Latte theme. The dedicated Display button still has the finer
// controls (per-mode submenus, temperature slider).
ColumnLayout {
    id: qs
    Layout.fillWidth: true
    spacing: 12

    // Bar root — set from Bar.qml so actions can dismiss the dropdown afterwards.
    property var ctrl: null
    function close() { if (ctrl) ctrl.openMenu = "" }

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
    Process { id: displayProc; onRunningChanged: if (!running) Surface.refresh() }
    Process { id: nightProc;   onRunningChanged: if (!running) Surface.refresh() }
    Process { id: wallProc }
    Process { id: powerProc }
    Process { id: brightSetProc; onRunningChanged: if (!running) brightPoll.running = true }

    function setTheme(dark) {
        themeProc.command = ["quickshell", "-c", "config", "ipc", "call", "theme", dark ? "setMocha" : "setLatte"]
        themeProc.running = true
    }
    function toggleHdr() {
        displayProc.command = ["bash", "-c",
            "\"$HOME/dotfiles/scripts/hdr-toggle.sh\" " + (Surface.hdrOn ? "sdr" : "hdr")]
        displayProc.running = true
    }
    function toggleVibrant() {
        displayProc.command = ["bash", "-c", "\"$HOME/dotfiles/scripts/color-accuracy-toggle.sh\""]
        displayProc.running = true
    }
    function night(arg) {
        nightProc.command = ["bash", "-c", "\"$HOME/dotfiles/scripts/night-shift.sh\" " + arg]
        nightProc.running = true
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

    // ── reusable quick-toggle tile ──────────────────────────────────────────────
    component Tile: Rectangle {
        id: tile
        property string icon: ""
        property string label: ""
        property bool on: false
        property color accent: Colors.mauve
        signal toggled()

        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: 12
        color: on ? Qt.rgba(accent.r, accent.g, accent.b, 0.22)
            : (tMa.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.85)
                                 : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.4))
        border.color: on ? Qt.rgba(accent.r, accent.g, accent.b, 0.6) : "transparent"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 10
            Text {
                text: tile.icon
                color: tile.on ? tile.accent : Colors.subtext1
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 18
                Behavior on color { ColorAnimation { duration: 120 } }
            }
            Text {
                text: tile.label
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 13
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
        MouseArea {
            id: tMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.toggled()
        }
    }

    // ── reusable slider row (icon · track · value) ──────────────────────────────
    component SliderRow: RowLayout {
        id: sr
        property string icon: ""
        property color tint: Colors.blue
        property real value: 0              // 0..1
        signal moved(real frac)
        signal iconTapped()

        Layout.fillWidth: true
        spacing: 10

        Text {
            text: sr.icon
            color: sr.tint
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 18
            MouseArea {
                anchors.fill: parent; anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: sr.iconTapped()
            }
        }
        Item {
            Layout.fillWidth: true
            height: 16
            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 6; radius: 3
                color: Colors.surface1
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, sr.value))
                    height: parent.height; radius: 3
                    color: sr.tint
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
            }
            Rectangle {
                width: 14; height: 14; radius: 7
                color: Colors.text; border.color: Colors.surface2; border.width: 1
                anchors.verticalCenter: parent.verticalCenter
                x: (track.width - width) * Math.max(0, Math.min(1, sr.value))
                Behavior on x { NumberAnimation { duration: 80 } }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: (m) => sr.moved(m.x / width)
                onPositionChanged: (m) => { if (pressed) sr.moved(m.x / width) }
            }
        }
        Text {
            text: Math.round(Math.max(0, Math.min(1, sr.value)) * 100) + "%"
            color: Colors.subtext1
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            Layout.minimumWidth: 38
            horizontalAlignment: Text.AlignRight
        }
    }

    // ── small icon button (wallpaper / power) ───────────────────────────────────
    component IconButton: Rectangle {
        id: ib
        property string icon: ""
        property string label: ""
        property color accent: Colors.text
        signal activated()

        Layout.fillWidth: true
        Layout.preferredHeight: label === "" ? 40 : 44
        radius: 10
        color: ibMa.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.18)
                                  : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.4)
        Behavior on color { ColorAnimation { duration: 100 } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: ib.icon
                color: ib.accent
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 17
            }
            Text {
                visible: ib.label !== ""
                text: ib.label
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 13
            }
        }
        MouseArea {
            id: ibMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ib.activated()
        }
    }

    // ── HEADER ──────────────────────────────────────────────────────────────────
    Text {
        text: "Quick Settings"
        color: Colors.subtext0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 13; font.weight: Font.Bold
    }

    // ── TOGGLE TILES ────────────────────────────────────────────────────────────
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        Tile {
            icon: Colors.darkMode ? "󰖔" : "󰖨"
            label: Colors.darkMode ? "Dark" : "Light"
            on: Colors.darkMode
            accent: Colors.lavender
            onToggled: qs.setTheme(!Colors.darkMode)
        }
        Tile {
            icon: Notifications.dnd ? "󰂛" : "󰂚"
            label: "Do Not Disturb"
            on: Notifications.dnd
            accent: Colors.red
            onToggled: Notifications.toggleDnd()
        }
        Tile {
            icon: "󰍹"
            label: Surface.hdrOn ? "HDR" : "SDR"
            on: Surface.hdrOn
            accent: Colors.peach
            onToggled: qs.toggleHdr()
        }
        Tile {
            icon: "󰏘"
            label: Surface.vibrant ? "Vibrant" : "Accurate"
            on: Surface.vibrant
            accent: Colors.pink
            onToggled: qs.toggleVibrant()
        }
        Tile {
            icon: "󰖔"
            label: "Night Shift"
            on: Surface.nightOn
            accent: Colors.peach
            onToggled: qs.night("toggle")
        }
        Tile {
            icon: "󰃡"
            label: "Auto Night"
            on: Surface.nightAuto
            accent: Colors.peach
            onToggled: qs.night(Surface.nightAuto ? "auto off" : "auto on")
        }
    }

    Rectangle {
        Layout.fillWidth: true; height: 1
        color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
    }

    // ── SLIDERS ─────────────────────────────────────────────────────────────────
    SliderRow {
        icon: qs.volumeIcon
        tint: qs.muted ? Colors.red : Colors.blue
        value: qs.volume
        onMoved: (f) => qs.setVolume(f)
        onIconTapped: qs.toggleMute()
    }
    SliderRow {
        visible: qs.hasBacklight
        icon: qs.brightness >= 70 ? "󰃠" : qs.brightness >= 30 ? "󰃟" : "󰃞"
        tint: Colors.yellow
        value: qs.brightness / 100
        onMoved: (f) => qs.setBrightness(f * 100)
    }

    Rectangle {
        Layout.fillWidth: true; height: 1
        color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
    }

    // ── WALLPAPER ───────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        IconButton { icon: "󰋩"; label: "Wallpaper"; accent: Colors.sky;  onActivated: qs.browseWallpaper() }
        IconButton { icon: "󰒝"; label: "Random";    accent: Colors.sky;  onActivated: qs.randomWallpaper() }
    }

    // ── POWER ───────────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        IconButton { icon: "󰌾"; accent: Colors.teal;   onActivated: qs.runPower(["loginctl", "lock-session"]) }
        IconButton { icon: "󰒲"; accent: Colors.blue;   onActivated: qs.runPower(["systemctl", "suspend"]) }
        IconButton { icon: "󰍃"; accent: Colors.yellow; onActivated: qs.runPower(["uwsm", "stop"]) }
        IconButton { icon: "󰜉"; accent: Colors.green;  onActivated: qs.runPower(["systemctl", "reboot"]) }
        IconButton { icon: "⏻";  accent: Colors.red;    onActivated: qs.runPower(["systemctl", "poweroff"]) }
    }
}

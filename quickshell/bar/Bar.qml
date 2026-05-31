import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../theme"

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: openMenu === "" ? 56 : 300
    exclusiveZone: 56
    margins.top: 0
    color: "transparent"

    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

    // ── HOVER-MENU CONTROLLER ─────────────────────────────────────────────────
    // One menu open at a time; opens after a short hover, closes after a grace
    // period so moving between the icon and its dropdown doesn't dismiss it.
    property string openMenu: ""
    property string hoveredMenu: ""

    function menuEnter(n) { hoveredMenu = n; menuCloseTimer.stop(); menuOpenTimer.restart() }
    function menuExit(n)  { if (hoveredMenu === n) hoveredMenu = ""; menuCloseTimer.restart() }
    function menuHover(n, h) {
        if (h) { hoveredMenu = n; menuCloseTimer.stop(); menuOpenTimer.stop(); openMenu = n }
        else   { if (hoveredMenu === n) hoveredMenu = ""; menuCloseTimer.restart() }
    }

    Timer { id: menuOpenTimer;  interval: 160; onTriggered: if (root.hoveredMenu !== "") root.openMenu = root.hoveredMenu }
    Timer { id: menuCloseTimer; interval: 320; onTriggered: if (root.hoveredMenu === "") root.openMenu = "" }

    // ── AUDIO (Pipewire) ──────────────────────────────────────────────────────
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    readonly property var  audioSink: Pipewire.defaultAudioSink
    readonly property var  audioNode: audioSink ? audioSink.audio : null
    readonly property real volume:    audioNode ? audioNode.volume : 0
    readonly property bool muted:     audioNode ? audioNode.muted  : false

    readonly property string volumeIcon: muted ? "󰖁"
        : volume <= 0   ? "󰕿"
        : volume <  0.5 ? "󰖀"
        : "󰕾"

    function setVolume(v) { if (audioNode) audioNode.volume = Math.max(0, Math.min(1, v)) }
    function adjustVolume(d) { setVolume(volume + d) }
    function toggleMute() { if (audioNode) audioNode.muted = !audioNode.muted }

    // ── THEME / WALLPAPER / POWER actions ─────────────────────────────────────
    function setTheme(dark) { if (dark) themeMochaProc.running = true; else themeLatteProc.running = true }
    function openWallpaperSwitcher() { wallpaperToggleProc.running = true }
    function randomWallpaper() { wallpaperRandomProc.running = true }
    function runPower(cmd) { root.openMenu = ""; powerProc.command = cmd; powerProc.running = true }

    Process { id: themeMochaProc; command: ["quickshell", "-c", "config", "ipc", "call", "theme", "setMocha"] }
    Process { id: themeLatteProc; command: ["quickshell", "-c", "config", "ipc", "call", "theme", "setLatte"] }
    Process { id: wallpaperToggleProc; command: ["quickshell", "-c", "config", "ipc", "call", "wallpaper", "toggle"] }
    Process {
        id: wallpaperRandomProc
        command: ["bash", "-c",
            "f=$(find \"$HOME/Pictures\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' " +
            "-o -iname '*.png' -o -iname '*.webp' \\) | shuf -n1); " +
            "[ -n \"$f\" ] && exec \"$HOME/dotfiles/scripts/set-wallpaper.sh\" \"$f\""]
    }
    Process { id: powerProc }

    readonly property color bubbleBg:     Qt.rgba(Colors.base.r,     Colors.base.g,     Colors.base.b,     0.92)
    readonly property color bubbleBorder: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.8)
    readonly property int   bubbleH:      40
    readonly property int   bubbleR:      20
    readonly property int   bubblePad:    14

    // ── FROSTED GLASS BACKDROP ───────────────────────────────────────────────
    Rectangle {
        anchors { left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12 }
        y: (56 - height) / 2
        height: root.bubbleH
        radius: root.bubbleR
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.75)
        border.color: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.4)
        border.width: 1
    }

    // ── LEFT BUBBLE — app menu + workspaces + visualizer ─────────────────────
    Rectangle {
        id: leftBubble
        anchors { left: parent.left; leftMargin: 12 }
        y: (56 - bubbleH) / 2
        height: root.bubbleH
        width: leftRow.implicitWidth + root.bubblePad * 2
        radius: root.bubbleR
        color: root.bubbleBg
        border.color: root.bubbleBorder
        border.width: 1

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
        Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        Component.onCompleted: { opacity = 0; scale = 0.95; opacity = 1; scale = 1 }

        RowLayout {
            id: leftRow
            anchors.centerIn: parent
            spacing: 8

            AppMenuButton { Layout.alignment: Qt.AlignVCenter }
            Workspaces {
                Layout.alignment: Qt.AlignVCenter
                screenName: root.screen ? root.screen.name : ""
            }

            AudioVisualizer { Layout.alignment: Qt.AlignVCenter }
        }
    }

    // ── CENTER BUBBLE — clock ────────────────────────────────────────────────
    Rectangle {
        id: centerBubble
        anchors.horizontalCenter: parent.horizontalCenter
        y: (56 - bubbleH) / 2
        height: root.bubbleH
        width: clockItem.implicitWidth + root.bubblePad * 2 + 8
        radius: root.bubbleR
        color: root.bubbleBg
        border.color: root.bubbleBorder
        border.width: 1

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
        Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        Component.onCompleted: { opacity = 0; scale = 0.95; opacity = 1; scale = 1 }

        Clock {
            id: clockItem
            anchors.centerIn: parent
        }
    }

    // ── RIGHT BUBBLE — stats + controls (each with a hover menu) ─────────────
    Rectangle {
        id: rightBubble
        anchors { right: parent.right; rightMargin: 12 }
        y: (56 - bubbleH) / 2
        height: root.bubbleH
        width: rightRow.implicitWidth + root.bubblePad * 2
        radius: root.bubbleR
        color: root.bubbleBg
        border.color: root.bubbleBorder
        border.width: 1

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
        Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        Component.onCompleted: { opacity = 0; scale = 0.95; opacity = 1; scale = 1 }

        RowLayout {
            id: rightRow
            anchors.centerIn: parent
            spacing: 12

            MediaPlayer {
                visible: hasMedia
                Layout.alignment: Qt.AlignVCenter
            }

            SystemStats { Layout.alignment: Qt.AlignVCenter }

            Rectangle {
                width: 1; height: 18
                color: Colors.surface1
                Layout.alignment: Qt.AlignVCenter
            }

            // ── VOLUME — click mutes, hover opens slider, scroll adjusts ──────
            HoverMenuButton {
                name: "volume"
                ctrl: root
                menuWidth: 250
                icon: root.volumeIcon
                iconColor: root.muted ? Colors.red : Colors.blue
                iconActiveColor: root.muted ? Colors.red : Colors.sky
                onClicked: root.toggleMute()
                onScrolled: (dy) => root.adjustVolume(dy > 0 ? 0.05 : -0.05)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: root.volumeIcon
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 18
                        color: root.muted ? Colors.red : Colors.blue
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleMute()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 16

                        Rectangle {
                            id: volTrack
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Colors.surface1

                            Rectangle {
                                width: parent.width * root.volume
                                height: parent.height
                                radius: 3
                                color: root.muted ? Colors.overlay1 : Colors.blue
                                Behavior on width { NumberAnimation { duration: 80 } }
                            }
                        }

                        Rectangle {
                            width: 14; height: 14; radius: 7
                            color: Colors.text
                            border.color: Colors.surface2
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            x: (volTrack.width - width) * root.volume
                            Behavior on x { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => root.setVolume(mouse.x / width)
                            onPositionChanged: (mouse) => { if (pressed) root.setVolume(mouse.x / width) }
                        }
                    }

                    Text {
                        text: Math.round(root.volume * 100) + "%"
                        color: Colors.subtext1
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 12
                        Layout.minimumWidth: 38
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.audioSink
                        ? (root.audioSink.description || root.audioSink.nickname || root.audioSink.name || "Output")
                        : "No output device"
                    color: Colors.overlay1
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            // ── THEME — click toggles, hover picks Mocha / Latte ─────────────
            HoverMenuButton {
                name: "theme"
                ctrl: root
                menuWidth: 175
                icon: Colors.darkMode ? "󰖔" : "󰖨"
                iconColor: Colors.darkMode ? Colors.lavender : Colors.yellow
                iconActiveColor: Colors.darkMode ? Colors.lavender : Colors.yellow
                onClicked: root.setTheme(!Colors.darkMode)

                Repeater {
                    model: [
                        { label: "Dark",  sub: "Mocha", icon: "󰖔", dark: true  },
                        { label: "Light", sub: "Latte", icon: "󰖨", dark: false },
                    ]
                    delegate: Rectangle {
                        id: themeItem
                        required property var modelData
                        readonly property bool active: Colors.darkMode === modelData.dark
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 8
                        color: active
                            ? Qt.rgba(Colors.mauve.r, Colors.mauve.g, Colors.mauve.b, 0.22)
                            : (thMa.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.8) : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 10
                            Text {
                                text: themeItem.modelData.icon
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 14
                                color: themeItem.modelData.dark ? Colors.lavender : Colors.yellow
                            }
                            Text {
                                text: themeItem.modelData.label
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 13
                                color: Colors.text
                                Layout.fillWidth: true
                            }
                            Text {
                                text: themeItem.modelData.sub
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 10
                                color: Colors.overlay1
                            }
                            Text {
                                visible: themeItem.active
                                text: "󰄬"
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 12
                                color: Colors.mauve
                            }
                        }

                        MouseArea {
                            id: thMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.setTheme(themeItem.modelData.dark); root.openMenu = "" }
                        }
                    }
                }
            }

            // ── WALLPAPER — click browses, hover offers browse / random ──────
            HoverMenuButton {
                name: "wallpaper"
                ctrl: root
                menuWidth: 190
                icon: "󰋩"
                iconColor: Colors.sky
                iconActiveColor: Colors.sky
                onClicked: root.openWallpaperSwitcher()

                Repeater {
                    model: [
                        { icon: "󰋩", label: "Browse all", act: "browse" },
                        { icon: "󰒝", label: "Random",     act: "random" },
                    ]
                    delegate: Rectangle {
                        id: wpItem
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 8
                        color: wpMa.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.8) : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 10
                            Text {
                                text: wpItem.modelData.icon
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 14
                                color: Colors.sky
                            }
                            Text {
                                text: wpItem.modelData.label
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 13
                                color: Colors.text
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: wpMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.openMenu = ""
                                if (wpItem.modelData.act === "browse") root.openWallpaperSwitcher()
                                else root.randomWallpaper()
                            }
                        }
                    }
                }
            }

            // ── POWER — hover opens the session menu ─────────────────────────
            HoverMenuButton {
                name: "power"
                ctrl: root
                menuWidth: 160
                icon: "⏻"
                iconColor: Colors.mauve
                iconActiveColor: Colors.red

                Repeater {
                    model: [
                        { icon: "󰒲", label: "Sleep",    color: Colors.blue,   cmd: ["systemctl", "suspend"]  },
                        { icon: "󰍃", label: "Logout",   color: Colors.yellow, cmd: ["uwsm", "stop"]          },
                        { icon: "󰜉", label: "Restart",  color: Colors.green,  cmd: ["systemctl", "reboot"]   },
                        { icon: "⏻",  label: "Shutdown", color: Colors.red,    cmd: ["systemctl", "poweroff"] },
                    ]
                    delegate: Rectangle {
                        id: pwItem
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 8
                        color: pwMa.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.9) : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 10
                            Text {
                                text: pwItem.modelData.icon
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 14
                                color: pwItem.modelData.color
                            }
                            Text {
                                text: pwItem.modelData.label
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 13
                                color: Colors.text
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: pwMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.runPower(pwItem.modelData.cmd)
                        }
                    }
                }
            }
        }
    }

    // Dismiss the open menu on a click anywhere below the bar.
    MouseArea {
        anchors { top: parent.top; topMargin: 56; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: root.openMenu !== ""
        onClicked: { root.openMenu = ""; root.hoveredMenu = "" }
        z: -1
    }
}

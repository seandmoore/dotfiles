import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../theme"
import "../services"

PanelWindow {
    id: root
    // Top bar: a single centered pill of widgets (see pillRow below).

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: openMenu === "" ? barH : 640   // tall enough for the largest dropdown (scaled apps list) so it isn't clipped square at the bottom
    exclusiveZone: barH
    margins.top: 0
    color: "transparent"

    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

    // Scan the installed apps once at startup so the launcher / Apps dropdown open
    // instantly with icons already resolved (instead of re-resolving each time).
    Component.onCompleted: { AppList.ensureLoaded(); Places.ensureLoaded() }

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

    // ── HDR / SDR (DP-1 colour management) ────────────────────────────────────
    // hdrOn mirrors DP-1's live colorManagementPreset so the bar icon + menu reflect
    // reality. The query runs at startup and again shortly after each switch.
    // HDR/SDR state lives in the shared Frost singleton (theme/Frost.qml) so the pill,
    // every dropdown and this HDR indicator all read one source. setHdr applies the
    // switch and nudges Frost to re-read immediately (Frost also polls on its own).
    readonly property bool hdrOn: Frost.hdrOn
    function setHdr(on) {
        hdrApplyProc.command = ["bash", "-c",
            "\"$HOME/dotfiles/scripts/hdr-toggle.sh\" " + (on ? "hdr" : "sdr")]
        hdrApplyProc.running = true
        root.openMenu = ""
    }
    Process {
        id: hdrApplyProc
        onRunningChanged: if (!running) Frost.refresh()
    }

    // Clear transparent pill (shared transparency level via Frost.glass).
    readonly property color bubbleBg:     Qt.rgba(Colors.base.r,     Colors.base.g,     Colors.base.b,     Frost.glass(0.45))
    readonly property color bubbleBorder: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.8)
    readonly property int   barH:         84   // collapsed bar strip height
    readonly property int   bubbleH:       66   // centered pill height (9px padding inside barH)
    readonly property int   bubblePad:     16

    // Thin group separator used between widget clusters inside the pill.
    component Sep: Rectangle {
        width: 1
        Layout.preferredHeight: 23
        Layout.alignment: Qt.AlignVCenter
        color: Colors.surface1
        opacity: 0.6
    }

    // ── FROSTED GLASS BAR — the rounded pill IS the frosted surface ───────────
    // The Hyprland layer_rule (namespace "quickshell") blurs wherever this layer has
    // alpha, and ignore_alpha skips the transparent area, so the blur follows the
    // pill's rounded shape and wraps around the bar instead of sitting in a sharp
    // full-width rectangle. The pill's translucent fill (bubbleBg) is what reads as
    // frosted glass.
    // ── CENTERED PILL — every widget in one rounded island ────────────────────
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: (barH - bubbleH) / 2
        height: root.bubbleH
        width: pillRow.implicitWidth + root.bubblePad * 2
        radius: root.bubbleH / 2            // fully rounded pill ends
        color: root.bubbleBg
        border.color: root.bubbleBorder
        border.width: 1

        Behavior on color   { ColorAnimation  { duration: 250 } }
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
        Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        Behavior on width   { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Component.onCompleted: { opacity = 0; scale = 0.95; opacity = 1; scale = 1 }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 10

            // ── Apps · Workspaces · Visualizer ───────────────────────────────
            HoverPanel {
                name: "apps"; ctrl: root; hAlign: Qt.AlignLeft; clickToggles: false; menuWidth: 375
                trigger: AppMenuButton {}
                menu: AppsMenu { onLaunched: root.openMenu = "" }
            }

            // Places — home folders, opens in the file manager (Nautilus)
            HoverPanel {
                name: "places"; ctrl: root; hAlign: Qt.AlignLeft; menuWidth: 300
                trigger: Item {
                    implicitWidth: 36; implicitHeight: 36
                    Text {
                        anchors.centerIn: parent
                        text: "󰉋"
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 19
                        color: root.openMenu === "places" ? Colors.sky : Colors.yellow
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
                menu: PlacesMenu { onOpened: root.openMenu = "" }
            }

            HoverPanel {
                name: "workspaces"; ctrl: root; hAlign: Qt.AlignLeft; clickToggles: false; menuWidth: 300
                trigger: Workspaces { screenName: root.screen ? root.screen.name : "" }
                menu: WorkspacesMenu {
                    screenName: root.screen ? root.screen.name : ""
                    onSwitched: root.openMenu = ""
                }
            }

            HoverPanel {
                name: "visualizer"; ctrl: root; hAlign: Qt.AlignLeft; menuWidth: 450
                trigger: AudioVisualizer {}
                menu: ColumnLayout {
                    spacing: 8
                    AudioVisualizer { Layout.fillWidth: true; Layout.preferredHeight: 160 }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: root.audioSink
                            ? (root.audioSink.description || root.audioSink.nickname || root.audioSink.name || "Output")
                            : "No output device"
                        color: Colors.overlay1
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }
            }

            Sep {}

            // ── Clock · Calendar (center) ────────────────────────────────────
            HoverPanel {
                name: "calendar"; ctrl: root; hAlign: Qt.AlignHCenter; menuWidth: 440
                trigger: Clock {}
                menu: Calendar {}
            }

            Sep {}

            // ── Media · System stats ─────────────────────────────────────────
            MediaPlayer {
                visible: hasMedia
                Layout.alignment: Qt.AlignVCenter
            }

            HoverPanel {
                name: "system"; ctrl: root; hAlign: Qt.AlignHCenter; menuWidth: 375
                trigger: SystemStats {}
                menu: SystemMenu {}
            }

            Sep {}

            // ── Updates · Notifications · Clipboard ──────────────────────────
            HoverMenuButton {
                name: "updates"
                ctrl: root
                menuWidth: 375
                icon: "󰚰"
                iconColor: Updates.total > 0 ? Colors.peach : Colors.subtext1
                iconActiveColor: Colors.sky
                badgeCount: Updates.total
                badgeColor: Colors.peach
                onClicked: root.openMenu = (root.openMenu === "updates" ? "" : "updates")

                UpdatesMenu { onActed: root.openMenu = "" }
            }

            HoverMenuButton {
                name: "notifications"
                ctrl: root
                menuWidth: 440
                icon: Notifications.dnd ? "󰂛" : "󰂚"
                iconColor: Notifications.dnd ? Colors.red
                    : (Notifications.unread > 0 ? Colors.yellow : Colors.subtext1)
                iconActiveColor: Notifications.dnd ? Colors.red : Colors.sky
                badgeCount: Notifications.dnd ? 0 : Notifications.unread
                onClicked: root.openMenu = (root.openMenu === "notifications" ? "" : "notifications")
                onMenuOpenChanged: if (menuOpen) Notifications.markRead()

                NotificationMenu {}
            }

            HoverMenuButton {
                name: "clipboard"
                ctrl: root
                menuWidth: 400
                icon: "󰅎"
                iconColor: Colors.teal
                iconActiveColor: Colors.sky
                onClicked: root.openMenu = (root.openMenu === "clipboard" ? "" : "clipboard")

                ClipboardMenu { onCopied: root.openMenu = "" }
            }

            Sep {}

            // ── Volume ───────────────────────────────────────────────────────
            HoverMenuButton {
                name: "volume"
                ctrl: root
                menuWidth: 310
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
                        font.pixelSize: 22
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
                        font.pixelSize: 15
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
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }

            // ── Theme ────────────────────────────────────────────────────────
            HoverMenuButton {
                name: "theme"
                ctrl: root
                menuWidth: 220
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
                        Layout.preferredHeight: 45
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
                                font.pixelSize: 18
                                color: themeItem.modelData.dark ? Colors.lavender : Colors.yellow
                            }
                            Text {
                                text: themeItem.modelData.label
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 16
                                color: Colors.text
                                Layout.fillWidth: true
                            }
                            Text {
                                text: themeItem.modelData.sub
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 13
                                color: Colors.overlay1
                            }
                            Text {
                                visible: themeItem.active
                                text: "󰄬"
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 15
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

            // ── Display (DP-1): night shift + HDR/SDR colour modes ───────────
            HoverMenuButton {
                name: "display"
                ctrl: root
                // 360 fits the longest option sub ("max saturation (1.35)")
                // next to its label without eliding.
                menuWidth: 360
                icon: "󰍹"
                iconColor: Frost.nightOn ? Colors.peach
                    : (root.hdrOn ? Colors.peach : Colors.overlay1)
                iconActiveColor: Colors.peach
                // Quick action: click toggles HDR<->SDR; the dropdown has full controls
                // (night shift toggle + temperature slider, HDR/SDR vibrant/standard).
                onClicked: root.setHdr(!root.hdrOn)
                // Re-read DP-1 state when the menu opens so everything is live even if
                // colour/night shift was changed via keybinds outside the bar.
                onMenuOpenChanged: if (menuOpen) Frost.refresh()

                DisplayMenu {}
            }

            // ── Wallpaper ────────────────────────────────────────────────────
            HoverMenuButton {
                name: "wallpaper"
                ctrl: root
                menuWidth: 240
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
                        Layout.preferredHeight: 45
                        radius: 8
                        color: wpMa.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.8) : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 10
                            Text {
                                text: wpItem.modelData.icon
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 18
                                color: Colors.sky
                            }
                            Text {
                                text: wpItem.modelData.label
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 16
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

            // ── Power ────────────────────────────────────────────────────────
            HoverMenuButton {
                name: "power"
                ctrl: root
                menuWidth: 200
                icon: "⏻"
                iconColor: Colors.mauve
                iconActiveColor: Colors.red

                Repeater {
                    model: [
                        // Lock routes through hypridle's lock_cmd (pidof-guards hyprlock).
                        { icon: "󰌾", label: "Lock",     color: Colors.teal,   cmd: ["loginctl", "lock-session"] },
                        { icon: "󰒲", label: "Sleep",    color: Colors.blue,   cmd: ["systemctl", "suspend"]  },
                        { icon: "󰍃", label: "Logout",   color: Colors.yellow, cmd: ["uwsm", "stop"]          },
                        { icon: "󰜉", label: "Restart",  color: Colors.green,  cmd: ["systemctl", "reboot"]   },
                        { icon: "⏻",  label: "Shutdown", color: Colors.red,    cmd: ["systemctl", "poweroff"] },
                    ]
                    delegate: Rectangle {
                        id: pwItem
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 45
                        radius: 8
                        color: pwMa.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.9) : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 10
                            Text {
                                text: pwItem.modelData.icon
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 18
                                color: pwItem.modelData.color
                            }
                            Text {
                                text: pwItem.modelData.label
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 16
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
        anchors { top: parent.top; topMargin: barH; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: root.openMenu !== ""
        onClicked: { root.openMenu = ""; root.hoveredMenu = "" }
        z: -1
    }
}

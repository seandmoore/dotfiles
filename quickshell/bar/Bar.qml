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

    implicitHeight: openMenu === "" ? barH : 820   // tall enough for the largest dropdown (consolidated Quick Settings, incl. laptop brightness row) so it isn't clipped at the bottom
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

    // IPC: toggle the Quick Settings dropdown from a keybind (SUPER+Q), the way
    // the launcher and cheat sheet open from theirs.
    //   qs -c config ipc call quicksettings toggle
    IpcHandler {
        target: "quicksettings"
        function toggle() { root.openMenu = (root.openMenu === "quicksettings" ? "" : "quicksettings") }
    }

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

    // Theme / display / wallpaper / power actions now live entirely in the
    // QuickSettings dropdown (and the DisplayMenu it embeds), which are
    // self-contained — the bar root no longer needs its own copies.

    readonly property int barH:      84   // collapsed bar strip height
    readonly property int bubbleH:   66   // pill height (9px padding inside barH)
    readonly property int bubblePad:    16   // horizontal padding inside each island
    readonly property int islandMargin: 12   // gap from the screen edge to the side islands

    // Thin group separator between widget clusters inside the pill.
    component Sep: Rectangle {
        width: 1
        Layout.preferredHeight: 23
        Layout.alignment: Qt.AlignVCenter
        color: Colors.surface1
        opacity: 0.5
    }

    // ── THREE FROSTED ISLANDS — left (launch/nav) · center (time) · right (status) ─
    // Each island is its own GlassSurface; because the bar window sits at the
    // monitor's top-left, an island's own x/y ARE its monitor-local origin, so each
    // one's frost lines up with the wallpaper behind it. The shared menu controller
    // (root.openMenu) keeps a single dropdown open at a time across all three.
    //
    // Island is an inline GlassSurface preset: shared frost/geometry + entrance pop;
    // declared children land in the centred row. Position each instance via anchors.
    component Island: GlassSurface {
        default property alias islandContent: islandRow.data
        y: (barH - bubbleH) / 2
        height: root.bubbleH
        width: islandRow.implicitWidth + root.bubblePad * 2
        radius: root.bubbleH / 2
        screen: root.screen
        originX: x
        originY: y
        tint: Colors.base
        tintAlpha: Colors.barFrost
        borderColor: Colors.glassBorder

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
        Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        Behavior on width   { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Component.onCompleted: { opacity = 0; scale = 0.95; opacity = 1; scale = 1 }

        RowLayout {
            id: islandRow
            anchors.centerIn: parent
            spacing: 10
        }
    }

    // ── LEFT — apps · places · workspaces · visualizer ────────────────────────
    Island {
        anchors.left: parent.left
        anchors.leftMargin: root.islandMargin

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
    }

    // ── CENTER — clock · calendar ─────────────────────────────────────────────
    Island {
        anchors.horizontalCenter: parent.horizontalCenter

        HoverPanel {
            name: "calendar"; ctrl: root; hAlign: Qt.AlignHCenter; menuWidth: 440
            trigger: Clock {}
            menu: Calendar {}
        }
    }

    // ── RIGHT — media · system · battery · updates · notifications · clipboard · cog ─
    Island {
        anchors.right: parent.right
        anchors.rightMargin: root.islandMargin

        MediaPlayer {
            visible: hasMedia
            Layout.alignment: Qt.AlignVCenter
        }

        HoverPanel {
            name: "system"; ctrl: root; hAlign: Qt.AlignHCenter; menuWidth: 375
            trigger: SystemStats {}
            menu: SystemMenu {}
        }

        // Battery — hover for the charge breakdown. The whole panel hides on
        // machines without a battery (desktop), so it only shows on a laptop.
        HoverPanel {
            name: "battery"; ctrl: root; hAlign: Qt.AlignHCenter; menuWidth: 260
            visible: Battery.present
            trigger: BatteryIndicator {}
            menu: BatteryMenu {}
        }

        Sep {}

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

        // Quick Settings — one dropdown with all the quick toggles, sliders,
        // wallpaper, and power actions.
        HoverMenuButton {
            name: "quicksettings"
            ctrl: root
            // 360 fits the embedded Display submode subs ("max saturation (1.35)").
            menuWidth: 360
            icon: "󰒓"
            iconColor: Colors.lavender
            iconActiveColor: Colors.sky
            onClicked: root.openMenu = (root.openMenu === "quicksettings" ? "" : "quicksettings")
            // Scroll on the cog adjusts volume without opening the panel — the one
            // gesture the old standalone Volume button had.
            onScrolled: (dy) => root.adjustVolume(dy > 0 ? 0.05 : -0.05)
            // Re-read DP-1 state on open so the embedded Display controls are live
            // even if colour/night shift was changed via keybinds outside the bar.
            onMenuOpenChanged: if (menuOpen) Surface.refresh()

            QuickSettings { ctrl: root; Layout.fillWidth: true }
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

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: powerMenuOpen ? 236 : 56
    exclusiveZone: 56
    margins.top: 0
    color: "transparent"

    property bool powerMenuOpen: false

    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

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

    // ── LEFT BUBBLE — app menu + workspaces ──────────────────────────────────
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

    // ── RIGHT BUBBLE — stats + controls ─────────────────────────────────────
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

            ThemeToggle { Layout.alignment: Qt.AlignVCenter }

            // Wallpaper button
            Item {
                Layout.alignment: Qt.AlignVCenter
                width: 28; height: 28

                Rectangle {
                    anchors.centerIn: parent
                    width: 32; height: 32; radius: 8
                    color: Colors.accentDim
                    opacity: wallMa.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰋩"
                    font.pixelSize: 15
                    font.family: "JetBrainsMono Nerd Font Propo"
                    color: Colors.sky
                }

                MouseArea {
                    id: wallMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wallpaperIpc.running = true
                }

                Process {
                    id: wallpaperIpc
                    command: ["quickshell", "-c", "config", "ipc", "call", "wallpaper", "toggle"]
                }
            }

            // Power button
            Item {
                Layout.alignment: Qt.AlignVCenter
                width: 28; height: 28

                Rectangle {
                    anchors.centerIn: parent
                    width: 32; height: 32; radius: 8
                    color: Colors.accentDim
                    opacity: powerMa.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "⏻"
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 15
                    color: root.powerMenuOpen ? Colors.red : Colors.mauve
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: powerMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.powerMenuOpen = !root.powerMenuOpen
                }
            }
        }
    }

    // ── POWER MENU DROPDOWN ──────────────────────────────────────────────────
    Rectangle {
        id: powerMenuPanel
        width: 160
        height: menuCol.implicitHeight + 16
        radius: 14
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.92)
        border.color: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.5)
        border.width: 1

        anchors {
            top: rightBubble.bottom
            topMargin: 6
            right: rightBubble.right
        }

        visible: root.powerMenuOpen
        opacity: root.powerMenuOpen ? 1 : 0
        scale: root.powerMenuOpen ? 1 : 0.92
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

        ColumnLayout {
            id: menuCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
            spacing: 2

            Repeater {
                model: [
                    { icon: "󰒲", label: "Sleep",    color: Colors.blue,   cmd: ["systemctl", "suspend"]                    },
                    { icon: "󰍃", label: "Logout",   color: Colors.yellow, cmd: ["hyprctl", "dispatch", "exit", "0"]        },
                    { icon: "⏻",  label: "Shutdown", color: Colors.red,    cmd: ["systemctl", "poweroff"]                   },
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 38; radius: 8
                    color: itemMa.containsMouse
                        ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.9)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 10
                        Text {
                            text: modelData.icon
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 14
                            color: modelData.color
                        }
                        Text {
                            text: modelData.label
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 13
                            color: Colors.text
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: itemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.powerMenuOpen = false
                            proc.command = modelData.cmd
                            proc.running = true
                        }
                    }
                }
            }
        }

        Process { id: proc }
    }

    // Dismiss power menu on click outside
    MouseArea {
        anchors { top: parent.top; topMargin: 56; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: root.powerMenuOpen
        onClicked: root.powerMenuOpen = false
        z: -1
    }
}

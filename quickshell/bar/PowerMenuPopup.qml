import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: false
    aboveWindows: true
    focusable: true

    IpcHandler {
        target: "powermenu"
        function toggle() {
            if (root.visible) {
                root.visible = false
            } else {
                openTimer.start()
            }
        }
    }

    Timer {
        id: openTimer
        interval: 50
        onTriggered: root.visible = true
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }

    // Dismiss on outside click
    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    // Menu panel — top-right corner
    Rectangle {
        id: menu
        width: 160
        height: col.implicitHeight + 16
        radius: 14
        color: Qt.rgba(Colors.mantle.r, Colors.mantle.g, Colors.mantle.b, 0.97)
        border.color: Colors.surface1
        border.width: 1

        anchors {
            top: parent.top
            topMargin: 68
            right: parent.right
            rightMargin: 28
        }

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.92
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

        ColumnLayout {
            id: col
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
            spacing: 2

            Repeater {
                model: [
                    { icon: "󰒲", label: "Sleep",    color: Colors.blue,   cmd: ["systemctl", "suspend"] },
                    { icon: "󰍃", label: "Logout",   color: Colors.yellow, cmd: ["uwsm", "stop"] },
                    { icon: "⏻",  label: "Shutdown", color: Colors.red,    cmd: ["systemctl", "poweroff"] },
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 8
                    color: ma.containsMouse
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
                            font.pixelSize: 13
                            color: Colors.text
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.visible = false
                            proc.command = modelData.cmd
                            proc.running = true
                        }
                    }
                }
            }
        }
    }

    Process { id: proc }
}

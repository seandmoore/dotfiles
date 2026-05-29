import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: root

    anchors { top: true; right: true }
    implicitWidth: 170
    implicitHeight: visible ? menu.implicitHeight + 20 : 0
    color: "transparent"
    visible: false
    aboveWindows: true

    IpcHandler {
        target: "powermenu"
        function toggle() { root.visible = !root.visible }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }

    Rectangle {
        id: menu
        anchors {
            top: parent.top
            topMargin: 68
            right: parent.right
            rightMargin: 16
        }
        implicitWidth: 158
        implicitHeight: col.implicitHeight + 16
        radius: 14
        color: Qt.rgba(Colors.mantle.r, Colors.mantle.g, Colors.mantle.b, 0.97)
        border.color: Colors.surface1
        border.width: 1

        layer.enabled: true
        layer.effect: null

        ColumnLayout {
            id: col
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
            spacing: 2

            Repeater {
                model: [
                    { icon: "󰒲", label: "Sleep",    color: Colors.blue,   cmd: ["systemctl", "suspend"] },
                    { icon: "󰍃", label: "Logout",   color: Colors.yellow, cmd: ["hyprctl", "dispatch", "exit", "0"] },
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
                            font.family: "JetBrainsMono Nerd Font"
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

    // Dismiss on outside click
    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
        z: -1
    }

    Process { id: proc }
}

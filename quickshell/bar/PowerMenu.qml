import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

Item {
    id: root
    width: 28
    height: 28

    // Hover glow
    Rectangle {
        anchors.centerIn: parent
        width: 32; height: 32; radius: 8
        color: Colors.accentDim
        opacity: btn.containsMouse && !menu.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: "⏻"
        font.pixelSize: 15
        color: menu.visible ? Colors.red : Colors.mauve
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        id: btn
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: menu.visible = !menu.visible
    }

    // Dropdown popup
    Rectangle {
        id: menu
        visible: false
        width: 150
        height: col.implicitHeight + 16
        radius: 12
        color: Qt.rgba(Colors.mantle.r, Colors.mantle.g, Colors.mantle.b, 0.97)
        border.color: Colors.surface1
        border.width: 1

        // Position above the bar
        anchors {
            right: parent.right
            bottom: parent.top
            bottomMargin: 10
        }

        // Close when clicking outside
        MouseArea {
            id: dismiss
            parent: root.Window.contentItem
            anchors.fill: parent
            visible: menu.visible
            z: menu.z - 1
            onClicked: menu.visible = false
        }

        ColumnLayout {
            id: col
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
            spacing: 2

            Repeater {
                model: [
                    { icon: "󰒲", label: "Sleep",    cmd: ["systemctl", "suspend"],    color: Colors.blue   },
                    { icon: "󰍃", label: "Logout",   cmd: ["hyprctl", "dispatch", "exit", "0"], color: Colors.yellow },
                    { icon: "⏻",  label: "Shutdown", cmd: ["systemctl", "poweroff"],   color: Colors.red    },
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 8
                    color: ma.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.8) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
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
                            menu.visible = false
                            proc.command = modelData.cmd
                            proc.running = true
                        }
                    }
                }
            }
        }

        Process { id: proc }
    }
}

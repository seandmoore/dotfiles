import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../theme"

RowLayout {
    id: root
    spacing: 6
    opacity: 1
    scale: 1

    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }

    Component.onCompleted: {
        opacity = 0
        scale = 0.9
        opacity = 1
        scale = 1
    }

    Repeater {
        model: Hyprland.workspaces

        delegate: Item {
            required property var modelData
            width: 10
            height: 10
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                id: dot
                anchors.centerIn: parent
                width: Hyprland.focusedWorkspace && modelData.id === Hyprland.focusedWorkspace.id ? 10 : 7
                height: width
                radius: width / 2
                color: Hyprland.focusedWorkspace && modelData.id === Hyprland.focusedWorkspace.id
                    ? Colors.mauve
                    : (modelData.windows > 0 ? Colors.overlay1 : Colors.surface1)
                scale: ma.containsMouse ? 1.3 : 1

                Behavior on width  { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color  { ColorAnimation  { duration: 150 } }
                Behavior on scale  { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: wsSwitcher.running = true
            }

            Process {
                id: wsSwitcher
                command: ["hyprctl", "eval", "hl.dsp.focus({workspace=" + modelData.id + "})"]
                running: false
            }
        }
    }
}

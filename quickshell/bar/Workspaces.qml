import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../theme"

RowLayout {
    spacing: 6

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

                Behavior on width  { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color  { ColorAnimation  { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
        }
    }
}

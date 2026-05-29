import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 8
        color: Colors.accentDim
        opacity: ma.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: "󰣇"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 16
            color: ma.containsMouse ? Colors.mauve : Colors.overlay1
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            text: "Apps"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.weight: Font.Bold
            font.pixelSize: 12
            color: ma.containsMouse ? Colors.mauve : Colors.subtext1
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: launcherProc.running = true
    }

    Process {
        id: launcherProc
        command: ["quickshell", "-c", "config", "ipc", "call", "launcher", "toggle"]
    }
}

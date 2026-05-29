import QtQuick
import Quickshell.Io
import "../theme"

Item {
    id: root
    width: 28
    height: 28

    Rectangle {
        anchors.centerIn: parent
        width: 32; height: 32; radius: 8
        color: Colors.accentDim
        opacity: ma.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: "⏻"
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 15
        color: Colors.mauve
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleProc.running = true
    }

    Process {
        id: toggleProc
        command: ["quickshell", "-c", "config", "ipc", "call", "powermenu", "toggle"]
    }
}

import QtQuick
import Quickshell.Io
import "../theme"

Item {
    id: root
    width: 28
    height: 28

    // Hover glow behind the icon
    Rectangle {
        anchors.centerIn: parent
        width: 32
        height: 32
        radius: 8
        color: Colors.accentDim
        opacity: ma.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: "󰣇"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        color: Colors.mauve
        Behavior on color { ColorAnimation { duration: 250 } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: launcherProc.running = true
    }

    // Uses quickshell IPC to toggle the launcher, which lives in shell.qml's
    // component tree and can't be accessed directly from Bar's tree.
    Process {
        id: launcherProc
        command: ["quickshell", "-c", "config", "ipc", "call", "launcher", "toggle"]
    }
}

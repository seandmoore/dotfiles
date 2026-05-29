import QtQuick
import Quickshell.Io
import "../theme"

Item {
    id: root
    width: 22
    height: 22

    Text {
        id: icon
        anchors.centerIn: parent
        // Moon for dark, sun for light
        text: Colors.darkMode ? "󰖔" : "󰖨"
        color: Colors.darkMode ? Colors.lavender : Colors.yellow
        font.family: "JetBrainsMono Nerd Font Propo"
        font.underline: false
        font.italic: false
        font.strikeout: false
        font.pixelSize: 15
        rotation: 0

        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    }

    // Hover glow
    Rectangle {
        anchors.centerIn: parent
        width: 28
        height: 28
        radius: 6
        color: Colors.accentDim
        opacity: ma.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // Mirror of AppMenuButton — use confirmed-working quickshell IPC path.
    // setMocha/setLatte in shell.qml run sync-theme.sh via ipcSyncMocha/ipcSyncLatte.
    Process {
        id: ipcSetMocha
        command: ["quickshell", "-c", "config", "ipc", "call", "theme", "setMocha"]
    }
    Process {
        id: ipcSetLatte
        command: ["quickshell", "-c", "config", "ipc", "call", "theme", "setLatte"]
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            Colors.toggle()
            icon.rotation += 180
            if (Colors.darkMode) ipcSetMocha.running = true
            else ipcSetLatte.running = true
        }
    }
}

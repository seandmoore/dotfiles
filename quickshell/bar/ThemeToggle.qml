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
        font.family: "JetBrainsMono Nerd Font"
        font.underline: false
        font.italic: false
        font.strikeout: false
        font.pixelSize: 15

        Behavior on color { ColorAnimation { duration: 250 } }
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

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        // Raise icon above hover rect
        onClicked: Colors.toggle()
    }

    // Process objects must live in the same component tree as the caller.
    // Colors is a singleton but QuickShell creates one instance per component
    // tree — Bar/ThemeToggle share one instance, shell.qml has another.
    // Colors.syncRequested signal is caught here where Process works.
    Process {
        id: syncMocha
        command: ["bash", "-c", "/home/seanmoore/dotfiles/scripts/sync-theme.sh mocha"]
    }
    Process {
        id: syncLatte
        command: ["bash", "-c", "/home/seanmoore/dotfiles/scripts/sync-theme.sh latte"]
    }
    Connections {
        target: Colors
        function onSyncRequested(toMocha) {
            if (toMocha) syncMocha.running = true
            else syncLatte.running = true
        }
    }
}

import QtQuick
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
}

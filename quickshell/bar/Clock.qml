import QtQuick
import QtQuick.Layouts
import "../theme"

ColumnLayout {
    id: root
    spacing: 1
    opacity: 1
    scale: 1

    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
    Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }

    Component.onCompleted: {
        opacity = 0
        scale = 0.9
        opacity = 1
        scale = 1
    }

    Text {
        id: timeLabel
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(new Date(), "h:mm ap")
        color: Colors.text
        font.family: "JetBrainsMono Nerd Font Propo"
        font.weight: Font.Bold
        font.pixelSize: 15
    }

    Text {
        id: dateLabel
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(new Date(), "ddd, MMM d")
        color: Colors.subtext0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.weight: Font.Normal
        font.pixelSize: 11
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date()
            timeLabel.text = Qt.formatDateTime(now, "h:mm ap")
            dateLabel.text = Qt.formatDateTime(now, "ddd, MMM d")
        }
    }
}

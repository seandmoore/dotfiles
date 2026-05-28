import QtQuick
import QtQuick.Layouts
import "../theme"

ColumnLayout {
    id: root
    spacing: 0
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

    Text {
        id: timeLabel
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(new Date(), "hh:mm")
        color: Colors.text
        font.family: "JetBrainsMono Nerd Font"
        font.underline: false
        font.italic: false
        font.strikeout: false
        font.pixelSize: 14
        font.weight: Font.Medium
    }

    Text {
        id: dateLabel
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(new Date(), "ddd dd MMM")
        color: Colors.subtext1
        font.family: "JetBrainsMono Nerd Font"
        font.underline: false
        font.italic: false
        font.strikeout: false
        font.pixelSize: 10
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date()
            timeLabel.text = Qt.formatDateTime(now, "hh:mm")
            dateLabel.text = Qt.formatDateTime(now, "ddd dd MMM")
        }
    }
}

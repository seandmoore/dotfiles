import QtQuick
import QtQuick.Layouts
import "../theme"

// Section header used across menu bodies: optional icon + bold label + optional
// trailing slot (any child declared inside lands on the right, e.g. a "Clear" action).
RowLayout {
    id: root
    property string icon: ""
    property string label: ""
    property color accent: Colors.subtext0

    default property alias trailing: slot.data

    Layout.fillWidth: true
    spacing: 8

    Text {
        visible: root.icon !== ""
        text: root.icon
        color: root.accent
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 15
    }
    Text {
        text: root.label
        color: Colors.subtext0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 13; font.weight: Font.Bold
        Layout.fillWidth: true
    }
    Item {
        id: slot
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        Layout.alignment: Qt.AlignVCenter
    }
}

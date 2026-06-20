import QtQuick
import QtQuick.Layouts
import "../theme"

// Rounded surface container with padding and an optional left accent stripe (e.g. for
// critical notifications or status). Children declared inside stack in a ColumnLayout.
Rectangle {
    id: card
    property color accent: Colors.accent
    property bool stripe: false
    property int pad: 12

    default property alias content: body.data

    Layout.fillWidth: true
    radius: 12
    color: Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.45)
    implicitHeight: body.implicitHeight + pad * 2

    Rectangle {
        visible: card.stripe
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 8; bottomMargin: 8 }
        width: 3; radius: 2
        color: card.accent
    }

    ColumnLayout {
        id: body
        anchors {
            left: parent.left; right: parent.right; top: parent.top
            leftMargin: card.pad; rightMargin: card.pad; topMargin: card.pad
        }
        spacing: 6
    }
}

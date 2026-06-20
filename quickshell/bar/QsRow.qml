import QtQuick
import QtQuick.Layouts
import "../theme"

// Hoverable list row: leading icon + title/subtitle + trailing slot. Surface hover
// background and an accent ripple on press; emits activated(). Any child declared
// inside lands in the trailing slot (e.g. a toggle or time label).
Rectangle {
    id: row
    property string icon: ""
    property color iconColor: Colors.subtext1
    property string title: ""
    property string subtitle: ""
    property color accent: Colors.accent
    property bool interactive: true

    default property alias trailing: slot.data
    signal activated()

    Layout.fillWidth: true
    implicitHeight: Math.max(44, content.implicitHeight + 14)
    radius: 10
    clip: true
    color: (interactive && rowMa.containsMouse)
        ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.85)
        : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.40)
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: content
        anchors {
            left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
            leftMargin: 12; rightMargin: 12
        }
        spacing: 10

        Text {
            visible: row.icon !== ""
            text: row.icon
            color: row.iconColor
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 17
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                text: row.title
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 14
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                visible: row.subtitle !== ""
                text: row.subtitle
                color: Colors.overlay1
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 11
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
        Item {
            id: slot
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
            Layout.alignment: Qt.AlignVCenter
        }
    }

    QsRipple { id: rip; color: row.accent }

    MouseArea {
        id: rowMa
        anchors.fill: parent
        enabled: row.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: (m) => rip.ripple(m.x, m.y)
        onClicked: row.activated()
    }
}

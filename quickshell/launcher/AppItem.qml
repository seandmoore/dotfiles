import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"

Item {
    id: root

    required property var app
    signal activated()

    width: 96
    height: 96

    Rectangle {
        id: bg
        anchors.fill: parent
        color: ma.containsMouse ? Colors.accentDim : "transparent"
        radius: 12
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6
        width: parent.width - 12

        // App icon
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 40
            height: 40

            Image {
                id: icon
                anchors.fill: parent
                source: app.icon ? "file://" + app.icon : ""
                visible: status === Image.Ready
            }

            // Letter fallback when icon unavailable
            Rectangle {
                anchors.fill: parent
                visible: icon.status !== Image.Ready
                color: Colors.mauve
                radius: 8

                Text {
                    anchors.centerIn: parent
                    text: root.app.name ? root.app.name[0].toUpperCase() : "?"
                    color: Colors.base
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    font.family: "JetBrainsMono Nerd Font"
                    font.underline: false
                    font.italic: false
                    font.strikeout: false
                }
            }
        }

        // App name
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            text: app.name || ""
            color: Colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.underline: false
            font.italic: false
            font.strikeout: false
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WordWrap
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}

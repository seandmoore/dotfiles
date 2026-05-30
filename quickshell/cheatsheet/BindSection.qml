import QtQuick
import QtQuick.Layouts
import "../theme"

ColumnLayout {
    id: root
    property string title: ""
    property color sectionColor: Colors.mauve
    property string icon: ""
    property var binds: []

    Layout.fillWidth: true
    spacing: 3

    // Section header
    RowLayout {
        spacing: 6

        Text {
            text: root.icon
            font { family: "JetBrainsMono Nerd Font Propo"; pixelSize: 13 }
            color: root.sectionColor
        }
        Text {
            text: root.title
            font { family: "JetBrainsMono Nerd Font Propo"; pixelSize: 11; weight: Font.DemiBold }
            color: root.sectionColor
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(root.sectionColor.r, root.sectionColor.g, root.sectionColor.b, 0.25)
        Layout.bottomMargin: 2
    }

    Repeater {
        model: root.binds
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                height: 19
                width: chipText.implicitWidth + 14
                radius: 5
                color: Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.85)
                border.color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.6)
                border.width: 1

                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: modelData.keys
                    font { family: "JetBrainsMono Nerd Font Propo"; pixelSize: 10 }
                    color: Colors.subtext0
                }
            }

            Text {
                Layout.fillWidth: true
                text: modelData.desc
                font { family: "JetBrainsMono Nerd Font Propo"; pixelSize: 11 }
                color: Colors.text
                elide: Text.ElideRight
            }
        }
    }
}

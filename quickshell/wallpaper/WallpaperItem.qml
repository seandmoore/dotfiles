import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"

Item {
    id: root

    required property string path
    required property bool isSelected
    required property int itemWidth
    required property int itemHeight
    signal activated(string path)

    width: itemWidth
    height: itemHeight

    Rectangle {
        id: frame
        anchors { fill: parent; margins: 5 }
        radius: 10
        color: isSelected
            ? Qt.rgba(Colors.mauve.r, Colors.mauve.g, Colors.mauve.b, 0.25)
            : (ma.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.55) : "transparent")
        border.color: isSelected ? Colors.mauve : "transparent"
        border.width: 2
        Behavior on color { ColorAnimation { duration: 120 } }

        ColumnLayout {
            anchors { fill: parent; margins: 6 }
            spacing: 5

            // Thumbnail
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent
                    color: Colors.surface0
                    radius: 6
                }

                Image {
                    id: img
                    anchors.fill: parent
                    source: "file://" + root.path
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    cache: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: img.status !== Image.Ready
                    text: "󰋩"
                    font.pixelSize: 24
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font"
                }

                Rectangle {
                    visible: isSelected
                    anchors { top: parent.top; right: parent.right; margins: 5 }
                    width: 20; height: 20; radius: 10
                    color: Colors.mauve

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Colors.base
                    }
                }
            }

            // Filename
            Text {
                Layout.fillWidth: true
                text: {
                    const base = root.path.split("/").pop()
                    const dot = base.lastIndexOf(".")
                    return dot > 0 ? base.substring(0, dot) : base
                }
                color: isSelected ? Colors.mauve : Colors.subtext0
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activated(root.path)
        }
    }
}

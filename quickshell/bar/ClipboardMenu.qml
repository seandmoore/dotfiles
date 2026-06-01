import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../services"

// Dropdown body for the bar's clipboard button: header + clear, then the recent
// text copies (newest first). Click an entry to put it back on the clipboard.
// Kept in its own file so QtQuick.Controls (for ScrollBar) is imported in
// isolation — importing it into Bar.qml shadows the local Calendar type.
ColumnLayout {
    id: clipMenu
    spacing: 6

    signal copied()

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            text: "󰅍"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 13
            color: Colors.teal
        }
        Text {
            text: "Clipboard"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Colors.subtext1
            Layout.fillWidth: true
        }
        Text {
            visible: Clipboard.entries.length > 0
            text: "󰩹 Clear"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 10
            color: clearMa.containsMouse ? Colors.red : Colors.overlay1
            Behavior on color { ColorAnimation { duration: 120 } }
            MouseArea {
                id: clearMa
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Clipboard.clear()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
    }

    // Empty state
    Text {
        Layout.fillWidth: true
        visible: Clipboard.entries.length === 0
        text: "Nothing copied yet"
        horizontalAlignment: Text.AlignHCenter
        topPadding: 8
        bottomPadding: 8
        color: Colors.overlay0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 11
    }

    // History list (capped height; scrolls when long)
    ListView {
        id: clipList
        visible: Clipboard.entries.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 280)
        clip: true
        spacing: 2
        model: Clipboard.entries
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        add: Transition {
            NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { properties: "x"; from: 25; to: 0; duration: 200; easing.type: Easing.OutCubic }
        }
        remove: Transition {
            NumberAnimation { properties: "opacity"; to: 0; duration: 140 }
        }
        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutCubic }
        }

        delegate: Rectangle {
            required property var modelData
            width: clipList.width
            height: 34
            radius: 8
            color: clipItemMa.containsMouse
                ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.85)
                : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }

            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 10
                Text {
                    text: clipItemMa.containsMouse ? "󰆏" : "󰅍"
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 13
                    color: clipItemMa.containsMouse ? Colors.sky : Colors.overlay1
                }
                Text {
                    Layout.fillWidth: true
                    text: modelData.preview
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: clipItemMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Clipboard.copy(modelData.text)
                    clipMenu.copied()
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle { radius: 3; color: Colors.surface1; implicitWidth: 4 }
        }
    }
}

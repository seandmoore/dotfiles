import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../theme"

PanelWindow {
    id: root

    required property Notification notification

    property int timeout: notification
        ? (notification.expireTimeout > 0 ? notification.expireTimeout : 5000)
        : 5000

    // Stack from top-right, 12px from screen edge
    anchors {
        top: true
        right: true
    }
    margins { top: 12 + (stackIndex * (height + 8)); right: 12 }

    property int stackIndex: 0

    implicitWidth: 360
    implicitHeight: contentCol.implicitHeight + 24
    color: "transparent"

    // Background card
    Rectangle {
        // Slide in from right on appear
        property real slideX: 400
        transform: Translate { x: card.slideX }
        id: card

        NumberAnimation on slideX {
            from: 400; to: 0
            duration: 250
            easing.type: Easing.OutCubic
            running: true
        }
        anchors.fill: parent
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.60)
        border.color: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.5)
        border.width: 1
        radius: 14

        ColumnLayout {
            id: contentCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 6

            // Header row — icon, app name, close button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // App icon or letter avatar
                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: Colors.mauve
                    opacity: 0.8

                    Text {
                        anchors.centerIn: parent
                        text: (notification && notification.appName) ? notification.appName[0].toUpperCase() : "?"
                        color: Colors.base
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        font.family: "JetBrainsMono Nerd Font"
                        font.underline: false
                        font.italic: false
                        font.strikeout: false
                    }
                }

                Text {
                    text: (notification && notification.appName) ? notification.appName : ""
                    color: Colors.subtext0
                    font.family: "JetBrainsMono Nerd Font"
                    font.underline: false
                    font.italic: false
                    font.strikeout: false
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: "✕"
                    color: Colors.overlay1
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    font.underline: false
                    font.italic: false
                    font.strikeout: false

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (notification) notification.dismiss()
                            root.destroy()
                        }
                    }
                }
            }

            // Title
            Text {
                text: (notification && notification.summary) ? notification.summary : ""
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font"
                font.underline: false
                font.italic: false
                font.strikeout: false
                font.pixelSize: 13
                font.weight: Font.Bold
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                visible: text !== ""
            }

            // Body
            Text {
                text: (notification && notification.body) ? notification.body : ""
                color: Colors.subtext1
                font.family: "JetBrainsMono Nerd Font"
                font.underline: false
                font.italic: false
                font.strikeout: false
                font.pixelSize: 11
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                visible: text !== ""
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            // Timeout progress bar
            Rectangle {
                id: progressTrack
                Layout.fillWidth: true
                height: 3
                color: Colors.surface1
                radius: 2

                Rectangle {
                    id: progressBar
                    height: parent.height
                    width: progressTrack.width
                    radius: 2
                    color: Colors.mauve

                    NumberAnimation on width {
                        from: progressTrack.width
                        to: 0
                        duration: root.timeout
                        running: true
                        onFinished: {
                            if (notification) notification.dismiss()
                            root.destroy()
                        }
                    }
                }
            }
        }
    }
}

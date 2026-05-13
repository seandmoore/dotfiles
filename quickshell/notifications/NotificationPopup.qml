import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../theme"

FloatingWindow {
    id: root

    required property Notification notification

    property int timeout: notification.expireTimeout > 0
        ? notification.expireTimeout
        : 5000

    // Stack from top-right, 12px from screen edge
    anchors {
        top: true
        right: true
    }
    margins { top: 12 + (stackIndex * (height + 8)); right: 12 }

    property int stackIndex: 0

    width: 360
    height: contentCol.implicitHeight + 24
    color: "transparent"

    // Slide in from the right
    NumberAnimation on anchors.margins.right {
        from: -400
        to: 12
        duration: 250
        easing.type: Easing.OutCubic
        running: true
    }

    // Background card
    Rectangle {
        anchors.fill: parent
        color: Colors.surface0
        border.color: Colors.surface1
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
                        text: notification.appName ? notification.appName[0].toUpperCase() : "?"
                        color: Colors.base
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                Text {
                    text: notification.appName || ""
                    color: Colors.subtext0
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: "✕"
                    color: Colors.overlay1
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            notification.dismiss()
                            root.destroy()
                        }
                    }
                }
            }

            // Title
            Text {
                text: notification.summary || ""
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.weight: Font.SemiBold
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                visible: text !== ""
            }

            // Body
            Text {
                text: notification.body || ""
                color: Colors.subtext1
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                visible: text !== ""
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            // Timeout progress bar
            Rectangle {
                Layout.fillWidth: true
                height: 3
                color: Colors.surface1
                radius: 2

                Rectangle {
                    id: progressBar
                    height: parent.height
                    width: parent.width
                    radius: 2
                    color: Colors.mauve

                    NumberAnimation on width {
                        from: parent.parent.width
                        to: 0
                        duration: root.timeout
                        running: true
                        onFinished: {
                            notification.dismiss()
                            root.destroy()
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 36
    color: "transparent"
    exclusiveZone: height

    // Main bar background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
            Colors.base.r,
            Colors.base.g,
            Colors.base.b,
            0.92
        )

        // Bottom accent line
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Colors.mauve
            opacity: 0.6
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 0

            // Left section — workspaces
            Workspaces {
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            // Center section — clock
            Clock {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            }

            Item { Layout.fillWidth: true }

            // Right section — stats + media + theme toggle
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 16

                MediaPlayer {
                    visible: hasMedia
                    Layout.alignment: Qt.AlignVCenter
                }

                SystemStats {
                    Layout.alignment: Qt.AlignVCenter
                }

                // Separator
                Rectangle {
                    width: 1
                    height: 18
                    color: Colors.surface1
                    Layout.alignment: Qt.AlignVCenter
                }

                ThemeToggle {
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}

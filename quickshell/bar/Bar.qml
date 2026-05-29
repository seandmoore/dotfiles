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

    implicitHeight: 60
    color: "transparent"
    exclusiveZone: height

    // Main bar background — floating + rounded
    Rectangle {
        id: barBg
        anchors {
            top: parent.top
            topMargin: 16
            left: parent.left
            leftMargin: 16
            right: parent.right
            rightMargin: 16
        }
        height: 44
        radius: 22
        color: Qt.rgba(
            Colors.base.r,
            Colors.base.g,
            Colors.base.b,
            0.92
        )
        border.color: Colors.surface1
        border.width: 1
        opacity: 1
        scale: 1
        transformOrigin: Item.Top

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

        Component.onCompleted: {
            opacity = 0
            scale = 0.95
            opacity = 1
            scale = 1
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 0

            // Left section — app menu + workspaces
            AppMenuButton {
                Layout.alignment: Qt.AlignVCenter
            }

            Item { implicitWidth: 8 }

            Workspaces {
                Layout.alignment: Qt.AlignVCenter
                screenName: root.screen ? root.screen.name : ""
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

                PowerMenu {
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}

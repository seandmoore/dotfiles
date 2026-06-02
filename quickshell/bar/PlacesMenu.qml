import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../theme"
import "../services"

// Scrollable list of the home folders (from the preloaded Places singleton, scanned
// once at startup). Click a folder to open it in the file manager (Nautilus, matching
// SUPER+E) and close the menu.
Item {
    id: placesMenu
    // Size to content, capped so a deep home folder still scrolls (45 + 2 spacing).
    implicitHeight: Math.min(440, Math.max(54, placesMenu.folders.length * 47))

    signal opened()

    readonly property var folders: Places.folders

    Component.onCompleted: Places.ensureLoaded()

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        spacing: 2
        model: placesMenu.folders
        boundsBehavior: Flickable.StopAtBounds

        populate: Transition {
            NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200 }
            NumberAnimation { properties: "x"; from: 20; to: 0; duration: 220; easing.type: Easing.OutCubic }
        }

        delegate: Rectangle {
            required property var modelData
            width: list.width
            height: 45
            radius: 8
            color: itemMa.containsMouse
                ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.8)
                : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }

            Row {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 25
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData.icon
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 18
                    color: itemMa.containsMouse ? Colors.mauve : Colors.overlay1
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40
                    text: modelData.name
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 15
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: itemMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    openProc.command = ["bash", "-c",
                        "nohup nautilus \"$1\" &>/dev/null &", "--", modelData.path]
                    openProc.running = true
                    placesMenu.opened()
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle { radius: 3; color: Colors.surface1; implicitWidth: 4 }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !Places.loaded
        text: "Loading folders…"
        color: Colors.overlay0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 15
    }

    Process { id: openProc }
}

import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../theme"
import "../services"

// Scrollable list of installed desktop apps. Reads from the preloaded AppList
// singleton (scanned once at startup) so opening the dropdown is instant and the
// icons don't re-resolve each time. Click launches and closes the menu; click the
// Apps button itself for the full Launcher (with search/categories).
Item {
    id: appsMenu
    implicitHeight: 320

    signal launched()

    readonly property var apps: AppList.apps

    Component.onCompleted: AppList.ensureLoaded()

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        spacing: 2
        model: appsMenu.apps
        boundsBehavior: Flickable.StopAtBounds

        populate: Transition {
            NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200 }
            NumberAnimation { properties: "x"; from: 20; to: 0; duration: 220; easing.type: Easing.OutCubic }
        }
        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutCubic }
        }

        delegate: Rectangle {
            required property var modelData
            width: list.width
            height: 36
            radius: 8
            color: itemMa.containsMouse
                ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.8)
                : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }

            Row {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 10

                // Real app icon, with a glyph fallback when none resolves
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20

                    Image {
                        id: appIcon
                        anchors.fill: parent
                        source: modelData.icon ? "file://" + modelData.icon : ""
                        sourceSize.width: 20
                        sourceSize.height: 20
                        visible: status === Image.Ready
                        smooth: true
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: appIcon.status !== Image.Ready
                        text: "󰣆"
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 14
                        color: itemMa.containsMouse ? Colors.mauve : Colors.overlay1
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40
                    text: modelData.name
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: itemMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (modelData.exec) {
                        const cmd = modelData.exec.replace(/%[fFuUdDnNickvm]/g, "").trim()
                        launchProc.command = ["bash", "-c", "nohup " + cmd + " &>/dev/null &"]
                        launchProc.running = true
                    }
                    appsMenu.launched()
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
        visible: !AppList.loaded
        text: "Loading apps…"
        color: Colors.overlay0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 12
    }

    Process { id: launchProc }
}

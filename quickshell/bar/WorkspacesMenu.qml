import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../theme"

// This monitor's workspaces with live window counts; click a row to switch.
// Mirrors the per-monitor scoping of the bar dots (see Workspaces.qml).
ColumnLayout {
    id: wsMenu
    spacing: 4

    property string screenName: ""
    signal switched()

    // HyprlandWorkspace doesn't expose a `windows` property directly — the count
    // lives in the raw IPC payload, so reach into lastIpcObject (0 when unknown).
    function winCount(w) {
        return (w && w.lastIpcObject && w.lastIpcObject.windows) || 0
    }

    // This monitor's workspaces, sorted by id (reactive via Hyprland.workspaces)
    readonly property var mine: {
        var arr = Hyprland.workspaces.values.filter(function (w) {
            return w.id > 0 && w.monitor && w.monitor.name === wsMenu.screenName
        })
        arr.sort(function (a, b) { return a.id - b.id })
        return arr
    }

    // ── Header ───────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            text: "󰕰"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 16
            color: Colors.mauve
        }
        Text {
            text: "Workspaces"
            color: Colors.subtext1
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 15
            font.weight: Font.Bold
            Layout.fillWidth: true
        }
        Text {
            text: wsMenu.screenName
            color: Colors.overlay0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 13
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
        Layout.bottomMargin: 2
    }

    // ── Rows ─────────────────────────────────────────────────────────────────
    Repeater {
        model: wsMenu.mine

        delegate: Rectangle {
            id: wsRow
            required property var modelData
            readonly property bool active: Hyprland.focusedWorkspace
                && modelData.id === Hyprland.focusedWorkspace.id
            readonly property int windows: wsMenu.winCount(modelData)

            Layout.fillWidth: true
            Layout.preferredHeight: 47
            radius: 10
            color: wsRow.active
                ? Qt.rgba(Colors.mauve.r, Colors.mauve.g, Colors.mauve.b, 0.18)
                : (rowMa.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.8) : "transparent")
            Behavior on color { ColorAnimation { duration: 120 } }

            // Left accent bar on the active workspace
            Rectangle {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: 3
                height: wsRow.active ? 20 : 0
                radius: 2
                color: Colors.mauve
                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
                spacing: 10

                // Index badge
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: 30; height: 30; radius: 9
                    color: wsRow.active
                        ? Colors.mauve
                        : Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.7)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: wsRow.modelData.id
                        color: wsRow.active ? Colors.base : Colors.subtext1
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: "Workspace " + wsRow.modelData.id
                    color: wsRow.active ? Colors.text : Colors.subtext1
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 15
                    Layout.fillWidth: true
                }

                // Window-count pill (only when the workspace has windows)
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    visible: wsRow.windows > 0
                    implicitWidth: pill.implicitWidth + 16
                    height: 20
                    radius: 10
                    color: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.6)
                    RowLayout {
                        id: pill
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "󰖲"
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 13
                            color: Colors.overlay2
                        }
                        Text {
                            text: wsRow.windows
                            color: Colors.subtext0
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                    }
                }

                // "empty" hint when no windows
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    visible: wsRow.windows === 0
                    text: "empty"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 9
                    font.italic: true
                }
            }

            MouseArea {
                id: rowMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Hyprland.dispatch("hl.dsp.focus({workspace=" + wsRow.modelData.id + "})")
                    wsMenu.switched()
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../theme"
import "../services"

// Bell dropdown: Do-Not-Disturb toggle with an expandable "Mute for…" submenu,
// then the rolling notification history. Kept in its own file so QtQuick.Controls
// (ScrollBar) is imported in isolation (importing it into Bar.qml shadows Calendar).
ColumnLayout {
    id: notifMenu
    spacing: 6

    property bool muteSubmenu: false

    function iconFor(entry) {
        const ai = entry.appIcon
        if (!ai) return entry.image ? (entry.image.startsWith("/") ? "file://" + entry.image : entry.image) : ""
        if (ai.startsWith("/")) return "file://" + ai
        if (ai.includes("://")) return ai
        return Quickshell.iconPath(ai, "dialog-information")
    }

    function timeAgo(ms) {
        const s = Math.floor((Date.now() - ms) / 1000)
        if (s < 60) return "now"
        if (s < 3600) return Math.floor(s / 60) + "m ago"
        if (s < 86400) return Math.floor(s / 3600) + "h ago"
        return Math.floor(s / 86400) + "d ago"
    }

    function minutesUntilTomorrow() {
        const now = new Date()
        const t = new Date(now)
        t.setDate(now.getDate() + 1); t.setHours(8, 0, 0, 0)   // 8:00 tomorrow
        return Math.round((t.getTime() - now.getTime()) / 60000)
    }

    // ── Header ───────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            text: Notifications.dnd ? "󰂛" : "󰂚"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 18
            color: Notifications.dnd ? Colors.red : Colors.yellow
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        Text {
            text: "Notifications"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 15
            font.weight: Font.Bold
            color: Colors.subtext1
            Layout.fillWidth: true
        }
        Text {
            visible: Notifications.history.length > 0
            text: "󰩹 Clear"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 13
            color: clearMa.containsMouse ? Colors.red : Colors.overlay1
            Behavior on color { ColorAnimation { duration: 120 } }
            MouseArea {
                id: clearMa
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.clearAll()
            }
        }
    }

    // ── Do Not Disturb row ───────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 47
        radius: 10
        color: dndMa.containsMouse
            ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.8)
            : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.4)
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
            spacing: 10

            Text {
                text: "󰂛"
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 18
                color: Notifications.dnd ? Colors.red : Colors.overlay1
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text {
                    text: "Do Not Disturb"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 15
                }
                Text {
                    visible: Notifications.dnd
                    text: "Muted " + Notifications.muteLabel
                    color: Colors.overlay1
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 9
                }
            }

            // Expand chevron for the "mute for…" submenu
            Text {
                text: "󰅀"
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 15
                color: chevMa.containsMouse ? Colors.mauve : Colors.overlay1
                rotation: notifMenu.muteSubmenu ? -180 : 0
                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    id: chevMa
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: notifMenu.muteSubmenu = !notifMenu.muteSubmenu
                }
            }

            // Toggle switch
            Rectangle {
                id: toggle
                Layout.alignment: Qt.AlignVCenter
                width: 36; height: 20; radius: 10
                color: Notifications.dnd ? Colors.green : Colors.surface2
                Behavior on color { ColorAnimation { duration: 180 } }
                Rectangle {
                    width: 16; height: 16; radius: 8
                    y: 2
                    x: Notifications.dnd ? parent.width - width - 2 : 2
                    color: Colors.base
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.toggleDnd()
                }
            }
        }

        MouseArea {
            id: dndMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // Row click toggles DND too (the switch/chevron handle their own clicks).
            onClicked: Notifications.toggleDnd()
            z: -1
        }
    }

    // ── "Mute for…" submenu (animated reveal) ────────────────────────────────
    Item {
        Layout.fillWidth: true
        clip: true
        Layout.preferredHeight: notifMenu.muteSubmenu ? subCol.implicitHeight : 0
        opacity: notifMenu.muteSubmenu ? 1 : 0
        Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        ColumnLayout {
            id: subCol
            width: parent.width
            spacing: 2

            Repeater {
                model: [
                    { label: "Mute for 15 minutes", mins: 15 },
                    { label: "Mute for 1 hour",     mins: 60 },
                    { label: "Mute for 4 hours",    mins: 240 },
                    { label: "Until tomorrow",      mins: -2 },
                    { label: "Until I turn it on",  mins: 0  },
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: 14
                    Layout.preferredHeight: 38
                    radius: 8
                    color: subMa.containsMouse
                        ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.85)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        spacing: 8
                        Text {
                            text: "󰔚"
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 14
                            color: subMa.containsMouse ? Colors.mauve : Colors.overlay1
                        }
                        Text {
                            text: modelData.label
                            color: Colors.subtext1
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 14
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: subMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const m = modelData.mins
                            Notifications.muteFor(m === -2 ? notifMenu.minutesUntilTomorrow() : m)
                            notifMenu.muteSubmenu = false
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
    }

    // ── Empty state ──────────────────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        visible: Notifications.history.length === 0
        spacing: 4
        Layout.topMargin: 6
        Layout.bottomMargin: 6
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "󰂜"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 24
            color: Colors.overlay0
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "No notifications"
            color: Colors.overlay0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
        }
    }

    // ── History list ─────────────────────────────────────────────────────────
    ListView {
        id: histList
        visible: Notifications.history.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 320)
        clip: true
        spacing: 4
        model: Notifications.history
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        // Smooth add / remove / reflow
        add: Transition {
            NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200 }
            NumberAnimation { properties: "x"; from: 30; to: 0; duration: 220; easing.type: Easing.OutCubic }
        }
        remove: Transition {
            NumberAnimation { properties: "opacity"; to: 0; duration: 150 }
            NumberAnimation { properties: "x"; to: 60; duration: 200; easing.type: Easing.InCubic }
        }
        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 220; easing.type: Easing.OutCubic }
        }

        delegate: Rectangle {
            required property var modelData
            readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
            width: histList.width
            implicitHeight: Math.max(46, histRow.implicitHeight + 16)
            radius: 10
            color: histMa.containsMouse
                ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.85)
                : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.35)
            Behavior on color { ColorAnimation { duration: 120 } }

            // Critical accent stripe
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 8; bottomMargin: 8 }
                width: 3; radius: 2
                visible: parent.critical
                color: Colors.red
            }

            RowLayout {
                id: histRow
                anchors { fill: parent; leftMargin: 12; rightMargin: 10; topMargin: 8; bottomMargin: 8 }
                spacing: 10

                Item {
                    Layout.alignment: Qt.AlignTop
                    width: 24; height: 24
                    Image {
                        id: histIcon
                        anchors.fill: parent
                        source: notifMenu.iconFor(modelData)
                        sourceSize.width: 48; sourceSize.height: 48
                        smooth: true
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: histIcon.status !== Image.Ready
                        text: "󰂚"
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 18
                        color: Colors.overlay1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            text: modelData.appName || "Notification"
                            color: Colors.overlay2
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: notifMenu.timeAgo(modelData.time)
                            color: Colors.overlay0
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 9
                        }
                    }
                    Text {
                        visible: text !== ""
                        text: modelData.summary || ""
                        color: Colors.text
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: text !== ""
                        text: modelData.body || ""
                        color: Colors.subtext0
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignTop
                    visible: histMa.containsMouse
                    text: "✕"
                    color: dismMa.containsMouse ? Colors.red : Colors.overlay1
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 14
                    Behavior on color { ColorAnimation { duration: 120 } }
                    MouseArea {
                        id: dismMa
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.dismiss(modelData.id)
                    }
                }
            }

            MouseArea {
                id: histMa
                anchors.fill: parent
                hoverEnabled: true
                z: -1
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle { radius: 3; color: Colors.surface1; implicitWidth: 4 }
        }
    }
}

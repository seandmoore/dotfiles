import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../theme"

PanelWindow {
    id: root

    required property Notification notification
    required property var server
    property int stackIndex: 0

    // Critical notifications never auto-dismiss; the rest honour their hint or
    // fall back to 5s.
    readonly property bool isCritical: notification
        && notification.urgency === NotificationUrgency.Critical
    readonly property bool isLow: notification
        && notification.urgency === NotificationUrgency.Low
    readonly property bool persistent: isCritical
    readonly property int timeout: notification
        ? (notification.expireTimeout > 0 ? notification.expireTimeout : 5000)
        : 5000

    readonly property color accentColor: isCritical ? Colors.red
        : isLow ? Colors.overlay1
        : Colors.mauve

    // Time the notification arrived, e.g. "9:41 AM"
    readonly property string timeStr: Qt.formatDateTime(new Date(), "h:mm AP")

    // Resolve the app icon (name → themed path, or an absolute/url path as-is)
    readonly property string appIconSource: {
        if (!notification || !notification.appIcon) return ""
        const ai = notification.appIcon
        if (ai.startsWith("/")) return "file://" + ai
        if (ai.includes("://")) return ai
        return Quickshell.iconPath(ai, "dialog-information")
    }

    // Larger image hint (album art, screenshot, sender avatar, …)
    readonly property string imageSource: {
        if (!notification || !notification.image) return ""
        const im = notification.image
        if (im.startsWith("/")) return "file://" + im
        return im
    }

    // Action buttons, excluding the implicit "default" (whole-card click) action
    readonly property var buttonActions: {
        const out = []
        if (notification && notification.actions)
            for (let i = 0; i < notification.actions.length; i++) {
                const a = notification.actions[i]
                if (a.identifier !== "default" && a.text !== "") out.push(a)
            }
        return out
    }

    // Slide + fade out, then let the server splice + destroy us.
    property bool closing: false
    function close() {
        if (closing) return
        closing = true
        card.slideX = 460
        card.opacity = 0
        removeTimer.start()
    }

    Timer { id: removeTimer; interval: 220; onTriggered: root.server.remove(root) }

    function finish(reason) {
        if (notification) {
            if (reason === "expire") notification.expire()
            else notification.dismiss()
        }
        close()
    }

    function activateDefault() {
        if (notification && notification.actions)
            for (let i = 0; i < notification.actions.length; i++)
                if (notification.actions[i].identifier === "default") {
                    notification.actions[i].invoke()
                    close()
                    return
                }
        finish("dismiss")
    }

    // Stack from top-right, growing downward. Animate the top margin so the rest
    // of the stack glides up smoothly when a popup above is dismissed.
    anchors { top: true; right: true }
    margins {
        top: 12 + (stackIndex * (height + 8))
        right: 12
        Behavior on top { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    }

    implicitWidth: 380
    implicitHeight: contentCol.implicitHeight + 24
    color: "transparent"

    Rectangle {
        id: card
        anchors.fill: parent

        // Slide + fade in on appear; slide + fade out on close() (driven by Behaviors).
        property real slideX: 400
        transform: Translate { x: card.slideX }
        opacity: 0
        Behavior on slideX { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
        Component.onCompleted: { slideX = 0; opacity = 1 }

        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Surface.opacity(0.55))
        border.color: root.isCritical
            ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.6)
            : Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.5)
        border.width: 1
        radius: 14

        // Urgency accent stripe down the left edge
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 4
            radius: 2
            color: root.accentColor
        }

        // Hover tracking + whole-card click → default action. Declared before
        // contentCol so its buttons sit on top and handle their own clicks.
        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activateDefault()
        }

        ColumnLayout {
            id: contentCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 14
                rightMargin: 12
                topMargin: 12
            }
            spacing: 8

            // ── Header: app icon, app name, time, close ───────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // App icon (themed) with letter-avatar fallback
                Item {
                    width: 22; height: 22

                    Image {
                        id: appIconImg
                        anchors.fill: parent
                        source: root.appIconSource
                        sourceSize.width: 44
                        sourceSize.height: 44
                        smooth: true
                        visible: status === Image.Ready
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: appIconImg.status !== Image.Ready
                        radius: 6
                        color: root.accentColor
                        opacity: 0.85
                        Text {
                            anchors.centerIn: parent
                            text: (root.notification && root.notification.appName)
                                ? root.notification.appName[0].toUpperCase() : "?"
                            color: Colors.base
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                    }
                }

                Text {
                    text: (root.notification && root.notification.appName)
                        ? root.notification.appName : "Notification"
                    color: Colors.subtext0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                // Critical badge
                Text {
                    visible: root.isCritical
                    text: "URGENT"
                    color: Colors.red
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }

                Text {
                    text: root.timeStr
                    color: Colors.overlay1
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 10
                }

                Text {
                    text: "✕"
                    color: closeMa.containsMouse ? Colors.red : Colors.overlay1
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font Propo"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.finish("dismiss")
                    }
                }
            }

            // ── Body: optional image + summary/body text ──────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Image hint (album art, screenshot, …)
                Rectangle {
                    visible: notifImg.status === Image.Ready
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 52
                    Layout.alignment: Qt.AlignTop
                    radius: 8
                    color: "transparent"
                    clip: true

                    Image {
                        id: notifImg
                        anchors.fill: parent
                        source: root.imageSource
                        sourceSize.width: 104
                        sourceSize.height: 104
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    // Title / summary
                    Text {
                        text: (root.notification && root.notification.summary)
                            ? root.notification.summary : ""
                        color: Colors.text
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        visible: text !== ""
                    }

                    // Body — supports the markup apps send (links, bold, …)
                    Text {
                        text: (root.notification && root.notification.body)
                            ? root.notification.body : ""
                        color: Colors.subtext1
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                        textFormat: Text.MarkdownText
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 8
                        elide: Text.ElideRight
                        onLinkActivated: link => Qt.openUrlExternally(link)
                        visible: text !== ""
                    }
                }
            }

            // ── Action buttons ────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 6
                visible: root.buttonActions.length > 0

                Repeater {
                    model: root.buttonActions

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: 8
                        color: actMa.containsMouse
                            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                            : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.8)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.text
                            color: Colors.text
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width - 12
                            horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            id: actMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                modelData.invoke()
                                root.close()
                            }
                        }
                    }
                }
            }

            // ── Timeout progress bar (skipped for critical) ───────────────────
            Rectangle {
                id: progressTrack
                Layout.fillWidth: true
                Layout.topMargin: 2
                height: 3
                radius: 2
                color: Colors.surface1
                visible: !root.persistent

                property real progress: 1

                Rectangle {
                    width: progressTrack.width * progressTrack.progress
                    height: parent.height
                    radius: 2
                    color: root.accentColor
                }

                NumberAnimation on progress {
                    from: 1; to: 0
                    duration: root.timeout
                    running: !root.persistent
                    paused: hoverArea.containsMouse
                    onFinished: root.finish("expire")
                }
            }

            // Hint shown instead of the bar for persistent notifications
            Text {
                visible: root.persistent
                Layout.topMargin: 2
                text: "Stays until dismissed"
                color: Colors.overlay0
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 9
                font.italic: true
            }
        }
    }
}

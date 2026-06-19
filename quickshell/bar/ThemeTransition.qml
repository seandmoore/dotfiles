import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// Brief, click-through fullscreen hint shown when the theme switches. Flatpak apps
// are killed + relaunched to re-read the flavor (GTK can't live-recolor a sandbox),
// so this covers that ~2-4s gap with a centered "applying theme" pill instead of
// apps silently blinking out. Triggered from shell.qml's setMocha/setLatte.
PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    aboveWindows: true
    focusable: false
    color: "transparent"
    visible: false

    // Empty input region → fully click-through, never steals focus/clicks.
    mask: Region {}

    property real anim: 0          // 0..1 drives fade + scale
    property real shimmer: 0       // 0..1 sweeps the activity bar

    function show() {
        visible = true
        anim = 0
        fadeIn.restart()
        shimmerLoop.restart()
        holdTimer.restart()
    }

    NumberAnimation {
        id: fadeIn
        target: root; property: "anim"
        from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: fadeOut
        target: root; property: "anim"
        from: 1; to: 0; duration: 360; easing.type: Easing.InCubic
        onFinished: { root.visible = false; shimmerLoop.stop() }
    }
    Timer {
        id: holdTimer
        interval: 1500           // long enough to cover the app relaunch
        onTriggered: fadeOut.restart()
    }
    NumberAnimation {
        id: shimmerLoop
        target: root; property: "shimmer"
        from: 0; to: 1; duration: 1100; loops: Animation.Infinite
        easing.type: Easing.InOutSine
    }

    // Faint full-screen wash in the (new) flavor so the whole desktop reads as
    // mid-transition while apps come back.
    Rectangle {
        anchors.fill: parent
        color: Colors.base
        opacity: root.anim * 0.28
    }

    // Centered pill
    Rectangle {
        anchors.centerIn: parent
        width: 248
        height: 92
        radius: 18
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.82)
        border.color: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.5)
        border.width: 1
        opacity: root.anim
        scale: 0.92 + root.anim * 0.08

        Column {
            anchors.centerIn: parent
            spacing: 8

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Colors.darkMode ? "󰖔" : "󰖨"   // moon / sun, matches the toggle
                    color: Colors.darkMode ? Colors.lavender : Colors.yellow
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 22
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Colors.darkMode ? "Mocha" : "Latte"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 18
                    font.weight: Font.Medium
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "applying theme to apps…"
                color: Colors.subtext0
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 11
            }

            // Indeterminate activity bar — a soft accent blob sweeping across,
            // hinting that apps are being relaunched into the new flavor.
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 168; height: 4; radius: 2
                color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.6)
                clip: true

                Rectangle {
                    width: 56; height: parent.height; radius: 2
                    color: Colors.accent
                    // sweep from left edge to right edge and back via InOutSine
                    x: (parent.width - width) * root.shimmer
                }
            }
        }
    }
}

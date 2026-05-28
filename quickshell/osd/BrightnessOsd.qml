import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    anchors.bottom: true
    margins.bottom: 80

    implicitWidth: 300
    implicitHeight: 56
    color: "transparent"

    visible: false

    property int brightness: 0
    property real windowOpacity: 0

    function show(pct) {
        brightness = pct
        visible = true
        fadeIn.restart()
        dismissTimer.restart()
    }

    NumberAnimation {
        id: fadeIn
        target: root
        property: "windowOpacity"
        from: 0; to: 1
        duration: 120
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: fadeOut
        target: root
        property: "windowOpacity"
        from: 1; to: 0
        duration: 300
        easing.type: Easing.InCubic
        onFinished: root.visible = false
    }

    Timer {
        id: dismissTimer
        interval: 1500
        onTriggered: fadeOut.restart()
    }

    // Pill background
    Rectangle {
        anchors.fill: parent
        opacity: root.windowOpacity
        color: Colors.surface0
        border.color: Colors.surface1
        border.width: 1
        radius: 28

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 16
                rightMargin: 16
            }
            spacing: 10

            // Icon
            Text {
                text: root.brightness >= 70 ? "󰃠" : root.brightness >= 30 ? "󰃟" : "󰃞"
                color: Colors.yellow
                font.family: "JetBrainsMono Nerd Font"
                font.underline: false
                font.italic: false
                font.strikeout: false
                font.pixelSize: 18
            }

            // Progress bar
            Rectangle {
                Layout.fillWidth: true
                height: 6
                color: Colors.surface1
                radius: 3

                Rectangle {
                    width: (root.brightness / 100) * parent.width
                    height: parent.height
                    color: Colors.yellow
                    radius: 3
                    Behavior on width { NumberAnimation { duration: 100 } }
                }
            }

            // Percentage
            Text {
                text: root.brightness + "%"
                color: Colors.subtext1
                font.family: "JetBrainsMono Nerd Font"
                font.underline: false
                font.italic: false
                font.strikeout: false
                font.pixelSize: 12
                Layout.minimumWidth: 36
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../theme"

// Workspace dots. Each dot carries its own WheelHandler so scrolling over a dot
// switches workspaces — a WheelHandler on the root ancestor never receives the
// wheel because events don't bubble up past the dot's MouseArea (clicks do, wheel
// doesn't). This mirrors the working scroll on HoverMenuButton.
Item {
    id: root

    property string screenName: ""

    implicitWidth: dots.implicitWidth
    implicitHeight: dots.implicitHeight

    opacity: 1
    scale: 1

    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }

    Component.onCompleted: {
        opacity = 0
        scale = 0.9
        opacity = 1
        scale = 1
    }

    // Cycle to the next (dir=+1) / previous (dir=-1) workspace on THIS bar's
    // monitor only, wrapping at the ends. Dispatching the absolute id keeps the
    // cursor on this screen — we never target the other monitor's workspaces.
    function cycleWorkspace(dir) {
        var mine = Hyprland.workspaces.values
            .filter(function (w) { return w.id > 0 && w.monitor && w.monitor.name === root.screenName })
            .sort(function (a, b) { return a.id - b.id })
        if (mine.length === 0)
            return

        var cur = -1
        var mons = Hyprland.monitors.values
        for (var i = 0; i < mons.length; i++) {
            if (mons[i].name === root.screenName && mons[i].activeWorkspace) {
                cur = mons[i].activeWorkspace.id
                break
            }
        }

        var idx = 0
        for (var j = 0; j < mine.length; j++) {
            if (mine[j].id === cur) { idx = j; break }
        }

        var next = (idx + dir + mine.length) % mine.length
        Hyprland.dispatch("hl.dsp.focus({workspace=" + mine[next].id + "})")
    }

    RowLayout {
        id: dots
        anchors.centerIn: parent
        // No gaps: each delegate is a wider/taller rectangle so the whole strip
        // is one contiguous scroll/click area. 16px wide keeps the dots at the
        // same 16px center-to-center spacing as before (10px dot + 6px gap).
        spacing: 0

        Repeater {
            model: Hyprland.workspaces

            delegate: Item {
                required property var modelData
                visible: !root.screenName || (modelData.monitor && modelData.monitor.name === root.screenName)
                width: 16
                height: 28
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: dot
                    anchors.centerIn: parent
                    width: Hyprland.focusedWorkspace && modelData.id === Hyprland.focusedWorkspace.id ? 10 : 7
                    height: width
                    radius: width / 2
                    color: Hyprland.focusedWorkspace && modelData.id === Hyprland.focusedWorkspace.id
                        ? Colors.mauve
                        : (modelData.windows > 0 ? Colors.overlay1 : Colors.surface1)
                    scale: ma.containsMouse ? 1.3 : 1

                    Behavior on width  { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on color  { ColorAnimation  { duration: 150 } }
                    Behavior on scale  { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.focus({workspace=" + modelData.id + "})")
                }

                // Scroll over a dot to cycle workspaces (matches mainMod + wheel binds)
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (wheel) => {
                        if (wheel.angleDelta.y < 0)
                            root.cycleWorkspace(1)
                        else if (wheel.angleDelta.y > 0)
                            root.cycleWorkspace(-1)
                    }
                }
            }
        }
    }
}

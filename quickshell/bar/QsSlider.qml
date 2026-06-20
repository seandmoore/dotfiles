import QtQuick
import QtQuick.Layouts
import "../theme"

// Modern slider row: optional tappable icon + track/accent-fill/knob + optional value
// label. `value` is the committed 0..1 level; while dragging the knob follows the
// finger locally (`shown`) and `moved(frac)` fires continuously, `released(frac)` once.
// Consumers that apply cheaply (volume/brightness) use moved; expensive ones (night
// temperature) use released. The knob springs larger while pressed.
RowLayout {
    id: root
    property string icon: ""
    property color tint: Colors.blue
    property real value: 0
    property string valueText: ""

    property bool _dragging: false
    property real _dragFrac: 0
    readonly property real shown: _dragging ? _dragFrac : Math.max(0, Math.min(1, value))

    signal moved(real frac)
    signal released(real frac)
    signal iconTapped()

    Layout.fillWidth: true
    spacing: 10

    Text {
        visible: root.icon !== ""
        text: root.icon
        color: root.tint
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 18
        TapHandler { onTapped: root.iconTapped() }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 18

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 6; radius: 3
            color: Colors.surface1

            Rectangle {
                width: parent.width * root.shown
                height: parent.height; radius: 3
                color: root.tint
                Behavior on width { enabled: !root._dragging; NumberAnimation { duration: 90 } }
            }
        }

        Rectangle {
            id: knob
            width: 15; height: 15; radius: width / 2
            color: Colors.text
            border.color: Colors.surface2; border.width: 1
            anchors.verticalCenter: parent.verticalCenter
            x: (track.width - width) * root.shown
            scale: drag.pressed ? 1.4 : 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 4 } }
            Behavior on x { enabled: !root._dragging; NumberAnimation { duration: 90 } }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function frac(mx) { return Math.max(0, Math.min(1, mx / width)) }
            onPressed: (m) => { root._dragging = true; root._dragFrac = frac(m.x); root.moved(root._dragFrac) }
            onPositionChanged: (m) => { if (pressed) { root._dragFrac = frac(m.x); root.moved(root._dragFrac) } }
            onReleased: { root.released(root._dragFrac); root._dragging = false }
        }
    }

    Text {
        visible: root.valueText !== ""
        text: root.valueText
        color: Colors.subtext1
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 14
        Layout.minimumWidth: 38
        horizontalAlignment: Text.AlignRight
    }
}

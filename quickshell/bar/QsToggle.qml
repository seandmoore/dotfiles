import QtQuick
import "../theme"

// Springy on/off switch. The knob settles with a slight overshoot and the track
// crossfades surface1 → accent. Set `interactive: false` to make it display-only
// (e.g. inside a QsTile whose whole header is the tap target).
Item {
    id: root
    property bool on: false
    property bool interactive: true
    property color accent: Colors.accent
    signal toggled()

    implicitWidth: 44
    implicitHeight: 24

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.on ? root.accent : Colors.surface1
        Behavior on color { ColorAnimation { duration: 200 } }

        Rectangle {
            id: knob
            width: parent.height - 6
            height: width
            radius: width / 2
            color: Colors.base
            anchors.verticalCenter: parent.verticalCenter
            x: root.on ? parent.width - width - 3 : 3
            Behavior on x {
                NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 3.2 }
            }
        }
    }

    TapHandler {
        enabled: root.interactive
        onTapped: root.toggled()
    }
}

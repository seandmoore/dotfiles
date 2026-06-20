import QtQuick
import "../theme"

// Reusable tap-ripple overlay. Drop in as the last child of a rounded Rectangle
// (set that Rectangle's `clip: true` so the ripple is masked to its shape) and call
// ripple(x, y) from the parent's pointer handler, e.g.
//   MouseArea { onPressed: (m) => rip.ripple(m.x, m.y) }
Item {
    id: root
    anchors.fill: parent
    property color color: Colors.accent

    property real cx: 0
    property real cy: 0

    // diameter big enough to cover the whole surface from any tap point
    readonly property real maxD: 2.4 * Math.max(width, height)

    function ripple(x, y) {
        root.cx = x; root.cy = y
        anim.stop()
        circle.width = 0
        anim.restart()
    }

    Rectangle {
        id: circle
        radius: width / 2
        color: root.color
        opacity: 0
        width: 0
        height: width
        x: root.cx - width / 2
        y: root.cy - height / 2
    }

    ParallelAnimation {
        id: anim
        NumberAnimation {
            target: circle; property: "width"
            from: 0; to: root.maxD; duration: 480; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: circle; property: "opacity"
            from: 0.30; to: 0; duration: 480; easing.type: Easing.OutCubic
        }
    }
}

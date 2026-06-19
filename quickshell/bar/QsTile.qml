import QtQuick
import QtQuick.Layouts
import "../theme"

// Quick-settings tile with two modes:
//   • toggle    — whole header is the tap target, shows an inline (display-only)
//                 QsToggle, emits toggled().
//   • expandable — header taps flip `expanded`; a chevron rotates and any children
//                 declared inside the tile slide+fade into view below the header.
// The tile background tints to `accent` while `on` or `expanded`, and the header
// shows an accent ripple on press.
Rectangle {
    id: tile

    property string icon: ""
    property string label: ""
    property color accent: Colors.accent

    property bool toggle: false       // inline toggle in the header
    property bool on: false           // active state (also tints the tile)
    property bool expandable: false
    property bool expanded: false

    signal toggled()

    // Children declared inside the tile land here (the expansion body).
    default property alias content: body.data

    readonly property int headerH: 52

    Layout.fillWidth: true
    clip: true
    radius: 14
    implicitHeight: headerH + (expanded ? bodyWrap.implicitHeight : 0)
    Behavior on implicitHeight {
        NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.05 }
    }

    color: (on || expanded)
        ? Qt.rgba(accent.r, accent.g, accent.b, 0.18)
        : (headerMa.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.85)
                                  : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.40))
    Behavior on color { ColorAnimation { duration: 150 } }
    border.color: (on || expanded) ? Qt.rgba(accent.r, accent.g, accent.b, 0.55) : "transparent"
    border.width: 1

    // ── header ───────────────────────────────────────────────────────────────
    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: tile.headerH

        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 10

            Text {
                text: tile.icon
                color: (tile.on || tile.expanded) ? tile.accent : Colors.subtext1
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 18
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            Text {
                text: tile.label
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 13
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            // trailing control: inline toggle OR chevron
            QsToggle {
                visible: tile.toggle
                interactive: false        // header MouseArea drives it (no double-fire)
                on: tile.on
                accent: tile.accent
            }
            Text {
                visible: tile.expandable
                text: "󰅂"
                color: Colors.subtext0
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 14
                rotation: tile.expanded ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
            }
        }

        QsRipple { id: rip; color: tile.accent }

        MouseArea {
            id: headerMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: (m) => rip.ripple(m.x, m.y)
            // Header tap always emits toggled(); the consumer decides what it means
            // (flip an instant setting, or set which tile is expanded — enabling an
            // accordion where only one detail is open at a time).
            onClicked: tile.toggled()
        }
    }

    // ── expansion body (slides + fades in) ─────────────────────────────────────
    Item {
        id: bodyWrap
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        implicitHeight: body.implicitHeight + 14   // bottom padding inside the tile
        opacity: tile.expanded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: tile.expanded ? 0 : -10
            Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        }

        ColumnLayout {
            id: body
            anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: 14; rightMargin: 14 }
            spacing: 8
        }
    }
}

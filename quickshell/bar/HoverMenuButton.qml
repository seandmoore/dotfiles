import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"

// A bar icon button whose dropdown menu opens on hover and hangs under the icon.
// Menu content is supplied as child items (they fill the menu's ColumnLayout).
// Open/close timing + mutual exclusivity are coordinated by `ctrl` (the Bar
// root), which must expose: string openMenu, menuEnter(name), menuExit(name),
// menuHover(name, hovered).
Item {
    id: btn

    property string name: ""
    property string icon: ""
    property color iconColor: Colors.text
    property color iconActiveColor: Colors.sky
    property real iconSize: 19
    property int menuWidth: 200
    property var ctrl: null

    // Optional unread badge drawn on the top-right of the icon.
    property int badgeCount: 0
    property color badgeColor: Colors.red

    signal clicked()
    signal scrolled(real dy)

    default property alias menuContent: body.data

    readonly property bool menuOpen: btn.ctrl && btn.ctrl.openMenu === btn.name

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: 36
    implicitHeight: 36

    Rectangle {
        anchors.centerIn: parent
        width: 40; height: 40; radius: 10
        color: Colors.accentDim
        opacity: (iconMa.containsMouse || btn.menuOpen) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: btn.icon
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: btn.iconSize
        color: btn.menuOpen ? btn.iconActiveColor : btn.iconColor
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Unread badge — pops in/out with a spring when the count crosses zero.
    Rectangle {
        id: badge
        visible: scale > 0.01
        anchors { right: parent.right; top: parent.top; rightMargin: 1; topMargin: 1 }
        implicitWidth: Math.max(14, badgeText.implicitWidth + 6)
        height: 14
        radius: 7
        color: btn.badgeColor
        border.color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.9)
        border.width: 1.5
        scale: btn.badgeCount > 0 ? 1 : 0
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: btn.badgeCount > 99 ? "99+" : btn.badgeCount
            color: Colors.base
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 8
            font.weight: Font.Bold
        }
    }

    MouseArea {
        id: iconMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
        onEntered: if (btn.ctrl) btn.ctrl.menuEnter(btn.name)
        onExited:  if (btn.ctrl) btn.ctrl.menuExit(btn.name)
    }

    WheelHandler {
        onWheel: (wheel) => btn.scrolled(wheel.angleDelta.y)
    }

    // Dropdown — child of the button so it tracks the icon's position, right-
    // aligned to the icon so it always stays on-screen. No clipping ancestors,
    // so it still receives mouse events despite overflowing the button bounds.
    GlassSurface {
        id: panel
        width: btn.menuWidth
        height: body.implicitHeight + 40
        radius: 18

        screen: btn.ctrl ? btn.ctrl.screen : null
        autoAlign: true
        tint: Colors.base
        tintAlpha: Colors.panelFrost
        borderColor: Colors.glassBorder

        anchors.top: parent.bottom
        anchors.topMargin: 14
        anchors.right: parent.right

        visible: btn.menuOpen
        opacity: btn.menuOpen ? 1 : 0
        scale: btn.menuOpen ? 1 : 0.90
        transformOrigin: Item.TopRight
        // Springy pop on open — slightly bouncier than a plain ease.
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on scale   { NumberAnimation { duration: 210; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }

        // Keep the menu open while the cursor is over it (covers the hand-off
        // across the small gap below the icon).
        HoverHandler {
            onHoveredChanged: if (btn.ctrl) btn.ctrl.menuHover(btn.name, hovered)
        }

        ColumnLayout {
            id: body
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
            spacing: 8
        }
    }
}

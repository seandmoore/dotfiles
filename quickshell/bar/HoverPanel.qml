import QtQuick
import QtQuick.Layouts
import "../theme"

// Generic bar widget with a dropdown that opens on hover (and optionally click),
// beneath the bar. Reuses Bar.qml's menu controller (`ctrl`): openMenu, menuEnter,
// menuExit, menuHover. `trigger` is the always-visible bar content; `menu` is the
// dropdown content (lazily loaded while open so polling/cava only runs when shown).
Item {
    id: panel

    property string name: ""
    property var ctrl: null
    property int menuWidth: 280
    property int hAlign: Qt.AlignHCenter      // dropdown alignment vs the trigger
    property bool clickToggles: true          // false when the trigger handles its own clicks
    property Component trigger
    property Component menu

    signal clicked()

    readonly property bool menuOpen: ctrl && ctrl.openMenu === name

    implicitWidth:  triggerLoader.item ? triggerLoader.item.implicitWidth  : 0
    implicitHeight: triggerLoader.item ? triggerLoader.item.implicitHeight : 0
    Layout.alignment: Qt.AlignVCenter

    Loader {
        id: triggerLoader
        anchors.centerIn: parent
        sourceComponent: panel.trigger
    }

    // Open on hover (passive — doesn't steal clicks/scroll from the trigger)
    HoverHandler {
        onHoveredChanged: {
            if (!panel.ctrl) return
            if (hovered) panel.ctrl.menuEnter(panel.name)
            else         panel.ctrl.menuExit(panel.name)
        }
    }

    // Click toggles the menu (skipped for triggers that handle their own clicks)
    TapHandler {
        enabled: panel.clickToggles
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: {
            panel.clicked()
            if (panel.ctrl)
                panel.ctrl.openMenu = (panel.ctrl.openMenu === panel.name ? "" : panel.name)
        }
    }

    // ── Dropdown ─────────────────────────────────────────────────────────────
    Rectangle {
        id: dropdown
        width: panel.menuWidth
        height: bodyLoader.item ? bodyLoader.item.implicitHeight + 40 : 0
        radius: 18
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Frost.glass(0.48))
        border.color: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.5)
        border.width: 1

        anchors.top: parent.bottom
        anchors.topMargin: 18
        anchors.horizontalCenter: panel.hAlign === Qt.AlignHCenter ? parent.horizontalCenter : undefined
        anchors.left:            panel.hAlign === Qt.AlignLeft     ? parent.left            : undefined
        anchors.right:           panel.hAlign === Qt.AlignRight    ? parent.right           : undefined

        visible: opacity > 0.01
        opacity: panel.menuOpen ? 1 : 0
        scale:   panel.menuOpen ? 1 : 0.92
        transformOrigin: panel.hAlign === Qt.AlignLeft  ? Item.TopLeft
                       : panel.hAlign === Qt.AlignRight ? Item.TopRight
                       : Item.Top
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

        // Keep open while the cursor is over the dropdown (covers the gap below
        // the bar so moving from trigger to menu doesn't dismiss it).
        HoverHandler {
            onHoveredChanged: if (panel.ctrl) panel.ctrl.menuHover(panel.name, hovered)
        }

        Loader {
            id: bodyLoader
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
            active: panel.menuOpen || dropdown.opacity > 0.01
            sourceComponent: panel.menu
        }
    }
}

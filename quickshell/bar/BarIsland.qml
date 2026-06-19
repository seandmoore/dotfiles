import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../theme"

// A floating bar island: a rounded, shadowed surface sized to its row of widgets, with
// a single accent highlight that glides behind whichever widget the cursor is over.
// Widgets declared inside land in the row (left→right). Hit-testing is on the island's
// own HoverHandler (passive — child triggers keep their own hover/click), so the
// highlight follows the cursor without each widget wiring anything up.
//
// The drop shadow is cast by a SEPARATE layered rect behind the real surface — the
// surface itself must NOT be layered, because the widgets' dropdown menus are its
// descendants and overflow far below the island; a layer would clip them.
Item {
    id: island

    property int pad: 10            // horizontal padding inside the surface
    property int gap: 8             // spacing between widgets
    property int extra: 8           // how much the highlight overhangs a widget

    default property alias content: row.data

    implicitWidth: surface.implicitWidth
    implicitHeight: 66

    // Entrance pop for the whole island.
    transformOrigin: Item.Center
    opacity: 1; scale: 1
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
    Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
    Component.onCompleted: { opacity = 0; scale = 0.95; opacity = 1; scale = 1 }

    function updateHighlight(pos) {
        // pos is in surface coords; row is centered, so map into row-local x.
        const rx = pos.x - row.x
        for (let i = 0; i < row.children.length; i++) {
            const c = row.children[i]
            if (!c.visible || c.width <= 0) continue
            if (rx >= c.x && rx <= c.x + c.width) {
                highlight.x = row.x + c.x - island.extra / 2
                highlight.width = c.width + island.extra
                highlight.opacity = 1
                return
            }
        }
        highlight.opacity = 0
    }

    // Shadow caster — same silhouette as the surface, layered so MultiEffect can blur
    // a drop shadow. Hidden behind the real surface; only its shadow peeks out.
    Rectangle {
        anchors.fill: surface
        radius: surface.radius
        color: Colors.base
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.45)
            shadowBlur: 0.9
            shadowVerticalOffset: 6
            autoPaddingEnabled: true
        }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: height / 2
        color: Colors.base
        border.color: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.8)
        border.width: 1
        implicitWidth: row.implicitWidth + island.pad * 2

        // Sliding highlight (declared before the row so it sits behind it).
        Rectangle {
            id: highlight
            radius: 13
            height: parent.height - 14
            y: (parent.height - height) / 2
            color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)
            opacity: 0
            visible: opacity > 0.01
            Behavior on x       { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on width   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: island.gap
        }

        HoverHandler {
            onPointChanged: island.updateHighlight(point.position)
            onHoveredChanged: if (!hovered) highlight.opacity = 0
        }
    }
}

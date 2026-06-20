import QtQuick
import QtQuick.Effects
import "."

// Reusable frosted-glass surface: a rounded panel whose background is a blurred,
// screen-aligned crop of the current wallpaper, finished with a translucent colour
// tint, a faint top inner sheen, a hairline border and (optionally) a soft drop
// shadow. Children declared inside land above the glass, in `content`.
//
// Why self-blur instead of compositor blur: the bar lives on an HDR output, where
// Hyprland can't render blur. So we sample the SAME wallpaper hyprpaper paints
// (Wall.source), downscale it (cheap soft blur) and blur+mask it to this panel's
// rounded shape. `screen` sizes the wallpaper crop; `originX/originY` (this surface's
// top-left in monitor-local pixels) shift the crop so the frost lines up with the
// real wallpaper behind the panel. For surfaces whose on-screen position is animated
// or nested, set `alignTo` to the panel window's root item and the origin is tracked
// automatically while visible.
Item {
    id: glass

    // ── Inputs ─────────────────────────────────────────────────────────────────
    property var   screen: null              // QsScreen this surface is on (for crop size)
    property real  originX: 0                 // surface top-left X in monitor pixels
    property real  originY: 0                 // surface top-left Y in monitor pixels
    // When true, originX/Y track this surface's position in the window's scene each
    // frame (while visible). For a layer window anchored at the monitor's top-left
    // (the bar) or a fullscreen overlay, scene coords == monitor coords, so nested /
    // animated panels line their frost up with the wallpaper for free.
    property bool  autoAlign: false

    property real  radius: 22
    property color tint: Colors.base   // colour wash over the frost
    property real  tintAlpha: 0.55           // 0 = clear glass, 1 = opaque panel
    property color borderColor: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.55)
    property real  borderWidth: 1
    property real  blurAmount: 1.0           // MultiEffect blur strength (0..1)
    property bool  sheen: true               // faint top inner highlight
    property bool  shadow: true              // soft drop shadow

    // Children go here, above all the glass layers.
    default property alias content: contentSlot.data

    readonly property real _sw: screen ? screen.width  : 1920
    readonly property real _sh: screen ? screen.height : 1080

    // ── Soft drop shadow ───────────────────────────────────────────────────────
    // Cast by a separate sibling so the glass layers above never clip overflowing
    // children (e.g. nested dropdowns).
    Rectangle {
        visible: glass.shadow
        anchors.fill: parent
        radius: glass.radius
        color: "black"
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.45)
            shadowBlur: 0.9
            shadowVerticalOffset: 7
            autoPaddingEnabled: true
        }
    }

    // ── Blurred wallpaper crop, masked to the rounded shape ─────────────────────
    Item {
        id: clipBox
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: glass.blurAmount > 0
            blur: glass.blurAmount
            blurMax: 48
            blurMultiplier: 1.0
            // Keep the blur inside the surface bounds so it can't bleed past the
            // rounded mask (autoPadding would expand the effect and haze the edge).
            autoPaddingEnabled: false
            maskEnabled: true
            maskSource: maskRect
            // Crisp edge: cut right at the mask rect's own ~1px antialiased rim. A
            // wide spread here is what produced the fuzzy see-through halo at the
            // corners — this rides the mask's AA instead for a clean rounded edge.
            maskThresholdMin: 0.45
            maskSpreadAtMin: 0.05
        }

        Image {
            id: wp
            // Full-monitor crop, shifted so its (0,0) sits at the monitor origin —
            // i.e. it lines up with the real wallpaper hyprpaper paints.
            width: glass._sw
            height: glass._sh
            x: -glass.originX
            y: -glass.originY
            source: Wall.source
            fillMode: Image.PreserveAspectCrop          // matches hyprpaper "cover"
            // Decode small: the upscale alone gives a soft blur and keeps the shared
            // pixmap-cache entry tiny (every panel samples the same decoded image).
            sourceSize.width:  Math.round(glass._sw / 4)
            sourceSize.height: Math.round(glass._sh / 4)
            cache: true
            asynchronous: true
            smooth: true
        }

        // Fallback fill while the wallpaper decodes / if it's unknown, so the panel
        // never flashes fully transparent.
        Rectangle {
            anchors.fill: parent
            visible: wp.status !== Image.Ready
            color: glass.tint
        }
    }

    // Rounded mask for the frost (alpha = 1 inside the shape, 0 in the corners).
    Rectangle {
        id: maskRect
        anchors.fill: parent
        radius: glass.radius
        color: "white"
        antialiasing: true
        visible: false
        layer.enabled: true
        layer.smooth: true
    }

    // ── Colour tint over the frost ──────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: glass.radius
        color: Qt.rgba(glass.tint.r, glass.tint.g, glass.tint.b, glass.tintAlpha)
        Behavior on color { ColorAnimation { duration: 250 } }
    }

    // ── Top inner sheen ─────────────────────────────────────────────────────────
    Rectangle {
        visible: glass.sheen
        anchors.fill: parent
        radius: glass.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
            GradientStop { position: 0.18; color: Qt.rgba(1, 1, 1, 0.025) }
            GradientStop { position: 0.5; color: "transparent" }
        }
    }

    // ── Hairline border ─────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: glass.radius
        color: "transparent"
        border.color: glass.borderColor
        border.width: glass.borderWidth
    }

    // ── Content ─────────────────────────────────────────────────────────────────
    Item {
        id: contentSlot
        anchors.fill: parent
    }

    // ── Origin tracking for nested / animated surfaces ──────────────────────────
    // Map through the PARENT at this surface's layout x/y rather than mapping the
    // surface itself: a dropdown animates its own `scale` on open, and mapping the
    // scaled item makes the wallpaper crop swim/jump each frame. The parent isn't
    // scaled and x/y are the (stable) anchored position, so the frost stays put while
    // the panel pops.
    function _recompute() {
        if (!autoAlign) return
        const par = glass.parent
        const p = par ? par.mapToItem(null, glass.x, glass.y) : glass.mapToItem(null, 0, 0)
        glass.originX = p.x
        glass.originY = p.y
    }
    onAutoAlignChanged: _recompute()
    onVisibleChanged: if (visible) _recompute()   // settle origin before the first painted frame
    Component.onCompleted: _recompute()
    FrameAnimation {
        running: glass.autoAlign && glass.visible
        onTriggered: glass._recompute()
    }
}

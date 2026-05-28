pragma Singleton
import QtQuick

QtObject {
    // ── Theme state ────────────────────────────────────────────────────────────
    property bool darkMode: true

    // Emitted by toggle() so listeners in the same component tree can
    // run sync-theme.sh via their own Process objects
    signal syncRequested(bool toMocha)

    function toggle() {
        darkMode = !darkMode
        syncRequested(darkMode)
    }

    // ── Catppuccin Mocha ───────────────────────────────────────────────────────
    readonly property var _mocha: ({
        crust:     "#11111b", mantle:    "#181825", base:      "#1e1e2e",
        surface0:  "#313244", surface1:  "#45475a", surface2:  "#585b70",
        overlay0:  "#6c7086", overlay1:  "#7f849c", overlay2:  "#9399b2",
        subtext0:  "#a6adc8", subtext1:  "#bac2de", text:      "#cdd6f4",
        lavender:  "#b4befe", blue:      "#89b4fa", sapphire:  "#74c7ec",
        sky:       "#89dceb", teal:      "#94e2d5", green:     "#a6e3a1",
        yellow:    "#f9e2af", peach:     "#fab387", maroon:    "#eba0ac",
        red:       "#f38ba8", mauve:     "#cba6f7", pink:      "#f5c2e7",
        flamingo:  "#f2cdcd", rosewater: "#f5e0dc"
    })

    // ── Catppuccin Latte ───────────────────────────────────────────────────────
    readonly property var _latte: ({
        crust:     "#dce0e8", mantle:    "#e6e9ef", base:      "#eff1f5",
        surface0:  "#ccd0da", surface1:  "#bcc0cc", surface2:  "#acb0be",
        overlay0:  "#9ca0b0", overlay1:  "#8c8fa1", overlay2:  "#7c7f93",
        subtext0:  "#6c6f85", subtext1:  "#5c5f77", text:      "#4c4f69",
        lavender:  "#7287fd", blue:      "#1e66f5", sapphire:  "#209fb5",
        sky:       "#04a5e5", teal:      "#179299", green:     "#40a02b",
        yellow:    "#df8e1d", peach:     "#fe640b", maroon:    "#e64553",
        red:       "#d20f39", mauve:     "#8839ef", pink:      "#ea76cb",
        flamingo:  "#dd7878", rosewater: "#dc8a78"
    })

    // Active palette — switches reactively
    readonly property var _p: darkMode ? _mocha : _latte

    // ── Typed color properties (reactive) ─────────────────────────────────────
    readonly property color crust:     _p.crust
    readonly property color mantle:    _p.mantle
    readonly property color base:      _p.base
    readonly property color surface0:  _p.surface0
    readonly property color surface1:  _p.surface1
    readonly property color surface2:  _p.surface2
    readonly property color overlay0:  _p.overlay0
    readonly property color overlay1:  _p.overlay1
    readonly property color overlay2:  _p.overlay2
    readonly property color subtext0:  _p.subtext0
    readonly property color subtext1:  _p.subtext1
    readonly property color text:      _p.text
    readonly property color lavender:  _p.lavender
    readonly property color blue:      _p.blue
    readonly property color sapphire:  _p.sapphire
    readonly property color sky:       _p.sky
    readonly property color teal:      _p.teal
    readonly property color green:     _p.green
    readonly property color yellow:    _p.yellow
    readonly property color peach:     _p.peach
    readonly property color maroon:    _p.maroon
    readonly property color red:       _p.red
    readonly property color mauve:     _p.mauve
    readonly property color pink:      _p.pink
    readonly property color flamingo:  _p.flamingo
    readonly property color rosewater: _p.rosewater

    // ── Semantic aliases ───────────────────────────────────────────────────────
    readonly property color accent:      mauve
    readonly property color accentDim: {
        const c = Qt.color(_p.mauve)
        return Qt.rgba(c.r, c.g, c.b, 0.2)
    }
    readonly property color border:      surface1
    readonly property color borderFocus: mauve
}

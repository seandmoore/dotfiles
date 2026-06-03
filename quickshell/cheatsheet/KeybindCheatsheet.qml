import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    aboveWindows: true
    focusable: true
    color: "transparent"
    visible: false

    IpcHandler {
        target: "cheatsheet"
        function toggle() { root.visible = !root.visible }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.62)
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    // Panel
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width:  Math.min(parent.width  * 0.84, 980)
        height: Math.min(parent.height * 0.84, 700)
        color:  Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Frost.glass(0.48))
        border.color: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.45)
        border.width: 1
        radius: 20
        clip: true
        opacity: root.visible ? 1 : 0
        scale:   root.visible ? 1 : 0.93
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
        Behavior on scale   { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors { fill: parent; margins: 22 }
            spacing: 14

            // ── Header ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "󰌌"
                    font { family: "JetBrainsMono Nerd Font Propo"; pixelSize: 20 }
                    color: Colors.mauve
                }
                Text {
                    text: "Keybind Cheat Sheet"
                    font { family: "JetBrainsMono Nerd Font Propo"; pixelSize: 16; weight: Font.Medium }
                    color: Colors.text
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Esc  to close"
                    font { family: "JetBrainsMono Nerd Font Propo"; pixelSize: 11 }
                    color: Colors.overlay0
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
            }

            // ── 3-column grid ────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // ── Column 1: Applications · Workspaces · Screenshot ─────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.rightMargin: 16
                    spacing: 14

                    BindSection {
                        title: "Applications"
                        icon: "󰀻"
                        sectionColor: Colors.blue
                        binds: [
                            { keys: "󰖳 + Return",       desc: "Terminal (kitty)" },
                            { keys: "󰖳 + Space",        desc: "App launcher" },
                            { keys: "󰖳 + E",            desc: "File manager (Nautilus)" },
                            { keys: "󰖳 + B",            desc: "Browser (Firefox)" },
                            { keys: "󰖳 + W",            desc: "Wallpaper switcher" },
                            { keys: "󰖳 + G",            desc: "Theme picker" },
                        ]
                    }

                    BindSection {
                        title: "Workspaces"
                        icon: "󰕰"
                        sectionColor: Colors.sapphire
                        binds: [
                            { keys: "󰖳 + 1 – 9, 0",         desc: "Switch workspace (0 = 10)" },
                            { keys: "󰖳 + Shift + 1 – 9, 0", desc: "Move window there" },
                            { keys: "󰖳 + Scroll",           desc: "Cycle workspaces" },
                            { keys: "Scroll on bar",        desc: "Cycle on this monitor" },
                        ]
                    }

                    BindSection {
                        title: "Screenshot"
                        icon: "󰹑"
                        sectionColor: Colors.pink
                        binds: [
                            { keys: "󰖳 + S",            desc: "Area → clipboard + Screenshots" },
                            { keys: "󰖳 + Shift + S",    desc: "All monitors → Screenshots" },
                        ]
                    }

                    Item { Layout.fillHeight: true }
                }

                Rectangle {
                    width: 1; Layout.fillHeight: true
                    color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.35)
                }

                // ── Column 2: Windows · Focus · Session ──────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    spacing: 14

                    BindSection {
                        title: "Windows"
                        icon: "󰖲"
                        sectionColor: Colors.mauve
                        binds: [
                            { keys: "󰖳 + C",            desc: "Close window" },
                            { keys: "󰖳 + F",            desc: "Fullscreen" },
                            { keys: "󰖳 + V",            desc: "Float toggle" },
                            { keys: "󰖳 + P",            desc: "Pseudo tile" },
                            { keys: "󰖳 + T",            desc: "Toggle split" },
                        ]
                    }

                    BindSection {
                        title: "Focus"
                        icon: "󰁕"
                        sectionColor: Colors.green
                        binds: [
                            { keys: "󰖳 + L",            desc: "Focus right" },
                            { keys: "󰖳 + K",            desc: "Focus up" },
                            { keys: "󰖳 + J",            desc: "Focus down" },
                        ]
                    }

                    BindSection {
                        title: "Session"
                        icon: "󰍃"
                        sectionColor: Colors.red
                        binds: [
                            { keys: "󰖳 + M",            desc: "Exit Hyprland" },
                            { keys: "󰖳 + H",            desc: "Keybind cheat sheet" },
                        ]
                    }

                    BindSection {
                        title: "Display"
                        icon: "󰍹"
                        sectionColor: Colors.peach
                        binds: [
                            { keys: "󰖳 + Shift + D",    desc: "HDR ⇄ SDR (DP-1)" },
                            { keys: "󰖳 + Shift + A",    desc: "Vibrant ⇄ Standard" },
                            { keys: "󰖳 + Shift + N",    desc: "Night shift toggle" },
                        ]
                    }

                    Item { Layout.fillHeight: true }
                }

                Rectangle {
                    width: 1; Layout.fillHeight: true
                    color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.35)
                }

                // ── Column 3: Move · Resize · Media ─────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 16
                    spacing: 14

                    BindSection {
                        title: "Move Windows"
                        icon: "󰀩"
                        sectionColor: Colors.peach
                        binds: [
                            { keys: "󰖳 + Shift + H",    desc: "Move left" },
                            { keys: "󰖳 + Shift + L",    desc: "Move right" },
                            { keys: "󰖳 + Shift + K",    desc: "Move up" },
                            { keys: "󰖳 + Shift + J",    desc: "Move down" },
                        ]
                    }

                    BindSection {
                        title: "Resize"
                        icon: "󰩈"
                        sectionColor: Colors.yellow
                        binds: [
                            { keys: "󰖳 + Alt + H",      desc: "Shrink width" },
                            { keys: "󰖳 + Alt + L",      desc: "Grow width" },
                            { keys: "󰖳 + Alt + K",      desc: "Shrink height" },
                            { keys: "󰖳 + Alt + J",      desc: "Grow height" },
                        ]
                    }

                    BindSection {
                        title: "Media"
                        icon: "󰝚"
                        sectionColor: Colors.teal
                        binds: [
                            { keys: "Vol ↑",             desc: "Volume up" },
                            { keys: "Vol ↓",             desc: "Volume down" },
                            { keys: "Mute",              desc: "Mute toggle" },
                            { keys: "⏯",                desc: "Play / Pause" },
                            { keys: "⏭",                desc: "Next track" },
                            { keys: "⏮",                desc: "Previous track" },
                            { keys: "Bright ↑",          desc: "Brightness up" },
                            { keys: "Bright ↓",          desc: "Brightness down" },
                        ]
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}

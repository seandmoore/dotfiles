import QtQuick
import Quickshell
import Quickshell.Wayland

// Entry point — Quickshell loads this file automatically.
// Each ShellRoot child is a top-level surface.
ShellRoot {
    // One bar per screen
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            Bar { anchors.fill: parent }
        }
    }

    // Notification daemon (singleton — one per compositor session)
    NotificationServer {}

    // OSD listeners (singleton)
    OsdRoot {}

    // App launcher (fullscreen overlay, hidden by default)
    Launcher {}
}

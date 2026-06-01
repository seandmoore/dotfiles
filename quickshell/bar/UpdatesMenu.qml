import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"

// Bell-style dropdown for system updates: a per-source breakdown (official repos,
// AUR via yay/paru, Flatpak) with live counts, a refresh control, and an
// "Update All" button that opens an interactive terminal upgrade.
ColumnLayout {
    id: upMenu
    spacing: 6

    signal acted()

    // One source row: icon + label, with a count pill (or a check when clear).
    component SourceRow: Rectangle {
        property string label: ""
        property string icon: ""
        property color accent: Colors.text
        property int count: 0

        Layout.fillWidth: true
        Layout.preferredHeight: 36
        radius: 10
        color: count > 0
            ? Qt.rgba(accent.r, accent.g, accent.b, 0.12)
            : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.4)
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
            spacing: 10
            Text {
                text: icon
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 14
                color: accent
            }
            Text {
                text: label
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                Layout.fillWidth: true
            }
            // Count pill, or a check mark when nothing to do
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                visible: count > 0
                implicitWidth: cnt.implicitWidth + 14
                height: 20
                radius: 10
                color: Qt.rgba(parent.parent.accent.r, parent.parent.accent.g, parent.parent.accent.b, 0.9)
                Text {
                    id: cnt
                    anchors.centerIn: parent
                    text: count
                    color: Colors.base
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }
            Text {
                visible: count === 0
                text: "󰄬"
                color: Colors.green
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
            }
        }
    }

    // ── Header ───────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            text: "󰚰"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            color: Updates.total > 0 ? Colors.peach : Colors.green
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        Text {
            text: "System Updates"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Colors.subtext1
            Layout.fillWidth: true
        }
        // Refresh — spins while checking
        Text {
            text: "󰑐"
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 13
            color: refMa.containsMouse ? Colors.sky : Colors.overlay1
            Behavior on color { ColorAnimation { duration: 120 } }
            RotationAnimation on rotation {
                from: 0; to: 360; duration: 900
                loops: Animation.Infinite
                running: Updates.checking
                onStopped: rotation = 0
            }
            MouseArea {
                id: refMa
                anchors.fill: parent
                anchors.margins: -5
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Updates.check()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
    }

    // ── Status line ──────────────────────────────────────────────────────────
    Text {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        topPadding: 2
        text: Updates.checking ? "Checking for updates…"
            : Updates.total === 0 ? "Your system is up to date"
            : Updates.total + (Updates.total === 1 ? " update available" : " updates available")
        color: Updates.total > 0 ? Colors.peach : Colors.overlay1
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 11
    }

    // ── Per-source breakdown ─────────────────────────────────────────────────
    SourceRow { label: "Official repos"; icon: "󰏖"; accent: Colors.blue; count: Updates.repo }
    SourceRow {
        label: "AUR" + (Updates.helper !== "" ? " (" + Updates.helper + ")" : "")
        icon: "󰣇"; accent: Colors.sky; count: Updates.aur
    }
    SourceRow { label: "Flatpak"; icon: "󰏗"; accent: Colors.teal; count: Updates.flatpak }

    // ── Update All ───────────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 2
        Layout.preferredHeight: 38
        radius: 10
        enabled: !Updates.updating
        opacity: Updates.updating ? 0.6 : 1
        color: upMa.containsMouse && !Updates.updating
            ? Qt.rgba(Colors.mauve.r, Colors.mauve.g, Colors.mauve.b, 0.9)
            : Qt.rgba(Colors.mauve.r, Colors.mauve.g, Colors.mauve.b, 0.7)
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: Updates.updating ? "󰦖" : "󰓦"
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 13
                color: Colors.base
            }
            Text {
                text: Updates.updating ? "Updating…"
                    : Updates.total > 0 ? ("Update All (" + Updates.total + ")")
                    : "Update / Sync"
                color: Colors.base
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: upMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: !Updates.updating
            onClicked: { Updates.update(); upMenu.acted() }
        }
    }
}

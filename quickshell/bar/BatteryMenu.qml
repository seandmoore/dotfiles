import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"

// Battery dropdown — big charge %, a themed charge bar, time-to-full/empty, and
// power draw + health when the kernel exposes them. Pure Colors.* styling, so it
// re-tints with the Mocha/Latte switch like every other menu.
ColumnLayout {
    id: menu
    spacing: 12

    readonly property color levelColor: Battery.charging ? Colors.green
        : Battery.low ? Colors.red
        : Battery.percent <= 30 ? Colors.yellow
        : Colors.teal

    // ── Header: icon · label · big percentage ────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
            text: Battery.icon
            color: menu.levelColor
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 24
            Behavior on color { ColorAnimation { duration: 250 } }
        }
        Text {
            text: "Battery"
            color: Colors.subtext0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            Layout.fillWidth: true
        }
        Text {
            text: Battery.percent + "%"
            color: Colors.text
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 22
            font.weight: Font.Bold
        }
    }

    // ── Charge bar ───────────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 9
        radius: 4.5
        color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.7)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, Battery.percent / 100))
            height: parent.height
            radius: 4.5
            color: menu.levelColor
            Behavior on width { NumberAnimation { duration: 250 } }
            Behavior on color { ColorAnimation { duration: 250 } }
        }
    }

    // ── Status · time remaining ──────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: Battery.status
            color: Colors.subtext1
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            Layout.fillWidth: true
        }
        Text {
            text: Battery.timeText
            visible: Battery.timeText !== ""
            color: Colors.overlay1
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 13
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
        visible: drawRow.visible || healthRow.visible
    }

    // ── Power draw ───────────────────────────────────────────────────────────
    RowLayout {
        id: drawRow
        Layout.fillWidth: true
        visible: Battery.power > 0
        Text {
            text: "Power draw"
            color: Colors.subtext1
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            Layout.fillWidth: true
        }
        Text {
            text: Battery.power.toFixed(1) + " W"
            color: Colors.overlay1
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 13
        }
    }

    // ── Health (full ÷ design capacity) ──────────────────────────────────────
    RowLayout {
        id: healthRow
        Layout.fillWidth: true
        visible: Battery.health > 0
        Text {
            text: "Health"
            color: Colors.subtext1
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            Layout.fillWidth: true
        }
        Text {
            text: Battery.health + "%"
            color: Battery.health < 70 ? Colors.peach : Colors.overlay1
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 13
        }
    }
}

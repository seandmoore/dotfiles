import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

// Battery indicator — only appears on hardware that actually has a battery.
// It polls /sys/class/power_supply/BAT* (the same approach SystemStats uses for
// /proc); on a desktop the poll prints nothing, `percent` stays -1, and the
// whole widget collapses out of the pill, so the bar is unchanged there.
RowLayout {
    id: root
    spacing: 6
    Layout.alignment: Qt.AlignVCenter
    visible: percent >= 0

    property int    percent: -1
    property string status: ""
    readonly property bool charging: status === "Charging" || status === "Full"
    readonly property bool low: percent >= 0 && percent <= 15 && !charging

    // Nerd Font mdi battery glyphs: a charging bolt, or a fill ramp 10→100.
    function battIcon(p, chg) {
        if (chg)       return "󰂄"
        if (p >= 95)   return "󰁹"
        if (p >= 90)   return "󰂂"
        if (p >= 80)   return "󰂁"
        if (p >= 70)   return "󰂀"
        if (p >= 60)   return "󰁿"
        if (p >= 50)   return "󰁾"
        if (p >= 40)   return "󰁽"
        if (p >= 30)   return "󰁼"
        if (p >= 20)   return "󰁻"
        if (p >= 10)   return "󰁺"
        return "󰂎"
    }

    readonly property color tint: low ? Colors.red
        : charging ? Colors.green
        : Colors.text

    Text {
        text: root.battIcon(root.percent, root.charging)
        color: root.tint
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 17
        Layout.alignment: Qt.AlignVCenter
        Behavior on color { ColorAnimation { duration: 250 } }
    }

    Text {
        text: root.percent + "%"
        color: root.low ? Colors.red : Colors.subtext1
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 15
        Layout.alignment: Qt.AlignVCenter
    }

    // First battery with a capacity file wins; prints "<percent> <status>".
    Process {
        id: battProc
        command: ["bash", "-c",
            "for b in /sys/class/power_supply/BAT*; do " +
            "[ -r \"$b/capacity\" ] && echo \"$(cat \"$b/capacity\") $(cat \"$b/status\")\" && break; done"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(/\s+/)
                const p = parseInt(parts[0])
                if (!isNaN(p)) {
                    root.percent = p
                    root.status  = parts[1] || ""
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: battProc.running = true
    }
}

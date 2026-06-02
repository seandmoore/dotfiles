import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

// Per-core CPU load + RAM/Swap usage. Polls /proc only while mounted, i.e. while
// the dropdown is open (HoverPanel loads this lazily and unloads it on close).
ColumnLayout {
    id: sys
    spacing: 8

    property var cores: []              // [{ name, pct }]
    property var prevIdle: ({})
    property var prevTotal: ({})

    property real ramUsed: 0
    property real ramTotal: 0
    property real swapUsed: 0
    property real swapTotal: 0

    function tint(p) {
        return p > 85 ? Colors.red : p > 60 ? Colors.yellow : Colors.green
    }

    Text {
        text: "System"
        color: Colors.subtext0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 13; font.weight: Font.Bold
    }

    // ── Per-core CPU ───────────────────────────────────────────────────────────
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 5
        columnSpacing: 12

        Repeater {
            model: sys.cores
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "C" + modelData.name
                    color: Colors.overlay1
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 13
                    Layout.preferredWidth: 22
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 6; radius: 3
                    color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.7)
                    Rectangle {
                        width: parent.width * Math.min(1, modelData.pct / 100)
                        height: parent.height; radius: 3
                        color: sys.tint(modelData.pct)
                        Behavior on width { NumberAnimation { duration: 250 } }
                    }
                }
                Text {
                    text: Math.round(modelData.pct) + "%"
                    color: Colors.subtext1
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 30
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true; height: 1
        color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
    }

    // ── Memory bar ─────────────────────────────────────────────────────────────
    component UsageBar: ColumnLayout {
        property string label: ""
        property real used: 0
        property real total: 0
        property color barColor: Colors.blue
        Layout.fillWidth: true
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: label; color: Colors.subtext1
                font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 14
                Layout.fillWidth: true
            }
            Text {
                text: used.toFixed(1) + " / " + total.toFixed(1) + " GB"
                color: Colors.overlay1
                font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 13
            }
        }
        Rectangle {
            Layout.fillWidth: true
            height: 7; radius: 3.5
            color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.7)
            Rectangle {
                width: parent.width * (total > 0 ? Math.min(1, used / total) : 0)
                height: parent.height; radius: 3.5
                color: barColor
                Behavior on width { NumberAnimation { duration: 250 } }
            }
        }
    }

    UsageBar {
        label: "RAM"; used: sys.ramUsed; total: sys.ramTotal
        barColor: (sys.ramTotal > 0 && sys.ramUsed / sys.ramTotal > 0.85) ? Colors.red : Colors.blue
    }
    UsageBar {
        label: "Swap"; used: sys.swapUsed; total: sys.swapTotal
        barColor: Colors.mauve
        visible: sys.swapTotal > 0
    }

    // ── Polling ────────────────────────────────────────────────────────────────
    Process {
        id: cpuProc
        command: ["bash", "-c", "grep -E '^cpu[0-9]+ ' /proc/stat"]
        property var tmp: []
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(/\s+/)
                const name = parts[0].replace("cpu", "")
                const nums = parts.slice(1).map(Number)
                const idle = nums[3] + (nums[4] || 0)
                const total = nums.reduce((a, b) => a + b, 0)
                const pIdle = sys.prevIdle[name] || 0
                const pTotal = sys.prevTotal[name] || 0
                const dIdle = idle - pIdle
                const dTotal = total - pTotal
                const pct = dTotal > 0 ? (1 - dIdle / dTotal) * 100 : 0
                sys.prevIdle[name] = idle
                sys.prevTotal[name] = total
                cpuProc.tmp.push({ name: name, pct: Math.max(0, Math.min(100, pct)) })
            }
        }
        onRunningChanged: {
            if (!running && tmp.length > 0) { sys.cores = tmp; tmp = [] }
        }
    }

    Process {
        id: memProc
        command: ["bash", "-c", "grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo"]
        property var vals: ({})
        stdout: SplitParser {
            onRead: line => {
                const p = line.split(/\s+/)
                memProc.vals[p[0].replace(":", "")] = parseInt(p[1])   // kB
            }
        }
        onRunningChanged: {
            if (!running) {
                const v = memProc.vals
                if (v.MemTotal) {
                    sys.ramTotal = v.MemTotal / 1048576
                    sys.ramUsed  = (v.MemTotal - (v.MemAvailable || 0)) / 1048576
                }
                if (v.SwapTotal !== undefined) {
                    sys.swapTotal = v.SwapTotal / 1048576
                    sys.swapUsed  = (v.SwapTotal - (v.SwapFree || 0)) / 1048576
                }
                memProc.vals = ({})
            }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { cpuProc.running = true; memProc.running = true }
    }
}

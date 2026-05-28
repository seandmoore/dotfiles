import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

RowLayout {
    id: root
    spacing: 14

    // CPU
    RowLayout {
        spacing: 4

        Text {
            text: "󰍛"
            color: cpuValue > 80 ? Colors.red : cpuValue > 50 ? Colors.yellow : Colors.green
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
        }
        Text {
            id: cpuLabel
            text: cpuValue + "%"
            color: Colors.subtext1
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
        }
    }

    // RAM
    RowLayout {
        spacing: 4

        Text {
            text: "󰧑"
            color: ramPercent > 85 ? Colors.red : ramPercent > 60 ? Colors.yellow : Colors.blue
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
        }
        Text {
            id: ramLabel
            text: ramUsed + " GB"
            color: Colors.subtext1
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
        }
    }

    property int cpuValue: 0
    property int ramPercent: 0
    property string ramUsed: "0.0"

    property var _prevIdle: 0
    property var _prevTotal: 0

    // CPU polling
    Process {
        id: cpuProcess
        command: ["bash", "-c", "cat /proc/stat | head -1"]
        running: false

        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(/\s+/)
                if (parts[0] !== "cpu") return
                const nums = parts.slice(1).map(Number)
                const idle = nums[3] + nums[4]
                const total = nums.reduce((a, b) => a + b, 0)
                const dIdle  = idle  - root._prevIdle
                const dTotal = total - root._prevTotal
                if (dTotal > 0)
                    cpuValue = Math.round((1 - dIdle / dTotal) * 100)
                root._prevIdle  = idle
                root._prevTotal = total
            }
        }
    }

    // RAM polling
    Process {
        id: ramProcess
        command: ["bash", "-c", "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        running: false

        property var lines: []

        stdout: SplitParser {
            onRead: line => {
                ramProcess.lines.push(line)
                if (ramProcess.lines.length >= 2) {
                    const total = parseInt(ramProcess.lines[0].split(/\s+/)[1])
                    const avail = parseInt(ramProcess.lines[1].split(/\s+/)[1])
                    const used  = (total - avail) / 1048576
                    ramUsed    = used.toFixed(1)
                    ramPercent = Math.round((1 - avail / total) * 100)
                    ramProcess.lines = []
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProcess.running = true
            ramProcess.running = true
        }
    }
}

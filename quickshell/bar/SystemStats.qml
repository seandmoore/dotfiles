import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

RowLayout {
    id: root
    spacing: 14
    opacity: 1
    scale: 1

    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }

    Component.onCompleted: {
        opacity = 0
        scale = 0.9
        opacity = 1
        scale = 1
    }

    // ── Canvas colour helpers (Canvas rejects the #aarrggbb form) ─────────────
    function hx(v) {
        const s = Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16)
        return s.length < 2 ? "0" + s : s
    }
    function hex(c) { return "#" + hx(c.r) + hx(c.g) + hx(c.b) }
    function rgba(c, a) {
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255)
             + "," + Math.round(c.b * 255) + "," + a + ")"
    }

    // ── A compact rolling-history sparkline: icon · graph · current value ─────
    // `push(v)` appends a 0..100 sample; the newest point is pinned at the right
    // edge and the trace scrolls left as history fills. Colour follows `tint`.
    component StatGraph: RowLayout {
        id: sg
        property string icon: ""
        property color  tint: Colors.green
        property string label: ""
        property var    history: []
        readonly property int maxPoints: 40

        spacing: 6

        function push(v) {
            const h = sg.history.slice()
            h.push(Math.max(0, Math.min(100, v)))
            while (h.length > sg.maxPoints) h.shift()
            sg.history = h
            graph.requestPaint()
        }

        Text {
            text: sg.icon
            color: sg.tint
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 48
            implicitHeight: 22
            radius: 5
            color: Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.45)

            Canvas {
                id: graph
                anchors.fill: parent
                anchors.margins: 2

                onPaint: {
                    const ctx = getContext("2d")
                    const w = width, h = height
                    ctx.clearRect(0, 0, w, h)

                    const hist = sg.history
                    const n = hist.length
                    if (n < 2) return

                    const step = w / (sg.maxPoints - 1)
                    const xs = [], ys = []
                    for (let i = 0; i < n; i++) {
                        xs.push(w - (n - 1 - i) * step)
                        const a = Math.max(0, Math.min(100, hist[i])) / 100
                        ys.push(h - a * (h - 2) - 1)
                    }

                    // Smooth trace via quadratic curves through sample midpoints.
                    function trace() {
                        ctx.moveTo(xs[0], ys[0])
                        for (let i = 0; i < n - 1; i++)
                            ctx.quadraticCurveTo(xs[i], ys[i],
                                (xs[i] + xs[i + 1]) / 2, (ys[i] + ys[i + 1]) / 2)
                        ctx.lineTo(xs[n - 1], ys[n - 1])
                    }

                    // Filled area under the curve, fading downward.
                    ctx.beginPath()
                    trace()
                    ctx.lineTo(xs[n - 1], h)
                    ctx.lineTo(xs[0], h)
                    ctx.closePath()
                    const g = ctx.createLinearGradient(0, 0, 0, h)
                    g.addColorStop(0, root.rgba(sg.tint, 0.55))
                    g.addColorStop(1, root.rgba(sg.tint, 0.05))
                    ctx.fillStyle = g
                    ctx.fill()

                    // Stroke the line on top.
                    ctx.beginPath()
                    trace()
                    ctx.lineWidth = 1.5
                    ctx.lineJoin = "round"
                    ctx.strokeStyle = root.hex(sg.tint)
                    ctx.stroke()
                }
            }
        }

        Text {
            text: sg.label
            color: Colors.subtext1
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // ── CPU — graph height & value are % load ────────────────────────────────
    StatGraph {
        id: cpuStat
        icon: "󰍛"
        label: root.cpuValue + "%"
        tint: root.cpuValue > 80 ? Colors.red : root.cpuValue > 50 ? Colors.yellow : Colors.green
    }

    // ── RAM — graph height is % used, value is GB used ───────────────────────
    StatGraph {
        id: ramStat
        icon: "󰧑"
        label: root.ramUsed + " GB"
        tint: root.ramPercent > 85 ? Colors.red : root.ramPercent > 60 ? Colors.yellow : Colors.blue
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
                if (dTotal > 0) {
                    cpuValue = Math.round((1 - dIdle / dTotal) * 100)
                    cpuStat.push(cpuValue)
                }
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
                    ramStat.push(ramPercent)
                    ramProcess.lines = []
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProcess.running = true
            ramProcess.running = true
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

// Fluid audio wave driven by `cava`. Always visible: it flows like liquid when
// idle (layered travelling sines) and swells to the spectrum when audio plays.
// Drawn as a smooth symmetric ribbon filled with a Catppuccin rainbow.
Item {
    id: root

    readonly property int points: 26
    property var levels: []        // raw 0..1 values from cava
    property var display: []       // eased values actually drawn (fluidity)
    property bool hasSound: false
    property real phase: 0         // idle-motion phase

    implicitWidth: 96
    implicitHeight: 30

    // color → "#rrggbb" (Canvas gradients reject the ARGB form)
    function hx(v) {
        const s = Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16)
        return s.length < 2 ? "0" + s : s
    }
    function hex(c) { return "#" + hx(c.r) + hx(c.g) + hx(c.b) }

    // ~60fps: ease `display` toward targets (fluid) + advance the idle flow
    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            root.phase += 0.045
            if (root.display.length !== root.points) {
                const init = []
                for (let i = 0; i < root.points; i++) init.push(0)
                root.display = init
            }
            const d = root.display.slice()
            for (let i = 0; i < root.points; i++) {
                // Layered travelling sines → an organic, liquid idle swell
                const idle = 0.30
                    + 0.26 * Math.sin(root.phase + i * 0.40)
                    + 0.13 * Math.sin(root.phase * 1.7 + i * 0.85)
                const want = root.hasSound
                    ? Math.min(1, Math.max(root.levels[i] ?? 0, 0.06) * 1.15)
                    : Math.max(0.05, idle)
                d[i] += (want - d[i]) * 0.20
            }
            root.display = d
            canvas.requestPaint()
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d")
            const w = width, h = height
            ctx.clearRect(0, 0, w, h)

            const n = root.display.length
            if (n < 2) return

            const cy = h / 2
            const amp = h / 2 - 1
            const xs = [], top = [], bot = []
            for (let i = 0; i < n; i++) {
                xs.push(i / (n - 1) * w)
                const a = Math.max(0.03, Math.min(1, root.display[i] ?? 0))
                top.push(cy - a * amp)
                bot.push(cy + a * amp)
            }

            // Smooth symmetric ribbon: top edge L→R, bottom edge R→L, via
            // quadratic curves through the midpoints of adjacent samples.
            ctx.beginPath()
            ctx.moveTo(xs[0], top[0])
            for (let i = 0; i < n - 1; i++)
                ctx.quadraticCurveTo(xs[i], top[i], (xs[i] + xs[i + 1]) / 2, (top[i] + top[i + 1]) / 2)
            ctx.lineTo(xs[n - 1], top[n - 1])
            ctx.lineTo(xs[n - 1], bot[n - 1])
            for (let i = n - 1; i > 0; i--)
                ctx.quadraticCurveTo(xs[i], bot[i], (xs[i] + xs[i - 1]) / 2, (bot[i] + bot[i - 1]) / 2)
            ctx.lineTo(xs[0], bot[0])
            ctx.closePath()

            const g = ctx.createLinearGradient(0, 0, w, 0)
            g.addColorStop(0.00, root.hex(Colors.mauve))
            g.addColorStop(0.18, root.hex(Colors.pink))
            g.addColorStop(0.34, root.hex(Colors.red))
            g.addColorStop(0.50, root.hex(Colors.peach))
            g.addColorStop(0.64, root.hex(Colors.yellow))
            g.addColorStop(0.78, root.hex(Colors.green))
            g.addColorStop(0.90, root.hex(Colors.sky))
            g.addColorStop(1.00, root.hex(Colors.blue))

            ctx.globalAlpha = 0.92
            ctx.fillStyle = g
            ctx.fill()
        }
    }

    Process {
        id: cava
        command: ["cava", "-p", "/home/seanmoore/dotfiles/quickshell/bar/cava.conf"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";").filter(s => s !== "")
                if (parts.length === 0) return
                root.levels = parts.map(v => (parseInt(v) || 0) / 100)
                if (Math.max.apply(null, root.levels) > 0.05) {
                    root.hasSound = true
                    lingerTimer.restart()
                }
            }
        }
    }

    Timer {
        id: lingerTimer
        interval: 1000
        onTriggered: root.hasSound = false
    }
}

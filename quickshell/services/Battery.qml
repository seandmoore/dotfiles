pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Battery state, polled from /sys/class/power_supply/BAT* (the same approach the
// other widgets use for /proc and /sys). `present` is false on machines without
// a battery — the bar uses that to hide the indicator entirely on the desktop.
// Exposes everything the indicator and its dropdown need from one source so they
// always agree: charge %, charging state, an icon, time-to-full/empty, power
// draw, and battery health.
QtObject {
    id: svc

    property bool   present: false
    property int    percent: 0
    property string status: "Unknown"
    property real   power: 0          // current draw, watts
    property int    health: 0         // full / design capacity, %
    property string timeText: ""      // "1h 23m left" / "45m to full" / ""

    readonly property bool charging: status === "Charging" || status === "Full"
    readonly property bool low: present && percent <= 15 && !charging

    // Nerd Font mdi battery glyphs: a charging bolt, or a fill ramp 10→100.
    readonly property string icon: charging ? "󰂄"
        : percent >= 95 ? "󰁹" : percent >= 90 ? "󰂂" : percent >= 80 ? "󰂁"
        : percent >= 70 ? "󰂀" : percent >= 60 ? "󰁿" : percent >= 50 ? "󰁾"
        : percent >= 40 ? "󰁽" : percent >= 30 ? "󰁼" : percent >= 20 ? "󰁻"
        : percent >= 10 ? "󰁺" : "󰂎"

    function _num(v) { const x = parseFloat(v); return isNaN(x) ? 0 : x }

    // First battery with a capacity file wins; emit "key=value" for whichever
    // sysfs fields exist (kernels expose either energy_* or charge_* + voltage).
    property Process proc: Process {
        command: ["bash", "-c",
            "b=''; for d in /sys/class/power_supply/BAT*; do [ -r \"$d/capacity\" ] && b=\"$d\" && break; done; " +
            "[ -z \"$b\" ] && exit 0; echo present=1; " +
            "for k in capacity status energy_now energy_full energy_full_design " +
            "power_now charge_now charge_full charge_full_design current_now voltage_now; do " +
            "[ -r \"$b/$k\" ] && echo \"$k=$(cat \"$b/$k\" 2>/dev/null)\"; done"]
        running: false

        property var tmp: ({})

        stdout: SplitParser {
            onRead: line => {
                const eq = line.indexOf("=")
                if (eq > 0) svc.proc.tmp[line.slice(0, eq)] = line.slice(eq + 1).trim()
            }
        }

        onRunningChanged: {
            if (running) { tmp = ({}); return }

            const t = tmp
            if (!t.present) { svc.present = false; return }

            svc.present = true
            svc.percent = Math.round(svc._num(t.capacity))
            svc.status  = t.status || "Unknown"

            const volt = svc._num(t.voltage_now)   // µV

            // Power draw (µW): prefer power_now, else current_now × voltage_now.
            let powerUw = svc._num(t.power_now)
            if (powerUw <= 0 && t.current_now && volt)
                powerUw = svc._num(t.current_now) * volt / 1e6
            svc.power = powerUw / 1e6

            // Energy (µWh): prefer energy_*, else charge_* × voltage_now.
            let eNow        = svc._num(t.energy_now)
            let eFull       = svc._num(t.energy_full)
            let eFullDesign = svc._num(t.energy_full_design)
            if (eNow <= 0        && t.charge_now         && volt) eNow        = svc._num(t.charge_now) * volt / 1e6
            if (eFull <= 0       && t.charge_full        && volt) eFull       = svc._num(t.charge_full) * volt / 1e6
            if (eFullDesign <= 0 && t.charge_full_design && volt) eFullDesign = svc._num(t.charge_full_design) * volt / 1e6

            svc.health = eFullDesign > 0 ? Math.round(eFull / eFullDesign * 100) : 0

            // Time to full / empty from energy ÷ power.
            let hours = 0
            if (powerUw > 0)
                hours = svc.charging ? (eFull - eNow) / powerUw : eNow / powerUw

            if (svc.status === "Full" || svc.percent >= 100) {
                svc.timeText = "Fully charged"
            } else if (hours > 0) {
                const mins = Math.round(hours * 60)
                const h = Math.floor(mins / 60), m = mins % 60
                const hm = (h > 0 ? h + "h " : "") + m + "m"
                svc.timeText = hm + (svc.charging ? " to full" : " left")
            } else {
                svc.timeText = ""
            }
        }
    }

    // Refresh on startup and every 10 seconds.
    property Timer poll: Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: svc.proc.running = true
    }
}

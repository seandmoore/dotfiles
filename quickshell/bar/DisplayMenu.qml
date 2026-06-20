import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

// Display detail controls, embedded in the Quick Settings "Display" tile. The on/off
// quick toggles (HDR, Night Shift) live in the main grid; this is the fine tuning:
//   • Vibrant / Standard colour  (display-color.sh — works for the current HDR or SDR mode)
//   • Auto night  (sunset → sunrise, night-shift.sh auto)
//   • Night-shift temperature slider (commits on release to avoid spamming the script)
// Reads live state from the Surface singleton.
ColumnLayout {
    id: dm
    spacing: 12

    Process { id: modeProc;  onRunningChanged: if (!running) Surface.refresh() }
    Process { id: nightProc; onRunningChanged: if (!running) Surface.refresh() }

    function setMode(hdr, vib) {
        modeProc.command = ["bash", "-c",
            "\"$HOME/dotfiles/scripts/display-color.sh\" set " + hdr + " " + vib]
        modeProc.running = true
    }
    function night(arg) {
        nightProc.command = ["bash", "-c",
            "\"$HOME/dotfiles/scripts/night-shift.sh\" " + arg]
        nightProc.running = true
    }

    // reusable label + subtitle + trailing toggle row
    component ToggleRow: RowLayout {
        id: row
        property string label: ""
        property string sub: ""
        property bool on: false
        property color accent: Colors.accent
        signal toggled()
        Layout.fillWidth: true
        spacing: 10
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                text: row.label
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 13
            }
            Text {
                visible: row.sub !== ""
                text: row.sub
                color: Colors.overlay1
                font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 11
            }
        }
        QsToggle {
            on: row.on
            accent: row.accent
            onToggled: row.toggled()
        }
    }

    // ── Vibrant / Standard colour ──────────────────────────────────────────────
    ToggleRow {
        label: "Vibrant"
        sub: on ? (Surface.hdrOn ? "max saturation" : "wide gamut") : "accurate sRGB"
        accent: Colors.pink
        on: Surface.vibrant
        // display-color.sh applies vibrant/standard within whichever mode (HDR/SDR) is live
        onToggled: dm.setMode(Surface.hdrOn ? "hdr" : "sdr", Surface.vibrant ? "standard" : "vibrant")
    }

    // ── Auto night schedule ────────────────────────────────────────────────────
    ToggleRow {
        label: "Auto night"
        sub: "sunset → sunrise"
        accent: Colors.peach
        on: Surface.nightAuto
        onToggled: dm.night(Surface.nightAuto ? "auto off" : "auto on")
    }

    // ── Night-shift temperature ────────────────────────────────────────────────
    QsSlider {
        id: temp
        readonly property int tMin: 2500
        readonly property int tMax: 6500
        function kelvin(frac) { return Math.round((tMin + Math.max(0, Math.min(1, frac)) * (tMax - tMin)) / 100) * 100 }

        icon: "󰖔"
        tint: Colors.peach
        value: (Surface.nightTemp - tMin) / (tMax - tMin)
        valueText: temp.kelvin(temp.shown) + "K"
        onReleased: (f) => dm.night("temp " + temp.kelvin(f))
    }
}

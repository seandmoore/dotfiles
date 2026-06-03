import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

// DP-1 colour controls: night shift (toggle + temperature slider) and HDR/SDR
// submenus, each with vibrant/standard. Reads live state from the Frost singleton
// and drives scripts/{display-color,night-shift}.sh. Used as the dropdown content of
// the bar's Display HoverMenuButton.
ColumnLayout {
    id: dm
    Layout.fillWidth: true
    spacing: 12

    // ── command runners ────────────────────────────────────────────────────────
    Process { id: modeProc;  onRunningChanged: if (!running) Frost.refresh() }
    Process { id: nightProc; onRunningChanged: if (!running) Frost.refresh() }

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

    function sectionLabel(t) { return t }

    // ── reusable option row (vibrant / standard) ────────────────────────────────
    component OptionRow: Rectangle {
        id: orow
        property string label: ""
        property string sub: ""
        property bool active: false
        property color accent: Colors.peach
        signal chosen()

        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.preferredHeight: 38
        radius: 8
        color: active
            ? Qt.rgba(accent.r, accent.g, accent.b, 0.22)
            : (orMa.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.8) : "transparent")
        Behavior on color { ColorAnimation { duration: 100 } }

        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 8
            Text {
                text: orow.label
                font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 15
                color: Colors.text; Layout.fillWidth: true
            }
            Text {
                text: orow.sub
                font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 12
                color: Colors.overlay1
            }
            Text {
                visible: orow.active
                text: "󰄬"
                font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 14
                color: orow.accent
            }
        }
        MouseArea {
            id: orMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: orow.chosen()
        }
    }

    // ── collapsible HDR/SDR section ─────────────────────────────────────────────
    component ModeSection: ColumnLayout {
        id: sect
        property string title: ""
        property string subtitle: ""
        property string icon: ""
        property string keyword: "hdr"          // "hdr" | "sdr"
        property bool isActiveGroup: false       // is this the live mode group?
        property bool expanded: false
        Layout.fillWidth: true
        spacing: 4

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: 8
            color: sect.isActiveGroup
                ? Qt.rgba(Colors.peach.r, Colors.peach.g, Colors.peach.b, 0.16)
                : (hdMa.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.8) : "transparent")
            Behavior on color { ColorAnimation { duration: 100 } }

            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 10
                Text {
                    text: sect.icon
                    font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 18
                    color: Colors.peach
                }
                Text {
                    text: sect.title
                    font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 16
                    color: Colors.text; Layout.fillWidth: true
                }
                Text {
                    text: sect.subtitle
                    font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 12
                    color: Colors.overlay1
                }
                Text {
                    text: "󰅂"                     // chevron, rotates when expanded
                    font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 14
                    color: Colors.subtext0
                    rotation: sect.expanded ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 150 } }
                }
            }
            MouseArea {
                id: hdMa; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sect.expanded = !sect.expanded
            }
        }

        OptionRow {
            visible: sect.expanded
            label: "Vibrant"
            sub: sect.keyword === "hdr" ? "saturation 1.3" : "wide gamut"
            active: sect.isActiveGroup && Frost.vibrant
            onChosen: dm.setMode(sect.keyword, "vibrant")
        }
        OptionRow {
            visible: sect.expanded
            label: "Standard"
            sub: sect.keyword === "hdr" ? "true sRGB" : "accurate sRGB"
            active: sect.isActiveGroup && !Frost.vibrant
            onChosen: dm.setMode(sect.keyword, "standard")
        }
    }

    // ── NIGHT SHIFT ──────────────────────────────────────────────────────────────
    Text {
        text: "Night shift"
        color: Colors.subtext0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 13; font.weight: Font.Bold
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
            text: "󰖔"
            font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 17
            color: Frost.nightOn ? Colors.peach : Colors.overlay1
        }
        Text {
            text: Frost.nightOn ? (Frost.nightTemp + "K") : "Off"
            font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 15
            color: Colors.text; Layout.fillWidth: true
        }
        // toggle switch
        Rectangle {
            width: 42; height: 22; radius: 11
            color: Frost.nightOn ? Colors.peach : Colors.surface1
            Behavior on color { ColorAnimation { duration: 150 } }
            Rectangle {
                width: 16; height: 16; radius: 8; color: Colors.base
                anchors.verticalCenter: parent.verticalCenter
                x: Frost.nightOn ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: dm.night("toggle")
            }
        }
    }

    // temperature slider (warmer = lower Kelvin)
    Item {
        id: tempSlider
        Layout.fillWidth: true
        height: 18
        readonly property int tMin: 2500
        readonly property int tMax: 6500
        property bool dragging: false
        property int dragTemp: Frost.nightTemp
        readonly property int shownTemp: dragging ? dragTemp : Frost.nightTemp
        readonly property real frac: (shownTemp - tMin) / (tMax - tMin)
        function tempAt(x, w) {
            var f = Math.max(0, Math.min(1, x / w))
            return Math.round((tMin + f * (tMax - tMin)) / 100) * 100
        }

        Rectangle {
            id: tTrack
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 6; radius: 3
            color: Colors.surface1
            Rectangle {
                width: parent.width * tempSlider.frac
                height: parent.height; radius: 3
                color: Colors.peach
                Behavior on width { NumberAnimation { duration: 60 } }
            }
        }
        Rectangle {
            width: 14; height: 14; radius: 7
            color: Colors.text; border.color: Colors.surface2; border.width: 1
            anchors.verticalCenter: parent.verticalCenter
            x: (tTrack.width - width) * tempSlider.frac
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onPressed: (m) => { tempSlider.dragging = true; tempSlider.dragTemp = tempSlider.tempAt(m.x, width) }
            onPositionChanged: (m) => { if (pressed) tempSlider.dragTemp = tempSlider.tempAt(m.x, width) }
            onReleased: { tempSlider.dragging = false; dm.night("temp " + tempSlider.dragTemp) }
        }
    }
    Text {
        text: tempSlider.shownTemp + "K" + (tempSlider.shownTemp >= 6000 ? "  (cool)" : tempSlider.shownTemp <= 3300 ? "  (warm)" : "")
        color: Colors.overlay1
        font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 12
        Layout.alignment: Qt.AlignRight
    }

    Rectangle {
        Layout.fillWidth: true; height: 1
        color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
    }

    // ── COLOUR MODE ───────────────────────────────────────────────────────────────
    Text {
        text: "Colour mode"
        color: Colors.subtext0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 13; font.weight: Font.Bold
    }

    ModeSection {
        title: "HDR"; subtitle: "HDR10"; icon: "󰃠"; keyword: "hdr"
        isActiveGroup: Frost.hdrOn
        expanded: Frost.hdrOn
    }
    ModeSection {
        title: "SDR"; subtitle: "sRGB"; icon: "󰃞"; keyword: "sdr"
        isActiveGroup: !Frost.hdrOn
        expanded: !Frost.hdrOn
    }
}

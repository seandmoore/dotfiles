import QtQuick
import QtQuick.Layouts
import "../theme"

// Calendar + clock dropdown. Big time/date at the top, a month grid below with
// today highlighted. `viewDate` can be paged month-by-month with the arrows.
ColumnLayout {
    id: cal
    spacing: 10

    property var now: new Date()
    property var viewDate: new Date()   // first-of-month anchor for the displayed grid

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: cal.now = new Date()
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate()
    }

    // ── Time + date ──────────────────────────────────────────────────────────
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(cal.now, "h:mm:ss ap")
        color: Colors.text
        font.family: "JetBrainsMono Nerd Font Propo"
        font.weight: Font.Bold
        font.pixelSize: 33
    }
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(cal.now, "dddd, MMMM d, yyyy")
        color: Colors.subtext0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 15
    }

    Rectangle {
        Layout.fillWidth: true; height: 1
        color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
    }

    // ── Month header with paging ──────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
            text: "󰅁"
            color: navPrev.containsMouse ? Colors.mauve : Colors.overlay1
            font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 20
            MouseArea {
                id: navPrev; anchors.fill: parent; anchors.margins: -6
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: cal.viewDate = new Date(cal.viewDate.getFullYear(), cal.viewDate.getMonth() - 1, 1)
            }
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDateTime(cal.viewDate, "MMMM yyyy")
            color: titleMa.containsMouse ? Colors.mauve : Colors.text
            font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 16; font.weight: Font.Medium
            Behavior on color { ColorAnimation { duration: 120 } }
            // Click the title to jump back to the current month after paging.
            MouseArea {
                id: titleMa; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: cal.viewDate = new Date()
            }
        }
        Text {
            text: "󰅂"
            color: navNext.containsMouse ? Colors.mauve : Colors.overlay1
            font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 20
            MouseArea {
                id: navNext; anchors.fill: parent; anchors.margins: -6
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: cal.viewDate = new Date(cal.viewDate.getFullYear(), cal.viewDate.getMonth() + 1, 1)
            }
        }
    }

    // ── Weekday headers ────────────────────────────────────────────────────────
    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 2

        Repeater {
            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
            delegate: Text {
                required property string modelData
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Colors.overlay0
                font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 13; font.weight: Font.Bold
            }
        }

        // 42 cells (6 weeks) — blanks before the 1st, then the month's days
        Repeater {
            model: 42
            delegate: Item {
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: 33

                readonly property int firstDow: new Date(cal.viewDate.getFullYear(), cal.viewDate.getMonth(), 1).getDay()
                readonly property int dayNum: index - firstDow + 1
                readonly property int daysInMonth: new Date(cal.viewDate.getFullYear(), cal.viewDate.getMonth() + 1, 0).getDate()
                readonly property bool inMonth: dayNum >= 1 && dayNum <= daysInMonth
                readonly property var cellDate: new Date(cal.viewDate.getFullYear(), cal.viewDate.getMonth(), dayNum)
                readonly property bool isToday: inMonth && cal.sameDay(cellDate, cal.now)

                Rectangle {
                    anchors.centerIn: parent
                    width: 30; height: 30; radius: 15
                    visible: parent.inMonth
                    color: parent.isToday ? Colors.mauve : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: parent.parent.inMonth ? parent.parent.dayNum : ""
                        color: parent.parent.isToday ? Colors.base : Colors.subtext1
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 14
                        font.weight: parent.parent.isToday ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../theme"

RowLayout {
    id: root
    spacing: 6
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

    property bool hasMedia: Mpris.players.length > 0
    property var player: hasMedia ? Mpris.players[0] : null

    // Prev
    Text {
        id: prevBtn
        text: "󰒮"
        color: Colors.subtext0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.underline: false
        font.italic: false
        font.strikeout: false
        font.pixelSize: 14
        visible: parent.hasMedia
        scale: ma1.containsMouse ? 1.15 : 1
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        MouseArea {
            id: ma1
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (player) player.previous()
        }
    }

    // Play/Pause
    Text {
        id: playBtn
        text: (player && player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
        color: Colors.mauve
        font.family: "JetBrainsMono Nerd Font Propo"
        font.underline: false
        font.italic: false
        font.strikeout: false
        font.pixelSize: 14
        visible: parent.hasMedia
        scale: ma2.containsMouse ? 1.15 : 1
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        MouseArea {
            id: ma2
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (player) player.togglePlaying()
        }
    }

    // Next
    Text {
        id: nextBtn
        text: "󰒭"
        color: Colors.subtext0
        font.family: "JetBrainsMono Nerd Font Propo"
        font.underline: false
        font.italic: false
        font.strikeout: false
        font.pixelSize: 14
        visible: parent.hasMedia
        scale: ma3.containsMouse ? 1.15 : 1
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        MouseArea {
            id: ma3
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (player) player.next()
        }
    }

    // Track title
    Text {
        text: player ? (player.trackTitle || "Unknown Track") : ""
        color: Colors.subtext1
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 11
        visible: parent.hasMedia
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.maximumWidth: 160
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../theme"

RowLayout {
    spacing: 6

    property bool hasMedia: Mpris.players.length > 0
    property var player: hasMedia ? Mpris.players[0] : null

    // Prev
    Text {
        text: "󰒮"
        color: Colors.subtext0
        font.family: "JetBrainsMono Nerd Font"
        font.underline: false
        font.italic: false
        font.strikeout: false
        font.pixelSize: 14
        visible: parent.hasMedia

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (player) player.previous()
        }
    }

    // Play/Pause
    Text {
        text: (player && player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
        color: Colors.mauve
        font.family: "JetBrainsMono Nerd Font"
        font.underline: false
        font.italic: false
        font.strikeout: false
        font.pixelSize: 14
        visible: parent.hasMedia

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (player) player.togglePlaying()
        }
    }

    // Next
    Text {
        text: "󰒭"
        color: Colors.subtext0
        font.family: "JetBrainsMono Nerd Font"
        font.underline: false
        font.italic: false
        font.strikeout: false
        font.pixelSize: 14
        visible: parent.hasMedia

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (player) player.next()
        }
    }

    // Track title
    Text {
        text: player ? (player.trackTitle || "Unknown Track") : ""
        color: Colors.subtext1
        font.family: "JetBrainsMono Nerd Font"
        font.underline: false
        font.italic: false
        font.strikeout: false
        font.pixelSize: 11
        visible: parent.hasMedia
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.maximumWidth: 160
    }
}

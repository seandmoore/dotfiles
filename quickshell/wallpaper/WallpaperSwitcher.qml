import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    aboveWindows: true
    focusable: true
    color: "transparent"
    visible: false

    property string currentWallpaper: ""
    property var wallpapers: []
    property string filterText: ""

    // Thumbnail decode size, shared by the grid items and the background preloader
    // so they hit the same pixmap-cache entry (~2x the 220x152 cell for crispness).
    readonly property int thumbW: 440
    readonly property int thumbH: 304

    IpcHandler {
        target: "wallpaper"
        function toggle() { root.visible = !root.visible }
    }

    // Preload in the background shortly after login: scan the folder and let the
    // hidden preloader (below) decode every thumbnail into Qt's pixmap cache, so the
    // first time the switcher is opened the grid is already warm and paints instantly.
    Timer {
        interval: 1500
        running: true
        repeat: false
        onTriggered: { scanner.found = []; scanner.running = true }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            searchField.text = ""
            filterText = ""
            scanner.found = []
            scanner.running = true
            currentLoader.running = true
        }
    }

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.70)
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    // Panel
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.88, 1300)
        height: Math.min(parent.height * 0.84, 720)
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Surface.opacity(0.50))
        border.color: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.45)
        border.width: 1
        radius: 20
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.93
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
        Behavior on scale   { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors { fill: parent; margins: 20 }
            spacing: 14

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                RowLayout {
                    spacing: 6
                    Text {
                        text: "󰋩"
                        color: Colors.text
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 16
                    }
                    Text {
                        text: "Wallpapers"
                        color: Colors.text
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.weight: Font.Bold
                        font.pixelSize: 16
                    }
                }

                Text {
                    text: root.wallpapers.length + " images"
                    color: Colors.overlay0
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font Propo"
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 220; height: 36
                    color: Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.55)
                    border.color: searchField.activeFocus
                        ? Colors.mauve
                        : Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.5)
                    border.width: 1
                    radius: 10
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        spacing: 6
                        Text {
                            text: ""
                            color: Colors.overlay0
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 13
                        }
                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: Colors.text
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font Propo"
                            Keys.onEscapePressed: root.visible = false
                            onTextChanged: root.filterText = text.toLowerCase()
                        }
                    }
                }
            }

            // Grid
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 220
                cellHeight: 152

                model: root.wallpapers.filter(w =>
                    root.filterText === "" || w.toLowerCase().includes(root.filterText)
                )

                delegate: WallpaperItem {
                    required property string modelData
                    path: modelData
                    isSelected: modelData === root.currentWallpaper
                    itemWidth: grid.cellWidth
                    itemHeight: grid.cellHeight
                    decodeW: root.thumbW
                    decodeH: root.thumbH
                    onActivated: (p) => {
                        root.currentWallpaper = p
                        // set-wallpaper.sh preloads (required by hyprpaper), applies live,
                        // and persists ~/.config/hypr/hyprpaper.conf so boot restores it.
                        applyProc.command = [
                            "bash", "-c",
                            "exec \"$HOME/dotfiles/scripts/set-wallpaper.sh\" \"$1\"",
                            "--", p
                        ]
                        applyProc.running = true
                        root.visible = false
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        radius: 3
                        color: Colors.surface1
                        implicitWidth: 4
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: grid.count === 0
                    text: scanner.running ? "Scanning…" : "No wallpapers found"
                    color: Colors.overlay0
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font Propo"
                }
            }
        }
    }

    Process {
        id: scanner
        property var found: []
        command: [
            "bash", "-c",
            "find \"$HOME/Pictures\" -maxdepth 1 -type f \\(" +
            " -iname '*.jpg' -o -iname '*.jpeg'" +
            " -o -iname '*.png' -o -iname '*.webp'" +
            " \\) | sort"
        ]
        stdout: SplitParser {
            onRead: line => { if (line.trim()) scanner.found.push(line.trim()) }
        }
        onRunningChanged: {
            if (!running) {
                root.wallpapers = found.slice()
                found = []
            }
        }
    }

    Process {
        id: currentLoader
        command: [
            "bash", "-c",
            "hyprctl hyprpaper listactive 2>/dev/null | awk -F ': ' 'NF==2{print $2}' | head -1"
        ]
        stdout: SplitParser {
            onRead: line => { if (line.trim()) root.currentWallpaper = line.trim() }
        }
    }

    Process { id: applyProc }

    // ── Background thumbnail preloader ─────────────────────────────────────────
    // Off-screen Images, one per wallpaper, decoded at the SAME sourceSize the grid
    // uses. Decoding happens off the GUI thread (asynchronous) as soon as the list
    // is known — even while this panel is hidden — and the decoded pixmaps stay in
    // the cache because these Images are kept alive. When the grid's delegates load
    // the same file+sourceSize later, they hit the warm cache and appear instantly.
    Item {
        visible: false
        width: 0; height: 0
        Repeater {
            model: root.wallpapers
            delegate: Image {
                required property string modelData
                source: "file://" + modelData
                sourceSize.width: root.thumbW
                sourceSize.height: root.thumbH
                asynchronous: true
                cache: true
                visible: false
                width: 0; height: 0
            }
        }
    }
}

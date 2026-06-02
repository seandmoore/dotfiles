import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"
import "../services"

PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    aboveWindows: true
    focusable: true
    color: "transparent"
    visible: false

    IpcHandler {
        target: "launcher"
        function toggle() { root.visible = !root.visible }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            searchField.text = ""
            searchField.forceActiveFocus()
            appsModel.refresh()
            categoryList.currentIndex = 0
        }
    }

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    // Main panel
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.72, 860)
        height: Math.min(parent.height * 0.72, 620)
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Frost.glass(0.48))
        border.color: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.45)
        border.width: 1
        radius: 20
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.93
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
        Behavior on scale   { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            // ── Left sidebar — categories ──────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: 160
                Layout.fillHeight: true
                color: Qt.rgba(Colors.mantle.r, Colors.mantle.g, Colors.mantle.b, 0.45)
                radius: 20

                // Right side flat to merge with content area
                Rectangle {
                    anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                    width: 20
                    color: parent.color
                }

                ColumnLayout {
                    anchors { fill: parent; margins: 10 }
                    spacing: 4

                    Text {
                        text: "Apps"
                        color: Colors.subtext0
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.family: "JetBrainsMono Nerd Font Propo"
                        leftPadding: 8
                        topPadding: 4
                    }

                    ListView {
                        id: categoryList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        currentIndex: 0
                        spacing: 2

                        model: appsModel.categories

                        onCurrentIndexChanged: appsModel.selectedCategory = model[currentIndex] ?? "All"

                        delegate: Rectangle {
                            required property string modelData
                            required property int index
                            width: categoryList.width
                            height: 34
                            radius: 8
                            color: categoryList.currentIndex === index
                                ? Qt.rgba(Colors.mauve.r, Colors.mauve.g, Colors.mauve.b, 0.22)
                                : (catMa.containsMouse ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.6) : "transparent")
                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                                spacing: 8

                                Text {
                                    text: appsModel.categoryIcon(modelData)
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 13
                                    color: categoryList.currentIndex === index ? Colors.mauve : Colors.overlay1
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                Text {
                                    text: modelData
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 12
                                    color: categoryList.currentIndex === index ? Colors.text : Colors.subtext0
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: catMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: categoryList.currentIndex = index
                            }
                        }
                    }

                    // ── Power menu ─────────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        Layout.topMargin: 4
                        Layout.preferredHeight: 1
                        color: Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.4)
                    }

                    Text {
                        text: "Power"
                        color: Colors.subtext0
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.family: "JetBrainsMono Nerd Font Propo"
                        leftPadding: 8
                        topPadding: 2
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 2
                        spacing: 2

                        Repeater {
                            model: [
                                { icon: "󰒲", color: Colors.blue,   cmd: ["systemctl", "suspend"]  },
                                { icon: "󰍃", color: Colors.yellow, cmd: ["uwsm", "stop"]          },
                                { icon: "󰜉", color: Colors.green,  cmd: ["systemctl", "reboot"]   },
                                { icon: "⏻",  color: Colors.red,    cmd: ["systemctl", "poweroff"] },
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                radius: 8
                                color: pwrMa.containsMouse
                                    ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.7)
                                    : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 15
                                    color: modelData.color
                                }

                                MouseArea {
                                    id: pwrMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.visible = false
                                        powerProcess.command = modelData.cmd
                                        powerProcess.running = true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Right content area ─────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 14
                Layout.bottomMargin: 14
                Layout.rightMargin: 14
                spacing: 10

                // Search bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 42
                    color: Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.55)
                    border.color: searchField.activeFocus ? Colors.mauve : Qt.rgba(Colors.surface2.r, Colors.surface2.g, Colors.surface2.b, 0.5)
                    border.width: 1
                    radius: 12
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 8

                        Text {
                            text: ""
                            color: Colors.overlay0
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 15
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: Colors.text
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font Propo"
                            selectionColor: Colors.mauve
                            selectedTextColor: Colors.base
                            clip: true
                            Keys.onEscapePressed: root.visible = false
                            onTextChanged: appsModel.filterText = text
                        }

                        Text {
                            text: "⌘K"
                            color: Colors.overlay0
                            font.pixelSize: 10
                            visible: searchField.text === ""
                        }
                    }
                }

                // App grid
                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: 96
                    cellHeight: 100
                    model: appsModel.filesMode ? appsModel.fileResults : appsModel.filteredApps

                    // Cascade in on open; smoothly reflow as the filter changes.
                    populate: Transition {
                        NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 220 }
                        NumberAnimation { properties: "scale"; from: 0.8; to: 1; duration: 260; easing.type: Easing.OutBack }
                    }
                    add: Transition {
                        NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 180 }
                        NumberAnimation { properties: "scale"; from: 0.8; to: 1; duration: 220; easing.type: Easing.OutBack }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic }
                    }

                    delegate: AppItem {
                        required property var modelData
                        app: modelData
                        onActivated: {
                            appsModel.launch(modelData)
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

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: grid.count === 0
                        text: appsModel.filesMode
                            ? (appsModel.filterText.trim().length < 2
                                ? "Type to search files in ~"
                                : "No files found")
                            : "No apps found"
                        color: Colors.overlay0
                        font.pixelSize: 14
                    }
                }
            }
        }
    }

    // ── App model ──────────────────────────────────────────────────────────────
    QtObject {
        id: appsModel

        property string filterText: ""
        property string selectedCategory: "All"
        // Apps come from the preloaded singleton (scanned once at startup), so the
        // grid is populated instantly on open instead of re-resolving every time.
        readonly property var apps: AppList.apps
        property var filteredApps: []
        property var fileResults: []
        readonly property var categories: AppList.categories.concat(["Files"])
        readonly property bool filesMode: selectedCategory === "Files"

        onFilterTextChanged: updateFilter()
        onSelectedCategoryChanged: updateFilter()
        onAppsChanged: updateFilter()

        function categoryIcon(cat) {
            const icons = {
                "All": "󰣇", "Internet": "󰖟", "Media": "󰝚", "Graphics": "󰋩",
                "Games": "󰊗", "Office": "󰈙", "Development": "󰅨", "System": "󰒓",
                "Utilities": "󰦛", "Education": "󰑐", "Science": "󰻲", "Other": "󰏔",
                "Files": "󰈞",
            }
            return icons[cat] ?? "󰏔"
        }

        // Map a filename to a nerd-font glyph + Catppuccin colour by extension.
        function fileGlyph(name) {
            const ext = (name.split(".").pop() || "").toLowerCase()
            const t = {
                png:["󰋩",Colors.sky], jpg:["󰋩",Colors.sky], jpeg:["󰋩",Colors.sky],
                gif:["󰋩",Colors.sky], webp:["󰋩",Colors.sky], bmp:["󰋩",Colors.sky],
                svg:["󰜡",Colors.sky], ico:["󰋩",Colors.sky],
                mp4:["󰕧",Colors.mauve], mkv:["󰕧",Colors.mauve], webm:["󰕧",Colors.mauve],
                mov:["󰕧",Colors.mauve], avi:["󰕧",Colors.mauve],
                mp3:["󰈣",Colors.pink], flac:["󰈣",Colors.pink], wav:["󰈣",Colors.pink],
                ogg:["󰈣",Colors.pink], m4a:["󰈣",Colors.pink],
                pdf:["󰈦",Colors.red],
                doc:["󰈬",Colors.blue], docx:["󰈬",Colors.blue], odt:["󰈬",Colors.blue],
                txt:["󰈙",Colors.subtext1], md:["󰍔",Colors.subtext1], rtf:["󰈙",Colors.subtext1],
                zip:["󰗄",Colors.peach], tar:["󰗄",Colors.peach], gz:["󰗄",Colors.peach],
                xz:["󰗄",Colors.peach], "7z":["󰗄",Colors.peach], zst:["󰗄",Colors.peach], rar:["󰗄",Colors.peach],
                js:["󰌞",Colors.yellow], ts:["󰛦",Colors.blue], py:["󰌠",Colors.yellow],
                rs:["󱘗",Colors.peach], go:["󰟓",Colors.sky], lua:["󰢱",Colors.blue],
                c:["󰙱",Colors.blue], cpp:["󰙲",Colors.blue], h:["󰙱",Colors.blue],
                sh:["󱆃",Colors.green], qml:["󰐱",Colors.mauve],
                json:["󰘦",Colors.yellow], yaml:["󰈙",Colors.green], yml:["󰈙",Colors.green],
                toml:["󰈙",Colors.peach], conf:["󰒓",Colors.overlay1], ini:["󰒓",Colors.overlay1],
            }
            const g = t[ext]
            return { glyph: g ? g[0] : "󰈔", color: g ? g[1] : Colors.lavender }
        }

        function refresh() { AppList.ensureLoaded() }

        function updateFilter() {
            // Files mode: search the filesystem (debounced) instead of the app list.
            if (filesMode) {
                fileResults = []
                fileSearchTimer.restart()
                return
            }
            const q = filterText.toLowerCase()
            let pool = selectedCategory === "All"
                ? apps.slice()
                : apps.filter(a => (a.category ?? "Other") === selectedCategory)
            if (q !== "")
                pool = pool.filter(a =>
                    a.name.toLowerCase().includes(q) ||
                    (a.comment && a.comment.toLowerCase().includes(q))
                )
            filteredApps = pool
        }

        function launch(app) {
            // File results open with the default handler; apps run their Exec.
            if (app.isFile) {
                launchProcess.command = ["xdg-open", app.path]
                launchProcess.running = true
                return
            }
            if (app.exec) {
                const cmd = app.exec.replace(/%[fFuUdDnNickvm]/g, "").trim()
                launchProcess.command = ["bash", "-c", "nohup " + cmd + " &>/dev/null &"]
                launchProcess.running = true
            }
        }
    }

    // Debounce keystrokes before spawning a filesystem search.
    Timer {
        id: fileSearchTimer
        interval: 250
        repeat: false
        onTriggered: {
            const q = appsModel.filterText.trim()
            if (q.length < 2) { appsModel.fileResults = []; return }
            // Clear first, so stopping any in-flight search can't briefly flash old hits.
            fileSearch.parsed = []
            fileSearch.running = false
            // Pass the query as argv ($1) so it can't break the script quoting.
            fileSearch.command = ["bash", "-c", fileSearch.script, "qsfind", q]
            fileSearch.running = true
        }
    }

    Process {
        id: fileSearch
        property var parsed: []
        // Prune heavy/irrelevant trees, then case-insensitively match filenames
        // under $HOME. Capped so a broad query can't flood the grid or hang.
        readonly property string script:
            "q=\"$1\"; [ -z \"$q\" ] && exit 0; " +
            "find \"$HOME\" " +
            "\\( -path \"$HOME/.cache\" -o -path \"$HOME/.var\" " +
            "-o -path \"$HOME/.local/share/Trash\" -o -path \"$HOME/.mozilla\" " +
            "-o -name node_modules -o -name .git \\) -prune -o " +
            "-type f -iname \"*$q*\" -print 2>/dev/null | head -120"

        stdout: SplitParser {
            onRead: line => {
                if (!line) return
                const path = line
                const name = path.split("/").pop()
                const g = appsModel.fileGlyph(name)
                fileSearch.parsed.push({
                    name: name, path: path, isFile: true,
                    glyph: g.glyph, glyphColor: g.color
                })
            }
        }
        onRunningChanged: {
            if (!running) appsModel.fileResults = parsed.slice()
        }
    }

    Process { id: launchProcess }

    Process { id: powerProcess }
}

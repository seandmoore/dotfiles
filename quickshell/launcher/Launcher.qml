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
        color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.60)
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
                    model: appsModel.filteredApps

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
                        text: "No apps found"
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
        property var apps: []
        property var filteredApps: []
        property var categories: ["All"]

        onFilterTextChanged: updateFilter()
        onSelectedCategoryChanged: updateFilter()

        function categoryIcon(cat) {
            const icons = {
                "All": "󰣇", "Internet": "󰖟", "Media": "󰝚", "Graphics": "󰋩",
                "Games": "󰊗", "Office": "󰈙", "Development": "󰅨", "System": "󰒓",
                "Utilities": "󰦛", "Education": "󰑐", "Science": "󰻲", "Other": "󰏔",
            }
            return icons[cat] ?? "󰏔"
        }

        function refresh() { appLoader.running = true }

        function updateFilter() {
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

        function buildCategories() {
            const seen = new Set()
            apps.forEach(a => { if (a.category) seen.add(a.category) })
            const sorted = Array.from(seen).sort()
            categories = ["All", ...sorted]
        }

        function launch(app) {
            if (app.exec) {
                const cmd = app.exec.replace(/%[fFuUdDnNickvm]/g, "").trim()
                launchProcess.command = ["bash", "-c", "nohup " + cmd + " &>/dev/null &"]
                launchProcess.running = true
            }
        }
    }

    Process { id: launchProcess }

    Process {
        id: appLoader
        property var parsed: []

        command: ["bash", "-c",
            "find /usr/share/applications ~/.local/share/applications " +
            "/var/lib/flatpak/exports/share/applications " +
            "${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/exports/share/applications " +
            "-name '*.desktop' 2>/dev/null | sort -u | " +
            "xargs -I{} awk 'BEGIN{n=\"\";e=\"\";i=\"\";c=\"\";nd=0;nt=0} " +
            "/\\[Desktop Entry\\]/{nt=1;next} /^\\[/{nt=0} " +
            "nt&&/^Name=/{n=substr($0,index($0,\"=\")+1)} " +
            "nt&&/^Exec=/{e=substr($0,index($0,\"=\")+1)} " +
            "nt&&/^Icon=/{i=substr($0,index($0,\"=\")+1)} " +
            "nt&&/^Categories=/{c=substr($0,index($0,\"=\")+1)} " +
            "nt&&/^NoDisplay=true/{nd=1} " +
            "END{if(!nd&&n!=\"\"&&e!=\"\")print n\"|\"e\"|\"i\"|\"c}' {} | sort -u | " +
            "while IFS='|' read -r name exec icon cats; do " +
            "  cat=$(echo \"$cats\" | tr ';' '\\n' | grep -Ew " +
            "'AudioVideo|Audio|Video|Graphics|Office|Game|Network|Science|Education|Development|System|Utility' " +
            "| head -1); " +
            "  case $cat in " +
            "    AudioVideo|Audio|Video) cat=Media ;; " +
            "    Game) cat=Games ;; " +
            "    Network) cat=Internet ;; " +
            "    Utility) cat=Utilities ;; " +
            "    *) [ -z \"$cat\" ] && cat=Other ;; " +
            "  esac; " +
            "  resolved=''; " +
            "  mode=theme; [[ \";${cats};\" == *\";Game;\"* ]] && mode=original; " +
            "  if [ -n \"$icon\" ]; then " +
            "    resolved=$(\"$HOME/dotfiles/scripts/icon-resolve.sh\" \"$icon\" \"${ICON_THEME:-Papirus-Dark}\" \"$mode\"); " +
            "  fi; " +
            "  echo \"${name}|${exec}|${resolved}|${cat}\"; " +
            "done"
        ]

        stdout: SplitParser {
            onRead: line => {
                const parts = line.split("|")
                if (parts.length >= 2) {
                    appLoader.parsed.push({
                        name: parts[0], exec: parts[1],
                        icon: parts[2] || "", category: parts[3] || "Other"
                    })
                }
            }
        }

        onRunningChanged: {
            if (!running && parsed.length > 0) {
                appsModel.apps = parsed.sort((a, b) => a.name.localeCompare(b.name))
                parsed = []
                appsModel.buildCategories()
                appsModel.updateFilter()
            }
        }
    }
}

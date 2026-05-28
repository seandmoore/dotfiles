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

    // IPC toggle — called by: qs ipc call launcher toggle
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
        }
    }

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.7)
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    // Center panel
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.7, 800)
        height: Math.min(parent.height * 0.75, 640)
        color: Colors.base
        border.color: Colors.surface1
        border.width: 1
        radius: 18

        ColumnLayout {
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 12

            // Search bar
            Rectangle {
                Layout.fillWidth: true
                height: 44
                color: Colors.surface0
                border.color: searchField.activeFocus ? Colors.mauve : Colors.surface1
                border.width: 1
                radius: 12

                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 8

                    Text {
                        text: ""
                        color: Colors.overlay0
                        font.family: "JetBrainsMono Nerd Font"
                        font.underline: false
                        font.italic: false
                        font.strikeout: false
                        font.pixelSize: 16
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        color: Colors.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.underline: false
                        font.italic: false
                        font.strikeout: false
                        font.pixelSize: 14
                        selectionColor: Colors.mauve
                        selectedTextColor: Colors.base
                        clip: true

                        Keys.onEscapePressed: root.visible = false

                        onTextChanged: appsModel.filterText = text
                    }
                }
            }

            // App grid
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                cellWidth: 100
                cellHeight: 104

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
                        color: Colors.overlay0
                    }
                }
            }
        }
    }

    // App list model — reads .desktop files
    QtObject {
        id: appsModel

        property string filterText: ""
        property var apps: []
        property var filteredApps: []

        onFilterTextChanged: updateFilter()

        function refresh() {
            appLoader.running = true
        }

        function updateFilter() {
            const q = filterText.toLowerCase()
            if (q === "") {
                filteredApps = apps.slice()
            } else {
                filteredApps = apps.filter(a =>
                    a.name.toLowerCase().includes(q) ||
                    (a.comment && a.comment.toLowerCase().includes(q))
                )
            }
        }

        function launch(app) {
            if (app.exec) {
                const cmd = app.exec
                    .replace(/%[fFuUdDnNickvm]/g, "")
                    .trim()
                launchProcess.command = ["bash", "-c", "nohup " + cmd + " &>/dev/null &"]
                launchProcess.running = true
            }
        }
    }

    Process {
        id: launchProcess
        running: false
    }

    // Parse .desktop files
    Process {
        id: appLoader
        command: ["bash", "-c",
            "find /usr/share/applications ~/.local/share/applications " +
            "/var/lib/flatpak/exports/share/applications " +
            "${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/exports/share/applications " +
            "-name '*.desktop' 2>/dev/null | " +
            "xargs -I{} awk 'BEGIN{f=\"{}\"; n=\"\"; e=\"\"; i=\"\"; nt=0} " +
            "/\\[Desktop Entry\\]/{nt=1} " +
            "nt && /^Name=/{n=substr($0,index($0,\"=\")+1)} " +
            "nt && /^Exec=/{e=substr($0,index($0,\"=\")+1)} " +
            "nt && /^Icon=/{i=substr($0,index($0,\"=\")+1)} " +
            "nt && /^NoDisplay=true/{nt=-1} " +
            "END{if(nt==1 && n!=\"\" && e!=\"\") print n\"|\"e\"|\"i}' {} | sort -u | " +
            "while IFS='|' read -r name exec icon; do " +
            "  resolved=''; " +
            "  if [ -n \"$icon\" ]; then " +
            "    case \"$icon\" in /*) resolved=\"$icon\" ;; " +
            "    *) resolved=$(find " +
            "/usr/share/icons/Papirus-Dark/48x48 /usr/share/icons/Papirus/48x48 " +
            "/usr/share/icons/hicolor/48x48 /usr/share/icons/hicolor/scalable " +
            "/var/lib/flatpak/exports/share/icons " +
            "${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/exports/share/icons " +
            "/usr/share/pixmaps " +
            "-name \"${icon}.svg\" -o -name \"${icon}.png\" 2>/dev/null | head -1) ;; " +
            "    esac; " +
            "  fi; " +
            "  echo \"${name}|${exec}|${resolved}\"; " +
            "done"]
        running: false

        property var parsed: []

        stdout: SplitParser {
            onRead: line => {
                const parts = line.split("|")
                if (parts.length >= 2) {
                    appLoader.parsed.push({
                        name: parts[0],
                        exec: parts[1],
                        icon: parts[2] || ""
                    })
                }
            }
        }

        onRunningChanged: {
            if (!running && parsed.length > 0) {
                appsModel.apps = parsed.sort((a, b) => a.name.localeCompare(b.name))
                parsed = []
                appsModel.updateFilter()
            }
        }
    }
}

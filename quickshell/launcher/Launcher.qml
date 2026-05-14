import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

FloatingWindow {
    id: root

    anchors { fill: true }
    color: "transparent"
    visible: false

    // IPC toggle — called by: qs ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        function toggle() { root.visible = !root.visible }
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
                        font.pixelSize: 16
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        color: Colors.text
                        font.family: "JetBrainsMono Nerd Font"
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

                model: appsModel

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
                Quickshell.exec(["bash", "-c", cmd + " &"])
            }
        }
    }

    // Parse .desktop files
    Process {
        id: appLoader
        command: ["bash", "-c",
            "find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null | " +
            "xargs -I{} awk -F= 'BEGIN{f=\"{}\"; n=\"\"; e=\"\"; i=\"\"; nt=0} " +
            "/\\[Desktop Entry\\]/{nt=1} nt && /^Name=/{n=$2} nt && /^Exec=/{e=$2} " +
            "nt && /^Icon=/{i=$2} nt && /^NoDisplay=true/{nt=-1} " +
            "END{if(nt==1 && n!=\"\" && e!=\"\") print n\"|\"e\"|\"i}' {} | sort -u"]
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

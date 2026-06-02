pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Preloaded list of the top-level (non-hidden) folders in $HOME, for the bar's
// Places / file-manager dropdown. Scanned once at startup (Bar.qml touches it) so
// the menu opens instantly. Each entry is { name, path, icon } where icon is a
// Nerd Font glyph chosen per well-known folder, falling back to a generic folder.
QtObject {
    id: places

    property var folders: []          // [{ name, path, icon }]
    property bool loaded: false
    property bool loading: false

    // Nerd Font glyph per folder name; generic folder otherwise.
    function glyphFor(name) {
        switch (name) {
        case "Home":      return "󰋜"
        case "Desktop":   return "󰇄"
        case "Downloads": return "󰉍"
        case "Documents": return "󰈙"
        case "Pictures":  return "󰉏"
        case "Music":     return "󰝚"
        case "Videos":    return "󰕧"
        case "Projects":  return "󰅴"
        default:          return "󰉋"
        }
    }

    function ensureLoaded() { if (!loaded && !loading) reload() }

    function reload() {
        loading = true
        scanner.parsed = []
        scanner.running = true
    }

    // Instantiated lazily on first import; Bar.qml calls ensureLoaded() at startup.
    Component.onCompleted: ensureLoaded()

    property Process scanner: Process {
        id: scanner
        property var parsed: []
        // "Home" first, then every visible top-level dir. "%f|%p" = basename|fullpath.
        command: ["bash", "-c",
            "printf 'Home|%s\\n' \"$HOME\"; " +
            "find \"$HOME\" -mindepth 1 -maxdepth 1 -type d -not -name '.*' " +
            "-printf '%f|%p\\n' 2>/dev/null | sort -f"]
        stdout: SplitParser {
            onRead: line => {
                const i = line.indexOf("|")
                if (i <= 0) return
                const nm = line.substring(0, i)
                const pth = line.substring(i + 1).trim()
                if (pth) scanner.parsed.push({ name: nm, path: pth, icon: places.glyphFor(nm) })
            }
        }
        onRunningChanged: {
            if (!running) {
                if (parsed.length > 0) { places.folders = parsed.slice(); parsed = [] }
                places.loaded = true
                places.loading = false
            }
        }
    }
}

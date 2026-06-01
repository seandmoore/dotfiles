pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// In-process clipboard history. cliphist isn't installed, so we run a single
// `wl-paste --watch` (this is a singleton — one watcher for the whole session,
// regardless of monitor count) and keep the most recent text copies in memory.
// History resets when Quickshell restarts (e.g. on a theme switch); that's the
// trade-off for not pulling in a separate clipboard daemon.
QtObject {
    id: clip

    // Newest first. Each entry: { text: <full>, preview: <one-line, trimmed> }.
    property var entries: []
    property int maxEntries: 25
    readonly property string separator: ""   // FS — won't appear in normal copies

    function addEntry(text) {
        if (!text || text.trim().length === 0)
            return
        const preview = text.replace(/\s+/g, " ").trim()
        // Drop any existing copy of the same text, then push to the front.
        const kept = entries.filter(e => e.text !== text)
        entries = [{ text: text, preview: preview }, ...kept].slice(0, maxEntries)
    }

    function copy(text) {
        // printf|wl-copy preserves the exact bytes (newlines, leading dashes, …).
        copyProc.command = ["bash", "-c", "printf '%s' \"$1\" | wl-copy", "_", text]
        copyProc.running = true
    }

    function clear() { entries = [] }

    property Process copyProc: Process { id: copyProc }

    // Stream every clipboard change. `cat` re-emits the new content, then we append
    // a record separator so multi-line copies stay a single entry (SplitParser
    // would otherwise break each newline into its own bogus entry).
    property Process watcher: Process {
        running: true
        command: ["wl-paste", "--type", "text", "--no-newline", "--watch",
                  "sh", "-c", "cat; printf '\\034'"]
        stdout: SplitParser {
            splitMarker: clip.separator
            onRead: data => clip.addEntry(data)
        }
    }
}

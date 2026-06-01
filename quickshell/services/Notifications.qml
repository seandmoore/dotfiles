pragma Singleton
import QtQuick
import Quickshell

// Shared notification state: Do-Not-Disturb (with optional timed mute) and a
// rolling history. The DBus server (NotificationServer.qml) logs every incoming
// notification here and suppresses the on-screen popup while DND is active; the
// bar's bell dropdown (NotificationMenu.qml) reads and controls this state.
QtObject {
    id: svc

    // Newest first. Each entry: { id, appName, summary, body, appIcon, image, urgency, time }
    property var history: []
    property int maxHistory: 50
    property int unread: 0

    // Do Not Disturb. muteUntil = 0 means indefinite; otherwise an epoch-ms deadline.
    property bool dnd: false
    property double muteUntil: 0
    property int _nextId: 1

    readonly property string muteLabel: {
        if (!dnd) return ""
        if (muteUntil === 0) return "On"
        const mins = Math.max(0, Math.round((muteUntil - Date.now()) / 60000))
        if (mins >= 60) return "for " + Math.round(mins / 60) + "h"
        return "for " + mins + "m"
    }

    function log(n) {
        const entry = {
            id: _nextId++,
            appName: n.appName || "",
            summary: n.summary || "",
            body: n.body || "",
            appIcon: n.appIcon || "",
            image: n.image || "",
            urgency: n.urgency,
            time: Date.now()
        }
        history = [entry, ...history].slice(0, maxHistory)
        unread++
    }

    function markRead() { unread = 0 }
    function dismiss(id) { history = history.filter(e => e.id !== id) }
    function clearAll() { history = []; unread = 0 }

    function toggleDnd() {
        dnd = !dnd
        muteUntil = 0
        muteTimer.stop()
    }

    // Mute for a number of minutes (0 = indefinite).
    function muteFor(minutes) {
        dnd = true
        if (minutes <= 0) {
            muteUntil = 0
            muteTimer.stop()
        } else {
            muteUntil = Date.now() + minutes * 60000
            muteTimer.interval = minutes * 60000
            muteTimer.restart()
        }
    }

    property Timer muteTimer: Timer {
        repeat: false
        onTriggered: { svc.dnd = false; svc.muteUntil = 0 }
    }
}

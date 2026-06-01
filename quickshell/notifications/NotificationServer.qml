import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../services"

// Implements the org.freedesktop.Notifications DBus interface.
// Spawns a NotificationPopup for each incoming notification (unless DND is on)
// and logs every notification to the shared history (Notifications singleton).
NotificationServer {
    id: root

    actionIconsSupported: true
    actionsSupported: true
    bodyHyperlinksSupported: true
    bodyMarkupSupported: true
    imageSupported: true

    property var popups: []
    property var popupComponent: Qt.createComponent("NotificationPopup.qml")

    // Re-number the stack so popups always pack tightly from the top edge.
    function relayout() {
        for (let i = 0; i < popups.length; i++)
            popups[i].stackIndex = i
    }

    function remove(popup) {
        const i = popups.indexOf(popup)
        if (i >= 0) {
            popups.splice(i, 1)
            relayout()
        }
        popup.destroy()
    }

    onNotification: notification => {
        // Retain the notification past this handler so its actions/timeout work.
        notification.tracked = true

        // Always record it in the bell's history.
        Notifications.log(notification)

        // Suppress the on-screen popup while Do Not Disturb is active. Critical
        // notifications still break through (they shouldn't be silently swallowed).
        const critical = notification.urgency === NotificationUrgency.Critical
        if (Notifications.dnd && !critical)
            return

        if (popupComponent.status === Component.Ready) {
            const popup = popupComponent.createObject(null, {
                notification: notification,
                server: root,
                stackIndex: popups.length
            })
            if (popup) popups.push(popup)
        } else {
            console.warn("NotificationPopup failed to load:", popupComponent.errorString())
        }
    }
}

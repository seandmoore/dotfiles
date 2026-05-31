import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Implements the org.freedesktop.Notifications DBus interface.
// Spawns a NotificationPopup for each incoming notification.
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

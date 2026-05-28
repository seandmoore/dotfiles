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

    property int nextIndex: 0
    property var popupComponent: Qt.createComponent("NotificationPopup.qml")

    onNotification: notification => {
        if (popupComponent.status === Component.Ready) {
            popupComponent.createObject(null, {
                notification: notification,
                stackIndex: nextIndex++
            })
        }
    }
}

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

    onNotification: notification => {
        const popup = popupComponent.createObject(popupLayer, {
            notification: notification
        })
    }

    Component {
        id: popupComponent
        NotificationPopup {}
    }

    // Anchor layer so popups stack correctly
    Item {
        id: popupLayer
        anchors.fill: parent
    }
}

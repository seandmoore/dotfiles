import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"

// Bar trigger for the battery HoverPanel: an icon + charge %, animated in like
// the other pill widgets. All data comes from the Battery service singleton, and
// every colour is a theme-reactive Colors.* value so it follows Mocha/Latte.
RowLayout {
    id: root
    spacing: 6
    Layout.alignment: Qt.AlignVCenter

    opacity: 1
    scale: 1
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
    Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
    Component.onCompleted: {
        opacity = 0
        scale = 0.9
        opacity = 1
        scale = 1
    }

    readonly property color tint: Battery.low ? Colors.red
        : Battery.charging ? Colors.green
        : Colors.text

    Text {
        text: Battery.icon
        color: root.tint
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 17
        Layout.alignment: Qt.AlignVCenter
        Behavior on color { ColorAnimation { duration: 250 } }
    }

    Text {
        text: Battery.percent + "%"
        color: Battery.low ? Colors.red : Colors.subtext1
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 15
        Layout.alignment: Qt.AlignVCenter
        Behavior on color { ColorAnimation { duration: 250 } }
    }
}

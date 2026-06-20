pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    required property string icon
    // When false the icon dims to secondaryText to signal an inactive/off state
    property bool active: true
    // Accent color used while active (lets callers highlight e.g. a charging battery)
    property color accent: Colors.chipIcon

    implicitWidth: 22
    implicitHeight: 22

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? root.accent : Colors.secondaryText
        font.pixelSize: 15
        font.family: "JetBrainsMono Nerd Font"

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}

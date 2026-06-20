pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    implicitWidth: 28
    implicitHeight: 22

    readonly property int count: Notifications.notifications.values.length

    Text {
        anchors.centerIn: parent
        text: "󰂞"
        color: Colors.chipIcon
        font.pixelSize: 15
        font.family: "JetBrainsMono Nerd Font"
    }

    Text {
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        text: count > 0 ? count : ""
        color: Colors.chipIconActive
        font.pixelSize: 9
        font.family: "Poppins"
        font.bold: true
        visible: count > 0
    }

    visible: count > 0
}
pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    required property string icon

    implicitWidth: 22
    implicitHeight: 22

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: Colors.chipIcon
        font.pixelSize: 15
        font.family: "JetBrainsMono Nerd Font"
    }
}

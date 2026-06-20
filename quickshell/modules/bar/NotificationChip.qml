pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    implicitWidth: 24
    implicitHeight: 22

    readonly property int count: Notifications.notifications.values.length

    visible: count > 0

    Text {
        id: bell
        anchors.centerIn: parent
        text: "󰂞"
        color: Colors.chipIcon
        font.pixelSize: 15
        font.family: "JetBrainsMono Nerd Font"
    }

    // Rounded count badge anchored to the top-right of the bell
    Rectangle {
        id: badge
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: -2
            topMargin: -1
        }
        implicitWidth: Math.max(14, badgeText.implicitWidth + 6)
        implicitHeight: 14
        radius: height / 2
        color: Colors.chipIconActive
        border.width: 1
        border.color: Colors.background
        visible: root.count > 0

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: root.count
            color: Colors.background
            font.pixelSize: 9
            font.family: "Poppins"
            font.bold: true
        }
    }

    // Gentle pulse whenever a new notification arrives
    SequentialAnimation {
        id: pulse
        NumberAnimation { target: root; property: "scale"; to: 1.18; duration: 110; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; to: 1.0; duration: 140; easing.type: Easing.OutCubic }
    }

    Connections {
        target: Notifications
        function onNotificationArrived() { pulse.restart() }
    }
}

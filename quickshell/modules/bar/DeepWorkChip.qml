pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// Live deep-work state in the bar: elapsed work time, or a pulsing break
// countdown so a break is obvious without opening the popup.
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: 22

    visible: DeepWork.running || DeepWork.sessionSeconds > 0

    readonly property color tint: DeepWork.onBreak ? Colors.chipIconActive : Colors.chipIcon

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: DeepWork.onBreak ? "󰅶" : "󰔛"
            color: root.tint
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14

            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: DeepWork.onBreak ? DeepWork.breakLabel : DeepWork.sessionShort
            color: root.tint
            font.family: "Poppins"
            font.pixelSize: 11
            font.weight: Font.Bold

            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    // Pulse while on a break
    SequentialAnimation {
        running: DeepWork.onBreak
        loops: Animation.Infinite

        NumberAnimation { target: root; property: "opacity"; to: 0.4; duration: 700; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "opacity"; to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
    }

    Connections {
        target: DeepWork
        function onOnBreakChanged() {
            if (!DeepWork.onBreak) root.opacity = 1
        }
    }
}

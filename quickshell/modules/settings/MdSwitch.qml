pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// MD3 switch. The thumb grows from 16px to 24px when checked and swells to
// 28px while pressed — that size change, not just the colour, is what reads as
// Material rather than a generic toggle.
Item {
    id: root

    property bool checked: false
    property bool interactive: true

    signal toggled()

    implicitWidth: 52
    implicitHeight: 32
    opacity: interactive ? 1 : Md.disabledOpacity

    Behavior on opacity { NumberAnimation { duration: Md.durMedium } }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Md.primary : Md.surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Md.outline

        Behavior on color { ColorAnimation { duration: Md.durMedium } }
        Behavior on border.color { ColorAnimation { duration: Md.durMedium } }
    }

    Rectangle {
        id: thumb
        width: hover.pressed ? 28 : (root.checked ? 24 : 16)
        height: width
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 : (32 - width) / 2
        color: root.checked ? Md.textOnPrimary : Md.outline

        Behavior on width { NumberAnimation { duration: Md.durShort; easing.type: Md.easingStandard } }
        Behavior on x { NumberAnimation { duration: Md.durMedium; easing.type: Md.easingEmphasized } }
        Behavior on color { ColorAnimation { duration: Md.durMedium } }

        Text {
            anchors.centerIn: parent
            text: "󰄬"
            font.family: Md.iconFamily
            font.pixelSize: 12
            color: Md.primary
            opacity: root.checked ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: Md.durShort } }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}

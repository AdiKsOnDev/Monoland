pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// MD3 icon button. `toggled` gives it the filled/selected treatment used for
// things like mute and scan, where the button reflects a state rather than
// firing a one-shot action.
Item {
    id: root

    property string icon: ""
    property bool toggled: false
    property bool interactive: true
    property int size: 40
    property int iconSize: 20
    property color accent: Md.primary

    signal clicked()

    implicitWidth: size
    implicitHeight: size
    opacity: interactive ? 1 : Md.disabledOpacity

    Rectangle {
        anchors.fill: parent
        radius: Md.cornerFull
        color: root.toggled ? root.accent : "transparent"

        Behavior on color { ColorAnimation { duration: Md.durMedium } }
    }

    Rectangle {
        anchors.fill: parent
        radius: Md.cornerFull
        color: root.toggled ? Md.textOnPrimary : Md.textOnSurface
        opacity: !root.interactive ? 0
            : hover.pressed ? Md.pressedOpacity
            : hover.containsMouse ? Md.hoverOpacity
            : 0

        Behavior on opacity { NumberAnimation { duration: Md.durShort } }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Md.iconFamily
        font.pixelSize: root.iconSize
        color: root.toggled ? Md.textOnPrimary : Md.textOnSurfaceVariant

        Behavior on color { ColorAnimation { duration: Md.durMedium } }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

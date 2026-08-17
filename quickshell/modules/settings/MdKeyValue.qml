pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// One detail row: label on the left, value on the right. Values are the kind
// of thing you end up pasting into a terminal, so the whole row copies on
// click and says so on hover.
Item {
    id: root

    property string label: ""
    property string value: ""
    property bool mono: true

    signal copyRequested(string text)

    readonly property bool empty: value === ""

    implicitHeight: 36
    implicitWidth: 320
    visible: !empty

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -6
        anchors.rightMargin: -6
        radius: Md.cornerS
        color: Md.textOnSurface
        opacity: hover.pressed ? Md.pressedOpacity
            : hover.containsMouse ? Md.hoverOpacity
            : 0

        Behavior on opacity { NumberAnimation { duration: Md.durShort } }
    }

    Text {
        id: key
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        width: Math.min(190, root.width * 0.42)
        text: root.label
        color: Md.textOnSurfaceVariant
        font.family: Md.fontFamily
        font.pixelSize: Md.bodySmall
        elide: Text.ElideRight
    }

    Text {
        anchors {
            left: key.right
            leftMargin: 12
            right: copyHint.left
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        text: root.value
        color: Md.textOnSurface
        font.family: root.mono ? Md.iconFamily : Md.fontFamily
        font.pixelSize: Md.bodySmall
        elide: Text.ElideRight
    }

    Text {
        id: copyHint
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        text: "󰆏"
        font.family: Md.iconFamily
        font.pixelSize: 13
        color: Md.textOnSurfaceVariant
        opacity: hover.containsMouse ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Md.durShort } }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.copyRequested(root.value)
    }
}

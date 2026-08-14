pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// MD3 list item: leading icon, headline over optional supporting text, and a
// trailing slot for controls. Hover/press paint a state layer over the row so
// the row itself stays transparent against whatever card holds it.
Item {
    id: root

    property string icon: ""
    property color iconColor: Md.textOnSurfaceVariant
    property string headline: ""
    property string supporting: ""
    property bool selected: false
    property bool interactive: true
    property int radius: Md.cornerM

    default property alias trailing: trailingSlot.data

    signal clicked()

    implicitHeight: supporting !== "" ? 64 : 56
    implicitWidth: 320

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.selected ? Md.secondaryContainer : "transparent"

        Behavior on color { ColorAnimation { duration: Md.durMedium } }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Md.textOnSurface
        opacity: !root.interactive ? 0
            : hover.pressed ? Md.pressedOpacity
            : hover.containsMouse ? Md.hoverOpacity
            : 0

        Behavior on opacity { NumberAnimation { duration: Md.durShort } }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Text {
        id: leading
        visible: root.icon !== ""
        width: visible ? 24 : 0
        anchors {
            left: parent.left
            leftMargin: 16
            verticalCenter: parent.verticalCenter
        }
        text: root.icon
        font.family: Md.iconFamily
        font.pixelSize: 20
        color: root.iconColor
        horizontalAlignment: Text.AlignHCenter

        Behavior on color { ColorAnimation { duration: Md.durMedium } }
    }

    Column {
        anchors {
            left: leading.visible ? leading.right : parent.left
            leftMargin: leading.visible ? 16 : 16
            right: trailingSlot.left
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        spacing: 2

        Text {
            width: parent.width
            text: root.headline
            color: Md.textOnSurface
            font.family: Md.fontFamily
            font.pixelSize: Md.bodyLarge
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: root.supporting !== ""
            text: root.supporting
            color: Md.textOnSurfaceVariant
            font.family: Md.fontFamily
            font.pixelSize: Md.bodySmall
            elide: Text.ElideRight
        }
    }

    Item {
        id: trailingSlot
        anchors {
            right: parent.right
            rightMargin: 16
            verticalCenter: parent.verticalCenter
        }
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        width: implicitWidth
        height: implicitHeight
    }
}

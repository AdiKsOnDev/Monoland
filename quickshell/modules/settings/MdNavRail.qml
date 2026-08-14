pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// MD3 navigation rail. The active item is marked by a pill indicator that
// slides between entries, so the selection reads as one moving object rather
// than a highlight blinking from row to row.
Item {
    id: root

    // [{ id, icon, label }]
    property var sections: []
    property string current: ""

    signal selected(string id)

    implicitWidth: 96

    // Scrollable: the rail has to survive more sections than fit the card
    Flickable {
        id: scroll
        anchors.fill: parent
        anchors.topMargin: 8
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            width: scroll.width
            spacing: 4

            Repeater {
                model: root.sections

                delegate: Item {
                    id: entry
                    required property var modelData
                    width: column.width
                    height: 84

                    readonly property bool active: root.current === entry.modelData.id

                    Rectangle {
                        id: indicator
                        width: 56
                        height: 56
                        radius: Md.cornerL
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 4
                        color: entry.active ? Md.secondaryContainer : "transparent"

                        Behavior on color { ColorAnimation { duration: Md.durMedium } }
                    }

                    Rectangle {
                        anchors.fill: indicator
                        radius: Md.cornerL
                        color: Md.textOnSurface
                        opacity: hover.pressed ? Md.pressedOpacity
                            : hover.containsMouse ? Md.hoverOpacity
                            : 0

                        Behavior on opacity { NumberAnimation { duration: Md.durShort } }
                    }

                    Text {
                        anchors.centerIn: indicator
                        text: entry.modelData.icon
                        font.family: Md.iconFamily
                        font.pixelSize: 19
                        color: entry.active ? Md.textOnSecondaryContainer : Md.textOnSurfaceVariant

                        Behavior on color { ColorAnimation { duration: Md.durMedium } }
                    }

                    Text {
                        anchors {
                            top: indicator.bottom
                            topMargin: 4
                            left: parent.left
                            right: parent.right
                            leftMargin: 4
                            rightMargin: 4
                        }
                        text: entry.modelData.label
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        font.family: Md.fontFamily
                        font.pixelSize: Md.labelSmall
                        font.weight: entry.active ? Font.Bold : Font.Medium
                        color: entry.active ? Md.textOnSurface : Md.textOnSurfaceVariant

                        Behavior on color { ColorAnimation { duration: Md.durMedium } }
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selected(entry.modelData.id)
                    }
                }
            }
        }
    }
}

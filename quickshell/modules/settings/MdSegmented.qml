pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// MD3 segmented button group. Options are [{ id, label }]; the selected
// segment fills and shows a check, matching the spec's single-select variant.
Item {
    id: root

    property var options: []
    property string current: ""
    property bool enabled: true

    signal selected(string id)

    implicitHeight: 40
    implicitWidth: 260
    opacity: enabled ? 1 : Md.disabledOpacity

    Behavior on opacity { NumberAnimation { duration: Md.durMedium } }

    Row {
        anchors.fill: parent

        Repeater {
            model: root.options

            delegate: Rectangle {
                id: seg
                required property var modelData
                required property int index

                readonly property bool active: root.current === seg.modelData.id
                readonly property bool first: seg.index === 0
                readonly property bool last: seg.index === root.options.length - 1

                width: root.width / Math.max(1, root.options.length)
                height: root.height

                color: seg.active ? Md.secondaryContainer : "transparent"
                border.width: 1
                border.color: Md.outline

                // Only the outer edges are rounded, so the group reads as one
                // control rather than a row of separate pills.
                topLeftRadius: seg.first ? Md.cornerFull : 0
                bottomLeftRadius: seg.first ? Md.cornerFull : 0
                topRightRadius: seg.last ? Md.cornerFull : 0
                bottomRightRadius: seg.last ? Md.cornerFull : 0

                Behavior on color { ColorAnimation { duration: Md.durMedium } }

                Rectangle {
                    anchors.fill: parent
                    color: Md.textOnSurface
                    opacity: hover.pressed ? Md.pressedOpacity
                        : hover.containsMouse ? Md.hoverOpacity
                        : 0
                    topLeftRadius: parent.topLeftRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomRightRadius: parent.bottomRightRadius

                    Behavior on opacity { NumberAnimation { duration: Md.durShort } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰄬"
                        font.family: Md.iconFamily
                        font.pixelSize: 14
                        color: Md.textOnSecondaryContainer
                        visible: seg.active
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: seg.modelData.label
                        color: seg.active ? Md.textOnSecondaryContainer : Md.textOnSurfaceVariant
                        font.family: Md.fontFamily
                        font.pixelSize: Md.labelLarge
                        font.weight: seg.active ? Font.DemiBold : Font.Medium

                        Behavior on color { ColorAnimation { duration: Md.durMedium } }
                    }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(seg.modelData.id)
                }
            }
        }
    }
}

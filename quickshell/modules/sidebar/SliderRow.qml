pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common

// Icon plus the shared MD3 slider, so the sidebar and the settings window
// stay visually identical instead of drifting apart as either is tweaked.
Item {
    id: root

    required property string icon
    required property int value

    signal moved(int percent)

    implicitWidth: parent?.width ?? 200
    implicitHeight: 48

    Text {
        id: iconLabel
        anchors {
            left: parent.left
            leftMargin: 4
            verticalCenter: parent.verticalCenter
        }
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: root.icon
        font.family: Md.iconFamily
        font.pixelSize: 18
        color: Md.textOnSurfaceVariant

        Behavior on color { ColorAnimation { duration: Md.durMedium } }
    }

    MdSlider {
        anchors {
            left: iconLabel.right
            right: parent.right
            leftMargin: 14
            verticalCenter: parent.verticalCenter
        }
        value: root.value
        onMoved: (percent) => root.moved(percent)
    }
}

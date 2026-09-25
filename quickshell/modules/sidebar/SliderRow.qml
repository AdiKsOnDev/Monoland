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
    property int maxValue: 100

    signal moved(int percent)

    implicitWidth: parent?.width ?? 200
    implicitHeight: 52

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
        // Thicker groove than the settings sliders — the sidebar's are the
        // primary, at-a-glance volume/brightness controls. Handle scales up
        // with it so it stays proud of the track.
        groove: 28
        handleHeight: 36
        handlePressedHeight: 42
        value: root.value
        maxValue: root.maxValue
        onMoved: (percent) => root.moved(percent)
    }
}

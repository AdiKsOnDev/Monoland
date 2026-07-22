pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services
import qs.modules.common

PanelWindow {
    id: root

    required property var screen
    property bool sidebarOpen: false

    onSidebarOpenChanged: {
        if (sidebarOpen) dismiss()
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusiveZone: -1
    color: "transparent"

    mask: Region { item: osdPill }

    readonly property int pillWidth: 56
    readonly property int pillHeight: 280
    readonly property int rightMargin: 20
    readonly property int topMargin: 60

    property string icon: ""
    property int value: 0
    property bool isVisible: false

    function showVolume() {
        icon = Audio.muted ? "󰖁" : Audio.volumePercent > 66 ? "󰕾" : Audio.volumePercent > 33 ? "󰖀" : "󰕿"
        value = Audio.muted ? 0 : Audio.volumePercent
        triggerShow()
    }

    function showBrightness() {
        icon = Brightness.brightnessPercent > 66 ? "󰃠" : Brightness.brightnessPercent > 33 ? "󰃟" : "󰃞"
        value = Brightness.brightnessPercent
        triggerShow()
    }

    function triggerShow() {
        if (root.sidebarOpen) return
        visible = true
        isVisible = true
        dismissTimer.restart()
    }

    function dismiss() {
        isVisible = false
    }

    onIsVisibleChanged: {
        if (!isVisible) hideTimer.start()
    }

    Connections {
        target: Audio
        function onVolumePercentChanged() { root.showVolume() }
        function onMutedChanged()         { root.showVolume() }
    }

    Connections {
        target: Brightness
        function onBrightnessPercentChanged() { root.showBrightness() }
    }

    Timer {
        id: dismissTimer
        interval: 1500
        repeat: false
        onTriggered: root.dismiss()
    }

    Timer {
        id: hideTimer
        interval: 300
        repeat: false
        onTriggered: root.visible = false
    }

    // Vertical version of the sidebar slider: filled pill (bottom) | playhead |
    // remaining pill (top), with the icon overlaid at the bottom.
    Item {
        id: osdPill

        width: root.pillWidth
        height: root.pillHeight

        x: root.screen.width - width - root.rightMargin
        y: root.topMargin

        readonly property real frac: Math.max(0, Math.min(1, root.value / 100))
        readonly property int thumbT: 4
        readonly property int gap: 5
        readonly property int pillW: 44
        readonly property int pillRadius: 8
        readonly property int innerRadius: 3   // corners adjacent to the playhead
        readonly property real headY: height * (1 - frac)               // playhead centre (from top)
        readonly property real filledH: Math.max(0, frac * height - gap - thumbT / 2)

        // Filled (current level) portion — grows from the bottom
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: osdPill.pillW
            height: osdPill.filledH
            radius: osdPill.pillRadius
            topLeftRadius: osdPill.innerRadius
            topRightRadius: osdPill.innerRadius
            color: Colors.primaryText

            Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
        }

        // Remaining portion — from the top down to the playhead
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: osdPill.pillW
            height: Math.max(0, osdPill.headY - osdPill.gap - osdPill.thumbT / 2)
            radius: osdPill.pillRadius
            bottomLeftRadius: osdPill.innerRadius
            bottomRightRadius: osdPill.innerRadius
            color: Colors.surfaceVariant

            Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
        }

        // Playhead — a thin horizontal bar, wider than the pills
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: osdPill.pillW + 8
            height: osdPill.thumbT
            radius: 1
            color: Colors.primaryText
            y: Math.max(0, Math.min(osdPill.height - height, osdPill.headY - height / 2))

            Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
        }

        // Icon overlaid at the bottom — on-fill colour over the filled pill, chipIcon otherwise
        Text {
            id: osdIcon
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 12
            }
            text: root.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            z: 2
            color: (12 + height / 2) < osdPill.filledH ? Colors.background : Colors.chipIcon

            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    Reveal {
        target: osdPill
        shown: root.isVisible
        motion: "right"
        distance: 22
    }
}

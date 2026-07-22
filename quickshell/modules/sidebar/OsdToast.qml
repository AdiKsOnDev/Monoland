pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services
import qs.modules.common

PanelWindow {
    id: root

    required property var screen
    property bool sidebarOpen: false

    // Start unmapped; triggerShow()/hideTimer manage visibility
    visible: false

    onSidebarOpenChanged: {
        if (sidebarOpen) dismiss()
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Surface ends at the right band's inner edge (plus the 1px seam) so the
    // compositor clips the slide behind the band, regardless of stacking
    margins.right: Frame.thickness - seam

    exclusiveZone: -1
    color: "transparent"

    // The OSD is purely informational — fully click-through
    mask: Region {}

    readonly property int pillWidth: 56
    readonly property int pillHeight: 280
    readonly property int padding: 18
    readonly property int seam: 1

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

    // Plate attached flush to the right frame band, vertically centered
    Item {
        id: plate

        width: root.pillWidth + 2 * root.padding + root.seam
        height: root.pillHeight + 2 * root.padding
        x: root.screen.width - Frame.thickness - width + root.seam
        y: (root.height - height) / 2

        Rectangle {
            anchors.fill: parent
            color: Frame.color
            topLeftRadius: Frame.radius
            bottomLeftRadius: Frame.radius
        }

        // Fillets fusing the plate with the band above and below, overlapped
        // 1px into the plate (y) and 1px into the band (x reaches plate.width,
        // whose last column lies inside the band)
        ConcaveCorner {
            corner: "bottomRight"
            x: plate.width - radius; y: -radius + 1
            radius: Frame.radius; color: Frame.color
        }
        ConcaveCorner {
            corner: "topRight"
            x: plate.width - radius; y: plate.height - 1
            radius: Frame.radius; color: Frame.color
        }

        // Vertical version of the sidebar slider: filled pill (bottom) | playhead |
        // remaining pill (top), with the icon overlaid at the bottom.
        Item {
            id: osdPill

            width: root.pillWidth
            height: root.pillHeight

            x: root.padding
            y: root.padding

            readonly property real frac: Math.max(0, Math.min(1, root.value / 100))
            readonly property int pillW: 44
            readonly property real filledH: frac * height

            // Track — single capsule spanning the full height
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: osdPill.pillW
                height: parent.height
                radius: osdPill.pillW / 2
                color: Colors.surfaceVariant
            }

            // Filled portion — a capsule inside the track, grows from the bottom
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: osdPill.pillW
                height: osdPill.filledH
                radius: osdPill.pillW / 2
                color: Colors.primaryText

                Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
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
    }

    Reveal {
        target: plate
        shown: root.isVisible
        motion: "emerge"
        edge: "right"
        squash: 0.90
        bulge: 1.03
        overshoot: 1.02
        distance: Frame.radius + 4
        inDuration: 240
        outDuration: 160
    }
}

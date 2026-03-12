pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

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

    Rectangle {
        id: osdPill

        width: root.pillWidth
        height: root.pillHeight
        radius: root.pillWidth / 2
        color: Colors.background
        clip: true

        x: root.isVisible
            ? root.screen.width - width - root.rightMargin
            : root.screen.width
        y: root.topMargin

        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // Filled level bar (grows from bottom)
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: parent.height * Math.max(0, Math.min(1, root.value / 100))
            color: Colors.primaryText
            radius: parent.radius

            Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
        }

        // Icon at bottom
        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 12
            }
            text: root.icon
            font.family: Settings.iconFont
            font.pixelSize: 18
            color: root.value > 15 ? Colors.background : Colors.primaryText
            z: 1

            Behavior on color { ColorAnimation { duration: 80 } }
        }


    }
}

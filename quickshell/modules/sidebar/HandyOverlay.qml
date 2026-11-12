pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.modules.common

PanelWindow {
    id: root

    readonly property bool selectedScreen: screen.name === Handy.screenName
        || (!Quickshell.screens.some(s => s.name === Handy.screenName)
            && screen === Quickshell.screens[0])
    readonly property bool shown: Handy.active && selectedScreen

    anchors { top: true; left: true; right: true }
    implicitHeight: 212
    exclusiveZone: -1
    color: "transparent"
    focusable: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "monoland-handy"
    mask: Region {}
    visible: false

    onShownChanged: {
        if (shown) {
            hideTimer.stop()
            visible = true
            return
        }
        hideTimer.restart()
    }
    Component.onCompleted: visible = shown

    Timer {
        id: hideTimer
        interval: 180
        onTriggered: root.visible = false
    }

    HandyIndicator {
        id: indicator
        width: Math.min(implicitWidth, parent.width - 32)
        height: implicitHeight
        x: (parent.width - width) / 2
        y: 60
        phase: Handy.phase
        elapsed: Handy.elapsed
        hint: Handy.meterHint
        message: Handy.message
        levels: Handy.levels
    }

    Reveal {
        target: indicator
        shown: root.shown
        motion: "down"
        distance: 10
        inDuration: 220
    }
}

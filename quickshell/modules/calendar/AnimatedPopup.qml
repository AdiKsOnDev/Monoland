pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.common

PanelWindow {
    id: root

    required property var screen

    property int popupWidth: 390
    property bool isOpen: false
    function toggle() {
        if (!isOpen) visible = true
        isOpen = !isOpen
    }

    onIsOpenChanged: {
        if (isOpen) visible = true
        else hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 340
        onTriggered: root.visible = false
    }

    // When true, the popup right-aligns to the bar's right edge instead of centering
    property bool alignRight: false

    // Exposed so callers can keep the popup open while the user hovers it
    readonly property bool isHovered: popupHoverArea.containsMouse

    // Visual Item children go into the column; non-visual objects (Timer, Connections…)
    // are accepted via data and parented to the window root.
    default property alias content: contentColumn.data

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: -1
    implicitHeight: screen.height
    color: "transparent"
    focusable: isOpen

    // Mask to a plain proxy, not `box`: `box` has layer.enabled (for the shadow),
    // and a layered item reports no usable region to Quickshell — which collapses
    // the window's input region and makes the popup unclickable.
    mask: Region {
        item: maskProxy
    }

    Item {
        id: maskProxy
        x: box.x
        y: box.y
        width: box.width
        height: box.height
    }

    readonly property int barRightEdge: Math.round(root.screen.width * 0.975)
    readonly property int barTopMargin: 60

    Rectangle {
        id: box

        clip: true

        width: root.popupWidth
        x: root.alignRight
            ? root.barRightEdge - width
            : (parent.width - width) / 2
        y: root.barTopMargin
        implicitHeight: contentColumn.implicitHeight + 24
        height: implicitHeight
        radius: 16

        // Subtle top-lit gradient for surface depth
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(Colors.background, 1.4) }
            GradientStop { position: 1.0; color: Colors.background }
        }
        border.width: 1
        border.color: Colors.surfaceVariant

        // Elevation: soft drop shadow so the popup floats above the desktop
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.5)
            shadowBlur: 0.8
            shadowVerticalOffset: 8
            autoPaddingEnabled: true
        }

        MouseArea {
            id: popupHoverArea
            anchors.fill: parent
            hoverEnabled: root.visible
            propagateComposedEvents: true
            acceptedButtons: Qt.NoButton
        }

        Column {
            id: contentColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 20
            }
            spacing: 20
        }
    }

    Reveal {
        target: box
        shown: root.isOpen
        motion: "rise"
        distance: 12
    }
}

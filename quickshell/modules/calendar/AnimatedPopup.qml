pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

PanelWindow {
    id: root

    required property var screen

    property int popupWidth: 390
    property bool isOpen: false
    function toggle() {
        if (!isOpen) visible = true
        isOpen = !isOpen
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

    mask: Region {
        item: box
    }

    readonly property int barRightEdge: Math.round(root.screen.width * 0.975)
    readonly property int barTopMargin: 60

    Rectangle {
        id: box

        clip: true

        width: root.popupWidth
        x: root.alignRight
            ? (root.isOpen ? root.barRightEdge - width : root.barRightEdge)
            : (parent.width - width) / 2
        y: root.alignRight
            ? root.barTopMargin
            : (root.isOpen ? root.barTopMargin : -(implicitHeight + root.barTopMargin))
        implicitHeight: contentColumn.implicitHeight + 24
        height: implicitHeight
        color: Colors.background
        radius: 16

        Behavior on x { enabled: root.alignRight; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !root.alignRight; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        onXChanged: if (!root.isOpen && root.alignRight && x >= root.barRightEdge) root.visible = false
        onYChanged: if (!root.isOpen && !root.alignRight && y <= -implicitHeight) root.visible = false

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
}

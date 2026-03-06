pragma ComponentBehavior: Bound

import Quickshell.Hyprland
import QtQuick
import qs.services

Item {
    id: root

    required property HyprlandWorkspace workspace

    implicitWidth: 28
    implicitHeight: 28

    readonly property bool isActive: workspace.focused
    readonly property bool isOccupied: workspace.toplevels.count > 0
    readonly property bool isHovered: hoverArea.containsMouse

    Rectangle {
        anchors.centerIn: parent
        width: root.isActive ? 22 : (root.isHovered ? 12 : (root.isOccupied ? 8 : 6))
        height: root.isActive ? 22 : (root.isHovered ? 12 : (root.isOccupied ? 8 : 6))
        radius: root.isActive ? 7 : width / 2
        color: root.isActive ? Colors.workspaceActive : (root.isHovered ? Colors.primaryText : (root.isOccupied ? Colors.workspaceOccupied : Colors.workspaceInactive))

        Behavior on width  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color  { ColorAnimation  { duration: 180 } }
        Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }


    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.workspace.activate()
        cursorShape: Qt.PointingHandCursor
    }
}

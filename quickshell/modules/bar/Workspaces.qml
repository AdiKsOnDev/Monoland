pragma ComponentBehavior: Bound

import Quickshell.Hyprland
import QtQuick

Row {
    spacing: 2

    Repeater {
        model: Hyprland.workspaces

        WorkspaceButton {
            required property var modelData
            workspace: modelData
            visible: modelData.id > 0
        }
    }
}

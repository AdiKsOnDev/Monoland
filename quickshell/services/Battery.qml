pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int capacity: 0
    property string status: "unknown"

    readonly property string capacityLabel: capacity + "%"
    readonly property bool isCharging: status === "charging"

    FileView {
        id: capacityFile
        path: "/sys/class/power_supply/BAT0/capacity"
        watchChanges: true
        preload: true
        Component.onCompleted: root.capacity = parseInt(capacityFile.text().trim()) || 0
    }

    FileView {
        id: statusFile
        path: "/sys/class/power_supply/BAT0/status"
        watchChanges: true
        preload: true
        Component.onCompleted: root.status = statusFile.text().trim().toLowerCase()
    }

    Connections {
        target: capacityFile
        function onInternalTextChanged() {
            root.capacity = parseInt(capacityFile.text().trim()) || 0
        }
    }

    Connections {
        target: statusFile
        function onInternalTextChanged() {
            root.status = statusFile.text().trim().toLowerCase()
        }
    }
}

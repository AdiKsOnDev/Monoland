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
    readonly property bool isCharging: status === "charging" || status === "pending-charge"

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

    FileView {
        id: acOnlineFile
        path: "/sys/class/power_supply/AC0/online"
        watchChanges: true
        preload: true
    }

    Connections {
        target: statusFile
        function onInternalTextChanged() {
            root.status = statusFile.text().trim().toLowerCase()
        }
    }

    Connections {
        target: acOnlineFile
        function onInternalTextChanged() {
            // AC online but battery not charging means pending/topping off
            if (parseInt(acOnlineFile.text().trim()) === 1 && root.status !== "charging") {
                root.status = "pending-charge"
            }
        }
    }

    Component.onCompleted: {
        if (parseInt(acOnlineFile.text().trim()) === 1 && root.status !== "charging") {
            root.status = "pending-charge"
        }
    }

    Connections {
        target: capacityFile
        function onInternalTextChanged() {
            root.capacity = parseInt(capacityFile.text().trim()) || 0
        }
    }
}

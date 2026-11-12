pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int capacity: 0
    property string batteryStatus: "unknown"
    property bool acOnline: false

    readonly property string status: acOnline && batteryStatus !== "charging" ? "pending-charge" : batteryStatus
    readonly property string capacityLabel: capacity + "%"
    readonly property bool isCharging: status === "charging" || status === "pending-charge"

    FileView {
        id: capacityFile
        path: "/sys/class/power_supply/BAT0/capacity"
        watchChanges: true
        preload: true
        onFileChanged: reload()
        onLoaded: root.capacity = parseInt(capacityFile.text().trim()) || 0
    }

    FileView {
        id: statusFile
        path: "/sys/class/power_supply/BAT0/status"
        watchChanges: true
        preload: true
        onFileChanged: reload()
        onLoaded: root.batteryStatus = statusFile.text().trim().toLowerCase()
    }

    FileView {
        id: acOnlineFile
        path: "/sys/class/power_supply/AC0/online"
        watchChanges: true
        preload: true
        onFileChanged: reload()
        onLoaded: root.acOnline = parseInt(acOnlineFile.text().trim()) === 1
    }

    // Sysfs attributes can change without emitting file-watch notifications.
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            capacityFile.reload()
            statusFile.reload()
            acOnlineFile.reload()
        }
    }
}

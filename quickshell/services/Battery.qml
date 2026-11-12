pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property int capacity: parseInt(capacityFile.text().trim(), 10) || 0
    readonly property string batteryStatus: statusFile.text().trim().toLowerCase() || "unknown"
    readonly property bool acOnline: acOnlineFile.text().trim() === "1"
    readonly property string status: acOnline && batteryStatus !== "charging" ? "pending-charge" : batteryStatus

    readonly property string capacityLabel: capacity + "%"
    readonly property bool isCharging: status === "charging" || status === "pending-charge"

    FileView {
        id: capacityFile
        path: "/sys/class/power_supply/BAT0/capacity"
        watchChanges: true
        preload: true
        onFileChanged: capacityFile.reload()
    }

    FileView {
        id: statusFile
        path: "/sys/class/power_supply/BAT0/status"
        watchChanges: true
        preload: true
        onFileChanged: statusFile.reload()
    }

    FileView {
        id: acOnlineFile
        path: "/sys/class/power_supply/AC0/online"
        watchChanges: true
        preload: true
        onFileChanged: acOnlineFile.reload()
    }

    // Sysfs power attributes do not reliably emit filesystem change notifications.
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

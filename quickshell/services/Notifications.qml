pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    readonly property var notifications: server.trackedNotifications

    // Focus mode / Do Not Disturb — suppresses notification toasts when on
    property bool doNotDisturb: false

    // Maps notification id -> arrival Date
    property var arrivalTimes: ({})

    function arrivalTimeFor(notifId) {
        return arrivalTimes[notifId] ?? null
    }

    // Resolve a notification's app logo to a usable image URL. The freedesktop
    // appIcon hint is usually a theme icon NAME (e.g. "org.telegram.desktop"),
    // which IconImage cannot open directly — it must go through iconPath().
    // Falls back to the app's desktop-entry icon when the hint is missing.
    function iconFor(notif) {
        if (!notif)
            return ""

        const ai = notif.appIcon ?? ""
        if (ai !== "") {
            if (ai.startsWith("file:") || ai.startsWith("qrc:"))
                return ai
            if (ai.startsWith("/"))
                return "file://" + ai
            const p = Quickshell.iconPath(ai, true)
            if (p !== "")
                return p
        }

        // Fall back to the matching desktop entry's icon
        const entry = DesktopEntries.heuristicLookup(notif.appName ?? "")
        if (entry && entry.icon) {
            const p = Quickshell.iconPath(entry.icon, true)
            if (p !== "")
                return p
        }

        return ""
    }

    property var dismissQueue: []

    function dismissAll() {
        dismissQueue = [...notifications.values]
        cascadeTimer.start()
    }

    Timer {
        id: cascadeTimer
        interval: 80
        repeat: true
        onTriggered: {
            if (root.dismissQueue.length === 0) {
                stop()
                return
            }
            const next = root.dismissQueue[0]
            root.dismissQueue = root.dismissQueue.slice(1)
            next.dismiss()
        }
    }

    signal notificationArrived(var notification)

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: false

        onNotification: (notif) => {
            notif.tracked = true
            const times = Object.assign({}, root.arrivalTimes)
            times[notif.id] = new Date()
            root.arrivalTimes = times
            root.notificationArrived(notif)
        }
    }
}

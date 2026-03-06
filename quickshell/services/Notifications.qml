pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    readonly property var notifications: server.trackedNotifications

    // Maps notification id -> arrival Date
    property var arrivalTimes: ({})

    function arrivalTimeFor(notifId) {
        return arrivalTimes[notifId] ?? null
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
        actionsSupported: true

        onNotification: (notif) => {
            notif.tracked = true
            const times = Object.assign({}, root.arrivalTimes)
            times[notif.id] = new Date()
            root.arrivalTimes = times
            root.notificationArrived(notif)
        }
    }
}

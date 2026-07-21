pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs.services
import qs.modules.common

PanelWindow {
    id: root

    required property var screen
    property bool sidebarOpen: false

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusiveZone: -1
    color: "transparent"

    mask: Region { item: cardLoader.item ?? emptyRegion }

    readonly property int toastWidth: 380
    readonly property int toastRightMargin: 16
    readonly property int toastTopMargin: 60

    property var pendingNotification: null
    property bool isVisible: false

    function show(notif) {
        pendingNotification = notif
        isVisible = true
        dismissTimer.restart()
    }

    function dismiss() {
        isVisible = false
    }

    onSidebarOpenChanged: {
        if (sidebarOpen) dismiss()
    }

    Connections {
        target: Notifications
        function onNotificationArrived(notif) {
            // Critical notifications (e.g. deep-work breaks) still toast during focus mode
            const critical = notif.urgency === NotificationUrgency.Critical
            if (!root.sidebarOpen && (!Notifications.doNotDisturb || critical))
                root.show(notif)
        }
    }

    onIsVisibleChanged: {
        if (isVisible) visible = true
        else hideTimer.start()
    }

    Timer {
        id: dismissTimer
        interval: 5000
        repeat: false
        onTriggered: root.dismiss()
    }

    Timer {
        id: hideTimer
        interval: 300
        repeat: false
        onTriggered: root.visible = false
    }

    // Zero-size fallback for the mask when no card is loaded
    Item {
        id: emptyRegion
        width: 0
        height: 0
    }

    Loader {
        id: cardLoader
        active: root.pendingNotification !== null

        readonly property int targetX: root.screen.width - root.toastWidth - root.toastRightMargin

        x: targetX
        y: root.toastTopMargin
        width: root.toastWidth

        sourceComponent: NotificationCard {
            notification: root.pendingNotification
            width: cardLoader.width
            onDismissed: root.dismiss()
        }
    }

    Droplet {
        target: cardLoader
        shown: root.isVisible
        origin: Item.TopRight
    }
}

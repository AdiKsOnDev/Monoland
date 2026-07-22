pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.common

PanelWindow {
    id: root

    required property var screen
    property bool sidebarOpen: false

    // Start unmapped; show()/hideTimer manage visibility
    visible: false

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Surface starts below the bar so the compositor clips the slide — the
    // toast can never draw over the bar, regardless of window stacking
    margins.top: Frame.barHeight - seam

    exclusiveZone: -1
    color: "transparent"

    // Mask to a plain proxy: `plate` has layer.enabled (for the shadow) and a
    // layered item reports no usable input region to Quickshell.
    mask: Region { item: root.pendingNotification !== null ? maskProxy : emptyRegion }

    Item {
        id: maskProxy
        x: plate.x
        y: plate.y
        width: plate.width
        height: plate.height
    }

    readonly property int toastWidth: 380
    readonly property int toastPadding: 10
    readonly property int seam: 1

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

    // Plate tucked into the top-right frame corner: attached to the bar above
    // and the right band, so the toast reads as fluid emerging from the frame.
    Item {
        id: plate

        width: root.toastWidth + 2 * root.toastPadding
        height: (cardLoader.item?.height ?? 0) + 2 * root.toastPadding + root.seam
        x: root.screen.width - Frame.thickness - width + root.seam
        y: 0

        // No shadow layer: the layered texture resamples at fractional scale
        // and shows a hairline along the edges. Flat matte matches the frame.

        Rectangle {
            id: box

            anchors.fill: parent
            color: Frame.color
            clip: true
            bottomLeftRadius: Frame.radius

            Loader {
                id: cardLoader
                active: root.pendingNotification !== null

                x: root.toastPadding
                y: root.toastPadding + root.seam
                width: root.toastWidth

                sourceComponent: NotificationCard {
                    notification: root.pendingNotification
                    width: cardLoader.width
                    onDismissed: root.dismiss()
                }
            }
        }

        // Fillets fusing the plate with the bar (left) and the right band
        // (below), overlapped 1px into the plate to avoid AA seams
        ConcaveCorner {
            corner: "topRight"
            x: -radius + 1; y: 0
            radius: Frame.radius; color: Frame.color
        }
        ConcaveCorner {
            corner: "topRight"
            x: plate.width - radius; y: plate.height - 1
            radius: Frame.radius; color: Frame.color
        }
    }

    Reveal {
        target: plate
        shown: root.isVisible
        motion: "emerge"
        edge: "top"
        squash: 0.92
        bulge: 1.02
        overshoot: 1.015
        distance: Frame.radius + 4
        inDuration: 280
    }
}

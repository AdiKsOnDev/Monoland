pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Flickable {
    id: root

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property var items: Notifications.notifications.values

    function timeLabel(notif) {
        const t = Notifications.arrivalTimeFor(notif.id)
        if (!t) return ""
        return Qt.formatDateTime(t, "HH:mm")
    }

    Column {
        id: column
        width: root.width
        spacing: 16

        MdCard {
            width: column.width

            MdListItem {
                width: parent.width
                icon: Notifications.doNotDisturb ? "󰂛" : "󰂚"
                iconColor: Notifications.doNotDisturb ? Md.primary : Md.textOnSurfaceVariant
                headline: "Do Not Disturb"
                supporting: Notifications.doNotDisturb
                    ? "Toasts are suppressed"
                    : "Toasts appear as they arrive"
                onClicked: Notifications.doNotDisturb = !Notifications.doNotDisturb

                MdSwitch {
                    checked: Notifications.doNotDisturb
                    onToggled: Notifications.doNotDisturb = !Notifications.doNotDisturb
                }
            }
        }

        MdCard {
            width: column.width
            padding: 8

            MdListItem {
                width: parent.width
                icon: "󰎟"
                headline: root.items.length === 0
                    ? "No notifications"
                    : root.items.length + (root.items.length === 1 ? " notification" : " notifications")
                supporting: root.items.length === 0 ? "" : "Tap an entry to dismiss it"
                interactive: false

                Rectangle {
                    visible: root.items.length > 0
                    width: clearLabel.implicitWidth + 28
                    height: 36
                    radius: Md.cornerFull
                    color: clearHover.containsMouse ? Md.primary : Md.surfaceContainerHigh

                    Behavior on color { ColorAnimation { duration: Md.durMedium } }

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: clearHover.containsMouse ? Md.textOnPrimary : Md.textOnSurface
                        font.family: Md.fontFamily
                        font.pixelSize: Md.labelLarge
                        font.weight: Font.Medium

                        Behavior on color { ColorAnimation { duration: Md.durMedium } }
                    }

                    MouseArea {
                        id: clearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.dismissAll()
                    }
                }
            }
        }

        MdCard {
            width: column.width
            visible: root.items.length > 0
            title: "Recent"
            padding: 8

            Repeater {
                model: root.items

                delegate: MdListItem {
                    id: notifItem
                    required property var modelData

                    width: column.width - 16
                    // The model drops entries as they are dismissed; guard every
                    // field so a delegate mid-teardown doesn't read from null.
                    headline: notifItem.modelData?.appName || "Notification"
                    supporting: notifItem.modelData?.summary || notifItem.modelData?.body || ""
                    icon: "󰎟"
                    onClicked: notifItem.modelData?.dismiss()

                    Text {
                        text: notifItem.modelData ? root.timeLabel(notifItem.modelData) : ""
                        color: Md.textOnSurfaceVariant
                        font.family: Md.fontFamily
                        font.pixelSize: Md.labelSmall
                    }
                }
            }
        }
    }
}

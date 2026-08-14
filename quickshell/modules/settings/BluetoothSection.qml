pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Flickable {
    id: root

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // Connected, then paired, then the rest alphabetically
    readonly property var sorted: {
        const list = Bluetooth.devices.slice()
        list.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            if (a.paired !== b.paired) return a.paired ? -1 : 1
            return (a.name || "").localeCompare(b.name || "")
        })
        return list
    }

    function iconFor(device) {
        const icon = (device.icon || "").toLowerCase()
        if (icon.includes("headset") || icon.includes("headphone")) return "󰋋"
        if (icon.includes("audio") || icon.includes("speaker")) return "󰓃"
        if (icon.includes("phone")) return "󰏳"
        if (icon.includes("mouse")) return "󰍽"
        if (icon.includes("keyboard")) return "󰌌"
        return "󰂯"
    }

    Column {
        id: column
        width: root.width
        spacing: 16

        MdCard {
            width: column.width

            MdListItem {
                width: parent.width
                icon: Bluetooth.enabled ? "󰂯" : "󰂲"
                iconColor: Bluetooth.enabled ? Md.primary : Md.textOnSurfaceVariant
                headline: "Bluetooth"
                supporting: Bluetooth.enabled
                    ? (Bluetooth.connectedDeviceName !== ""
                        ? "Connected to " + Bluetooth.connectedDeviceName
                        : "Not connected")
                    : "Off"
                onClicked: Bluetooth.toggle()

                MdSwitch {
                    checked: Bluetooth.enabled
                    onToggled: Bluetooth.toggle()
                }
            }
        }

        MdCard {
            width: column.width
            visible: Bluetooth.enabled
            padding: 8

            MdListItem {
                width: parent.width
                icon: "󰑐"
                iconColor: Bluetooth.discovering ? Md.primary : Md.textOnSurfaceVariant
                headline: Bluetooth.discovering ? "Scanning for devices…" : "Scan for devices"
                supporting: Bluetooth.discovering ? "Keep this open to discover nearby devices" : ""
                onClicked: Bluetooth.setDiscovering(!Bluetooth.discovering)

                MdSwitch {
                    checked: Bluetooth.discovering
                    onToggled: Bluetooth.setDiscovering(!Bluetooth.discovering)
                }
            }
        }

        MdCard {
            width: column.width
            visible: Bluetooth.enabled
            title: "Devices"
            padding: 8

            Repeater {
                model: root.sorted

                delegate: MdListItem {
                    id: devItem
                    required property var modelData
                    width: column.width - 16
                    icon: root.iconFor(devItem.modelData)
                    iconColor: devItem.modelData.connected ? Md.primary : Md.textOnSurfaceVariant
                    headline: devItem.modelData.name || "Unknown device"
                    supporting: devItem.modelData.connected ? "Connected"
                        : devItem.modelData.paired ? "Paired"
                        : "Available"
                    onClicked: {
                        if (devItem.modelData.connected) devItem.modelData.disconnect()
                        else devItem.modelData.connect()
                    }

                    Text {
                        text: devItem.modelData.connected ? "󰄬" : ""
                        font.family: Md.iconFamily
                        font.pixelSize: 16
                        color: Md.primary
                        visible: text !== ""
                    }
                }
            }

            Text {
                width: column.width - 16
                horizontalAlignment: Text.AlignHCenter
                text: Bluetooth.discovering ? "Scanning…" : "No devices found"
                color: Md.textOnSurfaceVariant
                font.family: Md.fontFamily
                font.pixelSize: Md.bodyMedium
                topPadding: 16
                bottomPadding: 16
                visible: root.sorted.length === 0
            }
        }

        Text {
            width: column.width
            horizontalAlignment: Text.AlignHCenter
            text: "Bluetooth is off"
            color: Md.textOnSurfaceVariant
            font.family: Md.fontFamily
            font.pixelSize: Md.bodyMedium
            topPadding: 32
            visible: !Bluetooth.enabled
        }
    }
}

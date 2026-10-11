pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property bool enabled: Networking.wifiEnabled

    readonly property bool ethernetConnected: {
        for (const device of Networking.devices.values) {
            if (device.type === DeviceType.Wired && device.connected) return true
        }
        return false
    }

    PersistentProperties {
        id: ethernetPolicy
        reloadableId: "ethernet-wifi-policy"
        property bool restoreWifi: false
        onLoaded: Qt.callLater(root.syncEthernetPolicy)
    }

    onEthernetConnectedChanged: Qt.callLater(root.syncEthernetPolicy)
    onEnabledChanged: Qt.callLater(root.syncEthernetPolicy)

    function syncEthernetPolicy() {
        if (ethernetConnected) {
            if (!enabled) return
            ethernetPolicy.restoreWifi = true
            Networking.wifiEnabled = false
            return
        }
        if (!ethernetPolicy.restoreWifi) return
        ethernetPolicy.restoreWifi = false
        Networking.wifiEnabled = true
    }

    // The active Wi-Fi device and its visible networks (for the control panel)
    readonly property var device: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wifi) return d
        return null
    }

    readonly property var networks: device ? device.networks.values : []

    readonly property string networkName: {
        const devices = Networking.devices.values
        for (const device of devices) {
            if (device.type !== DeviceType.Wifi) continue
            const networks = device.networks.values
            for (const network of networks) {
                if (network.connected) return network.name
            }
        }
        return ""
    }

    readonly property real signalStrength: {
        const devices = Networking.devices.values
        for (const device of devices) {
            if (device.type !== DeviceType.Wifi) continue
            const networks = device.networks.values
            for (const network of networks) {
                if (network.connected) return network.signalStrength
            }
        }
        return 0
    }

    readonly property string signalIcon: {
        if (!enabled) return "󰤭"
        if (signalStrength >= 0.8) return "󰤨"
        if (signalStrength >= 0.6) return "󰤥"
        if (signalStrength >= 0.4) return "󰤢"
        if (signalStrength >= 0.2) return "󰤟"
        return "󰤯"
    }

    function toggle() {
        if (ethernetConnected) return
        Networking.wifiEnabled = !Networking.wifiEnabled
    }
}

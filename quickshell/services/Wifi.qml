pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property bool enabled: Networking.wifiEnabled

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

    function toggle() { Networking.wifiEnabled = !Networking.wifiEnabled }
}

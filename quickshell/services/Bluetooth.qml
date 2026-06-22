pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false

    readonly property var devices: adapter?.devices?.values ?? []
    readonly property bool discovering: adapter?.discovering ?? false

    function setDiscovering(v) { if (adapter) adapter.discovering = v }

    readonly property string connectedDeviceName: {
        const devices = Bluetooth.defaultAdapter?.devices?.values ?? []
        for (const device of devices) {
            if (device.connected) return device.name
        }
        return ""
    }

    function toggle() {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
    }
}

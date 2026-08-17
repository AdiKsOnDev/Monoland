pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Quickshell.Networking
import qs.services

Flickable {
    id: root

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // Poll link details only while this page is on screen
    Component.onCompleted: NetworkInfo.active = true
    Component.onDestruction: NetworkInfo.active = false

    // Connected first, then by signal strength
    readonly property var sorted: {
        const list = Wifi.networks.slice()
        list.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            return (b.signalStrength ?? 0) - (a.signalStrength ?? 0)
        })
        return list
    }

    property var pskNetwork: null

    // Multi-valued nmcli keys, in index order
    readonly property var ip4Addrs:  NetworkInfo.collect("IP4.ADDRESS")
    readonly property var ip4Dns:    NetworkInfo.collect("IP4.DNS")
    readonly property var ip4Routes: NetworkInfo.collect("IP4.ROUTE")
    readonly property var ip6Addrs:  NetworkInfo.collect("IP6.ADDRESS")
    readonly property var ip6Routes: NetworkInfo.collect("IP6.ROUTE")

    property string copied: ""

    function copy(text) {
        if (!text) return
        // printf-into-wl-copy rather than passing the value as an argument, so
        // values that begin with a dash can't be read as flags
        copier.command = ["bash", "-c", 'printf "%s" "$1" | wl-copy', "wl-copy", text]
        copier.running = true
        root.copied = text
        copiedTimer.restart()
    }

    Process { id: copier }

    Timer {
        id: copiedTimer
        interval: 1500
        onTriggered: root.copied = ""
    }

    function iconFor(strength) {
        if (strength >= 0.8) return "󰤨"
        if (strength >= 0.6) return "󰤥"
        if (strength >= 0.4) return "󰤢"
        if (strength >= 0.2) return "󰤟"
        return "󰤯"
    }

    Column {
        id: column
        width: root.width
        spacing: 16

        MdCard {
            width: column.width

            MdListItem {
                width: parent.width
                icon: Wifi.signalIcon
                iconColor: Wifi.enabled ? Md.primary : Md.textOnSurfaceVariant
                headline: "Wi-Fi"
                supporting: Wifi.enabled
                    ? (Wifi.networkName !== "" ? "Connected to " + Wifi.networkName : "Not connected")
                    : "Off"
                onClicked: Wifi.toggle()

                MdSwitch {
                    checked: Wifi.enabled
                    onToggled: Wifi.toggle()
                }
            }
        }

        // ── Current connection ───────────────────────────────────────────
        MdCard {
            id: details
            width: column.width
            visible: Wifi.enabled && NetworkInfo.connected
            title: root.copied !== "" ? "Current connection  ·  copied" : "Current connection"
            padding: 20

            // MdCard insets its column by `padding` on both sides
            readonly property int rowWidth: column.width - 2 * padding

            component Group: Text {
                color: Md.primary
                font.family: Md.fontFamily
                font.pixelSize: Md.labelSmall
                font.weight: Font.DemiBold
                topPadding: 12
                bottomPadding: 4
                leftPadding: 2
            }

            Group { text: "LINK" }

            MdKeyValue {
                width: details.rowWidth
                label: "SSID"
                value: NetworkInfo.ssid
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "BSSID"
                value: NetworkInfo.bssid
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Mode"
                value: NetworkInfo.mode
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Band / channel"
                value: NetworkInfo.band !== "" ? NetworkInfo.band + "  ·  ch " + NetworkInfo.channel : ""
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Frequency"
                value: NetworkInfo.frequency
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Max rate"
                value: NetworkInfo.rate
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Link quality"
                value: NetworkInfo.signalQuality !== "" ? NetworkInfo.signalQuality + " / 100" : ""
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Security"
                value: NetworkInfo.security
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "RSN flags"
                value: NetworkInfo.rsnFlags === "(none)" ? "" : NetworkInfo.rsnFlags
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "WPA flags"
                value: NetworkInfo.wpaFlags === "(none)" ? "" : NetworkInfo.wpaFlags
                onCopyRequested: (t) => root.copy(t)
            }

            Group { text: "IPv4" }

            Repeater {
                model: root.ip4Addrs
                delegate: MdKeyValue {
                    required property var modelData
                    required property int index
                    width: details.rowWidth
                    label: root.ip4Addrs.length > 1 ? "Address " + (index + 1) : "Address"
                    value: modelData
                    onCopyRequested: (t) => root.copy(t)
                }
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Gateway"
                value: NetworkInfo.value("IP4.GATEWAY")
                onCopyRequested: (t) => root.copy(t)
            }
            Repeater {
                model: root.ip4Dns
                delegate: MdKeyValue {
                    required property var modelData
                    required property int index
                    width: details.rowWidth
                    label: root.ip4Dns.length > 1 ? "DNS " + (index + 1) : "DNS"
                    value: modelData
                    onCopyRequested: (t) => root.copy(t)
                }
            }
            Repeater {
                model: root.ip4Routes
                delegate: MdKeyValue {
                    required property var modelData
                    required property int index
                    width: details.rowWidth
                    label: "Route " + (index + 1)
                    value: modelData
                    onCopyRequested: (t) => root.copy(t)
                }
            }

            Group { text: "IPv6" }

            Repeater {
                model: root.ip6Addrs
                delegate: MdKeyValue {
                    required property var modelData
                    required property int index
                    width: details.rowWidth
                    label: root.ip6Addrs.length > 1 ? "Address " + (index + 1) : "Address"
                    value: modelData
                    onCopyRequested: (t) => root.copy(t)
                }
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Gateway"
                value: NetworkInfo.value("IP6.GATEWAY")
                onCopyRequested: (t) => root.copy(t)
            }
            Repeater {
                model: root.ip6Routes
                delegate: MdKeyValue {
                    required property var modelData
                    required property int index
                    width: details.rowWidth
                    label: "Route " + (index + 1)
                    value: modelData
                    onCopyRequested: (t) => root.copy(t)
                }
            }

            Group { text: "INTERFACE" }

            MdKeyValue {
                width: details.rowWidth
                label: "Device"
                value: NetworkInfo.iface
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "MAC"
                value: NetworkInfo.value("GENERAL.HWADDR")
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "MTU"
                value: NetworkInfo.value("GENERAL.MTU")
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "State"
                value: NetworkInfo.value("GENERAL.STATE")
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Connectivity"
                value: {
                    const v4 = NetworkInfo.value("GENERAL.IP4-CONNECTIVITY")
                    const v6 = NetworkInfo.value("GENERAL.IP6-CONNECTIVITY")
                    if (v4 === "" && v6 === "") return ""
                    return "IPv4 " + v4 + "  ·  IPv6 " + v6
                }
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Metered"
                value: NetworkInfo.value("GENERAL.METERED")
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Autoconnect"
                value: NetworkInfo.value("GENERAL.AUTOCONNECT")
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Driver"
                value: {
                    const d = NetworkInfo.value("GENERAL.DRIVER")
                    const v = NetworkInfo.value("GENERAL.DRIVER-VERSION")
                    return v !== "" ? d + "  ·  " + v : d
                }
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Firmware"
                value: NetworkInfo.value("GENERAL.FIRMWARE-VERSION")
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Adapter"
                value: {
                    const vendor = NetworkInfo.value("GENERAL.VENDOR")
                    const product = NetworkInfo.value("GENERAL.PRODUCT")
                    return [vendor, product].filter(x => x !== "").join("  ·  ")
                }
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "Profile"
                value: NetworkInfo.value("GENERAL.CONNECTION")
                onCopyRequested: (t) => root.copy(t)
            }
            MdKeyValue {
                width: details.rowWidth
                label: "UUID"
                value: NetworkInfo.value("GENERAL.CON-UUID")
                onCopyRequested: (t) => root.copy(t)
            }
        }

        // ── IPv4 configuration (editable) ────────────────────────────────
        MdCard {
            id: editor
            width: column.width
            visible: Wifi.enabled && NetworkInfo.connected
            title: "IPv4 configuration"
            padding: 20

            readonly property int rowWidth: column.width - 2 * padding

            // Draft state, seeded from the profile and re-seeded whenever the
            // profile changes underneath us (unless the user is mid-edit).
            property string method: "auto"
            property string address: ""
            property string gateway: ""
            property string dns: ""
            property bool ignoreAutoDns: false
            property bool dirty: false

            function seed() {
                method = NetworkInfo.setting("ipv4.method") === "manual" ? "manual" : "auto"
                address = NetworkInfo.setting("ipv4.addresses")
                gateway = NetworkInfo.setting("ipv4.gateway")
                dns = NetworkInfo.setting("ipv4.dns").replace(/,/g, " ")
                ignoreAutoDns = NetworkInfo.setting("ipv4.ignore-auto-dns") === "yes"
                dirty = false
            }

            Component.onCompleted: seed()

            Connections {
                target: NetworkInfo
                function onProfileChanged() { if (!editor.dirty) editor.seed() }
            }

            readonly property string problem:
                NetworkInfo.validateIpv4(method, address, gateway, dns)

            MdSegmented {
                width: editor.rowWidth
                enabled: !NetworkInfo.applying
                options: [
                    { id: "auto",   label: "Automatic (DHCP)" },
                    { id: "manual", label: "Manual" },
                ]
                current: editor.method
                onSelected: (id) => { editor.method = id; editor.dirty = true }
            }

            Item { width: 1; height: 6 }

            MdTextField {
                width: editor.rowWidth
                label: "Address (CIDR)"
                placeholder: "192.168.1.50/24"
                text: editor.address
                enabled: editor.method === "manual" && !NetworkInfo.applying
                invalid: editor.method === "manual" && text.trim() !== ""
                    && !NetworkInfo.isIpv4Cidr(text)
                onTextChanged: { editor.address = text; editor.dirty = true }
            }

            MdTextField {
                width: editor.rowWidth
                label: "Gateway"
                placeholder: "192.168.1.1"
                text: editor.gateway
                enabled: editor.method === "manual" && !NetworkInfo.applying
                invalid: text.trim() !== "" && !NetworkInfo.isIpv4(text)
                onTextChanged: { editor.gateway = text; editor.dirty = true }
            }

            MdTextField {
                width: editor.rowWidth
                label: editor.method === "manual" ? "DNS" : "DNS (leave empty to use DHCP's)"
                placeholder: "1.1.1.1 9.9.9.9"
                text: editor.dns
                enabled: !NetworkInfo.applying
                invalid: !NetworkInfo.isDnsList(text)
                onTextChanged: { editor.dns = text; editor.dirty = true }
            }

            MdListItem {
                width: editor.rowWidth
                headline: "Ignore DHCP-provided DNS"
                supporting: "Use only the servers listed above"
                visible: editor.method === "auto"
                onClicked: { editor.ignoreAutoDns = !editor.ignoreAutoDns; editor.dirty = true }

                MdSwitch {
                    checked: editor.ignoreAutoDns
                    interactive: !NetworkInfo.applying
                    onToggled: { editor.ignoreAutoDns = !editor.ignoreAutoDns; editor.dirty = true }
                }
            }

            // Status line: validation problem, nmcli error, or success
            Text {
                width: editor.rowWidth
                topPadding: 8
                wrapMode: Text.Wrap
                font.family: Md.fontFamily
                font.pixelSize: Md.bodySmall
                visible: text !== ""
                color: (editor.problem !== "" || NetworkInfo.lastError !== "")
                    ? Md.error : Md.primary
                text: NetworkInfo.applying ? "Applying…"
                    : editor.problem !== "" ? editor.problem
                    : NetworkInfo.lastError !== "" ? NetworkInfo.lastError
                    : NetworkInfo.lastOk ? "Applied — link reconnected"
                    : ""
            }

            Item {
                width: editor.rowWidth
                height: 56

                Row {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 10

                    Rectangle {
                        width: revertLabel.implicitWidth + 32
                        height: 40
                        radius: Md.cornerFull
                        color: revertHover.containsMouse ? Md.surfaceContainerHighest : "transparent"
                        border.width: 1
                        border.color: Md.outline

                        Behavior on color { ColorAnimation { duration: Md.durMedium } }

                        Text {
                            id: revertLabel
                            anchors.centerIn: parent
                            text: "Revert"
                            color: Md.textOnSurface
                            font.family: Md.fontFamily
                            font.pixelSize: Md.labelLarge
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: revertHover
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: editor.dirty && !NetworkInfo.applying
                            cursorShape: Qt.PointingHandCursor
                            onClicked: editor.seed()
                        }
                    }

                    Rectangle {
                        id: applyBtn

                        readonly property bool ready:
                            editor.dirty && editor.problem === "" && !NetworkInfo.applying

                        width: applyLabel.implicitWidth + 36
                        height: 40
                        radius: Md.cornerFull
                        color: applyHover.containsMouse && applyBtn.ready
                            ? Qt.lighter(Md.primary, 1.1)
                            : Md.primary
                        opacity: applyBtn.ready ? 1 : Md.disabledOpacity

                        Behavior on color { ColorAnimation { duration: Md.durMedium } }
                        Behavior on opacity { NumberAnimation { duration: Md.durMedium } }

                        Text {
                            id: applyLabel
                            anchors.centerIn: parent
                            text: "Apply"
                            color: Md.textOnPrimary
                            font.family: Md.fontFamily
                            font.pixelSize: Md.labelLarge
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: applyHover
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: applyBtn.ready
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                editor.dirty = false
                                NetworkInfo.applyIpv4(editor.method, editor.address,
                                    editor.gateway, editor.dns, editor.ignoreAutoDns)
                            }
                        }
                    }
                }
            }
        }

        // ── Profile options ──────────────────────────────────────────────
        MdCard {
            width: column.width
            visible: Wifi.enabled && NetworkInfo.connected
            title: "Profile"
            padding: 8

            MdListItem {
                width: column.width - 16
                icon: "󰑓"
                headline: "Connect automatically"
                supporting: "Join this network when it is in range"
                onClicked: NetworkInfo.setProfileFlag("connection.autoconnect",
                    NetworkInfo.setting("connection.autoconnect") === "yes" ? "no" : "yes")

                MdSwitch {
                    checked: NetworkInfo.setting("connection.autoconnect") === "yes"
                    interactive: !NetworkInfo.applying
                    onToggled: NetworkInfo.setProfileFlag("connection.autoconnect",
                        NetworkInfo.setting("connection.autoconnect") === "yes" ? "no" : "yes")
                }
            }

            MdListItem {
                width: column.width - 16
                icon: "󰄪"
                headline: "Metered connection"
                supporting: "Currently: " + (NetworkInfo.setting("connection.metered") || "unknown")
                onClicked: NetworkInfo.setProfileFlag("connection.metered",
                    NetworkInfo.setting("connection.metered") === "yes" ? "no" : "yes")

                MdSwitch {
                    checked: NetworkInfo.setting("connection.metered") === "yes"
                    interactive: !NetworkInfo.applying
                    onToggled: NetworkInfo.setProfileFlag("connection.metered",
                        NetworkInfo.setting("connection.metered") === "yes" ? "no" : "yes")
                }
            }
        }

        // ── Available networks ───────────────────────────────────────────
        MdCard {
            width: column.width
            visible: Wifi.enabled
            title: "Available networks"
            padding: 8

            Repeater {
                model: root.sorted

                delegate: Column {
                    id: netEntry
                    required property var modelData
                    width: column.width - 16
                    spacing: 0

                    readonly property bool secured: modelData.security !== WifiSecurityType.Open
                    readonly property bool pskActive: root.pskNetwork === modelData

                    Connections {
                        target: netEntry.modelData
                        function onRequestConnectWithPsk() {
                            root.pskNetwork = netEntry.modelData
                            pskField.text = ""
                            pskField.forceActiveFocus()
                        }
                    }

                    MdListItem {
                        width: parent.width
                        icon: root.iconFor(netEntry.modelData.signalStrength)
                        iconColor: netEntry.modelData.connected ? Md.primary : Md.textOnSurfaceVariant
                        headline: netEntry.modelData.name
                        supporting: netEntry.modelData.connected ? "Connected"
                            : netEntry.modelData.stateChanging ? "Connecting…"
                            : netEntry.modelData.known ? "Saved"
                            : (netEntry.secured ? "Secured" : "Open")
                        onClicked: {
                            if (netEntry.modelData.connected) netEntry.modelData.disconnect()
                            else netEntry.modelData.connect()
                        }

                        Row {
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: netEntry.secured ? "󰌾" : ""
                                font.family: Md.iconFamily
                                font.pixelSize: 14
                                color: Md.textOnSurfaceVariant
                                visible: text !== "" && !netEntry.modelData.connected
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰄬"
                                font.family: Md.iconFamily
                                font.pixelSize: 16
                                color: Md.primary
                                visible: netEntry.modelData.connected
                            }
                        }
                    }

                    // Inline password entry, shown when the network asks for a PSK
                    Rectangle {
                        width: parent.width
                        height: netEntry.pskActive ? 52 : 0
                        clip: true
                        radius: Md.cornerM
                        color: Md.surfaceContainerHigh

                        Behavior on height { NumberAnimation { duration: Md.durMedium; easing.type: Md.easingStandard } }

                        Rectangle {
                            anchors {
                                fill: parent
                                margins: 8
                            }
                            radius: Md.cornerS
                            color: Md.surfaceContainerLowest
                            border.width: pskField.activeFocus ? 2 : 1
                            border.color: pskField.activeFocus ? Md.primary : Md.outlineVariant

                            TextInput {
                                id: pskField
                                anchors {
                                    left: parent.left
                                    right: goBtn.left
                                    leftMargin: 12
                                    rightMargin: 8
                                    verticalCenter: parent.verticalCenter
                                }
                                color: Md.textOnSurface
                                font.family: Md.fontFamily
                                font.pixelSize: Md.bodyMedium
                                echoMode: TextInput.Password
                                clip: true

                                Text {
                                    anchors.fill: parent
                                    text: "Password"
                                    color: Md.textOnSurfaceVariant
                                    font: parent.font
                                    visible: parent.text.length === 0
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Keys.onReturnPressed: {
                                    netEntry.modelData.connectWithPsk(pskField.text)
                                    root.pskNetwork = null
                                }
                                Keys.onEscapePressed: root.pskNetwork = null
                            }

                            MdIconButton {
                                id: goBtn
                                anchors {
                                    right: parent.right
                                    rightMargin: 4
                                    verticalCenter: parent.verticalCenter
                                }
                                size: 28
                                iconSize: 15
                                icon: "󰁕"
                                onClicked: {
                                    netEntry.modelData.connectWithPsk(pskField.text)
                                    root.pskNetwork = null
                                }
                            }
                        }
                    }
                }
            }

            Text {
                width: column.width - 16
                horizontalAlignment: Text.AlignHCenter
                text: "No networks found"
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
            text: "Wi-Fi is off"
            color: Md.textOnSurfaceVariant
            font.family: Md.fontFamily
            font.pixelSize: Md.bodyMedium
            topPadding: 32
            visible: !Wifi.enabled
        }
    }
}

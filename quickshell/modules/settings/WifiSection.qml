pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Networking
import qs.services

Flickable {
    id: root

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

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

pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.common

PanelWindow {
    id: root

    required property var screen

    property bool isOpen: false

    function open() {
        visible = true
        isOpen = true
    }

    function close() {
        isOpen = false
        hideTimer.start()
    }

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: -1
    color: "transparent"
    focusable: isOpen
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region { item: isOpen ? backdrop : emptyRegion }

    Item { id: emptyRegion; width: 0; height: 0 }

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        opacity: root.isOpen ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: card
        width: cardColumn.implicitWidth + 72
        height: cardColumn.implicitHeight + 56
        x: (root.screen.width - width) / 2
        y: (root.screen.height - height) / 2
        radius: 28

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(Colors.background, 1.4) }
            GradientStop { position: 1.0; color: Colors.background }
        }
        border.width: 1
        border.color: Colors.surfaceVariant

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.5)
            shadowBlur: 0.8
            shadowVerticalOffset: 8
            autoPaddingEnabled: true
        }

        Keys.onEscapePressed: root.close()

        Column {
            id: cardColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 36
                leftMargin: 36
                rightMargin: 36
            }
            spacing: 28

            Text {
                text: "Power"
                color: Colors.primaryText
                font.family: "Poppins"
                font.pixelSize: 22
                font.weight: Font.Bold
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Repeater {
                    model: [
                        { icon: "󰌾", label: "Lock",      cmd: "quickshell ipc call lockscreen lock" },
                        { icon: "󰍃", label: "Log out",   cmd: "hyprctl dispatch exit" },
                        { icon: "󰒲", label: "Suspend",   cmd: "systemctl suspend" },
                        { icon: "󰤄", label: "Hibernate", cmd: "systemctl hibernate" },
                        { icon: "󰜉", label: "Reboot",    cmd: "systemctl reboot" },
                        { icon: "󰐥", label: "Shut down", cmd: "systemctl poweroff" },
                    ]

                    delegate: Column {
                        id: actionItem
                        required property var modelData
                        spacing: 12

                        Rectangle {
                            width: 68
                            height: 68
                            radius: 999
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: btnHover.containsMouse ? Colors.primaryText : Colors.surfaceVariant
                            border.width: btnHover.containsMouse ? 0 : 1
                            border.color: Qt.lighter(Colors.surfaceVariant, 1.6)
                            scale: btnHover.pressed ? 0.92 : (btnHover.containsMouse ? 1.05 : 1.0)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            Text {
                                anchors.centerIn: parent
                                text: actionItem.modelData.icon
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 26
                                color: btnHover.containsMouse ? Colors.background : Colors.primaryText

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: btnHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.close()
                                    actionRunner.command = ["bash", "-c", actionItem.modelData.cmd]
                                    actionRunner.running = true
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: actionItem.modelData.label
                            color: Colors.secondaryText
                            font.family: "Poppins"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 300
        repeat: false
        onTriggered: root.visible = false
    }

    Process { id: actionRunner }

    Droplet {
        target: card
        shown: root.isOpen
        origin: Item.Center
    }
}

pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

AnimatedPopup {
    id: root

    popupWidth: 860

    property int activeTab: 0
    readonly property var tabs: [
        { icon: "󰃭", label: "Calendar" },
        { icon: "󰄬", label: "Tasks" },
        { icon: "󰔛", label: "Deep Work" }
    ]

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Refresh the agenda whenever the popup is opened
    Connections {
        target: root
        function onIsOpenChanged() { if (root.isOpen) Agenda.refresh() }
    }

    component Card: Rectangle {
        radius: 16
        color: Colors.chipBackground
    }

    Item {
        id: dash
        width: parent.width
        implicitHeight: 636

        // Tab bar — icon over label, full width, with a sliding accent underline
        Item {
            id: tabBar
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 68

            readonly property real tabWidth: width / root.tabs.length

            Row {
                anchors.fill: parent

                Repeater {
                    model: root.tabs

                    Item {
                        id: tabBtn
                        required property int index
                        required property var modelData

                        readonly property bool current: root.activeTab === index

                        width: tabBar.tabWidth
                        height: tabBar.height

                        Column {
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 8 }
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tabBtn.modelData.icon
                                color: tabBtn.current ? Colors.chipIconActive : Colors.secondaryText
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tabBtn.modelData.label
                                color: tabBtn.current ? Colors.chipIconActive : Colors.secondaryText
                                font.family: "Poppins"
                                font.pixelSize: 13
                                font.weight: Font.Bold

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = tabBtn.index
                        }
                    }
                }
            }

            // Full-width divider
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color: Colors.surfaceVariant
            }

            // Sliding active-tab underline
            Rectangle {
                width: 32
                height: 2
                radius: 1
                color: Colors.chipIconActive
                y: tabBar.height - height
                x: (root.activeTab + 0.5) * tabBar.tabWidth - width / 2

                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
        }

        Item {
            id: tabContent
            anchors {
                top: tabBar.bottom
                topMargin: 12
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            // ── Tab 0: time / calendar / agenda / tasks ──
            Item {
                id: calendarTab
                anchors.fill: parent
                visible: root.activeTab === 0

                readonly property int gap: 16
                readonly property int leftW: Math.round((width - gap) * 0.44)
                readonly property int rightW: width - gap - leftW

                // LEFT: time/date hero + agenda
                Item {
                    id: leftCol
                    anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                    width: calendarTab.leftW

                    Card {
                        id: heroCard
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 150

                        Column {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 20
                                rightMargin: 20
                            }
                            spacing: 2

                            Text {
                                text: Qt.formatTime(clock.date, "hh:mm")
                                color: Colors.primaryText
                                font.family: "Poppins"
                                font.pixelSize: 52
                                font.weight: Font.Bold
                            }

                            Text {
                                text: Qt.formatDate(clock.date, "dddd")
                                color: Colors.primaryText
                                font.family: "Poppins"
                                font.pixelSize: 16
                                font.weight: Font.Medium
                            }

                            Text {
                                text: Qt.formatDate(clock.date, "MMMM d, yyyy")
                                color: Colors.secondaryText
                                font.family: "Poppins"
                                font.pixelSize: 13
                            }
                        }
                    }

                    Card {
                        anchors {
                            top: heroCard.bottom
                            topMargin: calendarTab.gap
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }

                        AgendaPanel {
                            anchors { fill: parent; margins: 18 }
                        }
                    }
                }

                // RIGHT: calendar + tasks
                Item {
                    id: rightCol
                    anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                    width: calendarTab.rightW

                    Card {
                        anchors.fill: parent

                        Calendar {
                            id: cal
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                topMargin: 16
                                leftMargin: 16
                                rightMargin: 16
                            }
                        }

                        Rectangle {
                            id: calDivider
                            anchors {
                                top: cal.bottom
                                topMargin: 16
                                left: parent.left
                                right: parent.right
                                leftMargin: 16
                                rightMargin: 16
                            }
                            height: 1
                            color: Colors.surfaceVariant
                        }

                        NextEvent {
                            anchors {
                                top: calDivider.bottom
                                topMargin: 14
                                left: parent.left
                                right: parent.right
                                leftMargin: 16
                                rightMargin: 16
                            }
                        }
                    }
                }
            }

            // ── Tab 1: Tasks ──
            Card {
                anchors.fill: parent
                visible: root.activeTab === 1

                TodoList {
                    anchors { fill: parent; margins: 20 }
                }
            }

            // ── Tab 2: Deep-work timer ──
            Card {
                anchors.fill: parent
                visible: root.activeTab === 2

                DeepWorkPanel {
                    anchors { fill: parent; margins: 24 }
                }
            }
        }
    }
}

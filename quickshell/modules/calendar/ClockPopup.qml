pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

AnimatedPopup {
    id: root

    popupWidth: 860

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
        border.width: 1
        border.color: Colors.surfaceVariant
    }

    Item {
        id: dash
        width: parent.width
        implicitHeight: 560

        readonly property int gap: 16
        readonly property int leftW: Math.round((width - gap) * 0.44)
        readonly property int rightW: width - gap - leftW

        // LEFT: time/date hero + agenda
        Item {
            id: leftCol
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            width: dash.leftW

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
                    topMargin: dash.gap
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
            width: dash.rightW

            Card {
                id: calCard
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: cal.implicitHeight + 32

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
            }

            Card {
                anchors {
                    top: calCard.bottom
                    topMargin: dash.gap
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                TodoList {
                    anchors { fill: parent; margins: 18 }
                }
            }
        }
    }
}

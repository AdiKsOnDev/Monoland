pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

AnimatedPopup {
    id: root

    popupWidth: 780

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        width: parent.width
        height: calendarPanel.implicitHeight
        spacing: 0

        // Left panel: time, date, calendar
        Column {
            id: calendarPanel
            width: parent.width / 2 - 1
            spacing: 16

            // Time
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, "hh:mm")
                color: Colors.primaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 72
                font.weight: Font.Bold
            }

            // Date
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(clock.date, "dddd, MMMM d")
                color: Colors.secondaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 13
                bottomPadding: 4
            }

            Calendar {
                width: parent.width
            }
        }

        // Vertical divider
        Item {
            width: 1
            height: parent.height

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: parent.height * 0.90
                color: Colors.border
                opacity: 0.4
            }
        }

        // Right panel: todo list
        Item {
            width: parent.width / 2 - 1
            height: calendarPanel.implicitHeight

            TodoList {
                anchors {
                    fill: parent
                    leftMargin: 20
                    rightMargin: 4
                    topMargin: 4
                }
            }
        }
    }
}

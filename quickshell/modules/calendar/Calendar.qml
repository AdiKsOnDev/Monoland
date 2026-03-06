pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    implicitWidth: parent?.width ?? 0
    implicitHeight: headerRow.height + weekdayRow.height + grid.height + 24

    readonly property int cellSize: 44
    readonly property int todayCircleSize: 36

    property int displayYear: today.getFullYear()
    property int displayMonth: today.getMonth()

    readonly property var today: new Date()
    readonly property int todayYear: today.getFullYear()
    readonly property int todayMonth: today.getMonth()
    readonly property int todayDay: today.getDate()

    readonly property int firstWeekday: new Date(displayYear, displayMonth, 1).getDay()
    readonly property int daysInMonth: new Date(displayYear, displayMonth + 1, 0).getDate()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayNames: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    function previousMonth() {
        if (displayMonth === 0) {
            displayMonth = 11
            displayYear -= 1
        } else {
            displayMonth -= 1
        }
    }

    function nextMonth() {
        if (displayMonth === 11) {
            displayMonth = 0
            displayYear += 1
        } else {
            displayMonth += 1
        }
    }

    // Month navigation header
    Row {
        id: headerRow
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 40

        // Previous month button
        Rectangle {
            width: 36
            height: 36
            radius: 999
            color: prevHover.containsMouse ? Colors.surfaceVariant : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "󰅁"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color: Colors.secondaryText
            }

            MouseArea {
                id: prevHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.previousMonth()
            }
        }

        Text {
            text: root.monthNames[root.displayMonth] + " " + root.displayYear
            color: Colors.primaryText
            font.family: "Poppins"
            font.italic: false
            font.pixelSize: 14
            font.weight: Font.SemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            width: parent.width - 72
            height: parent.height
        }

        // Next month button
        Rectangle {
            width: 36
            height: 36
            radius: 999
            color: nextHover.containsMouse ? Colors.surfaceVariant : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "󰅂"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color: Colors.secondaryText
            }

            MouseArea {
                id: nextHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.nextMonth()
            }
        }
    }

    // Day-of-week labels
    Row {
        id: weekdayRow
        anchors {
            top: headerRow.bottom
            topMargin: 4
            horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: root.dayNames
            Text {
                required property string modelData
                text: modelData
                width: root.cellSize
                height: 32
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: Colors.secondaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 11
                font.weight: Font.Medium
            }
        }
    }

    // Day grid
    Grid {
        id: grid
        anchors {
            top: weekdayRow.bottom
            topMargin: 2
            horizontalCenter: parent.horizontalCenter
        }
        columns: 7
        height: Math.ceil((root.firstWeekday + root.daysInMonth) / 7) * root.cellSize

        Repeater {
            model: root.firstWeekday + root.daysInMonth

            Item {
                required property int index
                width: root.cellSize
                height: root.cellSize

                readonly property int day: index - root.firstWeekday + 1
                readonly property bool isValidDay: index >= root.firstWeekday
                readonly property bool isToday: isValidDay
                    && root.displayYear === root.todayYear
                    && root.displayMonth === root.todayMonth
                    && day === root.todayDay

                Rectangle {
                    anchors.centerIn: parent
                    width: root.todayCircleSize
                    height: root.todayCircleSize
                    radius: 999
                    color: parent.isToday ? Colors.primaryText : (dayHover.containsMouse ? Colors.surfaceVariant : "transparent")
                    visible: parent.isValidDay

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: parent.isValidDay ? parent.day : ""
                    color: parent.isToday ? Colors.background : Colors.primaryText
                    font.family: "Poppins"
                    font.italic: false
                    font.pixelSize: 13
                    font.weight: parent.isToday ? Font.SemiBold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                }

                MouseArea {
                    id: dayHover
                    anchors.fill: parent
                    hoverEnabled: parent.isValidDay
                    cursorShape: parent.isValidDay ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }
    }
}

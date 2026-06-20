pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: root

    implicitWidth: parent?.width ?? 0
    implicitHeight: parent?.height ?? 0

    readonly property string scriptPath: Quickshell.shellDir + "/scripts/todo-manager.sh"

    // color-typed so .r/.g/.b are available (Colors.primaryText is a string)
    readonly property color selectionTint: Qt.rgba(
        Qt.color(Colors.primaryText).r,
        Qt.color(Colors.primaryText).g,
        Qt.color(Colors.primaryText).b,
        0.3
    )

    property var todos: []
    property int editingId: -1
    property var pendingArgs: []

    readonly property int activeCount: {
        let n = 0
        for (let i = 0; i < todos.length; i++) if (!todos[i].done) n++
        return n
    }

    function runCommand(args) {
        root.pendingArgs = args
        todoProc.running = true
    }

    function loadTodos()        { runCommand(["list"]) }
    function addTodo(text)      { runCommand(["add", text]) }
    function toggleTodo(id)     { runCommand(["toggle", String(id)]) }
    function editTodo(id, text) { runCommand(["edit", String(id), text]) }
    function removeTodo(id)     { runCommand(["remove", String(id)]) }

    Component.onCompleted: loadTodos()

    Process {
        id: todoProc
        command: [root.scriptPath].concat(root.pendingArgs)
        running: false

        stdout: SplitParser {
            property string buffer: ""
            onRead: (line) => { buffer += line }
        }

        onRunningChanged: {
            if (running) return
            const raw = todoProc.stdout.buffer.trim()
            todoProc.stdout.buffer = ""
            if (raw) root.todos = JSON.parse(raw)
            if (root.editingId !== -1 && root.pendingArgs[0] === "edit")
                root.editingId = -1
        }
    }

    // Header: title + active count + add button
    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 30

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: "Tasks"
                color: Colors.primaryText
                font.family: "Poppins"
                font.pixelSize: 14
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.activeCount > 0 ? root.activeCount : ""
                color: Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 12
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
                visible: root.activeCount > 0
            }
        }

        Rectangle {
            id: addBtn
            width: 26
            height: 26
            radius: 8
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            color: addHover.containsMouse ? Colors.surfaceVariant : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "󰐕"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: addHover.containsMouse ? Colors.primaryText : Colors.secondaryText

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: addHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.editingId = -1
                    newField.text = ""
                    newInput.visible = true
                    newField.forceActiveFocus()
                }
            }
        }
    }

    // Inline new-task input
    Rectangle {
        id: newInput
        anchors { top: header.bottom; topMargin: 6; left: parent.left; right: parent.right }
        height: visible ? 38 : 0
        visible: false
        color: Colors.surfaceVariant
        radius: 10
        clip: true

        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Row {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰐕"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: Colors.secondaryText
            }

            TextInput {
                id: newField
                width: parent.width - 28
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.primaryText
                font.family: "Poppins"
                font.pixelSize: 13
                selectionColor: root.selectionTint
                clip: true

                Text {
                    anchors.fill: parent
                    text: "New task..."
                    color: Colors.secondaryText
                    font: parent.font
                    visible: parent.text.length === 0
                    verticalAlignment: Text.AlignVCenter
                }

                Keys.onReturnPressed: {
                    const t = newField.text.trim()
                    if (t !== "") root.addTodo(t)
                    newInput.visible = false
                    newField.text = ""
                }
                Keys.onEscapePressed: {
                    newInput.visible = false
                    newField.text = ""
                }
            }
        }
    }

    ListView {
        id: listView
        anchors {
            top: newInput.visible ? newInput.bottom : header.bottom
            topMargin: 6
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        spacing: 2
        clip: true
        model: root.todos
        boundsBehavior: Flickable.StopAtBounds

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.5; to: 1; duration: 450; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.4 }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 180; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; to: 0.4; duration: 220; easing.type: Easing.InBack; easing.overshoot: 1.5 }
            }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }

        delegate: Item {
            id: row
            required property var modelData
            width: listView.width
            height: 38

            readonly property bool isEditing: root.editingId === modelData.id
            readonly property bool isHovered: rowHover.containsMouse
            readonly property bool done: modelData.done

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: row.isHovered ? Colors.surfaceVariant : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Checkbox
            Rectangle {
                id: check
                width: 19
                height: 19
                radius: 6
                anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                color: row.done ? Colors.chipIconActive : "transparent"
                border.color: row.done ? Colors.chipIconActive : Colors.secondaryText
                border.width: 1.5

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰄬"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: Colors.background
                    visible: row.done
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleTodo(row.modelData.id)
                }
            }

            // Task text (click to edit)
            TextInput {
                id: taskText
                anchors {
                    left: check.right
                    leftMargin: 10
                    right: removeBtn.left
                    rightMargin: 6
                    verticalCenter: parent.verticalCenter
                }
                text: row.modelData.text
                color: row.done ? Colors.secondaryText : Colors.primaryText
                font.family: "Poppins"
                font.pixelSize: 13
                font.weight: Font.Medium
                readOnly: !row.isEditing
                selectionColor: root.selectionTint
                clip: true
                opacity: row.done ? 0.5 : 1.0
                verticalAlignment: Text.AlignVCenter

                Behavior on color   { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }

                // Strikethrough for completed tasks
                Rectangle {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    width: Math.min(parent.contentWidth, parent.width)
                    height: 1
                    color: Colors.secondaryText
                    opacity: 0.6
                    visible: row.done && !row.isEditing
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    visible: !row.isEditing
                    onClicked: {
                        root.editingId = row.modelData.id
                        taskText.forceActiveFocus()
                        taskText.selectAll()
                    }
                }

                Keys.onReturnPressed: root.editTodo(row.modelData.id, taskText.text.trim())
                Keys.onEscapePressed: {
                    taskText.text = row.modelData.text
                    root.editingId = -1
                }
            }

            // Delete (hover only)
            Rectangle {
                id: removeBtn
                width: 24
                height: 24
                radius: 6
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                color: removeHover.containsMouse ? Colors.border : "transparent"
                opacity: row.isHovered ? 1.0 : 0.0

                Behavior on color   { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Colors.secondaryText
                }

                MouseArea {
                    id: removeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.removeTodo(row.modelData.id)
                }
            }

            MouseArea {
                id: rowHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        // Empty state
        Text {
            anchors.centerIn: parent
            visible: root.todos.length === 0
            text: "No tasks yet"
            color: Colors.secondaryText
            font.family: "Poppins"
            font.pixelSize: 13
        }
    }
}

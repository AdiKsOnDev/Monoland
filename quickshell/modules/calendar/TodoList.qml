pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: root

    implicitWidth: parent?.width ?? 0
    implicitHeight: parent?.height ?? 0

    readonly property string scriptPath: Quickshell.shellDir + "/scripts/todo-manager.sh"

    property var todos: []
    property int editingId: -1

    // Pending command to run — set args then trigger the process
    property var pendingArgs: []

    function runCommand(args) {
        root.pendingArgs = args
        todoProc.running = true
    }

    function loadTodos()              { runCommand(["list"]) }
    function addTodo(text)            { runCommand(["add", text]) }
    function toggleTodo(id)           { runCommand(["toggle", String(id)]) }
    function editTodo(id, text)       { runCommand(["edit", String(id), text]) }
    function removeTodo(id)           { runCommand(["remove", String(id)]) }

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

    // Header
    Row {
        id: todoHeader
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 40

        Text {
            text: "Tasks"
            color: Colors.primaryText
            font.family: "Poppins"
            font.italic: false
            font.pixelSize: 14
            font.weight: Font.SemiBold
            verticalAlignment: Text.AlignVCenter
            height: parent.height
            width: parent.width - addBtn.width
        }

        Rectangle {
            id: addBtn
            width: 28
            height: 28
            radius: 999
            anchors.verticalCenter: parent.verticalCenter
            color: addHover.containsMouse ? Colors.surfaceVariant : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "󰐕"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: Colors.primaryText
            }

            MouseArea {
                id: addHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.editingId = -1
                    newItemField.text = ""
                    newItemInput.visible = true
                    newItemField.forceActiveFocus()
                }
            }
        }
    }

    // New item input
    Rectangle {
        id: newItemInput
        anchors {
            top: todoHeader.bottom
            left: parent.left
            right: parent.right
        }
        height: visible ? 36 : 0
        visible: false
        color: Colors.surfaceVariant
        radius: 8

        TextInput {
            id: newItemField
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 10
                rightMargin: 10
            }
            color: Colors.primaryText
            font.family: "Poppins"
            font.italic: false
            font.pixelSize: 12
            selectionColor: Qt.rgba(Colors.primaryText.r, Colors.primaryText.g, Colors.primaryText.b, 0.3)
            clip: true

            Keys.onReturnPressed: {
                const text = newItemField.text.trim()
                if (text !== "") root.addTodo(text)
                newItemInput.visible = false
                newItemField.text = ""
            }
            Keys.onEscapePressed: {
                newItemInput.visible = false
                newItemField.text = ""
            }
        }
    }

    // Todo items
    ListView {
        id: todoListView
        anchors {
            top: newItemInput.visible ? newItemInput.bottom : todoHeader.bottom
            topMargin: 4
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        spacing: 2
        clip: true
        model: root.todos

        delegate: Item {
            id: todoDelegate
            required property var modelData
            width: todoListView.width
            height: 36

            readonly property bool isEditing: root.editingId === modelData.id

            // Strikethrough line for done items
            Rectangle {
                anchors {
                    left: todoText.left
                    right: todoText.right
                    verticalCenter: todoText.verticalCenter
                }
                height: 1
                color: Colors.secondaryText
                visible: todoDelegate.modelData.done && !todoDelegate.isEditing
            }

            // Check/uncheck button
            Rectangle {
                id: checkBtn
                width: 18
                height: 18
                radius: 999
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                color: todoDelegate.modelData.done ? Colors.primaryText : "transparent"
                border.color: todoDelegate.modelData.done ? Colors.primaryText : Colors.secondaryText
                border.width: 1.5

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰄬"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Colors.background
                    visible: todoDelegate.modelData.done
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleTodo(todoDelegate.modelData.id)
                }
            }

            // Editable text / display text
            TextInput {
                id: todoText
                anchors {
                    left: checkBtn.right
                    leftMargin: 8
                    right: removeBtn.left
                    rightMargin: 6
                    verticalCenter: parent.verticalCenter
                }
                text: todoDelegate.modelData.text
                color: todoDelegate.modelData.done ? Colors.secondaryText : Colors.primaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 12
                font.weight: Font.Medium
                readOnly: !todoDelegate.isEditing
                selectionColor: Qt.rgba(Colors.primaryText.r, Colors.primaryText.g, Colors.primaryText.b, 0.3)
                clip: true

                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    visible: !todoDelegate.isEditing
                    onClicked: {
                        root.editingId = todoDelegate.modelData.id
                        todoText.forceActiveFocus()
                        todoText.selectAll()
                    }
                }

                Keys.onReturnPressed: root.editTodo(todoDelegate.modelData.id, todoText.text.trim())
                Keys.onEscapePressed: {
                    todoText.text = todoDelegate.modelData.text
                    root.editingId = -1
                }
            }

            // Remove button
            Rectangle {
                id: removeBtn
                width: 20
                height: 20
                radius: 999
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                color: removeHover.containsMouse ? Colors.surfaceVariant : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

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
                    onClicked: root.removeTodo(todoDelegate.modelData.id)
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.todos.length === 0
            text: "No tasks"
            color: Colors.secondaryText
            font.family: "Poppins"
            font.italic: false
            font.pixelSize: 12
        }
    }
}

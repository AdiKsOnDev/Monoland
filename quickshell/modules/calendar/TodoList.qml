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
    property var pendingArgs: []

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

   
    Row {
        id: todoHeader
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 44

        Text {
            text: "Tasks"
            color: Colors.primaryText
            font.family: "Poppins"
            font.italic: false
            font.pixelSize: 15
            font.weight: Font.Bold
            verticalAlignment: Text.AlignVCenter
            height: parent.height
            width: parent.width - addBtn.implicitWidth
        }

        // Add button
        Rectangle {
            id: addBtn
            implicitWidth: 30
            implicitHeight: 30
            radius: 8
            anchors.verticalCenter: parent.verticalCenter
            color: addHover.containsMouse ? Colors.surfaceVariant : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "󰐕"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
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
                    newItemField.text = ""
                    newItemInput.visible = true
                    newItemField.forceActiveFocus()
                }
            }
        }
    }

   
    Rectangle {
        id: newItemInput
        anchors {
            top: todoHeader.bottom
            left: parent.left
            right: parent.right
        }
        height: visible ? 40 : 0
        visible: false
        color: Colors.surfaceVariant
        radius: 10

        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Row {
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰐕"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: Colors.secondaryText
            }

            TextInput {
                id: newItemField
                width: parent.width - 28
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.primaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 13
                selectionColor: Qt.rgba(Colors.primaryText.r, Colors.primaryText.g, Colors.primaryText.b, 0.3)
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
                    const trimmed = newItemField.text.trim()
                    if (trimmed !== "") root.addTodo(trimmed)
                    newItemInput.visible = false
                    newItemField.text = ""
                }
                Keys.onEscapePressed: {
                    newItemInput.visible = false
                    newItemField.text = ""
                }
            }
        }
    }

   
    ListView {
        id: todoListView
        anchors {
            top: newItemInput.visible ? newItemInput.bottom : todoHeader.bottom
            topMargin: 6
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        spacing: 4
        clip: true
        model: root.todos

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "x"; from: 20; to: 0; duration: 200; easing.type: Easing.OutCubic }
        }

        remove: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150; easing.type: Easing.InCubic }
        }

        displaced: Transition {
            NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }
        }

        delegate: Rectangle {
            id: todoDelegate
            required property var modelData
            width: todoListView.width
            height: 44
            radius: 10
            color: todoDelegate.modelData.done ? "transparent" : Colors.surfaceVariant

            Behavior on color { ColorAnimation { duration: 150 } }

            readonly property bool isEditing: root.editingId === modelData.id
            readonly property bool isHovered: delegateHover.containsMouse

            // Strikethrough
            Rectangle {
                anchors {
                    left: todoText.left
                    right: todoText.right
                    verticalCenter: todoText.verticalCenter
                }
                height: 1
                color: Colors.secondaryText
                visible: todoDelegate.modelData.done && !todoDelegate.isEditing
                opacity: 0.6
            }

            // Check button
            Rectangle {
                id: checkBtn
                width: 20
                height: 20
                radius: 6
                anchors {
                    left: parent.left
                    leftMargin: 12
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
                    font.pixelSize: 11
                    color: Colors.background
                    visible: todoDelegate.modelData.done
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleTodo(todoDelegate.modelData.id)
                }
            }

            // Task text
            TextInput {
                id: todoText
                anchors {
                    left: checkBtn.right
                    leftMargin: 10
                    right: removeBtn.left
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                text: todoDelegate.modelData.text
                color: todoDelegate.modelData.done ? Colors.secondaryText : Colors.primaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 13
                font.weight: Font.Medium
                readOnly: !todoDelegate.isEditing
                selectionColor: Qt.rgba(Colors.primaryText.r, Colors.primaryText.g, Colors.primaryText.b, 0.3)
                clip: true
                opacity: todoDelegate.modelData.done ? 0.5 : 1.0

                Behavior on color   { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }

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

            // Remove button — only visible on hover
            Rectangle {
                id: removeBtn
                width: 24
                height: 24
                radius: 6
                anchors {
                    right: parent.right
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                color: removeHover.containsMouse ? Colors.border : "transparent"
                opacity: todoDelegate.isHovered ? 1.0 : 0.0

                Behavior on color   { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
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

            MouseArea {
                id: delegateHover
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
            font.italic: false
            font.pixelSize: 13
        }
    }
}

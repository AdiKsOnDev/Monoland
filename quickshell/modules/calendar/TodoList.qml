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

    readonly property color selectionTint: Qt.rgba(
        Qt.color(Colors.primaryText).r,
        Qt.color(Colors.primaryText).g,
        Qt.color(Colors.primaryText).b,
        0.3
    )

    property var todos: []
    property int editingId: -1
    property string filter: "all"   // all | active | done
    property var pendingArgs: []

    readonly property int activeCount: todos.filter(t => !t.done).length
    readonly property int doneCount: todos.filter(t => t.done).length

    // Highest priority first (3=high … 0=none). Stable sort: tasks of equal
    // priority keep their existing/manual order.
    function byPriority(list) {
        return list.slice().sort((a, b) => b.priority - a.priority)
    }

    readonly property var filtered: {
        if (filter === "active") return byPriority(todos.filter(t => !t.done))
        if (filter === "done") return byPriority(todos.filter(t => t.done))
        return byPriority(todos)
    }

    function isoKey(d) {
        return d.getFullYear() + "-"
            + String(d.getMonth() + 1).padStart(2, "0") + "-"
            + String(d.getDate()).padStart(2, "0")
    }
    readonly property string todayKey: isoKey(new Date())

    function addDaysKey(n) {
        const d = new Date()
        d.setDate(d.getDate() + n)
        return isoKey(d)
    }

    // ── commands ──
    function runCommand(args) { root.pendingArgs = args; todoProc.running = true }
    function loadTodos()        { runCommand(["list"]) }
    function addTodo(text)      { runCommand(["add", text]) }
    function toggleTodo(id)     { runCommand(["toggle", String(id)]) }
    function editTodo(id, text) { runCommand(["edit", String(id), text]) }
    function removeTodo(id)     { runCommand(["remove", String(id)]) }
    function setPriority(id, p) { runCommand(["priority", String(id), String(p)]) }
    function setDue(id, d)      { runCommand(["due", String(id), d]) }
    function clearDone()        { runCommand(["clear-done"]) }
    function reorder(ids)       { runCommand(["reorder"].concat(ids)) }

    function cyclePriority(t) { setPriority(t.id, (t.priority + 1) % 4) }

    function cycleDue(t) {
        const seq = ["", root.addDaysKey(0), root.addDaysKey(1), root.addDaysKey(7)]
        let idx = seq.indexOf(t.due)
        if (idx < 0) idx = 0
        setDue(t.id, seq[(idx + 1) % seq.length])
    }

    // from/to are positions in the displayed (priority-sorted) list. Translate
    // to the underlying todos order by task identity so drag reorders the
    // manual tie-break order within a priority group.
    function moveTask(from, to) {
        const view = root.filtered
        to = Math.max(0, Math.min(view.length - 1, to))
        if (from < 0 || from === to) return

        const moved = view[from]
        const target = view[to]
        if (!moved || !target) return

        const arr = root.todos.slice()
        const fromReal = arr.findIndex(t => t.id === moved.id)
        if (fromReal < 0) return
        arr.splice(fromReal, 1)

        let toReal = arr.findIndex(t => t.id === target.id)
        if (toReal < 0) toReal = arr.length
        if (to > from) toReal += 1             // dragging down inserts after target
        arr.splice(toReal, 0, moved)

        root.todos = arr                       // optimistic
        root.reorder(arr.map(t => String(t.id)))
    }

    // ── display helpers ──
    function priColor(p) {
        if (p === 3) return "#e06c75"
        if (p === 2) return "#e5c07b"
        if (p === 1) return "#61afef"
        return Colors.secondaryText
    }

    function isOverdue(t) { return t.due !== "" && !t.done && t.due < root.todayKey }

    function dueLabel(dstr) {
        if (dstr === "") return ""
        const p = dstr.split("-")
        const d = new Date(p[0], p[1] - 1, p[2])
        const today = new Date()
        const start = new Date(today.getFullYear(), today.getMonth(), today.getDate())
        const diff = Math.round((d - start) / 86400000)
        if (diff === 0) return "Today"
        if (diff === 1) return "Tomorrow"
        if (diff === -1) return "Yesterday"
        if (diff > 1 && diff < 7) return Qt.formatDate(d, "ddd")
        return Qt.formatDate(d, "d MMM")
    }

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

    // ── Header ──
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

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 4

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: clearLbl.implicitWidth + 16
                height: 26
                radius: 8
                visible: root.doneCount > 0
                color: clearHover.containsMouse ? Colors.surfaceVariant : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    id: clearLbl
                    anchors.centerIn: parent
                    text: "Clear done"
                    color: clearHover.containsMouse ? Colors.primaryText : Colors.secondaryText
                    font.family: "Poppins"
                    font.pixelSize: 12
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea {
                    id: clearHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearDone()
                }
            }

            Rectangle {
                id: addBtn
                width: 26
                height: 26
                radius: 8
                anchors.verticalCenter: parent.verticalCenter
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
    }

    // ── Filter tabs ──
    Row {
        id: filterTabs
        anchors { top: header.bottom; topMargin: 6; left: parent.left }
        spacing: 6

        Repeater {
            model: [{ k: "all", l: "All" }, { k: "active", l: "Active" }, { k: "done", l: "Done" }]

            Rectangle {
                id: fpill
                required property var modelData
                readonly property bool current: root.filter === modelData.k
                width: fLbl.implicitWidth + 20
                height: 24
                radius: 999
                color: current ? Colors.surfaceVariant : (fHover.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.4) : "transparent")
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    id: fLbl
                    anchors.centerIn: parent
                    text: fpill.modelData.l
                    color: fpill.current ? Colors.primaryText : Colors.secondaryText
                    font.family: "Poppins"
                    font.pixelSize: 11
                    font.weight: fpill.current ? Font.Bold : Font.Medium
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea {
                    id: fHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.filter = fpill.modelData.k
                }
            }
        }
    }

    // ── Inline new-task input ──
    Rectangle {
        id: newInput
        anchors { top: filterTabs.bottom; topMargin: 8; left: parent.left; right: parent.right }
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
            top: newInput.visible ? newInput.bottom : filterTabs.bottom
            topMargin: 8
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        spacing: 2
        clip: true
        model: root.filtered
        boundsBehavior: Flickable.StopAtBounds

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; from: 14; to: 0; duration: 260; easing.type: Easing.OutQuint }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
                NumberAnimation { property: "x"; to: 20; duration: 180; easing.type: Easing.InCubic }
            }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            width: listView.width
            height: 44
            z: dragMA.drag.active ? 2 : 0

            readonly property bool isEditing: root.editingId === modelData.id
            readonly property bool isHovered: rowHover.containsMouse
            readonly property bool done: modelData.done
            readonly property bool canDrag: root.filter === "all"

            Item {
                id: content
                width: parent.width
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: row.isHovered || dragMA.drag.active ? Colors.surfaceVariant : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Drag grip
                Text {
                    id: grip
                    anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
                    text: "󰇙"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Colors.secondaryText
                    opacity: (row.isHovered && row.canDrag) ? 0.7 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // Checkbox
                Rectangle {
                    id: check
                    width: 19
                    height: 19
                    radius: 6
                    anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
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

                // Priority flag (click to cycle)
                Rectangle {
                    id: prioBtn
                    width: 22
                    height: 22
                    radius: 6
                    anchors { left: check.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
                    color: prioHover.containsMouse ? Colors.surfaceVariant : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰈻"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: root.priColor(row.modelData.priority)
                        opacity: row.modelData.priority > 0 ? 1 : 0.35
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        id: prioHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cyclePriority(row.modelData)
                    }
                }

                // Task text (click to edit)
                TextInput {
                    id: taskText
                    anchors {
                        left: prioBtn.right
                        leftMargin: 6
                        right: dueBadge.left
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

                // Due badge (click to cycle: none → today → tomorrow → +1wk)
                Rectangle {
                    id: dueBadge
                    readonly property bool hasDue: row.modelData.due !== ""
                    readonly property bool overdue: root.isOverdue(row.modelData)
                    anchors { right: removeBtn.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
                    visible: hasDue || row.isHovered
                    width: visible ? dueContent.implicitWidth + 12 : 0
                    height: 22
                    radius: 6
                    color: overdue ? Qt.rgba(0.88, 0.42, 0.46, 0.18)
                        : (dueHover.containsMouse ? Colors.surfaceVariant : (hasDue ? Colors.chipBackground : "transparent"))
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: dueContent
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰃭"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: dueBadge.overdue ? "#e06c75" : Colors.secondaryText
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.dueLabel(row.modelData.due)
                            color: dueBadge.overdue ? "#e06c75" : Colors.secondaryText
                            font.family: "Poppins"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            visible: dueBadge.hasDue
                        }
                    }
                    MouseArea {
                        id: dueHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cycleDue(row.modelData)
                    }
                }

                // Remove (hover)
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

                // Drag handle (over the grip) — reorders in the "All" filter
                MouseArea {
                    id: dragMA
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: 22
                    enabled: row.canDrag
                    cursorShape: enabled ? (drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.ArrowCursor
                    drag.target: content
                    drag.axis: Drag.YAxis

                    onReleased: {
                        const stride = row.height + listView.spacing
                        const moved = Math.round(content.y / stride)
                        content.y = 0
                        if (moved !== 0) root.moveTask(row.index, row.index + moved)
                    }
                }
            }
        }

        // Empty state
        Text {
            anchors.centerIn: parent
            visible: listView.count === 0
            text: root.todos.length === 0 ? "No tasks yet"
                : (root.filter === "active" ? "No active tasks" : "Nothing done yet")
            color: Colors.secondaryText
            font.family: "Poppins"
            font.pixelSize: 13
        }
    }
}

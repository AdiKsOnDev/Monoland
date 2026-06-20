pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Upcoming events: [{id, title, date "YYYY-MM-DD", time "HH:MM"|"", allDay, location, start}]
    property var events: []
    property bool configured: false
    property bool loading: false
    property string error: ""

    readonly property string scriptPath: Quickshell.shellDir + "/scripts/calendar-agenda.py"
    readonly property string configPath: Quickshell.env("HOME") + "/.local/share/monoland/calendar.url"

    property var pendingArgs: []

    function run(args) {
        root.pendingArgs = args
        proc.running = true
    }

    function refresh()       { run([]) }
    function addUrl(url)     { run(["add", url]) }
    function removeUrl(url)  { run(["remove", url]) }

    // True if any upcoming event falls on the given y / m(0-based) / d
    function hasEventsOn(year, month, day) {
        const key = year + "-"
            + String(month + 1).padStart(2, "0") + "-"
            + String(day).padStart(2, "0")
        for (let i = 0; i < events.length; i++)
            if (events[i].date === key) return true
        return false
    }

    Process {
        id: proc
        command: ["python3", root.scriptPath].concat(root.pendingArgs)
        running: false

        stdout: SplitParser {
            property string buffer: ""
            onRead: (line) => { buffer += line }
        }

        onRunningChanged: {
            if (running) {
                root.loading = true
                return
            }
            root.loading = false
            const raw = proc.stdout.buffer.trim()
            proc.stdout.buffer = ""
            if (!raw) return
            try {
                const data = JSON.parse(raw)
                root.configured = data.configured ?? false
                root.events = data.events ?? []
                root.error = data.error ?? ""
            } catch (e) {
                root.error = "parse error"
            }
        }
    }

    // Refresh every 5 minutes (and once on startup)
    Timer {
        interval: 300000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}

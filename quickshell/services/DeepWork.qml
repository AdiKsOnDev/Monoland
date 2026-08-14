pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// Deep-work timer: counts up while you work, and automatically pauses for a
// break every `workInterval` minutes. "Tick" banks the current session into
// today's total, which is kept per-day on disk.
Singleton {
    id: root

    readonly property string scriptPath: Quickshell.shellDir + "/scripts/deepwork.sh"

    // Config (minutes) — adjustable from the UI
    property int workInterval: 50
    property int breakDuration: 10

    property bool running: false
    property bool onBreak: false
    property int sessionSeconds: 0   // counts up while working
    property int sinceBreak: 0       // work seconds since the last break
    property int breakRemaining: 0

    // { "YYYY-MM-DD": seconds }
    property var history: ({})
    property string todayKey: isoKey(new Date())

    readonly property int todaySeconds: history[todayKey] ?? 0

    readonly property real intervalProgress: workInterval > 0
        ? Math.max(0, Math.min(1, sinceBreak / (workInterval * 60)))
        : 0
    readonly property real breakProgress: breakDuration > 0
        ? Math.max(0, Math.min(1, 1 - breakRemaining / (breakDuration * 60)))
        : 0

    readonly property string sessionLabel: hms(sessionSeconds)

    // Compact form for the bar chip, e.g. "1h05" / "23m"
    readonly property string sessionShort: {
        const t = Math.max(0, sessionSeconds)
        const h = Math.floor(t / 3600)
        const m = Math.floor((t % 3600) / 60)
        return h > 0 ? (h + "h" + String(m).padStart(2, "0")) : (m + "m")
    }
    readonly property string breakLabel: {
        const m = Math.floor(Math.max(0, breakRemaining) / 60)
        const s = Math.max(0, breakRemaining) % 60
        return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
    }

    function isoKey(d) {
        return d.getFullYear() + "-"
            + String(d.getMonth() + 1).padStart(2, "0") + "-"
            + String(d.getDate()).padStart(2, "0")
    }

    function hms(total) {
        const t = Math.max(0, total)
        const h = Math.floor(t / 3600)
        const m = Math.floor((t % 3600) / 60)
        const s = t % 60
        return String(h).padStart(2, "0") + ":" + String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
    }

    function hours(secs) { return (secs / 3600) }

    // Last 7 days ending today → [{ key, label, secs, isToday }]
    readonly property var week: {
        const out = []
        const now = new Date()
        for (let i = 6; i >= 0; i--) {
            const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i)
            const key = isoKey(d)
            out.push({
                key: key,
                label: Qt.formatDate(d, "ddd").charAt(0),
                secs: history[key] ?? 0,
                isToday: i === 0
            })
        }
        return out
    }

    readonly property int weekSeconds: {
        let sum = 0
        for (let i = 0; i < week.length; i++) sum += week[i].secs
        return sum
    }

    function toggle() { running = !running }
    function start()  { running = true }
    function pause()  { running = false }

    function reset() {
        running = false
        onBreak = false
        sessionSeconds = 0
        sinceBreak = 0
        breakRemaining = 0
    }

    // Bank the current session into today's total
    function tick() {
        if (sessionSeconds <= 0) return
        run(["add", String(sessionSeconds)])
        reset()
    }

    function startBreak() {
        onBreak = true
        breakRemaining = breakDuration * 60
        notify("Break time", breakDuration + " min", "message")
    }

    function endBreak() {
        onBreak = false
        breakRemaining = 0
        sinceBreak = 0
        notify("Back to work", workInterval + " min until the next break", "complete")
    }

    function skipBreak() { if (onBreak) endBreak() }

    // Critical urgency so break alerts still get through while focus mode is on
    function notify(title, body, sound) {
        notifier.command = ["notify-send", "-a", "Deep Work", "-u", "critical", title, body]
        notifier.running = true

        if (sound) {
            sounder.command = ["canberra-gtk-play", "-i", sound]
            sounder.running = true
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.onBreak) {
                if (root.breakRemaining > 1) root.breakRemaining -= 1
                else root.endBreak()
            } else {
                root.sessionSeconds += 1
                root.sinceBreak += 1
                if (root.sinceBreak >= root.workInterval * 60) root.startBreak()
            }
        }
    }

    // Keep the day key current across midnight
    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.todayKey = root.isoKey(new Date())
    }

    property var pendingArgs: []
    function run(args) {
        root.pendingArgs = args
        proc.running = true
    }
    function refresh() { run(["list"]) }

    Process {
        id: proc
        command: [root.scriptPath].concat(root.pendingArgs)
        running: false

        stdout: SplitParser {
            property string buffer: ""
            onRead: (line) => { buffer += line }
        }

        onRunningChanged: {
            if (running) return
            const raw = proc.stdout.buffer.trim()
            proc.stdout.buffer = ""
            if (!raw) return
            try {
                root.history = JSON.parse(raw)
            } catch (e) {
                // leave history as-is
            }
        }
    }

    Process { id: notifier }
    Process { id: sounder }

    Component.onCompleted: refresh()
}

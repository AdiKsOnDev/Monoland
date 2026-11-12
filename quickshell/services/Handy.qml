pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    property string phase: "idle"
    property string message: ""
    property string screenName: ""
    property string microphoneName: "Default"
    property bool watcherReady: false
    property bool handyRunning: false
    property bool pendingToggle: false
    property double startedAt: 0
    property int elapsedSeconds: 0
    property var levels: []

    readonly property bool active: phase !== "idle"
    readonly property bool recording: phase === "recording"
    readonly property string elapsed: String(Math.floor(elapsedSeconds / 60)).padStart(2, "0")
        + ":" + String(elapsedSeconds % 60).padStart(2, "0")

    readonly property PwNode captureStream: Audio.inputStreams.find(n => {
        const binary = String(n.properties["application.process.binary"] ?? "").toLowerCase()
        const name = String(n.properties["application.name"] ?? "").toLowerCase()
        return binary === "handy" || binary === ".handy-wrapped"
            || name === "handy" || name === "alsa plug-in [handy]"
            || name === "pipewire alsa [handy]"
    }) ?? null

    readonly property PwNode microphone: {
        if (!Pipewire.ready) return null
        // CPAL/ALSA device names need not match PipeWire descriptions. Prefer
        // the source actually linked to Handy, including non-default inputs.
        // Capture streams report isSink=false, so PwNodeLinkTracker looks in
        // the wrong direction. Their microphone feeds the link's target node.
        const link = root.captureStream ? Pipewire.linkGroups.values.find(g =>
            g.target?.id === root.captureStream.id && g.source?.audio) : null
        if (link) return link.source
        if (!microphoneName || microphoneName.toLowerCase() === "default") return null
        return Pipewire.nodes.values.find(n => n.audio && !n.isSink && !n.isStream
            && (n.description === microphoneName || n.name === microphoneName
                || n.nickname === microphoneName)) ?? null
    }
    readonly property bool micMuted: microphone?.audio?.muted ?? false
    readonly property string meterHint: !microphone ? "Microphone meter unavailable"
        : micMuted ? "Microphone muted" : "Super + D to finish"

    function chooseScreen() {
        screenName = Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
    }

    function fail(text, persistent = false) {
        acknowledgement.stop()
        pendingToggle = false
        if (!active) chooseScreen()
        message = text
        phase = "error"
        levels = []
        dismissError.stop()
        if (!persistent) dismissError.start()
    }

    function toggle() {
        if (command.running || debounce.running || pendingToggle) return
        debounce.start()
        dismissError.stop()
        if (!active || phase === "error") {
            chooseScreen()
            phase = "starting"
            message = ""
        }
        // Wait for the tailer's EOF checkpoint before Handy can write a new event.
        pendingToggle = true
        if (phase !== "transcribing") acknowledgement.restart()
        if (watcherReady) dispatchToggle()
    }

    function dispatchToggle() {
        pendingToggle = false
        if (!handyRunning) {
            fail("Open Handy, then press Super + D again.")
            return
        }
        if (phase === "idle") {
            chooseScreen()
            phase = "starting"
        }
        if (phase !== "transcribing") acknowledgement.restart()
        command.didStart = false
        command.running = true
    }

    function accept(event) {
        if (event.event === "availability") {
            handyRunning = event.running
            return
        }
        if (event.event === "ready") {
            watcherReady = true
            if (pendingToggle) dispatchToggle()
            return
        }
        if (event.event === "device") {
            microphoneName = event.name
            return
        }
        if (event.event === "offline") {
            if (active) fail("Handy closed. Open Handy to continue.")
            return
        }
        if (event.event === "unknown") {
            if ((active || handyRunning) && !pendingToggle)
                fail("Handy status unknown. Check the app.", true)
            return
        }
        if (event.event !== "state") return
        acknowledgement.stop()
        if (event.state === "error") {
            fail(event.message + " Check Handy.")
            return
        }
        // An error is usually followed immediately by Handy resetting its tray.
        if (event.state === "idle" && phase === "error" && dismissError.running) return
        dismissError.stop()
        if (event.state === "recording" && !recording) {
            if (!active) chooseScreen()
            startedAt = Date.now()
            elapsedSeconds = 0
            levels = []
        }
        phase = event.state
        if (!recording) levels = []
    }

    PwObjectTracker { objects: root.microphone ? [root.microphone] : [] }

    // Quickshell >= 0.3. Only meter while Handy is recording; never store audio.
    PwNodePeakMonitor {
        id: meter
        node: root.microphone
        enabled: root.recording && root.microphone !== null && !root.micMuted
    }

    Timer {
        interval: 50
        repeat: true
        running: root.recording
        onTriggered: {
            const peak = meter.enabled ? Math.max(0, Math.min(1, meter.peak)) : 0
            root.levels = [peak < 0.015 ? 0 : peak].concat(root.levels.slice(0, 14))
            root.elapsedSeconds = Math.floor((Date.now() - root.startedAt) / 1000)
        }
    }

    Timer { id: debounce; interval: 350 }
    Timer {
        id: acknowledgement
        interval: 8000
        onTriggered: root.fail("No status from Handy. Check its debug logs.", true)
    }
    Timer {
        id: dismissError
        interval: 6500
        onTriggered: root.phase = "idle"
    }
    Timer {
        id: restartWatcher
        interval: 3000
        onTriggered: watcher.running = true
    }

    Process {
        id: command
        property bool didStart: false
        // Hidden startup covers an exit between the presence check and invocation.
        // Detach so restarting Quickshell cannot terminate Handy.
        command: ["sh", "-c", "command -v handy >/dev/null 2>&1 || exit 127; handy --start-hidden --toggle-transcription >/dev/null 2>&1 &"]
        onStarted: didStart = true
        onExited: (code, status) => {
            if (code !== 0 || status !== 0) root.fail("Could not toggle Handy. Check its installation.")
        }
        onRunningChanged: {
            if (!running && !didStart) root.fail("Handy could not start. Check its installation.")
        }
    }

    Process {
        id: watcher
        command: ["python3", Quickshell.shellDir + "/scripts/handy-status.py"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try { root.accept(JSON.parse(line)) }
                catch (error) { console.warn("Invalid Handy status event") }
            }
        }
        onRunningChanged: {
            if (running) return
            root.watcherReady = false
            if (root.active) root.fail("Handy status unavailable. Check Python 3.", true)
            restartWatcher.restart()
        }
    }
}

pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property int volumePercent: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property int micVolumePercent: Math.round((source?.audio?.volume ?? 0) * 100)
    readonly property string volumeLabel: muted ? "MUTE" : volumePercent + "%"

    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted }
    function toggleMicMute() { if (source?.audio) source.audio.muted = !source.audio.muted }

    // Unmute on adjust: dragging a slider to a level and hearing nothing back
    // reads as broken, so a deliberate level change also lifts the mute.
    function setVolumePercent(percent) {
        if (!sink?.audio) return
        sink.audio.muted = false
        sink.audio.volume = percent / 100
    }
    function setMicVolumePercent(percent) {
        if (!source?.audio) return
        source.audio.muted = false
        source.audio.volume = percent / 100
    }

    // Per-application playback streams (for the volume mixer)
    readonly property var streams: Pipewire.ready
        ? Pipewire.nodes.values.filter(n =>
            n.audio && (n.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream)
        : []

    // Per-application capture streams (for the mic panel)
    readonly property var inputStreams: Pipewire.ready
        ? Pipewire.nodes.values.filter(n =>
            n.audio && (n.type & PwNodeType.AudioInStream) === PwNodeType.AudioInStream)
        : []

    // Physical devices. isStream is what separates a card/port from an app
    // stream — the AudioSink type bit alone also matches output streams.
    readonly property var outputDevices: Pipewire.ready
        ? Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
        : []

    readonly property var inputDevices: Pipewire.ready
        ? Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
        : []

    function setOutputDevice(node) { Pipewire.preferredDefaultAudioSink = node }
    function setInputDevice(node) { Pipewire.preferredDefaultAudioSource = node }

    // Per-application output routing. Pins a playback stream to a specific
    // output device via PipeWire's target.object metadata (persists across the
    // stream's lifetime); passing a null device clears the pin so the stream
    // follows the system default again. Uses the stream's PipeWire node id.
    Process { id: router }
    function routeStreamTo(streamNode, sinkNode) {
        if (!streamNode) return
        router.command = sinkNode
            ? ["pw-metadata", String(streamNode.id), "target.object", '"' + sinkNode.name + '"']
            : ["pw-metadata", "-d", String(streamNode.id), "target.object"]
        router.running = true
    }

    // description is the human label ("Built-in Audio Analog Stereo"); nickname
    // is shorter but often empty, and name is the raw pipewire id.
    function deviceName(node) {
        return node?.description || node?.nickname || node?.name || "Unknown device"
    }

    function appName(node) {
        return (node?.properties && node.properties["application.name"])
            || node?.description || node?.name || "Application"
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
            .concat(root.streams)
            .concat(root.inputStreams)
            .concat(root.outputDevices)
            .concat(root.inputDevices)
    }
}

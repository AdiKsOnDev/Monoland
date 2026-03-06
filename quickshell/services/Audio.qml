pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property int volumePercent: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property string volumeLabel: muted ? "MUTE" : volumePercent + "%"

    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted }
    function toggleMicMute() { if (source?.audio) source.audio.muted = !source.audio.muted }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}

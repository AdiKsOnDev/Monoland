pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values

    readonly property MprisPlayer activePlayer: {
        let pausedPlayer = null
        for (let i = 0; i < players.length; i++) {
            const player = players[i]
            if (player.isPlaying) return player
            if (pausedPlayer === null && player.playbackState === MprisPlaybackState.Paused)
                pausedPlayer = player
        }
        return pausedPlayer ?? (players.length > 0 ? players[0] : null)
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property string trackTitle: activePlayer?.trackTitle ?? ""
    readonly property string trackArtist: activePlayer?.trackArtist ?? ""
    readonly property string trackArtUrl: activePlayer?.trackArtUrl ?? ""
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false

    // Bypasses Quickshell's canPlay guard by calling D-Bus directly
    function playPause() {
        if (!activePlayer) return
        dbusCall.command = [
            "dbus-send", "--session", "--type=method_call",
            "--dest=" + activePlayer.dbusName,
            "/org/mpris/MediaPlayer2",
            "org.mpris.MediaPlayer2.Player.PlayPause"
        ]
        dbusCall.running = true
    }

    Process {
        id: dbusCall
    }
}

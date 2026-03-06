pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string background:        parsed.special?.background  ?? "#050402"
    readonly property string foreground:        parsed.special?.foreground  ?? "#dfdfe0"
    readonly property string primaryText:       parsed.colors?.color7       ?? "#dfdfe0"
    readonly property string secondaryText:     parsed.colors?.color8       ?? "#9c9c9c"
    readonly property string workspaceActive:   parsed.colors?.color7       ?? "#dfdfe0"
    readonly property string workspaceOccupied: parsed.colors?.color8       ?? "#9c9c9c"
    readonly property string workspaceInactive: parsed.colors?.color8       ?? "#9c9c9c"
    readonly property string chipBackground:    parsed.colors?.color0       ?? "#1a1a1a"
    readonly property string surfaceVariant:    Qt.darker(parsed.colors?.color8 ?? "#9c9c9c", 3.0)
    readonly property string chipIcon:          parsed.colors?.color7       ?? "#dfdfe0"
    readonly property string border:            parsed.colors?.color8       ?? "#9c9c9c"

    property var parsed: ({})

    property string colorsPath: "~/.cache/wal/colors.json"

    function reload() {
        reader.running = true
    }

    Process {
        id: reader
        command: ["cat", root.colorsPath]
        running: false

        stdout: SplitParser {
            property string buffer: ""
            onRead: (line) => { buffer += line + "\n" }
        }

        onRunningChanged: {
            if (!running) {
                const text = reader.stdout.buffer.trim()
                reader.stdout.buffer = ""
                if (text.length > 0) root.parsed = JSON.parse(text)
            }
        }
    }

    // Watch sentinel file written by set-wallpaper.sh after wal finishes
    FileView {
        id: sentinel
        path: "~/.cache/wal/.qs-reload"
        watchChanges: true
        preload: true
    }

    Connections {
        target: sentinel
        function onInternalTextChanged() { root.reload() }
    }

    Component.onCompleted: root.reload()
}

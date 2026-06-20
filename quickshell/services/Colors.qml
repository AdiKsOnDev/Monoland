pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string background:        parsed.special?.background  ?? "#050402"
    readonly property string foreground:        parsed.special?.foreground  ?? "#dfdfe0"

    // Detect a light palette from background luminance. pywal's light mode (-l)
    // makes color0/color8 dark, so the dark-mode surface derivations turn
    // near-black on a light background. Derive soft surfaces per mode instead.
    readonly property bool isLight: {
        const bg = Qt.color(background)
        return (0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b) > 0.5
    }
    readonly property string primaryText:       parsed.colors?.color7       ?? "#dfdfe0"
    readonly property string secondaryText:     parsed.colors?.color8       ?? "#9c9c9c"
    readonly property string workspaceActive:   parsed.colors?.color7       ?? "#dfdfe0"
    readonly property string workspaceOccupied: parsed.colors?.color8       ?? "#9c9c9c"
    readonly property string workspaceInactive: parsed.colors?.color8       ?? "#9c9c9c"
    // Surfaces sit just off the background: lighter in dark mode, darker in light
    // mode — a small, consistent step either way instead of harsh near-black.
    readonly property string chipBackground: isLight
        ? Qt.darker(background, 1.06)
        : (parsed.colors?.color0 ?? "#1a1a1a")
    readonly property string surfaceVariant: isLight
        ? Qt.darker(background, 1.13)
        : Qt.darker(parsed.colors?.color8 ?? "#9c9c9c", 3.0)
    readonly property string chipIcon:          parsed.colors?.color7       ?? "#dfdfe0"
    readonly property string chipIconActive:    parsed.colors?.color3       ?? "#ff6154"
    readonly property string border: isLight
        ? Qt.darker(background, 1.22)
        : (parsed.colors?.color8 ?? "#9c9c9c")

    // "Strong fill" for active toggles and slider fills. In dark mode this is the
    // bright primaryText (light pill on dark bg). In light mode primaryText is
    // near-black, so use the accent instead — and pick legible on-fill text from
    // the accent's luminance.
    readonly property real _accentLum: {
        const x = Qt.color(chipIconActive)
        return 0.299 * x.r + 0.587 * x.g + 0.114 * x.b
    }
    readonly property string fillStrong:     isLight ? chipIconActive : primaryText
    readonly property string fillStrongText: isLight
        ? (_accentLum > 0.6 ? "#101010" : "#ffffff")
        : background

    // Distinct accents for per-source coloring (e.g. one per calendar). Theme-aware.
    readonly property var accents: [
        parsed.colors?.color1 ?? "#e06c75",
        parsed.colors?.color2 ?? "#98c379",
        parsed.colors?.color4 ?? "#61afef",
        parsed.colors?.color5 ?? "#c678dd",
        parsed.colors?.color6 ?? "#56b6c2",
        parsed.colors?.color3 ?? "#e5c07b"
    ]

    function accentFor(index) {
        return accents[((index ?? 0) % accents.length + accents.length) % accents.length]
    }

    property var parsed: ({})

    property string colorsPath: Quickshell.env("HOME") + "/.cache/wal/colors.json"

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
        path: Quickshell.env("HOME") + "/.cache/wal/.qs-reload"
        watchChanges: true
        preload: true
    }

    Connections {
        target: sentinel
        function onInternalTextChanged() { root.reload() }
    }

    Component.onCompleted: root.reload()
}

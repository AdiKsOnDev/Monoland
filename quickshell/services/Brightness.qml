pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int brightnessPercent: 0

    function setBrightnessPercent(percent) {
        const clamped = Math.max(1, Math.min(100, Math.round(percent)))
        setter.command = ["brightnessctl", "set", clamped + "%"]
        setter.running = true
    }

    function refresh() {
        getter.running = true
    }

    Process {
        id: getter
        command: ["bash", "-c", "brightnessctl info | grep -oP '\\(\\K[0-9]+'"]
        running: true

        stdout: SplitParser {
            onRead: (line) => {
                const val = parseInt(line.trim())
                if (!isNaN(val)) root.brightnessPercent = val
            }
        }
    }

    Process {
        id: setter
        running: false
        onRunningChanged: if (!running) root.refresh()
    }
}

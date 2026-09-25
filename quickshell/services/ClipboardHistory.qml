pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    readonly property bool running: watcher.running

    Process {
        id: watcher
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
        running: true
    }
}

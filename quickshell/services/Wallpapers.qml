pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// Wallpaper library for the settings Appearance page. Applying shells out to
// set-wallpaper.sh, which regenerates the pywal palette and then calls
// `qs ipc call colors reload`, so the shell recolours without restarting.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    property var files: []
    readonly property bool scanning: scanner.running

    function scan() { scanner.running = true }

    function apply(file) {
        applier.command = [
            Quickshell.env("HOME") + "/.local/share/bin/set-wallpaper.sh",
            root.dir + "/" + file
        ]
        applier.running = true
    }

    function urlFor(file) { return "file://" + root.dir + "/" + file }

    function displayName(file) { return String(file).replace(/\.[^.]+$/, "") }

    Process {
        id: scanner
        command: ["bash", "-c",
            "ls -1 '" + root.dir + "' 2>/dev/null | grep -iE '\\.(jpg|jpeg|png|webp|bmp|gif)$'"]
        running: true

        stdout: SplitParser {
            property var lines: []
            onRead: (line) => {
                const t = line.trim()
                if (t !== "") scanner.stdout.lines.push(t)
            }
        }

        // Collect into a scratch array and publish once, so consumers don't
        // rebind against a list that is still filling in.
        onRunningChanged: {
            if (running) {
                scanner.stdout.lines = []
                return
            }
            root.files = scanner.stdout.lines.slice()
        }
    }

    Process { id: applier }
}

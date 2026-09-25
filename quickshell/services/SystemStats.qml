pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// Live CPU / memory / swap / load stats, streamed from /proc every 2s by a
// single lightweight shell loop (computes the CPU delta itself so no polling
// logic is needed on the QML side).
Singleton {
    id: root

    property int cpuPercent: 0
    property real memUsedKb: 0
    property real memTotalKb: 0
    property real swapUsedKb: 0
    property real swapTotalKb: 0
    property real load1: 0
    property real tempC: 0
    property int cores: 0

    readonly property real memPercent: memTotalKb > 0 ? memUsedKb / memTotalKb : 0
    readonly property real swapPercent: swapTotalKb > 0 ? swapUsedKb / swapTotalKb : 0

    function _gib(kb) { return (kb / 1048576).toFixed(1) }
    readonly property string memUsedLabel: _gib(memUsedKb)
    readonly property string memTotalLabel: _gib(memTotalKb)
    readonly property string swapUsedLabel: _gib(swapUsedKb)
    readonly property string swapTotalLabel: _gib(swapTotalKb)

    Process {
        running: true
        command: ["bash", "-c",
            'read -r _ a b c d0 e f g _ < /proc/stat; pt=$((a+b+c+d0+e+f+g)); pi=$((d0+e)); nc=$(nproc);' +
            ' while true; do sleep 2;' +
            ' read -r _ a b c d0 e f g _ < /proc/stat; t=$((a+b+c+d0+e+f+g)); i=$((d0+e));' +
            ' dt=$((t-pt)); di=$((i-pi)); pt=$t; pi=$i; cpu=0; [ "$dt" -gt 0 ] && cpu=$(( (100*(dt-di))/dt ));' +
            ' mt=$(grep -m1 MemTotal /proc/meminfo|tr -dc 0-9); ma=$(grep -m1 MemAvailable /proc/meminfo|tr -dc 0-9);' +
            ' st=$(grep -m1 SwapTotal /proc/meminfo|tr -dc 0-9); sf=$(grep -m1 SwapFree /proc/meminfo|tr -dc 0-9);' +
            ' ld=$(cut -d" " -f1 /proc/loadavg); tp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0);' +
            ' echo $cpu $((mt-ma)) $mt $((st-sf)) $st $ld $tp $nc; done'
        ]

        stdout: SplitParser {
            onRead: (line) => {
                const p = line.trim().split(/\s+/)
                if (p.length < 8) return
                root.cpuPercent = parseInt(p[0]) || 0
                root.memUsedKb = parseFloat(p[1]) || 0
                root.memTotalKb = parseFloat(p[2]) || 0
                root.swapUsedKb = parseFloat(p[3]) || 0
                root.swapTotalKb = parseFloat(p[4]) || 0
                root.load1 = parseFloat(p[5]) || 0
                root.tempC = (parseFloat(p[6]) || 0) / 1000
                root.cores = parseInt(p[7]) || 0
            }
        }
    }
}

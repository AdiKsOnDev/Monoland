pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// Detailed state for the active Wi-Fi link, plus editing of the NetworkManager
// profile behind it.
//
// Quickshell.Networking only surfaces SSID / strength / security / known, so
// everything below it — addressing, routes, DNS, band, driver, AP flags —
// comes from nmcli. One shell round-trip gathers the lot rather than spawning
// a process per field, and polling only runs while a page is watching.
Singleton {
    id: root

    property bool active: false

    property string iface: ""
    property var fields: ({})     // GENERAL.* / IP4.* / IP6.* from `device show`
    property var ap: []           // active row from `device wifi list`
    property var profile: ({})    // ipv4.* / ipv6.* / connection.* from the profile
    property bool ready: false

    // Change-detection snapshots for the poll (see onRunningChanged)
    property string _fieldsJson: ""
    property string _apJson: ""
    property string _profileJson: ""

    readonly property bool connected: iface !== "" && ap.length > 1
    readonly property string uuid: value("GENERAL.CON-UUID")

    // ── Editing state ─────────────────────────────────────────────────────
    property bool applying: false
    property string lastError: ""
    property bool lastOk: false

    function refresh() { if (!probe.running) probe.running = true }

    // nmcli -t escapes a colon inside a value as "\:" (BSSIDs do this); an
    // IPv6 address's colons are left bare. Splitting on unescaped colons and
    // unescaping as we go handles both, and rejoining the tail restores any
    // value that legitimately contained one.
    function splitTerse(line) {
        const out = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length) { cur += line[i + 1]; i++; continue }
            if (c === ":") { out.push(cur); cur = ""; continue }
            cur += c
        }
        out.push(cur)
        return out
    }

    function value(key) { return fields[key] ?? "" }
    function setting(key) { return profile[key] ?? "" }

    // IP4.DNS[1], IP4.ROUTE[2], IP6.ADDRESS[1] … collected in index order
    function collect(prefix) {
        const out = []
        for (let i = 1; i < 32; i++) {
            const v = fields[prefix + "[" + i + "]"]
            if (v === undefined) break
            out.push(v)
        }
        return out
    }

    // AP row fields, in the order requested from nmcli
    readonly property string ssid:     ap[1] ?? ""
    readonly property string bssid:    ap[2] ?? ""
    readonly property string mode:     ap[3] ?? ""
    readonly property string channel:  ap[4] ?? ""
    readonly property string frequency:ap[5] ?? ""
    readonly property string rate:     ap[6] ?? ""
    // Not "signal" — that is a QML keyword. nmcli reports 0-100 link quality
    // here, not dBm, so don't present it as a power figure.
    readonly property string signalQuality: ap[7] ?? ""
    readonly property string security: ap[8] ?? ""
    readonly property string wpaFlags: ap[9] ?? ""
    readonly property string rsnFlags: ap[10] ?? ""

    // "5180 MHz" -> band label. 6 GHz starts at 5925 MHz (U-NII-5).
    readonly property string band: {
        const mhz = parseInt(frequency)
        if (isNaN(mhz)) return ""
        if (mhz >= 5925) return "6 GHz"
        if (mhz >= 4900) return "5 GHz"
        return "2.4 GHz"
    }

    // ── Validation ────────────────────────────────────────────────────────
    function isIpv4(s) {
        const m = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec((s ?? "").trim())
        if (!m) return false
        for (let i = 1; i <= 4; i++) if (parseInt(m[i]) > 255) return false
        return true
    }

    function isIpv4Cidr(s) {
        const parts = (s ?? "").trim().split("/")
        if (parts.length !== 2) return false
        const prefix = parseInt(parts[1])
        return isIpv4(parts[0]) && !isNaN(prefix) && prefix >= 0 && prefix <= 32
    }

    // Whitespace- or comma-separated list of plain IPv4 addresses
    function isDnsList(s) {
        const t = (s ?? "").trim()
        if (t === "") return true
        return t.split(/[\s,]+/).every(x => isIpv4(x))
    }

    // "" when the inputs are usable, otherwise the reason why not. Catching
    // this here keeps a typo from tearing down a working link only to have
    // nmcli reject it afterwards.
    function validateIpv4(method, address, gateway, dns) {
        if (!isDnsList(dns)) return "DNS must be IPv4 addresses, space or comma separated"
        if (method !== "manual") return ""
        if (!isIpv4Cidr(address)) return "Address must be in CIDR form, e.g. 192.168.1.50/24"
        if ((gateway ?? "").trim() !== "" && !isIpv4(gateway)) return "Gateway must be an IPv4 address"
        return ""
    }

    // ── Writes ────────────────────────────────────────────────────────────
    //
    // Values are passed as positional arguments rather than interpolated into
    // the script, so nothing a user types can be read as shell syntax.
    // `connection up` re-activates the profile, which briefly drops the link —
    // unavoidable when changing addressing.
    function applyIpv4(method, address, gateway, dns, ignoreAutoDns) {
        if (uuid === "") return

        const problem = validateIpv4(method, address, gateway, dns)
        if (problem !== "") {
            lastError = problem
            lastOk = false
            return
        }

        lastError = ""
        lastOk = false
        applying = true
        applier.command = ["bash", "-c", `
set -e
uuid="$1"; method="$2"; addr="$3"; gw="$4"; dns="$5"; ignore="$6"
if [ "$method" = manual ]; then
    nmcli connection modify "$uuid" \
        ipv4.method manual \
        ipv4.addresses "$addr" \
        ipv4.gateway "$gw" \
        ipv4.dns "$dns"
else
    nmcli connection modify "$uuid" \
        ipv4.method auto \
        ipv4.addresses "" \
        ipv4.gateway "" \
        ipv4.dns "$dns" \
        ipv4.ignore-auto-dns "$ignore"
fi
nmcli connection up "$uuid" >/dev/null
`, "nm-apply", uuid, method,
            (address ?? "").trim(), (gateway ?? "").trim(), (dns ?? "").trim(),
            ignoreAutoDns ? "yes" : "no"]
        applier.running = true
    }

    // Single-key profile edits (autoconnect, metered, ipv6.method …). These
    // take effect on the stored profile; no re-activation needed.
    function setProfileFlag(key, val) {
        if (uuid === "") return
        lastError = ""
        lastOk = false
        applying = true
        applier.command = ["bash", "-c",
            'nmcli connection modify "$1" "$2" "$3"',
            "nm-flag", uuid, key, val]
        applier.running = true
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: applier

        stderr: SplitParser {
            property var lines: []
            onRead: (line) => applier.stderr.lines.push(line)
        }

        onRunningChanged: { if (running) applier.stderr.lines = [] }

        onExited: (exitCode) => {
            root.applying = false
            root.lastOk = exitCode === 0
            if (exitCode !== 0) {
                // nmcli prefixes with "Error: "; keep the useful part
                const msg = applier.stderr.lines.join(" ").replace(/^Error:\s*/, "").trim()
                root.lastError = msg !== "" ? msg : "nmcli exited with code " + exitCode
            }
            root.refresh()
        }
    }

    Process {
        id: probe
        command: ["bash", "-c", `
IFACE=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}')
echo "IFACE:$IFACE"
[ -z "$IFACE" ] && exit 0
nmcli -t -f GENERAL,IP4,IP6 device show "$IFACE" 2>/dev/null
echo "@@AP@@"
nmcli -t -f ACTIVE,SSID,BSSID,MODE,CHAN,FREQ,RATE,SIGNAL,SECURITY,WPA-FLAGS,RSN-FLAGS \
    device wifi list ifname "$IFACE" --rescan no 2>/dev/null | grep '^yes:' | head -1
echo "@@PROFILE@@"
UUID=$(nmcli -t -f GENERAL.CON-UUID device show "$IFACE" 2>/dev/null | cut -d: -f2)
[ -n "$UUID" ] && nmcli -t -f \
    ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.ignore-auto-dns,ipv6.method,connection.autoconnect,connection.metered \
    connection show "$UUID" 2>/dev/null
exit 0
`]

        stdout: SplitParser {
            property var lines: []
            onRead: (line) => probe.stdout.lines.push(line)
        }

        onRunningChanged: {
            if (running) {
                probe.stdout.lines = []
                return
            }

            const out = probe.stdout.lines
            const parsed = {}
            const prof = {}
            let apRow = []
            let section = "dev"
            let dev = ""

            for (const line of out) {
                if (line === "@@AP@@") { section = "ap"; continue }
                if (line === "@@PROFILE@@") { section = "profile"; continue }

                if (section === "ap") {
                    if (line.trim() !== "") apRow = root.splitTerse(line)
                    continue
                }

                const parts = root.splitTerse(line)
                if (parts.length < 2) continue
                const key = parts[0]
                const val = parts.slice(1).join(":")

                if (section === "profile") { prof[key] = val; continue }
                if (key === "IFACE") { dev = val; continue }
                parsed[key] = val
            }

            // Only republish when something actually changed. Reassigning
            // every 5s would hand each Repeater a brand-new array and make it
            // tear down and rebuild delegates that never changed.
            const fieldsJson = JSON.stringify(parsed)
            if (fieldsJson !== root._fieldsJson) {
                root._fieldsJson = fieldsJson
                root.fields = parsed
            }

            const apJson = JSON.stringify(apRow)
            if (apJson !== root._apJson) {
                root._apJson = apJson
                root.ap = apRow
            }

            const profJson = JSON.stringify(prof)
            if (profJson !== root._profileJson) {
                root._profileJson = profJson
                root.profile = prof
            }

            root.iface = dev
            root.ready = true
        }
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wifi link state and throughput, polled from nmcli and /sys/class/net.
Singleton {
    id: root

    property var info: ({})
    property real rxRate: 0
    property real txRate: 0
    property var history: []
    readonly property int historySize: 40

    readonly property bool connected: (info.ssid ?? "") !== ""
    readonly property int signal: connected ? (parseInt(info.signal ?? "0") || 0) : -1
    readonly property string ssid: info.ssid ?? ""
    readonly property string icon: signal < 0 ? "󰤮" : ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor(signal / 20))]

    property real lastRx: -1
    property real lastTx: -1
    property real lastT: 0

    Process {
        id: reader
        command: ["sh", "-c",
            "dev=$(nmcli -t -f DEVICE,TYPE dev | awk -F: '$2==\"wifi\"{print $1; exit}'); " +
            "echo dev=$dev; " +
            "nmcli -t -e no -f ACTIVE,SSID,SIGNAL,FREQ,RATE,SECURITY,CHAN dev wifi list --rescan no | " +
            "awk -F: '$1==\"yes\"{print \"ssid=\"$2; print \"signal=\"$3; print \"freq=\"$4; print \"rate=\"$5; print \"sec=\"$6; print \"chan=\"$7; exit}'; " +
            "nmcli -t -g IP4.ADDRESS,IP4.GATEWAY,IP4.DNS dev show $dev | sed -n '1s/^/ip=/p;2s/^/gw=/p;3s/^/dns=/p'; " +
            "echo mac=$(cat /sys/class/net/$dev/address 2>/dev/null); " +
            "echo rx=$(cat /sys/class/net/$dev/statistics/rx_bytes); " +
            "echo tx=$(cat /sys/class/net/$dev/statistics/tx_bytes)"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const out = {}
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=")
                    if (i > 0)
                        out[line.slice(0, i)] = line.slice(i + 1).trim()
                }
                const now = Date.now()
                const rx = parseFloat(out.rx), tx = parseFloat(out.tx)
                if (root.lastRx >= 0 && now > root.lastT) {
                    const dt = (now - root.lastT) / 1000
                    root.rxRate = Math.max(0, (rx - root.lastRx) / dt)
                    root.txRate = Math.max(0, (tx - root.lastTx) / dt)
                    const h = root.history.slice(1 - root.historySize)
                    h.push(root.rxRate + root.txRate)
                    root.history = h
                }
                root.lastRx = rx
                root.lastTx = tx
                root.lastT = now
                root.info = out
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: if (!reader.running) reader.running = true
    }
}

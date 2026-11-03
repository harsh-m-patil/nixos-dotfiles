pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

import "."

// The status island's store: audio, battery, radios, brightness and load as plain values,
// plus the actions the island's tiles call. Also holds which screen has the panel open.
Singleton {
    id: root

    property bool open: false
    property string screen: ""
    function toggle(onScreen) {
        if (open && (!onScreen || onScreen === screen)) { open = false; return }
        screen = onScreen || Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || ""
        open = true
    }
    onOpenChanged: if (open) { readRadio(); MonitorData.refresh() }

    // Audio
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool hasOutput: !!sink?.audio
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property bool hasMic: !!source?.audio
    readonly property string outputName: sink?.description || sink?.name || "No output"
    readonly property string volumeIcon: !hasOutput || muted ? "󰝟" : volume < 0.34 ? "󰕿" : volume < 0.67 ? "󰖀" : "󰕾"
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    function setVolume(v) { if (hasOutput) { sink.audio.muted = false; sink.audio.volume = Math.max(0, Math.min(1.5, v)) } }
    function toggleMute() { if (hasOutput) sink.audio.muted = !sink.audio.muted }
    function toggleMic() { if (hasMic) source.audio.muted = !source.audio.muted }
    function useSink(node) { Pipewire.preferredDefaultAudioSink = node }

    PwObjectTracker { objects: [root.sink, root.source] }

    // Battery
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: (battery?.isLaptopBattery ?? false) && (battery?.percentage ?? 0) > 0
    readonly property real batteryLevel: battery?.percentage ?? 0
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
    readonly property bool full: battery?.state === UPowerDeviceState.FullyCharged
    readonly property bool batteryLow: hasBattery && !charging && batteryLevel <= 0.2
    readonly property string batteryIcon: charging ? "󰂄" : full ? "󰚥"
        : ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.min(9, Math.floor(batteryLevel * 10))]
    readonly property string batteryDetail: {
        if (full) return "Fully charged"
        const s = charging ? battery?.timeToFull ?? 0 : battery?.timeToEmpty ?? 0
        if (s <= 0) return charging ? "Charging" : "On battery"
        return Fmt.duration(s / 3600) + (charging ? " until full" : " left")
    }

    // Wi-Fi and Bluetooth
    property bool wifiOn: true
    readonly property bool wifiConnected: Network.connected
    readonly property string wifiIcon: wifiOn ? Network.icon : "󰤭"
    readonly property string wifiDetail: !wifiOn ? "Off" : Network.connected ? Network.ssid : "Not connected"
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property var btConnected: (Bluetooth.devices?.values ?? []).filter(d => d.connected)
    readonly property string btDetail: !adapter ? "Unavailable" : !btOn ? "Off"
        : btConnected.length === 1 ? btConnected[0].name : btConnected.length > 1 ? btConnected.length + " devices" : "On"
    function toggleWifi() {
        wifiOn = !wifiOn
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiOn ? "on" : "off"])
    }
    function toggleBluetooth() { if (adapter) adapter.enabled = !adapter.enabled }
    function readRadio() { if (!radio.running) radio.running = true }

    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") root.wifiOn = text.trim() === "enabled" }
    }

    // Brightness
    readonly property bool hasBacklight: Backlight.percent !== ""
    readonly property real brightness: (parseInt(Backlight.percent) || 0) / 100
    function setBrightness(v) {
        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(Math.max(0.01, Math.min(1, v)) * 100) + "%"])
    }

    IpcHandler {
        target: "status"
        function toggle(): void { root.toggle() }
        function close(): void { root.open = false }
    }
}

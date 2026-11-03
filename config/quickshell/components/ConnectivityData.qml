pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking as Net

import "."

Singleton {
    id: root

    property bool ccWifiOpen: false
    property bool ccBtOpen: false

    readonly property bool pickersActive: (StatusData.open && (ccWifiOpen || ccBtOpen))
        || (SystemData.windowOpen && SystemData.tab === 3)

    readonly property var wifiDevice: {
        for (const d of Net.Networking.devices?.values ?? []) {
            if (d.type === Net.DeviceType.Wifi)
                return d
        }
        return null
    }

    readonly property bool wifiEnabled: Net.Networking.wifiEnabled
    readonly property bool wifiAvailable: !!wifiDevice
    readonly property var wifiNetworks: {
        const nets = wifiDevice?.networks?.values ?? []
        return nets.slice().sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1
            if (a.known !== b.known)
                return a.known ? -1 : 1
            return (b.signalStrength ?? 0) - (a.signalStrength ?? 0)
        })
    }
    readonly property string wifiTrailing: !wifiAvailable ? "No adapter"
        : !wifiEnabled ? "Off"
        : wifiNetworks.find(n => n.connected)?.name || "Not connected"

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btAvailable: !!btAdapter
    readonly property bool btEnabled: btAdapter?.enabled ?? false
    readonly property var btDevices: {
        const devs = Bluetooth.devices?.values ?? []
        return devs.slice().sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1
            const an = a.name || a.deviceName || a.address || ""
            const bn = b.name || b.deviceName || b.address || ""
            return an.localeCompare(bn)
        })
    }
    readonly property string btTrailing: !btAvailable ? "Unavailable"
        : !btEnabled ? "Off"
        : btDevices.find(d => d.connected)?.name
            || btDevices.find(d => d.connected)?.deviceName
            || (btAdapter.discovering ? "Scanning" : "On")

    function setWifiEnabled(on) {
        Net.Networking.wifiEnabled = on
    }

    function setBtEnabled(on) {
        if (btAdapter)
            btAdapter.enabled = on
    }

    function wifiIcon(strength, enabled) {
        if (!enabled)
            return "󰤭"
        const s = Math.round(Math.max(0, Math.min(1, strength ?? 0)) * 100)
        if (s < 0)
            return "󰤮"
        return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor(s / 20))]
    }

    function wifiDetail(net) {
        if (net.connected)
            return "Connected"
        if (net.stateChanging)
            return "Connecting…"
        if (net.known)
            return "Saved"
        const pct = Math.round(Math.max(0, Math.min(1, net.signalStrength ?? 0)) * 100)
        return pct + "%"
    }

    function activateWifi(net) {
        if (!net || net.connected || net.stateChanging)
            return
        net.connect()
    }

    function btLabel(device) {
        return device?.name || device?.deviceName || device?.address || "Device"
    }

    function btDetail(device) {
        if (!device)
            return ""
        if (device.connected)
            return device.batteryAvailable ? Math.round(device.battery * 100) + "% battery" : "Connected"
        if (device.pairing)
            return "Pairing…"
        if (device.paired)
            return "Paired"
        return "Tap to pair"
    }

    function activateBt(device) {
        if (!device || !btAdapter?.enabled)
            return
        if (device.connected)
            device.disconnect()
        else if (device.paired)
            device.connect()
        else
            device.pair()
    }

    onPickersActiveChanged: syncScanning()

    Connections {
        target: Net.Networking
        function onWifiEnabledChanged() { root.syncScanning() }
    }

    function syncScanning() {
        if (root.wifiDevice)
            root.wifiDevice.scannerEnabled = root.pickersActive && root.wifiEnabled
        if (!root.btAdapter)
            return
        if (root.pickersActive && root.btEnabled)
            root.btAdapter.discovering = true
        else if (!root.pickersActive)
            root.btAdapter.discovering = false
    }

    Connections {
        target: root.btAdapter
        function onEnabledChanged() { root.syncScanning() }
    }
}

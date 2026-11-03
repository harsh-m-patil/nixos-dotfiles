import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

import "."

Island {
    id: root
    hPad: 4

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var battery: UPower.displayDevice

    AudioPopup {
        trigger: audioIconItem
        triggerHovered: audioIconItem.hovered
        align: 0.9
    }

    WifiPopup {
        trigger: wifiIconItem
        triggerHovered: wifiIconItem.hovered
        align: 0.7
    }

    MonitorPopup {
        trigger: monitorIconItem
        triggerHovered: monitorIconItem.hovered
        align: 0.7
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    RowLayout {
        spacing: 4

        StatusIcon {
            id: audioIconItem
            icon: {
                if (!root.sink?.audio)
                    return "󰕿"
                if (root.sink.audio.muted)
                    return "󰝟"
                const v = Math.round((root.sink.audio.volume ?? 0) * 100)
                if (v < 34)
                    return "󰕿"
                if (v < 67)
                    return "󰖀"
                return "󰕾"
            }
            label: root.sink?.audio && !root.sink.audio.muted
                ? String(Math.round((root.sink.audio.volume ?? 0) * 100)) : ""
            onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
            onWheelUp: root.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"])
            onWheelDown: root.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"])
        }

        StatusIcon {
            visible: root.source?.audio?.muted ?? false
            icon: "󰍭"
            fg: Theme.love
            onClicked: if (root.source?.audio) root.source.audio.muted = false
        }

        StatusIcon {
            icon: root.batteryIcon(root.battery)
            label: root.battery ? String(Math.round(root.battery.percentage * 100)) : ""
            fg: root.batteryFg(root.battery)
            clickable: false
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter
            color: Theme.highlightLow
        }

        StatusIcon {
            id: monitorIconItem
            icon: "󰍹"
            label: MonitorData.monitors.length > 1 ? String(MonitorData.monitors.length) : ""
            fg: monitorIconItem.hovered ? Theme.iris : Theme.subtle
            onClicked: MonitorData.refresh()
        }

        StatusIcon {
            id: wifiIconItem
            icon: Network.icon
            fg: Network.signal < 0 ? Theme.muted : Theme.subtle
            onClicked: root.run(["xdg-open", "vicinae://launch/@dagimg-dot/store.vicinae.wifi-commander/scan-wifi"])
        }

        StatusIcon {
            icon: "󰂯"
            onClicked: root.run(["xdg-open", "vicinae://launch/@Gelei/store.vicinae.bluetooth/scan"])
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter
            color: Theme.highlightLow
        }

        SystemStatusChip {}

    }

    function run(cmd) {
        Quickshell.execDetached(cmd)
    }

    function batteryIcon(dev) {
        if (!dev)
            return "󰁹"
        if (dev.state === UPowerDeviceState.Charging)
            return "󰂄"
        if (dev.state === UPowerDeviceState.FullyCharged)
            return "󰚥"
        const p = Math.round(dev.percentage * 100)
        const icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
        const idx = Math.min(9, Math.max(0, Math.floor(p / 10)))
        return icons[idx]
    }

    function batteryFg(dev) {
        if (!dev)
            return Theme.subtle
        if (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged)
            return Theme.foam
        if (dev.percentage <= 0.10)
            return Theme.love
        if (dev.percentage <= 0.20)
            return Theme.gold
        return Theme.subtle
    }
}

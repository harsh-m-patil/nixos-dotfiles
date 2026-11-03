import QtQuick
import QtQuick.Layouts

import "."

RowLayout {
    id: page

    property int selected: 0

    readonly property var d: SystemData
    readonly property var items: [
        {
            name: "Processor", icon: "󰻠", accent: Theme.iris,
            value: Math.round(d.cpu * 100) + "%", sub: (d.freq[0] / 1000).toFixed(2) + " GHz",
            series: [{ values: d.cpuHistory, color: Theme.iris }], mirrored: false, max: 1
        },
        {
            name: "Memory", icon: "󰘚", accent: Theme.foam,
            value: Fmt.gb(d.memUsed), sub: Math.round(d.memFraction * 100) + "% of " + Fmt.gb(d.memTotal),
            series: [{ values: d.memHistory, color: Theme.foam }], mirrored: false, max: 1
        },
        {
            name: "Graphics", icon: "󰢮", accent: Theme.love,
            value: Math.round(d.gpuBusy * 100) + "%", sub: Fmt.deg(d.gpuTemp),
            series: [{ values: d.gpuHistory, color: Theme.love }], mirrored: false, max: 1
        },
        {
            name: "Network", icon: "󰖩", accent: Theme.foam,
            value: "↓ " + Fmt.rate(d.netRx), sub: "↑ " + Fmt.rate(d.netTx),
            series: [{ values: d.netRxHistory, color: Theme.foam }, { values: d.netTxHistory, color: Theme.iris }],
            mirrored: true, max: 0
        },
        {
            name: "Disk", icon: "󰋊", accent: Theme.gold,
            value: "R " + Fmt.rate(d.diskRead), sub: "W " + Fmt.rate(d.diskWrite),
            series: [{ values: d.diskReadHistory, color: Theme.gold }, { values: d.diskWriteHistory, color: Theme.rose }],
            mirrored: true, max: 0
        }
    ]
    readonly property var current: items[selected]

    spacing: 12

    ColumnLayout {
        Layout.preferredWidth: 260
        Layout.fillWidth: false
        Layout.fillHeight: true
        spacing: 6

        Repeater {
            model: page.items.length

            Rectangle {
                id: entry
                required property int index
                readonly property var item: page.items[index]
                readonly property bool active: page.selected === index
                Layout.fillWidth: true
                implicitHeight: 76
                radius: F1Hub.tileRadius
                color: active ? F1Hub.fillStrong : entryHover.hovered ? F1Hub.fill : "transparent"

                HoverHandler { id: entryHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: page.selected = entry.index }

                Rectangle {
                    visible: entry.active
                    x: 0
                    y: 14
                    width: 3
                    height: parent.height - 28
                    radius: 1.5
                    color: entry.item.accent
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    anchors.leftMargin: 14
                    spacing: 12

                    MonChart {
                        Layout.preferredWidth: 72
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        mirrored: entry.item.mirrored
                        maxValue: entry.item.max
                        floorValue: 16384
                        series: entry.item.series
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: entry.item.name
                            color: Theme.foreground
                            font.family: Theme.displayFont
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: entry.item.value
                            color: entry.active ? entry.item.accent : Theme.subtle
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: entry.item.sub
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    MonPanel {
        Layout.fillHeight: true
        title: page.current.name
        icon: page.current.icon
        accent: page.current.accent
        trailing: [
            page.d.info.cpuname || "",
            Fmt.gb(page.d.memTotal) + " installed",
            "amdgpu",
            page.d.s.netdev || "offline",
            "nvme  ·  /"
        ][page.selected]

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: page.selected

            // processor
            ColumnLayout {
                spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 32
                    MonValue { value: Math.round(page.d.cpu * 100); unit: "%"; size: 40 }
                    MonStat { Layout.fillWidth: false; label: "Frequency"; value: (page.d.freq[0] / 1000).toFixed(2) + " GHz" }
                    MonStat { Layout.fillWidth: false; label: "Peak"; value: (page.d.freq[1] / 1000).toFixed(2) + " GHz" }
                    MonStat { Layout.fillWidth: false; label: "Temperature"; value: Fmt.deg(page.d.temp); accent: Fmt.heat(page.d.temp) }
                    Item { Layout.fillWidth: true }
                }
                MonChart {
                    Layout.fillHeight: true
                    maxValue: 1
                    topLabel: "100%"
                    series: [{ values: page.d.cpuHistory, color: Theme.iris }]
                }
                Text { text: "Utilization per thread"; color: Theme.subtle; font.family: Theme.displayFont; font.pixelSize: 11 }
                MonThreads {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 110
                    showValues: true
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 24
                    rowSpacing: 14
                    MonStat { label: "Governor"; value: page.d.s.governor || "—" }
                    MonStat { label: "Threads"; value: page.d.cores.length }
                    MonStat { label: "Tasks"; value: page.d.s.procs ?? "—" }
                    MonStat { label: "Uptime"; value: Fmt.uptime(page.d.s.up) }
                    MonStat { label: "Load · 1 min"; value: page.d.load[0].toFixed(2) }
                    MonStat { label: "Load · 5 min"; value: page.d.load[1].toFixed(2) }
                    MonStat { label: "Load · 15 min"; value: page.d.load[2].toFixed(2) }
                    MonStat { label: "Fan"; value: page.d.num(page.d.s.fan) > 0 ? page.d.s.fan + " rpm" : "Idle" }
                }
            }

            // memory
            ColumnLayout {
                spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 32
                    MonValue { value: (page.d.memUsed / 1073741824).toFixed(1); unit: "GB"; size: 40 }
                    MonStat { Layout.fillWidth: false; label: "In use"; value: Math.round(page.d.memFraction * 100) + "%" }
                    MonStat { Layout.fillWidth: false; label: "Available"; value: Fmt.gb(page.d.memTotal - page.d.memUsed) }
                    Item { Layout.fillWidth: true }
                }
                MonChart {
                    Layout.fillHeight: true
                    maxValue: 1
                    topLabel: "100%"
                    series: [{ values: page.d.memHistory, color: Theme.foam }]
                }
                Text { text: "Composition"; color: Theme.subtle; font.family: Theme.displayFont; font.pixelSize: 11 }
                MonMemBar { implicitHeight: 12 }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20
                    MonKey { label: "In use"; value: Fmt.gb(page.d.memUsed); accent: Theme.foam }
                    MonKey { label: "Cache & buffers"; value: Fmt.gb(page.d.memCache); accent: Theme.alpha(Theme.foam, 0.35) }
                    MonKey { label: "Free"; value: Fmt.gb(Math.max(0, page.d.memTotal - page.d.memUsed - page.d.memCache)); accent: Theme.highlightMed }
                    Item { Layout.fillWidth: true }
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 24
                    rowSpacing: 14
                    MonStat { label: "Total"; value: Fmt.gb(page.d.memTotal) }
                    MonStat { label: "Swap used"; value: page.d.swapTotal > 0 ? Fmt.gb(page.d.swapUsed) : "—" }
                    MonStat { label: "Swap total"; value: page.d.swapTotal > 0 ? Fmt.gb(page.d.swapTotal) : "Disabled" }
                    MonStat { label: "Video memory"; value: Fmt.gb(page.d.vram[1] || 0) }
                }
            }

            // graphics
            ColumnLayout {
                spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 32
                    MonValue { value: Math.round(page.d.gpuBusy * 100); unit: "%"; size: 40 }
                    MonStat { Layout.fillWidth: false; label: "Power"; value: Fmt.watts(page.d.num(page.d.s.gpupower)) }
                    MonStat { Layout.fillWidth: false; label: "Temperature"; value: Fmt.deg(page.d.gpuTemp); accent: Fmt.heat(page.d.gpuTemp) }
                    Item { Layout.fillWidth: true }
                }
                MonChart {
                    Layout.fillHeight: true
                    maxValue: 1
                    topLabel: "100%"
                    series: [{ values: page.d.gpuHistory, color: Theme.love }]
                }
                MonMeter {
                    label: "Video memory"
                    value: Fmt.gb(page.d.vram[0] || 0) + " / " + Fmt.gb(page.d.vram[1] || 0)
                    fraction: page.d.vram[1] > 0 ? page.d.vram[0] / page.d.vram[1] : 0
                    accent: Theme.love
                }
            }

            // network
            ColumnLayout {
                spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 40
                    MonRate { label: "Download"; bps: page.d.netRx; accent: Theme.foam; size: 34 }
                    MonRate { label: "Upload"; bps: page.d.netTx; accent: Theme.iris; size: 34 }
                    Item { Layout.fillWidth: true }
                }
                MonChart {
                    id: netChart
                    Layout.fillHeight: true
                    mirrored: true
                    floorValue: 16384
                    topLabel: Fmt.rate(peak)
                    series: page.items[3].series
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 24
                    rowSpacing: 14
                    MonStat { label: "Interface"; value: page.d.s.netdev || "—" }
                    MonStat { label: "Received since boot"; value: Fmt.bytes(page.d.nio[0] || 0) }
                    MonStat { label: "Sent since boot"; value: Fmt.bytes(page.d.nio[1] || 0) }
                    MonStat { label: "Peak in window"; value: Fmt.rate(netChart.peak / 1.15) }
                }
            }

            // disk
            ColumnLayout {
                spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 40
                    MonRate { label: "Read"; bps: page.d.diskRead; accent: Theme.gold; size: 34 }
                    MonRate { label: "Write"; bps: page.d.diskWrite; accent: Theme.rose; size: 34 }
                    Item { Layout.fillWidth: true }
                }
                MonChart {
                    Layout.fillHeight: true
                    mirrored: true
                    floorValue: 65536
                    topLabel: Fmt.rate(peak)
                    series: page.items[4].series
                }
                MonMeter {
                    label: "Root filesystem"
                    value: Fmt.gb(page.d.disk[0]) + " / " + Fmt.gb(page.d.disk[1])
                    fraction: page.d.diskFraction
                    accent: page.d.diskFraction > 0.9 ? Theme.love : Theme.gold
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 24
                    rowSpacing: 14
                    MonStat { label: "Used"; value: Fmt.gb(page.d.disk[0]) }
                    MonStat { label: "Free"; value: Fmt.gb(page.d.disk[1] - page.d.disk[0]) }
                    MonStat { label: "Capacity"; value: Fmt.gb(page.d.disk[1]) }
                    MonStat { label: "NVMe temperature"; value: Fmt.deg(page.d.nvmeTemp); accent: Fmt.heat(page.d.nvmeTemp) }
                }
            }
        }
    }
}

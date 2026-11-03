import QtQuick
import QtQuick.Layouts

import "."

ColumnLayout {
    id: page

    signal showProcesses()

    readonly property var d: SystemData
    readonly property var topProcs: d.topBy("cpu", 4)

    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        MonPanel {
            title: "Processor"
            icon: "󰻠"
            accent: Theme.iris
            trailing: (page.d.s.governor || "") + "  ·  " + page.d.cores.length + " threads"
            Layout.preferredWidth: 200
            Layout.fillHeight: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 28
                MonValue { value: Math.round(page.d.cpu * 100); unit: "%"; size: 28 }
                MonStat { Layout.fillWidth: false; label: "Frequency"; value: (page.d.freq[0] / 1000).toFixed(2) + " GHz" }
                MonStat { Layout.fillWidth: false; label: "Temperature"; value: Fmt.deg(page.d.temp); accent: Fmt.heat(page.d.temp) }
                MonStat { Layout.fillWidth: false; label: "Load"; value: page.d.load[0].toFixed(2) }
                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                MonChart {
                    Layout.fillHeight: true
                implicitHeight: 56
                    maxValue: 1
                    topLabel: "100%"
                    series: [{ values: page.d.cpuHistory, color: Theme.iris }]
                }
                MonThreads {
                    Layout.preferredWidth: Math.max(200, page.d.cores.length * 20)
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                }
            }
        }

        MonPanel {
            title: "Memory"
            icon: "󰘚"
            accent: Theme.foam
            trailing: Fmt.gb(page.d.memTotal) + " installed"
            Layout.preferredWidth: 100
            Layout.fillHeight: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 28
                MonValue { value: (page.d.memUsed / 1073741824).toFixed(1); unit: "GB"; size: 28 }
                MonStat { Layout.fillWidth: false; label: "In use"; value: Math.round(page.d.memFraction * 100) + "%" }
                Item { Layout.fillWidth: true }
            }
            MonChart {
                Layout.fillHeight: true
                implicitHeight: 56
                maxValue: 1
                topLabel: "100%"
                series: [{ values: page.d.memHistory, color: Theme.foam }]
            }
            MonMemBar {}
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                MonKey { label: "Used"; value: Fmt.gb(page.d.memUsed); accent: Theme.foam }
                MonKey { label: "Cache"; value: Fmt.gb(page.d.memCache); accent: Theme.alpha(Theme.foam, 0.35) }
                Item { Layout.fillWidth: true }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        MonPanel {
            title: "Graphics"
            icon: "󰢮"
            accent: Theme.love
            trailing: Fmt.watts(page.d.num(page.d.s.gpupower))
            Layout.preferredWidth: 100
            Layout.fillHeight: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 24
                MonValue { value: Math.round(page.d.gpuBusy * 100); unit: "%"; size: 24 }
                Item { Layout.fillWidth: true }
                MonStat { Layout.fillWidth: false; label: "Temperature"; value: Fmt.deg(page.d.gpuTemp); accent: Fmt.heat(page.d.gpuTemp) }
            }
            MonChart {
                Layout.fillHeight: true
                implicitHeight: 56
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

        MonPanel {
            title: "Network"
            icon: "󰖩"
            accent: Theme.foam
            trailing: page.d.s.netdev || "offline"
            Layout.preferredWidth: 100
            Layout.fillHeight: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 28
                MonRate { label: "Download"; bps: page.d.netRx; accent: Theme.foam }
                MonRate { label: "Upload"; bps: page.d.netTx; accent: Theme.iris }
                Item { Layout.fillWidth: true }
            }
            MonChart {
                Layout.fillHeight: true
                implicitHeight: 56
                mirrored: true
                floorValue: 16384
                topLabel: Fmt.rate(peak)
                series: [
                    { values: page.d.netRxHistory, color: Theme.foam },
                    { values: page.d.netTxHistory, color: Theme.iris }
                ]
            }
            RowLayout {
                Layout.fillWidth: true
                MonKey { label: "Received"; value: Fmt.bytes(page.d.nio[0] || 0); accent: Theme.foam }
                Item { Layout.fillWidth: true }
                MonKey { label: "Sent"; value: Fmt.bytes(page.d.nio[1] || 0); accent: Theme.iris }
            }
        }

        MonPanel {
            title: "Disk"
            icon: "󰋊"
            accent: Theme.gold
            trailing: "nvme  ·  " + Fmt.deg(page.d.nvmeTemp)
            Layout.preferredWidth: 100
            Layout.fillHeight: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 28
                MonRate { label: "Read"; bps: page.d.diskRead; accent: Theme.gold }
                MonRate { label: "Write"; bps: page.d.diskWrite; accent: Theme.rose }
                Item { Layout.fillWidth: true }
            }
            MonChart {
                Layout.fillHeight: true
                implicitHeight: 56
                mirrored: true
                floorValue: 65536
                topLabel: Fmt.rate(peak)
                series: [
                    { values: page.d.diskReadHistory, color: Theme.gold },
                    { values: page.d.diskWriteHistory, color: Theme.rose }
                ]
            }
            MonMeter {
                label: "Root filesystem"
                value: Fmt.gb(page.d.disk[0]) + " / " + Fmt.gb(page.d.disk[1])
                fraction: page.d.diskFraction
                accent: page.d.diskFraction > 0.9 ? Theme.love : Theme.gold
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        MonPanel {
            title: "Top processes"
            icon: "󰐱"
            accent: Theme.iris
            trailing: "View all  →"
            trailingLink: true
            onTrailingClicked: page.showProcesses()
            Layout.preferredWidth: 200
            Layout.fillHeight: true

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: -8
                spacing: 0
                MonProcRow { header: true; compact: true }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.highlightLow }
                Repeater {
                    model: 4
                    MonProcRow {
                        required property int index
                        compact: true
                        p: page.topProcs[index] ?? null
                        cpuScale: Math.max(0.02, page.topProcs[0]?.cpu ?? 0)
                    }
                }
            }
        }

        MonPanel {
            title: "Battery"
            icon: page.d.charging ? "󰂄" : "󰁹"
            accent: page.d.batFraction < 0.2 ? Theme.love : Theme.foam
            trailing: page.d.s.batstatus || ""
            Layout.preferredWidth: 100
            Layout.fillHeight: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 24
                MonValue { value: Math.round(page.d.batFraction * 100); unit: "%"; size: 28 }
                Item { Layout.fillWidth: true }
                MonStat { Layout.fillWidth: false; label: page.d.charging ? "Charge rate" : "Draw"; value: Fmt.watts(page.d.num(page.d.s.batpower)) }
                MonStat { Layout.fillWidth: false; label: "Health"; value: page.d.batHealth > 0 ? Math.round(page.d.batHealth * 100) + "%" : "—" }
            }
            MonBar {
                thickness: 6
                value: page.d.batFraction
                fill: page.d.batFraction < 0.2 ? Theme.love : Theme.foam
            }
            Item { Layout.fillHeight: true }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                MonKV { label: "Power profile"; value: page.d.s.profile || "—" }
                MonKV { last: true; label: "Charge cycles"; value: page.d.s.batcycles || "—" }
            }
        }
    }
}

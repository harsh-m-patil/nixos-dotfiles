import QtQuick
import QtQuick.Layouts

import "."

BarPopup {
    id: root

    signal openDetails()

    readonly property var topProcs: SystemData.topBy("cpu", 3)

    padding: 12
    contentMinWidth: 450

    SystemSampler {
        active: root.visible
    }

    ColumnLayout {
        Layout.preferredWidth: 450
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Rectangle {
                implicitWidth: 38
                implicitHeight: 38
                radius: 12
                color: Theme.alpha(Theme.iris, 0.14)

                Text {
                    anchors.centerIn: parent
                    text: "󰍛"
                    color: Theme.iris
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                }
            }

            ColumnLayout {
                spacing: 1
                Text {
                    text: "System activity"
                    color: Theme.foreground
                    font.family: Theme.displayFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
                Text {
                    text: SystemData.info.host || SystemData.cpuModel || "Live overview"
                    color: Theme.subtle
                    font.family: Theme.displayFont
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.maximumWidth: 210
                }
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                spacing: 1
                Text {
                    text: "UPTIME"
                    color: Theme.muted
                    font.family: Theme.displayFont
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                    Layout.fillWidth: true
                }
                Text {
                    text: Fmt.uptime(SystemData.s.up)
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignRight
                    Layout.fillWidth: true
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: [SystemData.s.profile, SystemData.s.governor,
                "load " + ((SystemData.s.load ?? "").split(" ")[0] || "?")]
                .filter(x => x && x !== "load ?").join("  ·  ")
            visible: text !== ""
            color: Theme.muted
            font.family: Theme.displayFont
            font.pixelSize: 9
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Gauge {
                value: SystemData.cpu
                label: "CPU"
                sublabel: (SystemData.freq[0] / 1000).toFixed(2) + " GHz"
            }
            Gauge {
                value: SystemData.gpuBusy
                label: "GPU"
                sublabel: Fmt.deg(SystemData.gpuTemp)
                colorA: Theme.love
                colorB: Theme.rose
            }
            Gauge {
                value: SystemData.memFraction
                label: "Memory"
                sublabel: Fmt.gb(SystemData.memUsed)
                colorA: Theme.foam
                colorB: Theme.iris
            }
            Gauge {
                value: SystemData.temp / 100
                text: Fmt.deg(SystemData.temp)
                label: "Temp"
                sublabel: "fan " + (SystemData.num(SystemData.s.fan) > 0 ? SystemData.s.fan : "idle")
                colorA: Theme.gold
                colorB: Theme.love
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.highlightLow
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 7

            Text {
                text: "Throughput"
                color: Theme.foreground
                font.family: Theme.displayFont
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                StatBar {
                    Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1
                    icon: "󰋊"; label: "Read"; value: Fmt.rate(SystemData.diskRead); valueWidth: 78; accent: Theme.gold
                }
                StatBar {
                    Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1
                    icon: "󰋊"; label: "Write"; value: Fmt.rate(SystemData.diskWrite); valueWidth: 78; accent: Theme.rose
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                StatBar {
                    Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1
                    icon: "󰁅"; label: "Download"; value: Fmt.rate(SystemData.netRx); valueWidth: 78; accent: Theme.foam
                }
                StatBar {
                    Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1
                    icon: "󰁝"; label: "Upload"; value: Fmt.rate(SystemData.netTx); valueWidth: 78; accent: Theme.iris
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 7

            Text {
                text: "Storage and graphics memory"
                color: Theme.foreground
                font.family: Theme.displayFont
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            MonMeter {
                label: "Root disk"
                value: Fmt.gb(SystemData.disk[0]) + " / " + Fmt.gb(SystemData.disk[1])
                fraction: SystemData.diskFraction
                accent: SystemData.diskFraction > 0.9 ? Theme.love : Theme.gold
            }

            MonMeter {
                visible: SystemData.swapTotal > 0
                label: "Swap"
                value: Fmt.gb(SystemData.swapUsed) + " / " + Fmt.gb(SystemData.swapTotal)
                fraction: SystemData.swapTotal > 0 ? SystemData.swapUsed / SystemData.swapTotal : 0
                accent: Theme.iris
            }

            MonMeter {
                visible: SystemData.vram[1] > 0
                label: "VRAM"
                value: Fmt.gb(SystemData.vram[0]) + " / " + Fmt.gb(SystemData.vram[1])
                fraction: SystemData.vram[1] > 0 ? SystemData.vram[0] / SystemData.vram[1] : 0
                accent: Theme.love
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Top processes"
                    color: Theme.foreground
                    font.family: Theme.displayFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: (SystemData.s.procs || "0") + " running"
                    color: Theme.muted
                    font.family: Theme.displayFont
                    font.pixelSize: 9
                }
            }

            MonProcRow { header: true; compact: true }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.highlightLow }
            Repeater {
                model: 3
                MonProcRow {
                    required property int index
                    compact: true
                    p: root.topProcs[index] ?? null
                    cpuScale: Math.max(0.02, root.topProcs[0]?.cpu ?? 0)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 32
            radius: 10
            color: openArea.containsMouse ? Theme.highlightLow : Theme.surface
            border.width: 1
            border.color: Theme.highlightLow
            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 7
                Text { text: "󰄪"; color: Theme.iris; font.family: Theme.fontFamily; font.pixelSize: 12 }
                Text { text: "Open System Monitor"; color: Theme.foreground; font.family: Theme.displayFont; font.pixelSize: 10; font.weight: Font.DemiBold }
            }

            MouseArea {
                id: openArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openDetails()
            }
        }
    }
}

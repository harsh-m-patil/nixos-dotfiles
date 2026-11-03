import QtQuick
import QtQuick.Layouts

import "."

Item {
    id: page

    signal showProcesses()

    readonly property var d: SystemData
    readonly property var topProcs: d.topBy("cpu", 3)
    readonly property real gap: 12
    readonly property real cellW: (width - gap * 5) / 6
    readonly property real cellH: (height - gap * 2) / 3

    function heatColor(c) { return c > 85 ? Theme.love : c > 70 ? Theme.gold : Theme.foam }

    component Head: RowLayout {
        id: head
        property string icon
        property string label
        property string trailing
        property color accent: Theme.subtle
        Layout.fillWidth: true
        spacing: 7
        Text { text: head.icon; color: head.accent; font.family: Theme.iconFont; font.pixelSize: 13 }
        Text { text: head.label; color: Theme.subtle; font.family: Theme.displayFont; font.pixelSize: 12; font.weight: Font.Medium }
        Item { Layout.fillWidth: true }
        Text { text: head.trailing; color: Theme.foreground; font.family: Theme.displayFont; font.pixelSize: 12; font.weight: Font.DemiBold; font.features: { "tnum": 1 } }
    }

    component Big: Text {
        color: Theme.foreground
        font.family: Theme.displayFont
        font.pixelSize: 40
        font.weight: Font.DemiBold
        font.letterSpacing: -1.2
        font.features: { "tnum": 1 }
    }

    component Track: Rectangle {
        id: track
        property real value: 0
        property color accent: Theme.iris
        Layout.fillWidth: true
        implicitHeight: 8
        radius: height / 2
        color: Theme.alpha(Theme.foreground, 0.12)
        Rectangle {
            height: parent.height
            radius: parent.radius
            color: track.accent
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, track.value)))
            Behavior on width { NumberAnimation { duration: 480; easing.type: Easing.OutCubic } }
        }
    }

    CarTile {
        col: 0; row: 0; colSpan: 2; rowSpan: 2
        cellW: page.cellW; cellH: page.cellH; gap: page.gap

        CarGauge {
            anchors.fill: parent
            anchors.margins: 14
            style: "sweep"
            accent: Theme.gold
            value: page.d.cpu
            text: Math.round(page.d.cpu * 100)
            unit: "% cpu"
            caption: page.d.s.governor || ""
            scaleLabels: ["0", "20", "40", "60", "80", "100"]
            footer: "󰾆  " + (page.d.freq[0] / 1000).toFixed(2) + " GHz   ·   " + Fmt.deg(page.d.temp)
        }
    }

    CarTile {
        col: 2; row: 0
        cellW: page.cellW; cellH: page.cellH; gap: page.gap

        CarGauge {
            anchors.fill: parent
            anchors.margins: 10
            style: "ring"
            accent: Theme.foam
            value: page.d.memFraction
            text: (page.d.memUsed / 1073741824).toFixed(1)
            unit: "GB memory"
            footer: Fmt.pct(page.d.memFraction) + " of " + Fmt.gb(page.d.memTotal)
        }
    }

    CarTile {
        col: 3; row: 0
        cellW: page.cellW; cellH: page.cellH; gap: page.gap

        CarGauge {
            anchors.fill: parent
            anchors.margins: 10
            style: "needle"
            accent: Theme.love
            value: page.d.gpuBusy
            text: Math.round(page.d.gpuBusy * 100)
            unit: "% gpu"
            ticks: 30
            scaleLabels: ["0", "25", "50", "75", "100"]
            footer: Fmt.deg(page.d.gpuTemp)
        }
    }

    CarTile {
        col: 4; row: 0; colSpan: 2
        cellW: page.cellW; cellH: page.cellH; gap: page.gap

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10
            Head { icon: "󰖩"; label: "Network"; accent: Theme.foam; trailing: page.d.s.netdev || "offline" }
            CarTicks {
                Layout.fillWidth: true
                Layout.fillHeight: true
                values: page.d.netRxHistory
                floorValue: 16384
                accent: Theme.foam
            }
            CarTicks {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                values: page.d.netTxHistory
                floorValue: 16384
                accent: Theme.iris
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "↓ " + Fmt.rate(page.d.netRx); color: Theme.foam; font.family: Theme.displayFont; font.pixelSize: 12; font.weight: Font.Medium }
                Item { Layout.fillWidth: true }
                Text { text: "↑ " + Fmt.rate(page.d.netTx); color: Theme.iris; font.family: Theme.displayFont; font.pixelSize: 12; font.weight: Font.Medium }
            }
        }
    }

    CarTile {
        col: 2; row: 1
        cellW: page.cellW; cellH: page.cellH; gap: page.gap

        CarGauge {
            anchors.fill: parent
            anchors.margins: 22
            fullCircle: true
            ticks: 48
            majorEvery: 12
            accent: page.heatColor(page.d.temp)
            value: page.d.temp / 100
            text: page.d.temp > 0 ? Math.round(page.d.temp) + "°" : "—"
            unit: "CPU temp"
        }
    }

    CarTile {
        col: 3; row: 1
        cellW: page.cellW; cellH: page.cellH; gap: page.gap

        CarGauge {
            anchors.fill: parent
            anchors.margins: 22
            fullCircle: true
            ticks: 48
            majorEvery: 12
            accent: page.d.batFraction < 0.2 ? Theme.love : page.d.charging ? Theme.gold : Theme.foam
            value: page.d.batFraction
            text: Math.round(page.d.batFraction * 100) + "%"
            unit: page.d.charging ? "󰂄 charging" : Fmt.watts(page.d.num(page.d.s.batpower))
        }
    }

    CarTile {
        col: 4; row: 1; colSpan: 2
        cellW: page.cellW; cellH: page.cellH; gap: page.gap

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            Head { icon: "󰋊"; label: "Disk"; accent: Theme.gold; trailing: Fmt.gb(page.d.disk[0]) + " / " + Fmt.gb(page.d.disk[1]) }
            Item { Layout.fillHeight: true }
            CarPills {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                count: 12
                value: page.d.diskFraction
                accent: page.d.diskFraction > 0.9 ? Theme.love : Theme.foam
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Read  " + Fmt.rate(page.d.diskRead); color: Theme.subtle; font.family: Theme.displayFont; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                Text { text: "Write  " + Fmt.rate(page.d.diskWrite); color: Theme.subtle; font.family: Theme.displayFont; font.pixelSize: 12 }
            }
        }
    }

    CarTile {
        col: 0; row: 2; colSpan: 2
        cellW: page.cellW; cellH: page.cellH; gap: page.gap

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10
            Head { icon: "󰻠"; label: "Threads"; accent: Theme.iris; trailing: page.d.cores.length + " · " + Fmt.uptime(page.d.s.up) }
            CarTicks {
                Layout.fillWidth: true
                Layout.fillHeight: true
                count: Math.max(1, page.d.cores.length)
                values: page.d.cores
                maxValue: 1
                accent: Theme.iris
            }
            CarTicks {
                Layout.fillWidth: true
                Layout.preferredHeight: 14
                values: page.d.cpuHistory
                maxValue: 1
                count: 64
                accent: Theme.gold
            }
        }
    }

    CarTile {
        col: 2; row: 2; colSpan: 2
        cellW: page.cellW; cellH: page.cellH; gap: page.gap

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Big { text: page.d.load[0].toFixed(2) }
                Item { Layout.fillWidth: true }
                Text { Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 8; text: "load"; color: Theme.subtle; font.family: Theme.displayFont; font.pixelSize: 12 }
            }
            Track { value: page.d.load[0] / Math.max(1, page.d.cores.length); accent: Theme.iris }
            Item { Layout.fillHeight: true }
            Head { icon: "󰾴"; label: "Swap"; accent: Theme.rose; trailing: Fmt.gb(page.d.swapUsed) }
            Track { value: page.d.swapTotal > 0 ? page.d.swapUsed / page.d.swapTotal : 0; accent: Theme.rose }
        }
    }

    CarTile {
        col: 4; row: 2; colSpan: 2
        cellW: page.cellW; cellH: page.cellH; gap: page.gap
        pressable: true
        onClicked: page.showProcesses()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10
            Head { icon: "󰐱"; label: "Top processes"; accent: Theme.gold; trailing: "View all  →" }
            Item { Layout.fillHeight: true }
            Repeater {
                model: 3
                ColumnLayout {
                    id: proc
                    required property int index
                    readonly property var p: page.topProcs[index] ?? null
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Text { Layout.fillWidth: true; text: proc.p?.name ?? "—"; elide: Text.ElideRight; color: Theme.foreground; font.family: Theme.displayFont; font.pixelSize: 12 }
                        Text { text: ((proc.p?.cpu ?? 0) * 100).toFixed(1) + "%"; color: Theme.subtle; font.family: Theme.displayFont; font.pixelSize: 12; font.features: { "tnum": 1 } }
                    }
                    Track {
                        implicitHeight: 4
                        value: (proc.p?.cpu ?? 0) / Math.max(0.02, page.topProcs[0]?.cpu ?? 0)
                        accent: (proc.p?.cpu ?? 0) > 0.25 ? Theme.gold : Theme.iris
                    }
                }
            }
        }
    }
}

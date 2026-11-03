import QtQuick
import QtQuick.Layouts

import "."

Flickable {
    id: page

    readonly property var d: SystemData
    readonly property var i: d.info
    readonly property bool reveal: d.showPrivate
    readonly property string hidden: "••••••"
    readonly property var sensorNames: ({ k10temp: "CPU", coretemp: "CPU", amdgpu: "GPU", nvme: "NVMe", acpitz: "Chassis" })
    readonly property real hottest: d.sensors.reduce((m, s) => Math.max(m, (parseFloat(s[2]) || 0) / 1000), 0)
    readonly property real signal: Math.min(1, d.num(i.signal) / 70)
    readonly property bool wifi: i.wifi === "1"
    readonly property date bootedAt: new Date(Date.now() - d.num(d.s.up) * 1000)
    readonly property string product: {
        const v = i.vendor ?? "", p = i.product ?? ""
        return p.startsWith(v) ? p : (v + " " + p).trim()
    }
    readonly property color batAccent: d.batFraction < 0.2 && !d.charging ? Theme.love : Theme.foam
    readonly property string batEta: {
        if (d.s.batstatus === "Full")
            return "Fully charged"
        if (d.batHours <= 0 || d.batHours > 48)
            return d.charging ? "Charging" : (d.s.batstatus || "—")
        return Fmt.duration(d.batHours) + (d.charging ? " to full" : " left")
    }

    contentWidth: width
    contentHeight: body.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    onHeightChanged: returnToBounds()
    onContentHeightChanged: returnToBounds()

    component HeroStat: ColumnLayout {
        id: hs
        property string label
        property string value
        property string sub
        property color accent: Theme.foreground
        spacing: 2
        Text { text: hs.label; color: Theme.muted; font.family: Theme.displayFont; font.pixelSize: 10 }
        Text {
            text: hs.value
            color: hs.accent
            font.family: Theme.displayFont
            font.pixelSize: 17
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
        Text {
            Layout.maximumWidth: 160
            text: hs.sub
            color: Theme.subtle
            font.family: Theme.displayFont
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    component VRule: Rectangle {
        implicitWidth: 1
        implicitHeight: 40
        color: Theme.highlightLow
    }

    component Spacer: Item { Layout.fillHeight: true }

    component MonoToggle: Rectangle {
        id: toggle
        property bool checked: false
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: 28
        radius: height / 2
        color: toggleHover.hovered ? Theme.alpha(Theme.foreground, 0.06) : "transparent"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 2
            anchors.rightMargin: 8
            spacing: 8
            Text {
                text: "Radio"
                color: Theme.subtle
                font.family: Theme.displayFont
                font.pixelSize: 11
            }
            Item { Layout.fillWidth: true }
            Text {
                text: toggle.checked ? "On" : "Off"
                color: toggle.checked ? Theme.foam : Theme.muted
                font.family: Theme.displayFont
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
            Text {
                text: toggle.checked ? "󰖩" : "󰤭"
                color: toggle.checked ? Theme.foam : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }
        }
        HoverHandler { id: toggleHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: toggle.clicked() }
    }

    ColumnLayout {
        id: body
        width: page.width
        height: Math.max(implicitHeight, page.height)
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 76
            radius: F1Hub.tileRadius
            border.width: 0
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.tint(Theme.surface, Theme.alpha(Theme.foam, 0.08)) }
                GradientStop { position: 0.55; color: Theme.surface }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 22
                spacing: 18

                Rectangle {
                    implicitWidth: 52
                    implicitHeight: 52
                    radius: 14
                    color: Theme.alpha(Theme.foam, 0.16)
                    Text {
                        anchors.centerIn: parent
                        text: "󱄅"
                        color: Theme.foam
                        font.family: Theme.fontFamily
                        font.pixelSize: 28
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        Layout.fillWidth: true
                        text: page.product || (page.reveal ? page.i.host : "") || "This computer"
                        color: Theme.foreground
                        font.family: Theme.displayFont
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: [
                            page.reveal ? page.i.host : "",
                            page.i.os ? "NixOS " + page.i.os.split(".").slice(0, 2).join(".") : "",
                            page.i.kernel ? "Linux " + page.i.kernel : "",
                            page.i.arch
                        ].filter(Boolean).join("  ·  ")
                        color: Theme.muted
                        font.family: Theme.displayFont
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                HeroStat {
                    label: "Uptime"
                    value: Fmt.uptime(page.d.s.up)
                    sub: "since " + Qt.formatDateTime(page.bootedAt,
                        page.bootedAt.toDateString() === new Date().toDateString() ? "hh:mm" : "ddd hh:mm")
                }
                VRule {}
                HeroStat {
                    label: "Generation"
                    value: page.i.gen ? "#" + page.i.gen : "—"
                    sub: "built " + Fmt.ago(page.d.num(page.i.gentime))
                }
                VRule {}
                HeroStat {
                    label: "Services"
                    value: page.d.failedUnits.length > 0 ? page.d.failedUnits.length + " failed" : "Healthy"
                    accent: page.d.failedUnits.length > 0 ? Theme.love : Theme.foam
                    sub: page.d.failedUnits.length > 0 ? page.d.failedUnits.join(", ") : (page.i.running || 0) + " running"
                }
                VRule {}
                HeroStat {
                    label: "Tasks"
                    value: page.d.s.procs ?? "—"
                    sub: "load " + page.d.load[0].toFixed(2)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MonPanel {
                title: "Hardware"
                icon: "󰍹"
                accent: Theme.iris
                trailing: page.i.bios ? "BIOS " + page.i.bios + (page.i.biosdate ? "  ·  " + page.i.biosdate : "") : ""
                Layout.preferredWidth: 100
                Layout.fillHeight: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    MonKV { dense: true; label: "Processor"; value: page.d.cpuModel || "—" }
                    MonKV {
                        dense: true
                        label: "Topology"
                        value: (page.i.cpucores ? page.i.cpucores + " cores  ·  " : "") + page.d.cores.length + " threads"
                    }
                    MonKV {
                        dense: true
                        label: "Max clock"
                        value: page.d.num(page.i.cpumax) > 0 ? (page.d.num(page.i.cpumax) / 1e6).toFixed(2) + " GHz" : "—"
                    }
                    MonKV {
                        dense: true
                        label: "Cache"
                        value: [page.i.l2 ? "L2 " + page.i.l2 : "", page.i.l3 ? "L3 " + page.i.l3 : ""].filter(Boolean).join("  ·  ") || "—"
                    }
                    MonKV {
                        dense: true
                        label: "Memory"
                        value: Fmt.gb(page.d.memTotal) + (page.d.swapTotal > 0 ? "  ·  " + Fmt.gb(page.d.swapTotal) + " swap" : "")
                    }
                    MonKV { dense: true; label: "Graphics"; value: page.d.gpuModel || "—" }
                    MonKV {
                        dense: true
                        last: page.d.monitors.length === 0
                        label: "Video memory"
                        value: page.d.vram[1] > 0 ? Fmt.bytes(page.d.vram[1]) : "—"
                    }
                    Repeater {
                        model: page.d.monitors
                        MonKV {
                            required property var modelData
                            required property int index
                            dense: true
                            last: index === page.d.monitors.length - 1
                            label: page.d.monitors.length > 1 ? "Display  ·  " + modelData.name : "Display"
                            value: modelData.width + "×" + modelData.height + " @ " + Math.round(modelData.refreshRate)
                                + " Hz  ·  " + modelData.scale + "×"
                        }
                    }
                }
                Spacer {}
            }

            MonPanel {
                title: "Software"
                icon: "󱄅"
                accent: Theme.foam
                trailing: page.i.rev ? "nixpkgs " + page.i.rev.slice(0, 7) : ""
                Layout.preferredWidth: 100
                Layout.fillHeight: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    MonKV { dense: true; label: "NixOS"; value: page.i.os || "—" }
                    MonKV {
                        dense: true
                        label: "Generation"
                        value: page.i.gen
                            ? "#" + page.i.gen + "  ·  " + Fmt.ago(page.d.num(page.i.gentime)) + "  ·  " + page.i.gens + " kept"
                            : "—"
                    }
                    MonKV { dense: true; label: "Kernel"; value: page.i.kernel || "—" }
                    MonKV {
                        dense: true
                        label: "Compositor"
                        value: page.i.hypr ? "Hyprland " + page.i.hypr + (page.i.session ? "  ·  " + page.i.session : "") : "—"
                    }
                    MonKV { dense: true; label: "Desktop shell"; value: page.i.qs ? "Quickshell " + page.i.qs : "—" }
                    MonKV { dense: true; label: "Login shell"; value: page.i.shell || "—" }
                    MonKV {
                        dense: true
                        label: "Binaries"
                        value: page.i.pkgs ? page.i.pkgs + " system  ·  " + (page.i.userpkgs || 0) + " user" : "—"
                    }
                    MonKV {
                        dense: true
                        last: true
                        label: "Nix"
                        value: [page.i.nix, page.i.closure ? page.i.closure + " store paths" : ""].filter(Boolean).join("  ·  ") || "—"
                    }
                }
                Spacer {}
            }

            MonPanel {
                title: "Battery"
                icon: page.d.charging ? "󰂄" : "󰁹"
                accent: page.batAccent
                trailing: page.d.s.batstatus || ""
                Layout.preferredWidth: 100
                Layout.fillHeight: true

                RowLayout {
                    Layout.fillWidth: true
                    MonValue { value: Math.round(page.d.batFraction * 100); unit: "%"; size: 36 }
                    Item { Layout.fillWidth: true }
                    ColumnLayout {
                        spacing: 2
                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: page.batEta
                            color: Theme.foreground
                            font.family: Theme.displayFont
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.alignment: Qt.AlignRight
                            visible: page.d.num(page.d.s.batpower) > 0
                            text: Fmt.watts(page.d.num(page.d.s.batpower)) + (page.d.charging ? " in" : " draw")
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }
                MonBar {
                    thickness: 6
                    value: page.d.batFraction
                    fill: page.batAccent
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    MonKV {
                        dense: true
                        label: "Health"
                        value: page.d.batHealth > 0 ? (page.d.batHealth * 100).toFixed(1) + "%" : "—"
                        valueColor: page.d.batHealth > 0 && page.d.batHealth < 0.7 ? Theme.love
                            : page.d.batHealth > 0 && page.d.batHealth < 0.85 ? Theme.gold : Theme.foreground
                    }
                    MonKV {
                        dense: true
                        label: "Capacity"
                        value: page.d.batFull[1] > 0
                            ? (page.d.batFull[0] / 1e6).toFixed(1) + " / " + (page.d.batFull[1] / 1e6).toFixed(1) + " Wh"
                            : "—"
                    }
                    MonKV { dense: true; label: "Charge cycles"; value: page.d.s.batcycles || "—" }
                    MonKV {
                        dense: true
                        label: "Cell"
                        value: [[page.i.batvendor, page.i.batmodel].filter(Boolean).join(" "), page.i.battech]
                            .filter(Boolean).join("  ·  ") || "—"
                    }
                    MonKV { dense: true; last: true; label: "Power profile"; value: page.d.s.profile || "—" }
                }
                Spacer {}
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            MonPanel {
                title: "Storage"
                icon: "󰋊"
                accent: Theme.gold
                trailing: page.d.nvmeTemp > 0 ? Fmt.deg(page.d.nvmeTemp) : ""
                Layout.preferredWidth: 100
                Layout.fillHeight: true

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        text: page.i.diskmodel || "Disk"
                        color: Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: page.d.num(page.i.disksize) > 0
                        text: Math.round(page.d.num(page.i.disksize) / 1e9) + " GB"
                        color: Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }
                }
                Repeater {
                    model: page.d.mounts
                    MonMeter {
                        required property var modelData
                        readonly property real usedBytes: Number(modelData[2]) || 0
                        readonly property real sizeBytes: Number(modelData[3]) || 0
                        label: modelData[0] + "  ·  " + modelData[1]
                        value: Fmt.bytes(usedBytes) + " / " + Fmt.bytes(sizeBytes)
                        fraction: sizeBytes > 0 ? usedBytes / sizeBytes : 0
                        accent: fraction > 0.9 ? Theme.love : Theme.gold
                    }
                }
                MonKV {
                    dense: true
                    last: true
                    label: "Activity"
                    value: "R " + Fmt.rate(page.d.diskRead) + "  ·  W " + Fmt.rate(page.d.diskWrite)
                }
                Spacer {}
            }

            MonPanel {
                title: "Wi‑Fi"
                icon: "󰖩"
                accent: Theme.foam
                trailing: ConnectivityData.wifiTrailing
                Layout.preferredWidth: 100
                Layout.fillHeight: true

                MonoToggle {
                    checked: ConnectivityData.wifiEnabled
                    onClicked: ConnectivityData.setWifiEnabled(!ConnectivityData.wifiEnabled)
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentHeight: sysWifiList.implicitHeight

                    ColumnLayout {
                        id: sysWifiList
                        width: parent.width
                        spacing: 0

                        Repeater {
                            model: ConnectivityData.wifiEnabled ? ConnectivityData.wifiNetworks : []
                            MonPickRow {
                                required property var modelData
                                required property int index
                                title: modelData.name
                                detail: ConnectivityData.wifiDetail(modelData)
                                icon: ConnectivityData.wifiIcon(modelData.signalStrength, true)
                                active: modelData.connected
                                last: index === ConnectivityData.wifiNetworks.length - 1
                                onActivated: ConnectivityData.activateWifi(modelData)
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            visible: !ConnectivityData.wifiAvailable
                            text: "No Wi‑Fi adapter found"
                            color: Theme.muted
                            font.family: Theme.displayFont
                            font.pixelSize: 11
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            visible: ConnectivityData.wifiAvailable && !ConnectivityData.wifiEnabled
                            text: "Turn Wi‑Fi on to browse networks"
                            color: Theme.muted
                            font.family: Theme.displayFont
                            font.pixelSize: 11
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            visible: ConnectivityData.wifiEnabled && ConnectivityData.wifiNetworks.length === 0
                            text: "Scanning for networks…"
                            color: Theme.muted
                            font.family: Theme.displayFont
                            font.pixelSize: 11
                        }
                    }
                }
            }

            MonPanel {
                title: "Bluetooth"
                icon: ConnectivityData.btEnabled ? "󰂯" : "󰂲"
                accent: Theme.iris
                trailing: ConnectivityData.btTrailing
                Layout.preferredWidth: 100
                Layout.fillHeight: true

                MonoToggle {
                    checked: ConnectivityData.btEnabled
                    onClicked: ConnectivityData.setBtEnabled(!ConnectivityData.btEnabled)
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentHeight: sysBtList.implicitHeight

                    ColumnLayout {
                        id: sysBtList
                        width: parent.width
                        spacing: 0

                        Repeater {
                            model: ConnectivityData.btEnabled ? ConnectivityData.btDevices : []
                            MonPickRow {
                                required property var modelData
                                required property int index
                                title: ConnectivityData.btLabel(modelData)
                                detail: ConnectivityData.btDetail(modelData)
                                icon: modelData.icon || "󰂯"
                                active: modelData.connected
                                last: index === ConnectivityData.btDevices.length - 1
                                onActivated: ConnectivityData.activateBt(modelData)
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            visible: !ConnectivityData.btAvailable
                            text: "Bluetooth unavailable"
                            color: Theme.muted
                            font.family: Theme.displayFont
                            font.pixelSize: 11
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            visible: ConnectivityData.btAvailable && !ConnectivityData.btEnabled
                            text: "Turn Bluetooth on to find devices"
                            color: Theme.muted
                            font.family: Theme.displayFont
                            font.pixelSize: 11
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            visible: ConnectivityData.btEnabled && ConnectivityData.btDevices.length === 0
                            text: ConnectivityData.btAdapter?.discovering ? "Scanning for devices…" : "No devices nearby"
                            color: Theme.muted
                            font.family: Theme.displayFont
                            font.pixelSize: 11
                        }
                    }
                }
            }

            MonPanel {
                title: "Network"
                icon: !page.i.netdev ? "󰖪" : page.wifi ? "󰖩" : "󰈀"
                accent: Theme.foam
                trailing: [page.reveal ? page.i.conn : "", page.i.netdev].filter(Boolean).join("  ·  ") || "offline"
                Layout.preferredWidth: 100
                Layout.fillHeight: true

                MonMeter {
                    visible: page.wifi
                    label: "Signal"
                    value: Math.round(page.signal * 100) + "%"
                    fraction: page.signal
                    accent: page.signal < 0.35 ? Theme.love : page.signal < 0.6 ? Theme.gold : Theme.foam
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    MonKV {
                        dense: true
                        label: "Network name"
                        value: page.reveal ? page.i.conn || "—" : page.hidden
                        valueColor: page.reveal ? Theme.foreground : Theme.muted
                    }
                    MonKV {
                        dense: true
                        label: "Address"
                        value: page.reveal ? page.i.ipv4 || "—" : page.hidden
                        valueColor: page.reveal ? Theme.foreground : Theme.muted
                    }
                    MonKV {
                        dense: true
                        label: "Gateway"
                        value: page.reveal ? page.i.gateway || "—" : page.hidden
                        valueColor: page.reveal ? Theme.foreground : Theme.muted
                    }
                    MonKV {
                        dense: true
                        label: "MAC"
                        value: page.reveal ? page.i.mac || "—" : page.hidden
                        valueColor: page.reveal ? Theme.foreground : Theme.muted
                    }
                    MonKV {
                        dense: true
                        last: true
                        label: "Activity"
                        value: "↓ " + Fmt.rate(page.d.netRx) + "  ·  ↑ " + Fmt.rate(page.d.netTx)
                    }
                }
                Spacer {}
            }

            MonPanel {
                title: "Sensors"
                icon: "󰔏"
                accent: Theme.gold
                trailing: (page.d.num(page.d.s.fan) > 0 ? page.d.s.fan + " rpm" : "fan idle")
                    + (page.hottest > 0 ? "  ·  peak " + Fmt.deg(page.hottest) : "")
                Layout.preferredWidth: 100
                Layout.fillHeight: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Repeater {
                        model: page.d.sensors

                        Item {
                            id: probe
                            required property var modelData
                            required property int index
                            readonly property real c: (parseFloat(modelData[2]) || 0) / 1000
                            readonly property string chip: page.sensorNames[modelData[0]] ?? modelData[0]
                            Layout.fillWidth: true
                            implicitHeight: 28

                            RowLayout {
                                anchors.fill: parent
                                spacing: 12
                                Text {
                                    Layout.fillWidth: true
                                    text: /^temp\d+$/.test(probe.modelData[1]) ? probe.chip : probe.chip + "  ·  " + probe.modelData[1]
                                    color: Theme.subtle
                                    font.family: Theme.displayFont
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                                MonBar {
                                    Layout.fillWidth: false
                                    Layout.preferredWidth: 90
                                    value: probe.c / 100
                                    fill: probe.c > 85 ? Theme.love : probe.c > 70 ? Theme.gold : Theme.foam
                                }
                                Text {
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                    text: Fmt.deg(probe.c)
                                    color: Fmt.heat(probe.c)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                }
                            }
                            Rectangle {
                                visible: probe.index < page.d.sensors.length - 1
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: Theme.highlightLow
                            }
                        }
                    }
                }
                Spacer {}
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts

import "."

// Expanded island: headline figures, then Models / Days / Limits pages driven by the keyboard.
ColumnLayout {
    id: hub
    spacing: 10
    property bool showHints: false
    property int model: 0
    property int day: Math.max(0, AgentUsageData.days.length - 1)

    readonly property var d: AgentUsageData
    readonly property var selModel: d.models[Math.min(model, d.models.length - 1)] ?? null
    readonly property var selDay: d.days[Math.min(day, d.days.length - 1)] ?? null
    readonly property var hints: [
        [["1–3", "Pages"], ["j k", "Model"], ["r", "Refresh"], ["esc", "Close"]],
        [["1–3", "Pages"], ["h l", "Day"], ["r", "Refresh"], ["esc", "Close"]],
        [["1–3", "Pages"], ["r", "Refresh"], ["esc", "Close"]]
    ][d.page]

    function clamp(v, n) { return Math.max(0, Math.min(n - 1, v)) }

    function handleKey(e) {
        const k = e.key, n = d.pages.length
        const down = k === Qt.Key_J || k === Qt.Key_Down, up = k === Qt.Key_K || k === Qt.Key_Up
        const right = k === Qt.Key_L || k === Qt.Key_Right, left = k === Qt.Key_H || k === Qt.Key_Left
        if (k === Qt.Key_Escape || k === Qt.Key_Q) d.open = false
        else if (k >= Qt.Key_1 && k < Qt.Key_1 + n) d.page = k - Qt.Key_1
        else if (k === Qt.Key_Tab) d.page = (d.page + 1) % n
        else if (k === Qt.Key_Backtab) d.page = (d.page + n - 1) % n
        else if (k === Qt.Key_R) d.refresh()
        else if (k === Qt.Key_Question || (k === Qt.Key_Slash && (e.modifiers & Qt.ShiftModifier))) showHints = !showHints
        else if (d.page === 0 && (down || up)) model = clamp(model + (down ? 1 : -1), Math.min(6, d.models.length))
        else if (d.page === 1 && (right || left || down || up)) day = clamp(day + (right || down ? 1 : -1), d.days.length)
        else return false
        return true
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        AgentUsageRing {
            implicitWidth: 22; implicitHeight: 22; stroke: 3
            value: hub.d.tightest ? hub.d.tightest.used / 100 : 0
            accent: hub.d.accent
        }
        F1Text { text: "Agent usage"; role: "title2" }
        F1Text {
            Layout.fillWidth: true
            text: hub.d.loading ? "Refreshing…" : hub.d.readAt > 0 ? "Updated " + Fmt.ago(hub.d.readAt / 1000) : ""
            role: "footnote"
            tone: "tertiary"
        }
        F1Segmented {
            items: hub.d.pages
            keys: hub.d.pages.map((p, i) => String(i + 1))
            current: hub.d.page
            onPicked: i => hub.d.page = i
        }
        Rectangle {
            implicitWidth: 24; implicitHeight: 24; radius: 12
            color: hub.showHints ? F1Hub.fillStrong : F1Hub.fill
            F1Text { anchors.centerIn: parent; text: "?"; role: "footnote"; tone: "secondary" }
            TapHandler { onTapped: hub.showHints = !hub.showHints }
        }
    }

    F1Text {
        visible: hub.d.error !== ""
        Layout.fillWidth: true
        text: hub.d.error
        role: "footnote"
        color: Theme.gold
        wrapMode: Text.WordWrap
    }

    // Headline figures
    component Tag: Text {
        color: F1Hub.ink3
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.weight: Font.DemiBold
    }

    // Trip computer: odometers, the tightest limit as the main fuel gauge, service countdown
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 116
        radius: 22
        color: F1Hub.fill
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 16
            ColumnLayout {
                spacing: 6
                HudOdometer {
                    label: "Trip · today"
                    cell: 15
                    text: Fmt.usd(hub.d.today.cost)
                    sub: Fmt.tokens(hub.d.today.tokens) + " tokens"
                }
                HudOdometer {
                    label: "Odo · cycle"
                    cell: 12
                    accent: F1Hub.ink2
                    text: Fmt.usd(hub.d.cycle.cost)
                    sub: hub.d.cycle.sessions + " sessions · " + Fmt.tokens(hub.d.cycle.tokens)
                }
            }
            Item { Layout.fillWidth: true }
            HudFuel {
                Layout.preferredWidth: 210
                Layout.preferredHeight: 108
                label: hub.d.tightest ? hub.d.tightest.label : "No limits"
                value: hub.d.tightest ? hub.d.tightest.left / 100 : 1
                readout: hub.d.tightest ? hub.d.tightest.left + "% left" : "—"
                sub: hub.d.tightest ? hub.d.resetsIn(hub.d.tightest.resetsAt) : ""
            }
            Item { Layout.fillWidth: true }
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                Tag { Layout.alignment: Qt.AlignRight; text: "Service due" }
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: hub.d.cycleEnd > 0 ? Qt.formatDate(new Date(hub.d.cycleEnd), "MMM d") : "—"
                    color: F1Hub.ink
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: hub.d.cycleEnd > 0 ? hub.d.resetsIn(hub.d.cycleEnd).replace("resets ", "") : ""
                    color: F1Hub.ink2
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
                Item { implicitHeight: 8 }
                Tag { Layout.alignment: Qt.AlignRight; text: "Avg per day" }
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: Fmt.usd(hub.d.days.length ? hub.d.cycle.cost / hub.d.days.length : 0)
                    color: F1Hub.ink
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                }
            }
        }
    }

    // Pages
    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: hub.d.page

        // Models: ranked list + selected model detail
        RowLayout {
            spacing: 14
            F1Group {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Models by cost"
                detail: hub.d.models.length + " this cycle"
                pad: 4
                Repeater {
                    model: hub.d.models.slice(0, 6)
                    AgentUsageRow {
                        required property var modelData
                        required property int index
                        rank: String(index + 1)
                        title: modelData.name
                        subtitle: Fmt.tokens(modelData.tokens)
                        value: Fmt.usd(modelData.cost)
                        share: modelData.share
                        selected: index === hub.model
                        onClicked: hub.model = index
                    }
                }
                Item { Layout.fillHeight: true; visible: hub.d.models.length < 6 }
            }
            F1Group {
                Layout.preferredWidth: 240
                Layout.fillHeight: true
                title: "Selected"
                pad: 4
                F1Text {
                    Layout.fillWidth: true
                    Layout.margins: 11
                    Layout.bottomMargin: 0
                    text: hub.selModel ? hub.selModel.name : "No models yet"
                    role: "headline"
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 8
                    spacing: 12
                    HudGauge {
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 140
                        label: "of spend"
                        value: hub.selModel ? hub.selModel.share : 0
                        redline: 1.01
                        accent: Theme.iris
                        sub: hub.selModel ? Fmt.usd(hub.selModel.cost) : ""
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        columns: 1
                        rowSpacing: 10
                        Repeater {
                            model: hub.selModel ? [
                                ["Tokens", Fmt.tokens(hub.selModel.tokens)],
                                ["Requests", String(hub.selModel.events)],
                                ["Per request", Fmt.usd(hub.selModel.events ? hub.selModel.cost / hub.selModel.events : 0)],
                                ["Provider", hub.selModel.provider || "—"]
                            ] : []
                            ColumnLayout {
                                required property var modelData
                                spacing: 1
                                Tag { text: modelData[0] }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData[1]
                                    color: F1Hub.ink
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    font.features: { "tnum": 1 }
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }

        // Days: cycle spend chart + selected day
        ColumnLayout {
            spacing: 14
            F1Group {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Daily spend"
                detail: hub.selDay ? Fmt.dayShort(hub.selDay.day) : ""
                pad: 14
                AgentUsageChart {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    days: hub.d.days
                    current: hub.day
                    onPicked: i => hub.day = i
                }
            }
            F1Group {
                Layout.fillWidth: true
                Layout.fillHeight: false
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    F1Stat { label: hub.selDay ? Fmt.dayShort(hub.selDay.day) : "Day"; value: hub.selDay ? Fmt.usd(hub.selDay.cost) : "" }
                    F1Stat { label: "Tokens"; value: hub.selDay ? Fmt.tokens(hub.selDay.tokens) : "" }
                    F1Stat {
                        label: "Daily average"
                        value: Fmt.usd(hub.d.days.length ? hub.d.cycle.cost / hub.d.days.length : 0)
                        sub: hub.d.days.length + " days so far"
                    }
                }
            }
        }

        // Limits: every window plus included spend
        F1Group {
            title: "Subscription limits"
            pad: 10
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: hub.d.limits
                    HudFuel {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 118
                        label: modelData.label
                        value: modelData.left / 100
                        readout: modelData.left + "% left"
                        sub: modelData.resetsAt > 0 ? "resets " + Qt.formatDate(new Date(modelData.resetsAt), "MMM d") : ""
                    }
                }
                HudFuel {
                    visible: hub.d.spend !== null
                    Layout.fillWidth: true
                    Layout.preferredHeight: 118
                    label: "Included spend"
                    readonly property bool over: hub.d.spend && hub.d.spend.used > hub.d.spend.limit
                    exceeded: over
                    value: hub.d.spend && !over ? Math.max(0, 1 - hub.d.spend.used / hub.d.spend.limit) : 0
                    readout: !hub.d.spend ? ""
                        : over ? Fmt.usd(hub.d.spend.used - hub.d.spend.limit) + " over"
                        : Fmt.usd(hub.d.spend.used)
                    sub: hub.d.spend ? "of " + Fmt.usd(hub.d.spend.limit) + " included" : ""
                }
                F1Text {
                    visible: hub.d.limits.length === 0 && hub.d.spend === null
                    text: "No subscription limits reported."
                    role: "callout"
                    tone: "tertiary"
                }
            }
            Item { Layout.fillHeight: true }
        }
    }

    F1Keys { visible: hub.showHints; hints: hub.hints }
}

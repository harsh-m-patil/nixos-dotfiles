import QtQuick
import QtQuick.Layouts

import "."

// Expanded island: headline figures, then Models / Days / Limits pages driven by the keyboard.
ColumnLayout {
    id: hub
    spacing: 14
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
        else if (d.page === 0 && (down || up)) model = clamp(model + (down ? 1 : -1), d.models.length)
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
    F1Group {
        Layout.fillWidth: true
        Layout.fillHeight: false
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            F1Stat { label: "Today"; value: Fmt.usd(hub.d.today.cost); sub: Fmt.tokens(hub.d.today.tokens) + " tokens" }
            F1Stat { label: "This cycle"; value: Fmt.usd(hub.d.cycle.cost); sub: hub.d.cycle.sessions + " sessions · " + Fmt.tokens(hub.d.cycle.tokens) + " tokens" }
            F1Stat {
                label: "Tightest limit"
                value: hub.d.tightest ? hub.d.tightest.left + "% left" : "—"
                sub: hub.d.tightest ? hub.d.tightest.label : ""
                accent: hub.d.tightest && hub.d.tightest.left <= 35 ? hub.d.accent : F1Hub.ink
            }
            F1Stat {
                label: "Cycle ends"
                value: hub.d.cycleEnd > 0 ? Qt.formatDate(new Date(hub.d.cycleEnd), "MMM d") : "—"
                sub: hub.d.cycleEnd > 0 ? hub.d.resetsIn(hub.d.cycleEnd) : ""
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
                    model: hub.d.models
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
                F1Stat { label: "Cost"; value: hub.selModel ? Fmt.usd(hub.selModel.cost) : ""; sub: hub.selModel ? Fmt.pct(hub.selModel.share, 0) + " of cycle spend" : "" }
                F1Stat { label: "Tokens"; value: hub.selModel ? Fmt.tokens(hub.selModel.tokens) : "" }
                F1Stat { label: "Requests"; value: hub.selModel ? String(hub.selModel.events) : ""; sub: hub.selModel ? hub.selModel.provider : "" }
                Item { Layout.fillHeight: true }
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
            pad: 18
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 18
                Repeater {
                    model: hub.d.limits
                    AgentUsageMeter {
                        required property var modelData
                        label: modelData.label
                        detail: modelData.resetsAt > 0 ? "resets " + Qt.formatDate(new Date(modelData.resetsAt), "MMM d") : ""
                        value: Math.round(modelData.used) + "% used · " + modelData.left + "% left"
                        fraction: modelData.used / 100
                        accent: modelData.left <= 15 ? Theme.love : modelData.left <= 35 ? Theme.gold : Theme.iris
                    }
                }
                AgentUsageMeter {
                    visible: hub.d.spend !== null
                    label: "Included spend"
                    value: hub.d.spend ? Fmt.usd(hub.d.spend.used) + " of " + Fmt.usd(hub.d.spend.limit) : ""
                    fraction: hub.d.spend ? hub.d.spend.used / hub.d.spend.limit : 0
                    accent: hub.d.spend && hub.d.spend.used >= hub.d.spend.limit ? Theme.love : Theme.foam
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

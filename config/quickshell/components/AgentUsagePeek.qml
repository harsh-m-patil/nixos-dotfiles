import QtQuick
import QtQuick.Layouts

import "."

// Peek: today's spend and the subscription limits at a glance.
ColumnLayout {
    id: peek
    signal openRequested()
    spacing: 14

    readonly property var d: AgentUsageData

    RowLayout {
        Layout.fillWidth: true
        spacing: 14
        AgentUsageRing {
            implicitWidth: 40; implicitHeight: 40; stroke: 4
            value: peek.d.tightest ? peek.d.tightest.used / 100 : 0
            accent: peek.d.accent
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            F1Text { text: "Agent usage"; role: "headline" }
            F1Text {
                Layout.fillWidth: true
                text: peek.d.error !== "" ? peek.d.error
                    : !peek.d.ready ? "Scanning local agent history…"
                    : Fmt.tokens(peek.d.today.tokens) + " tokens today · " + peek.d.cycle.sessions + " sessions this cycle"
                role: "footnote"
                tone: peek.d.error !== "" ? "primary" : "secondary"
                color: peek.d.error !== "" ? Theme.gold : F1Hub.ink2
            }
        }
        ColumnLayout {
            spacing: 0
            F1Text { Layout.alignment: Qt.AlignRight; text: Fmt.usd(peek.d.today.cost); role: "title"; numeric: true }
            F1Text { Layout.alignment: Qt.AlignRight; text: "spent today"; role: "caption"; tone: "tertiary" }
        }
    }

    F1Group {
        Layout.fillWidth: true
        visible: peek.d.limits.length > 0 || peek.d.spend !== null
        title: "Limits"
        detail: peek.d.tightest ? peek.d.resetsIn(peek.d.tightest.resetsAt) : ""
        pad: 14

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            Repeater {
                model: peek.d.limits
                AgentUsageMeter {
                    required property var modelData
                    label: modelData.label
                    value: modelData.left + "% left"
                    fraction: modelData.used / 100
                    accent: modelData.left <= 15 ? Theme.love : modelData.left <= 35 ? Theme.gold : Theme.iris
                }
            }
            AgentUsageMeter {
                visible: peek.d.spend !== null
                label: "Included spend"
                value: peek.d.spend ? Fmt.usd(peek.d.spend.used) + " of " + Fmt.usd(peek.d.spend.limit) : ""
                fraction: peek.d.spend ? peek.d.spend.used / peek.d.spend.limit : 0
                accent: peek.d.spend && peek.d.spend.used >= peek.d.spend.limit ? Theme.love : Theme.foam
            }
        }
    }

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: openRow.implicitWidth + 28
        implicitHeight: 32
        radius: 16
        color: openHover.hovered ? F1Hub.fillStrong : F1Hub.fill
        border.width: 1
        border.color: F1Hub.hairline
        scale: openTap.pressed ? 0.96 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutQuint } }
        Row {
            id: openRow
            anchors.centerIn: parent
            F1Text { text: "Open Agent usage"; role: "footnote"; font.weight: Font.DemiBold }
        }
        HoverHandler { id: openHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: openTap; onTapped: peek.openRequested() }
    }
}

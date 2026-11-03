import QtQuick
import QtQuick.Layouts

import "."

// Peek — a trip computer: today's and the cycle's spend on odometers, limits as fuel gauges.
ColumnLayout {
    id: peek
    signal openRequested()
    spacing: 10

    readonly property var d: AgentUsageData
    readonly property var tanks: {
        const t = d.limits.slice(0, 3).map(l => ({ label: l.label.replace(/ models?$/i, ""), left: l.left / 100, sub: d.resetsIn(l.resetsAt).replace("resets in ", "") }))
        if (d.spend) t.push({ label: "Spend", left: Math.max(0, 1 - d.spend.used / d.spend.limit), readout: Fmt.usd(d.spend.used), sub: "of " + Fmt.usd(d.spend.limit) })
        return t
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 14
        HudOdometer {
            label: "Trip · today"
            text: peek.d.ready ? Fmt.usd(peek.d.today.cost) : "$-.--"
            sub: Fmt.tokens(peek.d.today.tokens) + " tokens"
        }
        Item { Layout.fillWidth: true }
        HudOdometer {
            label: "Odo · cycle"
            accent: F1Hub.ink2
            cell: 13
            text: peek.d.ready ? Fmt.usd(peek.d.cycle.cost) : "$-.--"
            sub: peek.d.cycle.sessions + " sessions"
        }
    }

    Text {
        visible: peek.d.error !== "" || !peek.d.ready
        Layout.fillWidth: true
        text: peek.d.error !== "" ? peek.d.error : "Scanning local agent history…"
        color: peek.d.error !== "" ? Theme.gold : F1Hub.ink3
        font.family: Theme.fontFamily
        font.pixelSize: 10
        elide: Text.ElideRight
    }

    Rectangle {
        Layout.fillWidth: true
        visible: peek.tanks.length > 0
        implicitHeight: 112
        Layout.preferredWidth: Math.max(340, peek.tanks.length * 92)
        radius: 22
        color: F1Hub.fill
        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 0
            Repeater {
                model: peek.tanks
                HudFuel {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    label: modelData.label
                    value: modelData.left
                    readout: modelData.readout ?? Math.round(modelData.left * 100) + "%"
                    sub: modelData.sub
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: peek.d.models.length > 0
        spacing: 6
        Text {
            text: "Lead"
            color: F1Hub.ink3
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
        Text {
            Layout.fillWidth: true
            text: peek.d.models[0]?.name ?? ""
            color: F1Hub.ink
            font.family: Theme.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
        }
        Text {
            text: peek.d.models[0] ? Fmt.pct(peek.d.models[0].share, 0) + " of spend" : ""
            color: F1Hub.ink2
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }
    }

    ClockButton {
        Layout.alignment: Qt.AlignHCenter
        text: "Open Agent usage"
        onClicked: peek.openRequested()
    }
}

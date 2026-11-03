import QtQuick
import QtQuick.Layouts

import "."

F1Page {
    id: page
    property int column: 0              // 0 drivers · 1 constructors
    property var cursors: [0, 0]
    readonly property var lists: [F1Data.driverStandings, F1Data.teamStandings]
    readonly property var picked: lists[column][cursors[column]] ?? null
    readonly property var ahead: cursors[column] > 0 ? lists[column][cursors[column] - 1] : null
    readonly property var leader: lists[column][0] ?? null
    readonly property color tint: F1Data.teamColour(picked?.team ?? "", F1Hub.accent)

    hints: [["j k", "Move"], ["h l", "Drivers / Teams"], ["g G", "Top / Bottom"]]

    function move(to) {
        const c = cursors.slice()
        c[column] = clamp(to, lists[column].length)
        cursors = c
    }
    function handleKey(e) {
        const v = vertical(e), h = horizontal(e)
        if (v) { move(cursors[column] + v); return true }
        if (h) { column = clamp(column + h, 2); return true }
        if (e.key === Qt.Key_G) { move(e.modifiers & Qt.ShiftModifier ? 99 : 0); return true }
        return false
    }

    component Standings: F1Tile {
        id: list
        property int which: 0
        property int limit: 12
        property int rowHeight: 30
        readonly property var entries: page.lists[which]
        readonly property real best: Math.max(1, entries[0]?.points ?? 1)
        pad: 8
        clip: true
        label: which === 0 ? "Drivers" : "Constructors"
        detail: entries.length ? entries.length + " classified" : ""
        opacity: page.column === which ? 1 : 0.55
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Repeater {
            model: list.entries.slice(0, list.limit)
            F1Row {
                required property var modelData
                required property int index
                implicitHeight: list.rowHeight
                Layout.fillHeight: false
                position: String(modelData.pos)
                title: modelData.name
                subtitle: list.which === 0 ? F1Data.teamName(modelData.team) : ""
                value: String(modelData.points)
                team: modelData.team
                bar: modelData.points / list.best
                separator: false
                selected: page.column === list.which && page.cursors[list.which] === index
                onClicked: { page.column = list.which; page.move(index) }
            }
        }
        Item { Layout.fillHeight: true }
    }

    F1Grid {
        anchors.fill: parent

        Standings { col: 0; row: 0; colSpan: 2; rowSpan: 3; which: 0; limit: 16; rowHeight: 32 }
        Standings { col: 2; row: 0; colSpan: 2; rowSpan: 2; which: 1; limit: 11; rowHeight: 30 }

        F1Tile {
            col: 2; row: 2
            pad: 8
            F1Arc {
                Layout.fillWidth: true
                Layout.fillHeight: true
                value: page.picked && page.leader ? page.picked.points / Math.max(1, page.leader.points) : 0
                thickness: 8
                accent: page.tint
                Column {
                    anchors.centerIn: parent
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.picked ? "P" + page.picked.pos : "—"
                        role: "numeral"; numeric: true
                    }
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.picked ? page.picked.points + " pts" : ""
                        role: "caption"; tone: "secondary"; numeric: true
                    }
                }
                F1Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                    text: page.picked?.name ?? ""
                    role: "caption"; tone: "tertiary"
                }
            }
        }

        F1Tile {
            col: 3; row: 2
            label: "To leader"
            F1Text {
                text: !page.picked ? "—" : page.picked.pos === 1 ? "Leads" : "−" + (page.leader.points - page.picked.points)
                role: "numeral"; numeric: true
            }
            F1Text {
                text: page.picked ? page.picked.wins + (page.picked.wins === 1 ? " win" : " wins") : ""
                role: "caption"; tone: "tertiary"
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.fillWidth: true
                F1Text { text: "Ahead"; role: "caption"; tone: "secondary"; Layout.fillWidth: true }
                F1Text { text: page.ahead ? "−" + (page.ahead.points - page.picked.points) : "—"; role: "headline"; numeric: true }
            }
            F1Pill {
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 8
                value: page.ahead ? page.picked.points / Math.max(1, page.ahead.points) : 1
                accent: page.tint
            }
        }
    }
}

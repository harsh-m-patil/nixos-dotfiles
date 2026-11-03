import QtQuick
import QtQuick.Layouts

import "."

F1Page {
    id: page
    property int choice: 0              // 0 latest session · 1 last grand prix
    property int cursor: 0
    // Between weekends the latest session is that Grand Prix's race: one source, no toggle.
    readonly property bool same: {
        const s = F1Data.session, r = F1Data.lastRace
        if (!s || !r) return !s
        const race = F1Data.races.find(x => x.round === r.round)
        const start = race?.sessions[race.sessions.length - 1]?.start
        return s.name === "Race" && !!start && Math.abs(s.ended - start) < F1Data.day
    }
    readonly property int source: same ? 1 : choice
    readonly property var rows: source === 0 ? (F1Data.session?.results ?? []) : (F1Data.lastRace?.results ?? [])
    readonly property var picked: rows[cursor] ?? null
    readonly property var standing: F1Data.driverStandings.find(d => d.code === picked?.code) ?? null
    readonly property int gained: picked && picked.grid > 0 ? picked.grid - picked.pos : 0

    hints: (same ? [] : [["s", "Session / Grand Prix"]]).concat([["j k", "Move"], ["g G", "Top / Bottom"]])
    onSourceChanged: cursor = 0

    function handleKey(e) {
        if (e.key === Qt.Key_S && !same) { choice = 1 - choice; return true }
        const v = vertical(e)
        if (v) { cursor = clamp(cursor + v, rows.length); return true }
        if (e.key === Qt.Key_G) { cursor = e.modifiers & Qt.ShiftModifier ? rows.length - 1 : 0; return true }
        return false
    }

    F1Grid {
        anchors.fill: parent

        F1Tile {
            id: list
            readonly property real rowHeight: Math.min(32, Math.floor((height - 16 - 38) / Math.max(1, page.rows.length)))
            col: 0; row: 0; colSpan: 2; rowSpan: 3
            pad: 8
            clip: true
            F1Segmented {
                visible: !page.same
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 4
                items: [(F1Data.weekend ? F1Data.weekend.short + " · " : "") + (F1Data.session?.name ?? "Latest session"),
                        F1Data.lastRace ? F1Data.lastRace.short + " Grand Prix" : "Last Grand Prix"]
                current: page.source
                onPicked: i => page.choice = i
            }
            RowLayout {
                visible: page.same
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.bottomMargin: 4
                F1Text { text: F1Data.lastRace ? F1Data.lastRace.short + " Grand Prix" : ""; role: "headline"; Layout.fillWidth: true }
                F1Text { text: F1Data.lastRace ? "Round " + F1Data.lastRace.round : ""; role: "caption"; tone: "tertiary"; numeric: true }
            }
            Repeater {
                model: page.rows
                F1Row {
                    required property var modelData
                    required property int index
                    Layout.fillHeight: false
                    Layout.preferredHeight: list.rowHeight
                    Layout.minimumHeight: list.rowHeight
                    Layout.maximumHeight: list.rowHeight
                    position: String(modelData.pos)
                    title: modelData.name
                    subtitle: page.source === 1 && modelData.fastest ? "Fastest lap" : ""
                    value: modelData.time
                    team: modelData.team
                    selected: index === page.cursor
                    separator: false
                    onClicked: page.cursor = index
                }
            }
            Item { Layout.fillHeight: true }
        }

        F1Tile {
            col: 2; row: 0; colSpan: 2; rowSpan: 2
            pad: 10
            label: page.source === 0 ? (F1Data.session?.name ?? "") : F1Data.lastRace ? "Round " + F1Data.lastRace.round + " · " + F1Data.lastRace.season : ""
            detail: page.source === 0 && F1Data.session ? Qt.formatDateTime(F1Data.session.ended, "ddd d MMM") : ""
            F1Podium { entries: page.rows.slice(0, 3); height1: 300; Layout.fillHeight: true }
        }

        F1Tile {
            col: 2; row: 2
            pad: 8
            F1Arc {
                Layout.fillWidth: true
                Layout.fillHeight: true
                value: page.picked ? (page.rows.length - page.picked.pos + 1) / Math.max(1, page.rows.length) : 0
                thickness: 8
                accent: F1Data.teamColour(page.picked?.team ?? "", F1Hub.accent)
                Column {
                    anchors.centerIn: parent
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.picked ? "P" + page.picked.pos : "—"
                        role: "numeral"; numeric: true
                    }
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.picked?.time ?? ""
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
            label: page.source === 1 ? "Started" : "Championship"
            F1Text {
                text: !page.picked ? "—"
                    : page.source === 1 ? (page.picked.grid === 0 ? "Pit" : "P" + page.picked.grid)
                    : page.standing ? "P" + page.standing.pos : "—"
                role: "numeral"; numeric: true
            }
            F1Text {
                text: page.source === 1
                    ? (page.picked && page.picked.grid > 0 ? (page.gained > 0 ? "+" : "") + page.gained + " places" : "from pit lane")
                    : page.standing ? page.standing.points + " pts" : ""
                role: "caption"
                color: page.source === 1 && page.gained > 0 ? Theme.foam : page.source === 1 && page.gained < 0 ? F1Hub.live : F1Hub.ink3
                numeric: true
            }
            Item { Layout.fillHeight: true }
            F1Ticks {
                Layout.fillWidth: true
                cells: true
                count: 10
                value: page.source === 1 ? (page.picked?.points ?? 0) / 25
                    : (page.standing?.points ?? 0) / Math.max(1, F1Data.driverStandings[0]?.points ?? 1)
                accent: F1Data.teamColour(page.picked?.team ?? "", F1Hub.accent)
            }
            F1Text {
                Layout.topMargin: 4
                text: page.source === 1 ? (page.picked ? "+" + page.picked.points + " pts" + (page.picked.fastest ? " · fastest lap" : "") : "")
                    : "share of leader"
                role: "caption"; tone: "tertiary"
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts

import "."

F1Page {
    id: page
    readonly property int cols: 8
    readonly property var races: F1Data.races
    readonly property int current: Math.max(0, races.indexOf(F1Data.weekend))
    property int cursor: current
    readonly property var picked: races[cursor] ?? null
    readonly property int done: Object.keys(F1Data.winners).length

    // Wins so far, most first: [{ key, team, wins }].
    function tally(by) {
        const m = {}
        for (const r in F1Data.winners) {
            const w = F1Data.winners[r], k = w[by]
            m[k] = m[k] ?? { key: k, team: w.team, wins: 0 }
            m[k].wins++
        }
        return Object.values(m).sort((a, b) => b.wins - a.wins)
    }
    readonly property var teamCodes: ({ mercedes: "MER", redbull: "RBR", mclaren: "MCL", ferrari: "FER", astonmartin: "AMR",
        alpine: "ALP", williams: "WIL", racingbulls: "RCB", haas: "HAA", audi: "AUD", cadillac: "CAD" })
    readonly property var driverWins: tally("code")
    readonly property var teamWins: tally("team")
    readonly property var upcoming: races.find(r => !F1Data.winners[r.round] && r !== F1Data.weekend && r.start > F1Data.now) ?? null

    hints: [["h j k l", "Move"], ["c", "Current round"]]
    onCurrentChanged: cursor = current

    function handleKey(e) {
        const v = vertical(e), h = horizontal(e)
        if (v) { cursor = clamp(cursor + v * cols, races.length); return true }
        if (h) { cursor = clamp(cursor + h, races.length); return true }
        if (e.key === Qt.Key_C) { cursor = current; return true }
        return false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: F1Hub.gap

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            columns: page.cols
            rowSpacing: F1Hub.gap
            columnSpacing: F1Hub.gap

            Repeater {
                model: page.races
                Rectangle {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property var winner: F1Data.winners[modelData.round] ?? null
                    readonly property bool done: winner !== null
                    readonly property bool isCurrent: index === page.current
                    readonly property bool selected: index === page.cursor
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 60
                    radius: 14
                    color: isCurrent ? F1Hub.fillStrong : F1Hub.fill
                    border.width: selected ? 1.5 : 0
                    border.color: Theme.alpha(F1Hub.accent, 0.85)
                    scale: cellTap.pressed ? 0.96 : 1
                    Behavior on scale { enabled: !Motion.reduced; SpringAnimation { spring: 6; damping: 0.6; epsilon: 0.002 } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Rectangle {
                                visible: flag.status === Image.Ready
                                implicitWidth: 21; implicitHeight: 14; radius: 3
                                color: "transparent"
                                clip: true
                                Image {
                                    id: flag
                                    anchors.fill: parent
                                    source: F1Data.flags[cell.modelData.round] ?? ""
                                    sourceSize.width: 42
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }
                            }
                            F1Text { text: "R" + cell.modelData.round; role: "caption"; tone: "tertiary"; numeric: true; Layout.fillWidth: true }
                            F1Text {
                                text: cell.done ? cell.winner.code : cell.isCurrent ? "Next" : Qt.formatDate(cell.modelData.start, "d MMM")
                                role: "caption"
                                color: cell.done ? F1Data.teamColour(cell.winner.team, F1Hub.ink2) : cell.isCurrent ? F1Hub.accent : F1Hub.ink3
                                font.weight: cell.done ? Font.Bold : Font.Medium
                                numeric: true
                            }
                        }
                        Item { Layout.fillHeight: true }
                        F1Text {
                            text: cell.modelData.short
                            role: "headline"
                            tone: cell.done && !cell.selected ? "secondary" : "primary"
                            Layout.fillWidth: true
                        }
                    }
                    TapHandler { id: cellTap; onTapped: page.cursor = cell.index }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: F1Hub.gap

            Repeater {
                model: [
                    { label: "Race wins", list: page.driverWins, name: k => k },
                    { label: "Wins by team", list: page.teamWins, name: k => page.teamCodes[k] ?? k.slice(0, 3).toUpperCase() }
                ]
                F1Tile {
                    id: winsTile
                    required property var modelData
                    readonly property real most: Math.max(1, modelData.list[0]?.wins ?? 1)
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    label: modelData.label
                    detail: modelData.list.length + (modelData.list.length === 1 ? " winner" : " winners")
                    Repeater {
                        model: winsTile.modelData.list.slice(0, 8)
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.maximumHeight: 30
                            spacing: 10
                            Image {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 14
                                source: F1Data.teamLogo(modelData.team)
                                sourceSize.height: 28
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }
                            F1Text { text: winsTile.modelData.name(modelData.key); role: "headline"; numeric: true; Layout.preferredWidth: 36 }
                            F1Pill {
                                Layout.fillWidth: true
                                implicitHeight: 8
                                value: modelData.wins / winsTile.most
                                accent: F1Data.teamColour(modelData.team, F1Hub.accent)
                            }
                            F1Text { text: String(modelData.wins); role: "headline"; numeric: true; Layout.preferredWidth: 18; horizontalAlignment: Text.AlignRight }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            F1Tile {
                id: progressTile
                readonly property int done: page.done
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                label: "Season " + F1Data.season
                detail: done + " / " + page.races.length
                F1Text { text: Math.round(progressTile.done / Math.max(1, page.races.length) * 100) + "%"; role: "display"; numeric: true }
                F1Text { text: "complete"; role: "caption"; tone: "tertiary" }
                Item { Layout.fillHeight: true }
                F1Text {
                    Layout.bottomMargin: 6
                    Layout.fillWidth: true
                    text: page.upcoming ? "Then " + page.upcoming.short + " · " + Qt.formatDate(page.upcoming.start, "d MMM") : ""
                    role: "caption"; tone: "secondary"
                }
                F1Ticks { Layout.fillWidth: true; cells: true; count: Math.max(1, page.races.length); value: progressTile.done / Math.max(1, page.races.length) }
                F1Text { Layout.topMargin: 6; text: (page.races.length - progressTile.done) + " rounds to go"; role: "caption"; tone: "tertiary" }
            }

        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 92
            spacing: F1Hub.gap

            F1Tile {
                id: roundTile
                readonly property var win: page.picked ? F1Data.winners[page.picked.round] ?? null : null
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 2
                label: page.picked ? "Round " + page.picked.round + " · " + page.picked.name : ""
                detail: page.picked?.circuit ?? ""
                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Repeater {
                        model: page.picked?.sessions ?? []
                        ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 0
                            F1Text { text: F1Data.sessionShort[modelData.label] ?? modelData.label; role: "caption"; tone: "secondary" }
                            F1Text { text: Qt.formatDateTime(modelData.start, "ddd HH:mm"); role: "headline"; numeric: true }
                        }
                    }
                    ColumnLayout {
                        visible: roundTile.win !== null
                        spacing: 0
                        F1Text { text: "Winner"; role: "caption"; tone: "secondary" }
                        F1Text {
                            readonly property var win: roundTile.win
                            text: win ? (F1Data.driverStandings.find(d => d.code === win.code)?.last ?? win.code) : ""
                            role: "headline"
                            color: F1Data.teamColour(win?.team ?? "", F1Hub.ink)
                        }
                    }
                }
            }
        }
    }
}

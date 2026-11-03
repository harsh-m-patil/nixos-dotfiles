import QtQuick
import QtQuick.Layouts

import "."

F1Page {
    id: page
    property int source: 0              // 0 latest session · 1 last grand prix
    property int cursor: 0
    readonly property var rows: source === 0 ? (F1Data.session?.results ?? []) : (F1Data.lastRace?.results ?? [])
    readonly property var picked: rows[cursor] ?? null
    readonly property int half: Math.ceil(rows.length / 2)

    hints: [["s", "Session / Grand Prix"], ["j k", "Move"], ["h l", "Column"]]
    onSourceChanged: cursor = 0

    function handleKey(e) {
        if (e.key === Qt.Key_S) { source = 1 - source; return true }
        const v = vertical(e), h = horizontal(e)
        if (v) { cursor = clamp(cursor + v, rows.length); return true }
        if (h) { cursor = clamp(h > 0 ? cursor + half : cursor - half, rows.length); return true }
        return false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            F1Segmented {
                items: [F1Data.session?.name ?? "Latest session", F1Data.lastRace ? F1Data.lastRace.short + " Grand Prix" : "Last Grand Prix"]
                current: page.source
                onPicked: i => page.source = i
            }
            Item { Layout.fillWidth: true }
            F1Text {
                text: page.source === 1 && F1Data.lastRace ? "Round " + F1Data.lastRace.round + " · " + F1Data.lastRace.season : ""
                role: "footnote"; tone: "tertiary"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            Repeater {
                model: 2
                F1Group {
                    id: col
                    required property int index
                    readonly property int offset: index * page.half
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    Repeater {
                        model: page.rows.slice(col.offset, col.offset + page.half)
                        F1Row {
                            required property var modelData
                            required property int index
                            position: String(modelData.pos)
                            title: modelData.name
                            subtitle: page.source === 1 && modelData.fastest ? "Fastest lap" : ""
                            value: modelData.time
                            team: modelData.team
                            selected: col.offset + index === page.cursor
                            separator: index < page.half - 1
                            onClicked: page.cursor = col.offset + index
                        }
                    }
                }
            }
        }

        F1Group {
            visible: page.picked !== null
            Layout.fillHeight: false
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                F1Stat { label: "Driver"; value: page.picked?.name ?? ""; sub: F1Data.teamName(page.picked?.team ?? ""); accent: F1Data.teamColour(page.picked?.team ?? "") }
                F1Stat { label: "Finished"; value: page.picked ? "P" + page.picked.pos : ""; sub: page.picked?.time ?? "" }
                F1Stat {
                    visible: page.source === 1
                    label: "Started"
                    value: page.picked ? (page.picked.grid === 0 ? "Pit lane" : "P" + page.picked.grid) : ""
                    sub: page.picked && page.picked.grid > 0 ? (page.picked.grid - page.picked.pos > 0 ? "+" : "") + (page.picked.grid - page.picked.pos) + " places" : ""
                }
                F1Stat { visible: page.source === 1; label: "Points"; value: page.picked ? String(page.picked.points) : ""; sub: page.picked?.fastest ? "Fastest lap " + page.picked.fastest : "" }
                F1Stat {
                    visible: page.source === 0
                    label: "Championship"
                    readonly property var st: F1Data.driverStandings.find(d => d.code === page.picked?.code) ?? null
                    value: st ? "P" + st.pos : "—"
                    sub: st ? st.points + " pts" : ""
                }
            }
        }
    }
}

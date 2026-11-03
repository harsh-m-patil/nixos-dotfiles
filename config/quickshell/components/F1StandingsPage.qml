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

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Repeater {
                model: 2
                F1Group {
                    id: col
                    required property int index
                    readonly property var list: page.lists[index]
                    readonly property real leader: Math.max(1, list[0]?.points ?? 1)
                    title: index === 0 ? "Drivers" : "Constructors"
                    Layout.fillWidth: true
                    Layout.preferredWidth: index === 0 ? 3 : 2
                    Layout.fillHeight: true
                    opacity: page.column === index ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    Repeater {
                        model: col.list.slice(0, 10)
                        F1Row {
                            required property var modelData
                            required property int index
                            implicitHeight: 30
                            position: String(modelData.pos)
                            title: modelData.name
                            subtitle: col.index === 0 ? F1Data.teamName(modelData.team) : ""
                            value: String(modelData.points)
                            team: modelData.team
                            bar: modelData.points / col.leader
                            selected: page.column === col.index && page.cursors[col.index] === index
                            onClicked: { page.column = col.index; page.move(index) }
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
                F1Stat { label: page.column === 0 ? "Driver" : "Team"; value: page.picked?.name ?? ""; accent: F1Data.teamColour(page.picked?.team ?? "") }
                F1Stat { label: "Points"; value: page.picked ? String(page.picked.points) : ""; sub: page.picked ? page.picked.wins + (page.picked.wins === 1 ? " win" : " wins") : "" }
                F1Stat {
                    label: "To leader"
                    value: page.picked ? (page.picked.pos === 1 ? "Leading" : "−" + (page.lists[page.column][0].points - page.picked.points)) : ""
                }
                F1Stat { label: "To position ahead"; value: page.ahead ? "−" + (page.ahead.points - page.picked.points) : "—"; sub: page.ahead?.name ?? "" }
            }
        }
    }
}

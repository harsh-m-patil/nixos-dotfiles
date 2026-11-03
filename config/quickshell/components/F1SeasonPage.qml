import QtQuick
import QtQuick.Layouts

import "."

F1Page {
    id: page
    readonly property int cols: 6
    readonly property var races: F1Data.races
    readonly property int current: Math.max(0, races.indexOf(F1Data.weekend))
    property int cursor: current
    readonly property var picked: races[cursor] ?? null

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
        spacing: 12

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: page.cols
            rowSpacing: 8
            columnSpacing: 8

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
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
                    implicitHeight: 76
                    radius: 12
                    color: selected ? Theme.alpha(Theme.iris, 0.16)
                        : isCurrent ? F1Hub.fillStrong : Theme.alpha(Theme.foreground, 0.035)
                    border.width: 1
                    border.color: selected ? Theme.alpha(Theme.iris, 0.5)
                        : isCurrent ? Theme.alpha(Theme.foreground, 0.25) : F1Hub.fill
                    Behavior on color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Rectangle {
                                visible: flag.status === Image.Ready
                                implicitWidth: 27; implicitHeight: 18; radius: 3
                                color: "transparent"
                                clip: true
                                Image {
                                    id: flag
                                    anchors.fill: parent
                                    source: F1Data.flags[cell.modelData.round] ?? ""
                                    sourceSize.width: 54
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }
                            }
                            F1Text { text: "R" + cell.modelData.round; role: "caption"; tone: "tertiary"; numeric: true }
                            Item { Layout.fillWidth: true }
                            F1Text { text: Qt.formatDate(cell.modelData.start, "d MMM"); role: "caption"; tone: "tertiary"; numeric: true }
                        }
                        F1Text {
                            text: cell.modelData.short
                            role: "title2"
                            tone: cell.done && !cell.selected ? "secondary" : "primary"
                            Layout.fillWidth: true
                        }
                        Item { Layout.fillHeight: true }
                        RowLayout {
                            spacing: 6
                            Image {
                                visible: cell.done
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 20
                                source: cell.done ? F1Data.teamLogo(cell.winner.team) : ""
                                sourceSize.height: 40
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }
                            F1Text {
                                text: cell.done ? cell.winner.code : cell.isCurrent ? "This weekend" : ""
                                role: "footnote"
                                tone: cell.done ? "secondary" : "primary"
                                numeric: cell.done
                            }
                        }
                    }
                    TapHandler { onTapped: page.cursor = cell.index }
                }
            }
        }

        F1Group {
            visible: page.picked !== null
            title: page.picked ? "Round " + page.picked.round + " · " + page.picked.name : ""
            detail: page.picked ? page.picked.circuit : ""
            Layout.fillHeight: false
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: page.picked?.sessions ?? []
                    F1Stat {
                        required property var modelData
                        label: modelData.label
                        value: Qt.formatDateTime(modelData.start, "ddd HH:mm")
                        sub: Qt.formatDate(modelData.start, "d MMM")
                    }
                }
                F1Stat {
                    readonly property var win: page.picked ? F1Data.winners[page.picked.round] ?? null : null
                    visible: win !== null
                    label: "Winner"
                    value: win ? (F1Data.driverStandings.find(d => d.code === win.code)?.last ?? win.code) : ""
                    accent: F1Data.teamColour(win?.team ?? "", F1Hub.ink)
                }
            }
        }
    }
}

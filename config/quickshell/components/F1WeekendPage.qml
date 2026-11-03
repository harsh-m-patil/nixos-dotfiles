import QtQuick
import QtQuick.Layouts

import "."

F1Page {
    index: 0
    
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        ColumnLayout {
            Layout.preferredWidth: 380
            Layout.maximumWidth: 380
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: 10

            F1Card {
                pad: 12
                RowLayout {
                    spacing: 12
                    Image {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 24
                        source: F1Data.meeting?.country_flag ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        F1Label { text: "ROUND " + (F1Data.nextRace?.round ?? "") + " · " + (F1Data.nextRace?.Circuit.Location.locality ?? "").toUpperCase() }
                        Text {
                            text: F1Data.nextRace?.raceName ?? "Season complete"
                            color: Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Black
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        F1Label {
                            Layout.alignment: Qt.AlignRight
                            text: F1Data.raceLive ? "" : (F1Data.nextSession?.label ?? "").toUpperCase() + " IN"
                        }
                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: F1Data.raceLive ? "● LIVE" : F1Data.nextSession ? F1Data.countdown(F1Data.nextSession.start) : ""
                            color: F1Data.raceLive ? Theme.love : Theme.gold
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Black
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 5
                    Repeater {
                        model: F1Data.sessions
                        F1Pill {
                            required property var modelData
                            readonly property bool done: modelData.start < F1Data.now
                            readonly property bool isNext: F1Data.nextSession === modelData
                            text: modelData.label + "  " + Qt.formatDateTime(modelData.start, "ddd hh:mm")
                            tint: isNext ? Theme.gold : done ? Theme.muted : Theme.foam
                            filled: isNext
                        }
                    }
                }
            }

            F1Podium {
                entries: F1Data.sessionResults.slice(0, 3).map(r => ({ code: r.code, value: r.time, team: r.team }))
                headshotScale: 1.35
            }

            F1Label {
                visible: F1Data.weather !== null
                text: "SESSION CONDITIONS"
            }
            GridLayout {
                readonly property var w: F1Data.weather
                visible: w !== null
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                F1StatTile {
                    stretch: false
                    label: "AIR"
                    value: parent.w ? parent.w.air_temperature.toFixed(1) + " °C" : ""
                    sub: parent.w ? "Humidity " + Math.round(parent.w.humidity) + "%" : ""
                }
                F1StatTile {
                    stretch: false
                    label: "TRACK"
                    value: parent.w ? parent.w.track_temperature.toFixed(1) + " °C" : ""
                    sub: parent.w ? Math.round(parent.w.pressure) + " hPa" : ""
                }
                F1StatTile {
                    stretch: false
                    label: "WIND"
                    value: parent.w ? (parent.w.wind_speed * 3.6).toFixed(0) + " km/h" : ""
                    sub: parent.w ? "From " + ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Math.round(parent.w.wind_direction / 45) % 8] : ""
                }
                F1StatTile {
                    stretch: false
                    label: "CONDITIONS"
                    value: parent.w ? (parent.w.rainfall ? "Wet" : "Dry") : ""
                    sub: "End of " + F1Data.sessionName
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            F1Label {
                visible: F1Data.sessionResults.length > 0
                text: "LATEST SESSION · " + F1Data.sessionName.toUpperCase()
                bottomPadding: 6
            }
            Repeater {
                model: F1Data.sessionResults.slice(3, 13)
                F1DriverRow {
                    required property var modelData
                    position: modelData.position
                    code: modelData.code
                    name: modelData.name.replace(/\b(\w)(\w*)$/, (m, a, b) => a + b.toLowerCase())
                    team: modelData.team
                    value: modelData.time
                }
            }
        }
    }
}

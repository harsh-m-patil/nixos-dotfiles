import QtQuick
import QtQuick.Layouts

import "."

F1Page {
    id: page
    readonly property var s: F1Data.session
    readonly property var w: s?.weather ?? null
    readonly property var me: F1Data.myStanding
    readonly property var ahead: me && me.pos > 1 ? F1Data.teamStandings[me.pos - 2] : null

    RowLayout {
        anchors.fill: parent
        spacing: 12

        ColumnLayout {
            Layout.preferredWidth: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            F1Group {
                title: page.s ? "Latest session · " + page.s.name : "Latest session"
                detail: page.s ? Qt.formatDateTime(page.s.ended, "ddd d MMM") : ""
                pad: 10
                Layout.fillHeight: true
                F1Podium { entries: page.s?.results.slice(0, 3) ?? []; height1: 150; Layout.fillHeight: true }
            }

            F1Group {
                visible: page.w !== null
                title: "Conditions"
                Layout.fillHeight: false
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    F1Stat { label: "Air"; value: page.w ? page.w.air_temperature.toFixed(1) + "°" : ""; sub: page.w ? Math.round(page.w.humidity) + "% humidity" : "" }
                    F1Stat { label: "Track"; value: page.w ? page.w.track_temperature.toFixed(1) + "°" : "" }
                    F1Stat {
                        label: "Wind"
                        value: page.w ? (page.w.wind_speed * 3.6).toFixed(0) + " km/h" : ""
                        sub: page.w ? "from " + ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Math.round(page.w.wind_direction / 45) % 8] : ""
                    }
                    F1Stat { label: "Surface"; value: page.w ? (page.w.rainfall ? "Wet" : "Dry") : ""; accent: page.w?.rainfall ? Theme.foam : F1Hub.ink }
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            F1Group {
                title: "Your team"
                detail: F1Data.myStanding ? "Constructors' championship" : ""
                Layout.fillHeight: false

                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 14
                    spacing: 14
                    Image {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 32
                        source: F1Data.teamLogo(F1Data.myTeam)
                        sourceSize.height: 64
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        F1Text { text: F1Data.teamName(F1Data.myTeam); role: "title2"; Layout.fillWidth: true }
                        F1Text {
                            text: page.me ? page.me.wins + (page.me.wins === 1 ? " win" : " wins") + " this season" : "Not classified yet"
                            role: "footnote"; tone: "secondary"
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        F1Text { Layout.alignment: Qt.AlignRight; text: page.me ? "P" + page.me.pos : "—"; role: "title"; numeric: true; color: F1Data.teamColour(F1Data.myTeam) }
                        F1Text { Layout.alignment: Qt.AlignRight; text: page.me ? page.me.points + " pts" : ""; role: "footnote"; tone: "secondary"; numeric: true }
                    }
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: F1Hub.fill }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    F1Stat {
                        label: "To leader"
                        value: page.me ? (page.me.pos === 1 ? "Leading" : "−" + (F1Data.teamStandings[0].points - page.me.points)) : ""
                        sub: page.me && page.me.pos > 1 ? F1Data.teamStandings[0].name : ""
                    }
                    F1Stat {
                        label: "To car ahead"
                        value: page.ahead ? "−" + (page.ahead.points - page.me.points) : "—"
                        sub: page.ahead?.name ?? ""
                    }
                    F1Stat {
                        label: "Last race"
                        value: {
                            const rs = (F1Data.lastRace?.results ?? []).filter(r => r.team === F1Data.myTeam)
                            return rs.length ? "+" + rs.reduce((a, r) => a + r.points, 0) + " pts" : ""
                        }
                        sub: F1Data.lastRace?.short ?? ""
                    }
                }
            }

            F1Group {
                title: "Drivers"
                Layout.fillHeight: true
                Repeater {
                    model: F1Data.myDrivers
                    F1Row {
                        required property var modelData
                        required property int index
                        readonly property var latest: page.s?.results.find(r => r.code === modelData.code) ?? null
                        position: "P" + modelData.pos
                        title: modelData.name
                        subtitle: latest ? page.s.short + " P" + latest.pos : ""
                        value: modelData.points + " pts"
                        team: modelData.team
                        separator: index < F1Data.myDrivers.length - 1
                    }
                }
            }

            F1Group {
                title: "Championship leaders"
                Layout.fillHeight: true
                Repeater {
                    model: F1Data.driverStandings.slice(0, 3)
                    F1Row {
                        required property var modelData
                        required property int index
                        position: String(modelData.pos)
                        title: modelData.name
                        subtitle: F1Data.teamName(modelData.team)
                        value: modelData.points + " pts"
                        team: modelData.team
                        separator: index < 2
                        onClicked: F1Hub.page = 2
                    }
                }
            }
        }
    }
}

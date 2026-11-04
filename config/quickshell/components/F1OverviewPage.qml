import QtQuick
import QtQuick.Layouts

import "."

// The dashboard: what's next, where the team stands, and the conditions at the track.
F1Page {
    id: page
    readonly property var topDriver: F1Data.driverStandings[0] ?? null
    readonly property var me: F1Data.myStanding
    readonly property var leader: F1Data.teamStandings[0] ?? null
    readonly property var ahead: me && me.pos > 1 ? F1Data.teamStandings[me.pos - 2] : null
    readonly property var s: F1Data.session
    readonly property var h: F1Data.history
    readonly property var w: s?.weather ?? null
    Component.onCompleted: F1Data.loadHistory()

    readonly property string mode: F1Data.mode
    readonly property var live: F1Data.liveSession
    readonly property var next: F1Data.nextSession
    // How far the dial has wound: through the live session, or toward the next one from the last.
    readonly property real wind: {
        const now = F1Data.now
        if (live) return (now - live.start) / (live.end - live.start)
        if (!next) return 1
        const i = F1Data.sessions.indexOf(next)
        const from = i > 0 ? F1Data.sessions[i - 1].end : new Date(next.start - 7 * F1Data.day)
        return (now - from) / (next.start - from)
    }

    F1Grid {
        anchors.fill: parent

        F1Tile {
            col: 0; row: 0
            pad: 6
            F1Arc {
                Layout.fillWidth: true
                Layout.fillHeight: true
                value: page.wind
                thickness: 9
                ticks: 30
                accent: page.live ? F1Hub.live : F1Hub.accent

                Column {
                    anchors.centerIn: parent
                    spacing: 0
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.live ? page.live.label + " · live" : page.next ? page.next.label + " starts in" : "Season complete"
                        role: "caption"
                        color: page.live ? F1Hub.live : F1Hub.ink2
                    }
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.live ? F1Data.elapsed(page.live.start)
                            : page.next ? F1Data.countdown(page.next.start) : "—"
                        role: "title"
                        numeric: true
                    }
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.live ? "of " + Math.round((page.live.end - page.live.start) / F1Data.minute) + " min"
                            : page.next ? Qt.formatDateTime(page.next.start, "ddd HH:mm") : ""
                        role: "caption"; tone: "tertiary"; numeric: true
                    }
                }
                F1Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    text: page.next ? (F1Data.sessionShort[page.next.label] ?? page.next.label) + " · " + Qt.formatDate(page.next.start, "d MMM") : ""
                    role: "footnote"; tone: "secondary"
                }
            }
        }

        F1Tile {
            readonly property var movers: (F1Data.lastRace?.results ?? []).filter(r => r.grid > 0)
                .map(r => Object.assign({ gain: r.grid - r.pos }, r)).sort((a, b) => b.gain - a.gain).slice(0, 4)
            id: moversTile
            col: 0; row: 1
            label: "Biggest movers"
            detail: F1Data.lastRace?.short ?? ""
            Repeater {
                model: moversTile.movers
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    Rectangle { implicitWidth: 4; implicitHeight: 16; radius: 2; color: F1Data.teamColour(modelData.team, F1Hub.ink) }
                    F1Text { text: modelData.code; role: "headline"; numeric: true; Layout.fillWidth: true }
                    F1Text { text: "P" + modelData.grid + " → P" + modelData.pos; role: "caption"; tone: "tertiary"; numeric: true }
                    F1Text {
                        text: (modelData.gain > 0 ? "+" : "") + modelData.gain
                        role: "footnote"; font.weight: Font.Bold; numeric: true
                        color: modelData.gain > 0 ? Theme.foam : F1Hub.ink3
                        Layout.preferredWidth: 22; horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }

        F1Tile {
            col: 1; row: 0
            interactive: true
            onClicked: F1Hub.page = 2
            label: F1Data.lastRace ? F1Data.lastRace.short + " GP" : "Last race"
            detail: F1Data.lastRace ? "R" + F1Data.lastRace.round : ""
            Repeater {
                model: (F1Data.lastRace?.results ?? []).slice(0, 3)
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    Rectangle {
                        implicitWidth: 4; implicitHeight: 18; radius: 2
                        color: F1Data.teamColour(modelData.team, F1Hub.ink)
                    }
                    F1Text { text: String(modelData.pos); role: "caption"; tone: "tertiary"; numeric: true }
                    F1Text { text: modelData.code; role: "headline"; numeric: true; Layout.fillWidth: true }
                    F1Text { text: modelData.pos === 1 ? "+" + modelData.points : modelData.time; role: "caption"; tone: "secondary"; numeric: true }
                }
            }
            F1Text {
                readonly property var fl: (F1Data.lastRace?.results ?? []).find(r => r.fastest) ?? null
                text: fl ? "Fastest lap " + fl.code + " · " + fl.fastest : ""
                role: "caption"; tone: "tertiary"
            }
        }

        F1Tile {
            col: 1; row: 1
            interactive: true
            onClicked: F1Hub.page = 3
            label: "Championship"
            detail: F1Data.driverStandings.length ? (F1Data.races.length - Object.keys(F1Data.winners).length) + " to go" : ""
            Repeater {
                model: F1Data.driverStandings.slice(0, 5)
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    F1Text { text: modelData.code; role: "footnote"; font.weight: Font.Bold; numeric: true; Layout.preferredWidth: 30 }
                    F1Pill {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        value: modelData.points / Math.max(1, page.topDriver?.points ?? 1)
                        accent: F1Data.teamColour(modelData.team, F1Hub.accent)
                    }
                    F1Text { text: String(modelData.points); role: "caption"; tone: "secondary"; numeric: true; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignRight }
                }
            }
        }

        F1Tile {
            col: 2; row: 0; colSpan: 2
            label: "This weekend"
            detail: F1Data.weekend ? Qt.formatDate(F1Data.weekend.start, "d MMM") : ""
            F1Timeline { Layout.fillWidth: true; Layout.topMargin: 8 }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                spacing: 0
                Repeater {
                    model: [
                        ["Last winner", page.h?.recent?.[0] ? (F1Data.driverStandings.find(d => d.name === page.h.recent[0].name)?.code ?? page.h.recent[0].name.split(" ").pop().slice(0, 3).toUpperCase()) : "—",
                            page.h?.recent?.[0] ? page.h.recent[0].season + " · from P" + page.h.recent[0].grid : ""],
                        ["Laps", page.h?.laps ? String(page.h.laps) : "—", F1Data.track?.corners ? F1Data.track.corners.length + " turns" : ""],
                        ["Pole wins", page.h?.races ? Math.round(page.h.fromPole / page.h.races * 100) + "%" : "—", page.h?.races ? page.h.races + " races" : ""],
                        ["Pit loss", F1Data.track?.pitLoss ? F1Data.track.pitLoss.toFixed(1) + "s" : "—", "per stop"]
                    ]
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 0
                        F1Text { text: modelData[0]; role: "caption"; tone: "secondary" }
                        F1Text { text: modelData[1]; role: "title2"; numeric: true }
                        F1Text { text: modelData[2]; role: "caption"; tone: "tertiary"; Layout.fillWidth: true }
                    }
                }
            }
            F1Pill { Layout.fillWidth: true; implicitHeight: 6; value: F1Data.progress; accent: page.live ? F1Hub.live : F1Hub.ink }
        }

        F1Tile {
            col: 2; row: 1
            interactive: true
            onClicked: F1Hub.page = 1
            F1Arc {
                Layout.fillWidth: true
                Layout.fillHeight: true
                value: page.me && page.leader ? page.me.points / Math.max(1, page.leader.points) : 0
                thickness: 9
                Column {
                    anchors.centerIn: parent
                    spacing: 0
                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 30; height: 20
                        source: F1Data.teamLogo(F1Data.myTeam)
                        sourceSize.height: 40
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.me ? "P" + page.me.pos : "—"
                        role: "numeral"; numeric: true
                    }
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.me ? page.me.points + " pts" : ""
                        role: "caption"; tone: "secondary"; numeric: true
                    }
                }
                F1Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: "Constructors"
                    role: "caption"; tone: "tertiary"
                }
            }
        }

        F1Tile {
            col: 3; row: 1
            label: "To leader"
            F1Text {
                text: !page.me ? "—" : page.me.pos === 1 ? "Leading" : "−" + (page.leader.points - page.me.points)
                role: "numeral"; numeric: true
            }
            F1Text { text: page.me && page.me.pos > 1 ? page.leader.name : ""; role: "caption"; tone: "tertiary" }
            Item { Layout.fillHeight: true }
            F1Pill { Layout.fillWidth: true; value: page.me && page.leader ? page.me.points / Math.max(1, page.leader.points) : 0 }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.fillWidth: true
                F1Text { text: "Car ahead"; role: "caption"; tone: "secondary"; Layout.fillWidth: true }
                F1Text { text: page.ahead ? "−" + (page.ahead.points - page.me.points) : "—"; role: "headline"; numeric: true }
            }
        }

        F1Tile {
            col: 0; row: 2; colSpan: 2
            interactive: true
            onClicked: F1Hub.page = 1
            label: F1Data.teamName(F1Data.myTeam)
            detail: "Drivers' championship"
            Repeater {
                model: F1Data.myDrivers.slice(0, 2)
                ColumnLayout {
                    required property var modelData
                    readonly property var latest: page.s?.results.find(r => r.code === modelData.code) ?? null
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 3
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        F1Text { text: "P" + modelData.pos; role: "headline"; numeric: true; Layout.preferredWidth: 34 }
                        F1Text { text: modelData.name; role: "body"; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        F1Text { text: latest ? page.s.short + " P" + latest.pos : ""; role: "caption"; tone: "tertiary" }
                        F1Text { text: modelData.points + " pts"; role: "callout"; tone: "secondary"; numeric: true }
                    }
                    F1Ticks {
                        Layout.fillWidth: true
                        implicitHeight: 12
                        count: 48
                        value: modelData.points / Math.max(1, page.topDriver?.points ?? 1)
                    }
                    F1Text {
                        text: modelData.wins + (modelData.wins === 1 ? " win" : " wins")
                            + (page.topDriver && modelData.pos > 1 ? "  ·  −" + (page.topDriver.points - modelData.points) + " to " + page.topDriver.code : "  ·  leading")
                        role: "caption"; tone: "tertiary"; numeric: true
                    }
                }
            }
        }

        F1Tile {
            col: 2; row: 2
            pad: 8
            F1Arc {
                Layout.fillWidth: true
                Layout.fillHeight: true
                value: page.w ? page.w.air_temperature / 45 : 0
                thickness: 7
                accent: Theme.gold
                Column {
                    anchors.centerIn: parent
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.w ? page.w.air_temperature.toFixed(1) + "°" : "—"
                        role: "title"; numeric: true
                    }
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.w ? "Track " + page.w.track_temperature.toFixed(0) + "°" : "Air"
                        role: "caption"; tone: "secondary"; numeric: true
                    }
                }
                F1Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: page.w ? Math.round(page.w.humidity) + "% humidity" : ""
                    role: "caption"; tone: "tertiary"
                }
            }
        }

        F1Tile {
            col: 3; row: 2
            pad: 8
            F1Compass {
                Layout.fillWidth: true
                Layout.fillHeight: true
                heading: page.w?.wind_direction ?? 0
                accent: page.w?.rainfall ? Theme.foam : F1Hub.accent
                Column {
                    anchors.centerIn: parent
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.w ? ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Math.round(page.w.wind_direction / 45) % 8] : "—"
                        role: "title2"
                    }
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.w ? (page.w.wind_speed * 3.6).toFixed(0) + " km/h" : ""
                        role: "caption"; tone: "secondary"; numeric: true
                    }
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.w ? (page.w.rainfall ? "Wet" : "Dry") : ""
                        role: "caption"
                        color: page.w?.rainfall ? Theme.foam : F1Hub.ink3
                    }
                }
            }
        }
    }
}

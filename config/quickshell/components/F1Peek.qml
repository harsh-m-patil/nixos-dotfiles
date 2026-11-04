import QtQuick
import QtQuick.Layouts

import "."

// F1 peek — a race-day cluster: a countdown dial and the team's championship dial around
// the Grand Prix, then the weekend as pill lamps, the podium when results land, and the open pill.
ColumnLayout {
    id: peek
    signal openRequested()
    spacing: 8

    implicitWidth: 340

    readonly property var w: F1Data.weekend
    readonly property string mode: F1Data.mode
    readonly property var live: F1Data.liveSession
    readonly property var next: F1Data.nextSession
    readonly property var me: F1Data.myStanding
    readonly property var leader: F1Data.teamStandings[0] ?? null
    readonly property var podium: peek.mode === "result" ? (F1Data.session?.results ?? []).slice(0, 3) : []

    // How far the dial has wound: through the live session, or toward the next one from the last.
    readonly property real wind: {
        const now = F1Data.now
        if (live) return (now - live.start) / (live.end - live.start)
        if (!next) return 1
        const i = F1Data.sessions.indexOf(next)
        const from = i > 0 ? F1Data.sessions[i - 1].end : new Date(next.start - 7 * F1Data.day)
        return (now - from) / (next.start - from)
    }
    readonly property int liveMinutes: live ? Math.round((live.end - live.start) / F1Data.minute) : 0

    function short(s) { return F1Data.sessionShort[s.label] ?? s.label }

    component Caption: Text {
        color: F1Hub.ink3
        font.family: Theme.displayFont
        font.pixelSize: 10
        font.features: { "tnum": 1 }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        HudGauge {
            Layout.preferredWidth: 112
            Layout.preferredHeight: 100
            value: peek.wind
            redline: 2
            accent: peek.live ? F1Hub.live : F1Hub.accent
            numerals: peek.live ? [0, 1, 2, 3, 4].map(i => Math.round(peek.liveMinutes * i / 4)) : []
            readout: peek.live ? F1Data.elapsed(peek.live.start)
                : peek.next ? F1Data.countdown(peek.next.start) : "—"
            label: peek.live ? peek.short(peek.live) + " live"
                : peek.next ? peek.short(peek.next) + " in" : "Season done"
            sub: peek.live ? "of " + peek.liveMinutes + "m"
                : peek.next ? Qt.formatDateTime(peek.next.start, "ddd HH:mm") : ""
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 116
            spacing: 3

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 5
                Rectangle {
                    visible: peek.mode === "live"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6; height: 6; radius: 3
                    color: F1Hub.live
                    SequentialAnimation on opacity {
                        running: peek.mode === "live" && !Motion.reduced
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
                    }
                }
                Text {
                    text: peek.mode === "live" ? "Live" : peek.w ? "Round " + peek.w.round : "Formula 1"
                    color: peek.mode === "live" ? F1Hub.live : F1Hub.ink3
                    font.family: Theme.displayFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 116
                text: (peek.w?.short ?? F1Data.lastRace?.short ?? "F1") + " GP"
                color: F1Hub.ink
                font.family: Theme.displayFont
                font.pixelSize: 16
                font.weight: Font.Bold
                font.letterSpacing: -0.3
                elide: Text.ElideRight
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 116
                text: peek.w ? peek.w.locality : ""
                visible: text !== ""
                color: F1Hub.ink2
                font.family: Theme.displayFont
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                visible: flag.status === Image.Ready
                implicitWidth: 27; implicitHeight: 18
                radius: 4
                color: "transparent"
                clip: true
                Image {
                    id: flag
                    anchors.fill: parent
                    source: F1Data.meeting?.flag ?? ""
                    sourceSize.width: 54
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
        }

        HudGauge {
            Layout.preferredWidth: 112
            Layout.preferredHeight: 100
            value: peek.me && peek.leader ? peek.me.points / Math.max(1, peek.leader.points) : 0
            redline: 2
            accent: F1Hub.accent
            numerals: []
            readout: peek.me ? "P" + peek.me.pos : "—"
            label: "Constructors"
            sub: peek.me ? peek.me.points + " pts" : ""
        }
    }

    // The weekend: one lamp per session — lit once run, filling while live, tinted when next.
    Rectangle {
        Layout.fillWidth: true
        visible: F1Data.sessions.length > 0
        implicitHeight: 58
        radius: F1Hub.tileRadius
        color: F1Hub.fill

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 6

            Repeater {
                model: F1Data.sessions
                ColumnLayout {
                    id: stop
                    required property var modelData
                    readonly property bool done: modelData.end <= F1Data.now
                    readonly property bool isLive: modelData.start <= F1Data.now && !done
                    readonly property bool isNext: !peek.live && +modelData.start === +(peek.next?.start ?? 0)
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 2

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 3
                        implicitHeight: 10
                        radius: 5
                        color: stop.done ? F1Hub.ink
                            : stop.isNext ? F1Hub.accent
                            : Theme.alpha(Theme.foreground, 0.1)
                        Behavior on color { ColorAnimation { duration: 260 } }
                        Rectangle {
                            visible: stop.isLive
                            height: parent.height
                            width: Math.max(height, parent.width * Math.min(1, peek.wind))
                            radius: parent.radius
                            color: F1Hub.live
                            Behavior on width { enabled: !Motion.reduced; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: peek.short(stop.modelData)
                        color: stop.isLive ? F1Hub.live : stop.done ? F1Hub.ink3 : F1Hub.ink
                        font.family: Theme.displayFont
                        font.pixelSize: 11
                        font.weight: stop.isLive || stop.isNext ? Font.Bold : Font.DemiBold
                    }
                    Caption {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(stop.modelData.start, "ddd HH:mm")
                    }
                }
            }
        }
    }

    // Results: the top three as a row of driver readouts, team colour as the lamp.
    Rectangle {
        Layout.fillWidth: true
        visible: peek.podium.length > 0
        implicitHeight: 62
        radius: F1Hub.tileRadius
        color: F1Hub.fill

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            Repeater {
                model: peek.podium
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 8
                    Rectangle {
                        implicitWidth: 4; implicitHeight: 30; radius: 2
                        color: F1Data.teamColour(modelData.team, F1Hub.ink)
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Caption { text: "P" + modelData.pos; font.weight: Font.DemiBold }
                        Text {
                            text: modelData.code
                            color: F1Hub.ink
                            font.family: Theme.displayFont
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            font.letterSpacing: -0.3
                        }
                        Caption {
                            Layout.fillWidth: true
                            text: modelData.time ?? ""
                            visible: text !== ""
                            font.pixelSize: 9
                            elide: Text.ElideLeft
                        }
                    }
                }
            }
        }
    }

    ClockButton {
        Layout.alignment: Qt.AlignHCenter
        text: "Open F1 Hub"
        hint: "Super⇧F"
        onClicked: peek.openRequested()
    }
}

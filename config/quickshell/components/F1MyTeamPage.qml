import QtQuick
import QtQuick.Layouts

import "."

// Team dashboard: championship fight, season numbers, points by round, teammate duel, all-time record.
F1Page {
    id: page
    readonly property var me: F1Data.myStanding
    readonly property var leader: F1Data.teamStandings[0] ?? null
    readonly property var ahead: me && me.pos > 1 ? F1Data.teamStandings[me.pos - 2] : null
    readonly property var behind: me && me.pos < F1Data.teamStandings.length ? F1Data.teamStandings[me.pos] : null
    readonly property color tint: F1Data.teamColour(F1Data.myTeam, F1Hub.accent)
    readonly property color tint2: Theme.alpha(tint, 0.45)

    readonly property var ts: F1Data.teamSeason && F1Data.teamSeason.id === me?.id ? F1Data.teamSeason : null
    readonly property var races: ts?.races ?? []
    readonly property var quali: ts?.quali ?? ({})
    readonly property var results: [].concat(...races.map(r => r.results.map(x => Object.assign({ round: r.round, short: r.short }, x))))
    readonly property var qualis: [].concat(...Object.values(quali))
    readonly property var codes: {
        const c = F1Data.myDrivers.slice(0, 2).map(d => d.code)
        for (const r of results)
            if (c.length < 2 && !c.includes(r.code)) c.push(r.code)
        return c
    }

    readonly property var th: F1Data.teamHistory && F1Data.teamHistory.id === me?.id ? F1Data.teamHistory : null
    readonly property var seasons: (th?.years ?? []).filter(y => th.seasons[y]).map(y => Object.assign({ year: y }, th.seasons[y]))
    readonly property var finished: seasons.filter(s => s.year < F1Data.season)
    readonly property var bestEver: bestSeason ?? seasons.find(s => s.year === F1Data.season) ?? null
    readonly property var bestSeason: finished.reduce((b, s) => !b || s.pos < b.pos || (s.pos === b.pos && s.points > b.points) ? s : b, null)

    property int hoverRound: -1

    Component.onCompleted: F1Data.loadTeam()
    onMeChanged: F1Data.loadTeam()
    Connections { target: F1Data; function onSessionChanged() { F1Data.loadTeam() } }

    function mean(a) { return a.length ? a.reduce((s, x) => s + x, 0) / a.length : NaN }
    function fixed(v) { return isNaN(v) ? "—" : v.toFixed(1) }
    function signed(n) { return n > 0 ? "+" + n : n < 0 ? "−" + -n : "0" }
    function bestOf(rs) { return rs.reduce((b, r) => !b || r.pos < b.pos ? r : b, null) }

    function driverStats(code) {
        const rs = results.filter(r => r.code === code)
        const done = rs.filter(r => !r.dnf)
        const best = bestOf(rs)
        return {
            best: best ? best.pos : 0,
            avgFinish: mean(done.map(r => r.pos)),
            avgQuali: mean(qualis.filter(q => q.code === code).map(q => q.pos)),
            scored: rs.filter(r => r.points > 0).length,
            points: F1Data.driverStandings.find(d => d.code === code)?.points ?? 0
        }
    }

    // Rounds where both drivers took part: who out-qualified / out-finished whom.
    readonly property var duel: {
        const [a, b] = codes
        const n = { qa: 0, qb: 0, ra: 0, rb: 0 }
        const tally = (list, ka, kb) => {
            const x = list.find(r => r.code === a), y = list.find(r => r.code === b)
            if (x && y) x.pos < y.pos ? n[ka]++ : n[kb]++
        }
        for (const k in quali) tally(quali[k], "qa", "qb")
        for (const r of races) tally(r.results, "ra", "rb")
        return n
    }

    readonly property var chart: F1Data.races.map(cal => {
        const r = races.find(x => x.round === cal.round)
        const rows = (r?.results ?? []).concat(ts?.sprint?.[cal.round] ?? [])
        const pts = code => rows.filter(x => code === undefined || x.code === code).reduce((s, x) => s + x.points, 0)
        const total = pts()
        const a = pts(codes[0]), b = pts(codes[1])
        const fin = code => (r?.results ?? []).find(x => x.code === code) ?? null
        return { round: cal.round, short: cal.short, done: !!r, total, a, b, other: total - a - b, fa: fin(codes[0]), fb: fin(codes[1]),
            sprint: !!ts?.sprint?.[cal.round], results: r?.results ?? [] }
    })
    readonly property var played: chart.filter(c => c.done)
    readonly property real chartMax: Math.max(10, ...played.map(c => c.total))
    readonly property int recent: played.slice(-5).reduce((s, c) => s + c.total, 0)
    // Without points there is nothing to stack, so the chart plots where each car finished instead.
    readonly property bool finishMode: played.length > 0 && played.every(c => c.total === 0)
    readonly property int field: Math.max(20, ...results.map(r => r.pos))
    function finishShare(r) { return r && !r.dnf ? (field + 1 - r.pos) / field : 0 }

    F1Grid {
        anchors.fill: parent
        rows: 4

        // ── Championship ────────────────────────────────────────

        F1Tile {
            col: 0; row: 0; colSpan: 2
            pad: 12
            label: "Constructors' championship"
            detail: F1Data.season
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14
                ColumnLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter
                    RowLayout {
                        spacing: 8
                        Image {
                            Layout.preferredWidth: 30; Layout.preferredHeight: 22
                            source: F1Data.teamLogo(F1Data.myTeam)
                            sourceSize.height: 44
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                        F1Text { text: page.me ? "P" + page.me.pos : "—"; role: "display"; numeric: true }
                    }
                    F1Text {
                        text: page.me ? page.me.points + " pts · " + page.me.wins + (page.me.wins === 1 ? " win" : " wins") : ""
                        role: "footnote"; tone: "secondary"; numeric: true
                    }
                }
                Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: F1Hub.hairline }
                Repeater {
                    model: page.me?.pos === 1
                        ? [1, 2, 3].map(i => F1Data.teamStandings[i]).map(t => ({ cap: t ? "P" + t.pos + " behind" : "", team: t ?? null }))
                        : [
                            { cap: "Leader", team: page.leader },
                            { cap: page.ahead ? "P" + page.ahead.pos + " ahead" : "Ahead", team: page.ahead },
                            page.behind || !page.me || page.me.pos < 3
                                ? { cap: page.behind ? "P" + page.behind.pos + " behind" : "Behind", team: page.behind }
                                : { cap: "P" + (page.me.pos - 2) + " ahead", team: F1Data.teamStandings[page.me.pos - 3] }
                        ]
                    ColumnLayout {
                        required property var modelData
                        readonly property int gap: modelData.team && page.me ? page.me.points - modelData.team.points : 0
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2
                        F1Text { text: modelData.cap; role: "caption"; tone: "tertiary" }
                        F1Text {
                            text: modelData.team ? page.signed(gap) : "—"
                            role: "title"; numeric: true
                            color: !modelData.team ? F1Hub.ink3 : gap >= 0 ? F1Hub.ink : F1Hub.ink2
                        }
                        F1Text {
                            text: modelData.team?.name ?? ""
                            role: "caption"; tone: "secondary"
                            Layout.fillWidth: true
                        }
                        F1Pill {
                            Layout.fillWidth: true
                            Layout.topMargin: 3
                            implicitHeight: 5
                            accent: page.tint
                            value: !modelData.team || !page.me ? 0
                                : Math.min(page.me.points, modelData.team.points) / Math.max(1, page.me.points, modelData.team.points)
                        }
                    }
                }
            }
        }

        // ── Season numbers ──────────────────────────────────────

        F1Tile {
            id: seasonTile
            col: 2; row: 2; colSpan: 2; rowSpan: 2
            pad: 12
            readonly property var best: page.bestOf(page.results)
            readonly property var classified: page.results.filter(r => !r.dnf)
            label: "Season so far"
            detail: page.races.length ? page.races.length + " rounds · " + page.codes.length * page.races.length + " starts" : ""
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                rowSpacing: 0
                columnSpacing: 16
                Repeater {
                    model: [
                        ["Podiums", String(page.results.filter(r => r.pos <= 3).length),
                            page.results.filter(r => r.pos === 1).length + " wins"],
                        ["Best finish", seasonTile.best ? "P" + seasonTile.best.pos : "—", (() => {
                            const n = seasonTile.best ? page.results.filter(r => r.pos === seasonTile.best.pos).length : 0
                            return n > 1 ? n + " times" : seasonTile.best?.short ?? ""
                        })()],
                        ["In the points", page.results.filter(r => r.points > 0).length + "/" + page.results.length,
                            page.results.length ? Math.round(page.results.filter(r => r.points > 0).length / page.results.length * 100) + "%" : ""],
                        ["Retirements", String(page.results.filter(r => r.dnf).length),
                            page.codes.map(c => c + " " + page.results.filter(r => r.dnf && r.code === c).length).join(" · ")],
                        ["Into Q3", page.qualis.filter(q => q.pos <= 10).length + "/" + page.qualis.length,
                            page.qualis.length ? "best P" + Math.min(...page.qualis.map(q => q.pos)) : ""],
                        ["Avg quali", page.fixed(page.mean(page.qualis.map(q => q.pos))), "grid slot"],
                        ["Avg finish", page.fixed(page.mean(seasonTile.classified.map(r => r.pos))), "classified"],
                        ["Places gained", page.signed(seasonTile.classified.filter(r => r.grid > 0).reduce((s, r) => s + r.grid - r.pos, 0)), "grid → flag"]
                    ]
                    ColumnLayout {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        spacing: 0
                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: F1Hub.hairline; visible: index > 1 }
                        Item { Layout.fillHeight: true }
                        F1Text { text: modelData[0]; role: "caption"; tone: "tertiary"; Layout.fillWidth: true }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            F1Text { text: modelData[1]; role: "title"; numeric: true }
                            F1Text {
                                text: modelData[2]
                                role: "caption"; tone: "secondary"
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignBottom
                                Layout.bottomMargin: 3
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }

        // ── Points by round ─────────────────────────────────────

        F1Tile {
            id: roundsTile
            col: 0; row: 1; colSpan: 4
            pad: 12
            readonly property var hovered: page.chart.find(c => c.round === page.hoverRound) ?? null
            label: page.finishMode ? "Finishes by round" : "Points by round"
            detail: {
                const c = hovered
                if (!c && page.finishMode) {
                    const best = page.bestOf(page.results)
                    return best ? "Still chasing a first point · closest P" + best.pos + " in " + best.short : ""
                }
                if (!c) return page.played.length
                    ? page.fixed(page.me?.points / page.played.length) + " per round · last 5: " + page.recent + (page.recent === 1 ? " pt" : " pts") : ""
                if (!c.done) return "R" + c.round + " " + c.short + " · upcoming"
                return "R" + c.round + " " + c.short + " · " + c.results.map(r => r.code + " " + (r.dnf ? "DNF" : "P" + r.pos)).join(" · ")
                    + " · " + c.total + " pts" + (c.sprint ? " incl. sprint" : "")
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 3
                Repeater {
                    model: page.chart
                    Item {
                        id: col
                        required property var modelData
                        readonly property bool lit: page.hoverRound === modelData.round
                        readonly property real unit: (bars.height) / page.chartMax
                        readonly property var bestFin: [modelData.fa, modelData.fb].filter(r => r && !r.dnf).sort((x, y) => x.pos - y.pos)[0] ?? null
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        HoverHandler { onHoveredChanged: page.hoverRound = hovered ? col.modelData.round : (page.hoverRound === col.modelData.round ? -1 : page.hoverRound) }

                        Rectangle {
                            anchors.fill: parent
                            anchors.bottomMargin: 18
                            radius: 6
                            color: col.lit ? F1Hub.hairline : "transparent"
                        }
                        F1Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: bars.bottom
                            anchors.bottomMargin: (page.finishMode ? page.finishShare(col.bestFin) * bars.height : col.modelData.total * col.unit) + 1
                            visible: page.finishMode ? col.bestFin !== null : col.modelData.total > 0
                            text: page.finishMode ? (col.bestFin ? "P" + col.bestFin.pos : "") : String(col.modelData.total)
                            role: "caption"; tone: col.lit ? "primary" : "secondary"; numeric: true
                        }
                        Item {
                            id: bars
                            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: flag.top }
                            anchors.topMargin: 14
                            anchors.bottomMargin: 4
                            Row {
                                visible: page.finishMode && col.modelData.done
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 2
                                Repeater {
                                    model: [[col.modelData.fa, page.tint], [col.modelData.fb, page.tint2]]
                                    Rectangle {
                                        required property var modelData
                                        anchors.bottom: parent.bottom
                                        width: Math.min(8, (bars.width - 8) / 2)
                                        height: Math.max(3, page.finishShare(modelData[0]) * bars.height)
                                        radius: 2
                                        color: modelData[0] && !modelData[0].dnf ? modelData[1] : F1Hub.ink3
                                    }
                                }
                            }
                            Column {
                                visible: !page.finishMode
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(18, parent.width - 6)
                                spacing: 0
                                Repeater {
                                    model: [[col.modelData.other, F1Hub.ink3], [col.modelData.b, page.tint2], [col.modelData.a, page.tint]]
                                    Rectangle {
                                        required property var modelData
                                        width: parent.width
                                        height: modelData[0] * col.unit
                                        visible: modelData[0] > 0
                                        radius: 2
                                        color: modelData[1]
                                    }
                                }
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(18, parent.width - 6)
                                height: 3; radius: 1.5
                                visible: col.modelData.total === 0 && !(page.finishMode && col.modelData.done)
                                color: col.modelData.done ? F1Hub.ink3 : col.modelData === page.chart.find(c => !c.done) ? page.tint : F1Hub.track
                            }
                        }
                        Item {
                            id: flag
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 18; height: 12
                            Rectangle {
                                anchors.fill: parent
                                radius: 2
                                color: "transparent"
                                clip: true
                                opacity: col.modelData.done || col.lit ? 1 : 0.4
                                Image {
                                    id: flagImg
                                    anchors.fill: parent
                                    source: F1Data.flags[col.modelData.round] ?? ""
                                    sourceSize.width: 36
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }
                            }
                            F1Text {
                                anchors.centerIn: parent
                                visible: flagImg.status !== Image.Ready
                                text: String(col.modelData.round)
                                role: "caption"; tone: "tertiary"; numeric: true
                            }
                        }
                    }
                }
            }
        }

        // ── Teammate duel ───────────────────────────────────────

        F1Tile {
            id: duelTile
            col: 0; row: 2; colSpan: 2; rowSpan: 2
            pad: 12
            readonly property var a: page.driverStats(page.codes[0] ?? "")
            readonly property var b: page.driverStats(page.codes[1] ?? "")
            label: "Teammate duel"
            detail: "head to head"

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: [0, 1]
                    RowLayout {
                        id: side
                        required property int modelData
                        readonly property string code: page.codes[modelData] ?? ""
                        readonly property var st: F1Data.driverStandings.find(d => d.code === code) ?? null
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        layoutDirection: modelData === 0 ? Qt.LeftToRight : Qt.RightToLeft
                        spacing: 10
                        F1DriverAvatar { code: side.code; size: 50 }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Rectangle {
                                Layout.alignment: side.modelData === 0 ? Qt.AlignLeft : Qt.AlignRight
                                implicitWidth: 18; implicitHeight: 4; radius: 2
                                color: side.modelData === 0 ? page.tint : page.tint2
                            }
                            F1Text {
                                text: side.st?.last ?? side.code
                                role: "headline"
                                Layout.fillWidth: true
                                horizontalAlignment: side.modelData === 0 ? Text.AlignLeft : Text.AlignRight
                            }
                            F1Text {
                                text: side.st ? "P" + side.st.pos + " · " + side.st.points + " pts" : ""
                                role: "caption"; tone: "secondary"; numeric: true
                                Layout.fillWidth: true
                                horizontalAlignment: side.modelData === 0 ? Text.AlignLeft : Text.AlignRight
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }

            Repeater {
                // [label, a, b, lower is better, text a, text b]
                model: {
                    const a = duelTile.a, b = duelTile.b, d = page.duel
                    const pos = v => v ? "P" + v : "—"
                    return [
                        ["Qualifying", d.qa, d.qb, false],
                        ["Races", d.ra, d.rb, false],
                        ["Points", a.points, b.points, false],
                        ["Points finishes", a.scored, b.scored, false],
                        ["Best finish", a.best, b.best, true, pos(a.best), pos(b.best)],
                        ["Avg quali", a.avgQuali, b.avgQuali, true, page.fixed(a.avgQuali), page.fixed(b.avgQuali)],
                        ["Avg finish", a.avgFinish, b.avgFinish, true, page.fixed(a.avgFinish), page.fixed(b.avgFinish)]
                    ]
                }
                ColumnLayout {
                    id: stat
                    required property var modelData
                    readonly property real va: isNaN(modelData[1]) || !modelData[1] ? 0 : modelData[1]
                    readonly property real vb: isNaN(modelData[2]) || !modelData[2] ? 0 : modelData[2]
                    // 0 means "no data" for lower-is-better rows, so the other driver leads.
                    readonly property int lead: va === vb ? -1
                        : !modelData[3] ? (va > vb ? 0 : 1)
                        : !va ? 1 : !vb ? 0 : va < vb ? 0 : 1
                    readonly property real sa: va === vb ? 0.5
                        : !modelData[3] ? va / (va + vb)
                        : !va || !vb ? (lead === 0 ? 1 : 0) : vb / (va + vb)
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 3
                    RowLayout {
                        Layout.fillWidth: true
                        F1Text {
                            text: stat.modelData[4] ?? String(stat.modelData[1])
                            role: "headline"; numeric: true
                            tone: stat.lead === 1 ? "tertiary" : "primary"
                            Layout.preferredWidth: 50
                        }
                        F1Text {
                            text: stat.modelData[0]
                            role: "caption"; tone: "secondary"
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        F1Text {
                            text: stat.modelData[5] ?? String(stat.modelData[2])
                            role: "headline"; numeric: true
                            tone: stat.lead === 0 ? "tertiary" : "primary"
                            Layout.preferredWidth: 50
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 5
                        Rectangle {
                            width: Math.max(0, parent.width * stat.sa - 1.5)
                            height: parent.height; radius: 2.5
                            color: page.tint
                        }
                        Rectangle {
                            anchors.right: parent.right
                            width: Math.max(0, parent.width * (1 - stat.sa) - 1.5)
                            height: parent.height; radius: 2.5
                            color: page.tint2
                        }
                    }
                }
            }
        }

        // ── All-time record ─────────────────────────────────────

        F1Tile {
            id: historyTile
            col: 2; row: 0; colSpan: 2
            pad: 12
            readonly property var win: page.th?.firstWin
            readonly property var last: (page.th?.wins ?? 0) > 1 ? page.th.lastWin : null
            label: "All-time · " + F1Data.teamName(F1Data.myTeam)
            detail: page.th?.debut ? "since " + page.th.debut.season + " " + page.th.debut.short + " · " + page.th.races + " GPs" : ""

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: [
                        ["Titles", String(page.finished.filter(s => s.pos === 1).length), Theme.gold],
                        ["Wins", page.th?.wins !== undefined ? String(page.th.wins) : "—", F1Hub.ink],
                        ["Podiums", [page.th?.wins, page.th?.p2, page.th?.p3].every(n => n !== undefined)
                            ? String(page.th.wins + page.th.p2 + page.th.p3) : "—", F1Hub.ink],
                        ["Poles", page.th?.poles !== undefined ? String(page.th.poles) : "—", F1Hub.ink],
                        ["Best", page.bestEver ? "P" + page.bestEver.pos : "—", F1Hub.ink,
                            page.bestEver ? page.bestEver.year + (page.bestEver.year === F1Data.season ? "*" : "") : ""]
                    ]
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 0
                        F1Text { text: modelData[0]; role: "caption"; tone: "tertiary" }
                        RowLayout {
                            spacing: 4
                            F1Text {
                                text: modelData[1]; role: "title"; numeric: true
                                color: modelData[1] !== "0" ? modelData[2] : F1Hub.ink
                            }
                            F1Text {
                                visible: !!modelData[3]
                                text: modelData[3] ?? ""
                                role: "caption"; tone: "secondary"; numeric: true
                                Layout.alignment: Qt.AlignBottom
                                Layout.bottomMargin: 3
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: [
                        ["Recent seasons", null],
                        ["First win", historyTile.win],
                        ["Latest win", historyTile.last]
                    ]
                    ColumnLayout {
                        required property var modelData
                        required property int index
                        visible: index !== 2 || historyTile.last
                        Layout.fillWidth: index > 0
                        Layout.preferredWidth: index === 0 ? Math.max(recentRow.implicitWidth, 90) + 8 : 1
                        spacing: 1
                        F1Text { text: modelData[0]; role: "caption"; tone: "tertiary" }
                        Row {
                            id: recentRow
                            visible: index === 0
                            spacing: 6
                            Repeater {
                                model: page.seasons.slice(-5)
                                F1Text {
                                    required property var modelData
                                    readonly property bool current: modelData.year === F1Data.season
                                    text: "P" + modelData.pos + (current ? "*" : "")
                                    role: "footnote"; numeric: true; font.weight: Font.DemiBold
                                    color: modelData.pos === 1 && !current ? Theme.gold : F1Hub.ink
                                }
                            }
                        }
                        F1Text {
                            visible: index > 0
                            Layout.fillWidth: true
                            role: "footnote"; numeric: true
                            font.weight: Font.DemiBold
                            text: modelData[1] ? modelData[1].season + " " + modelData[1].short
                                : page.th?.wins === 0 ? "Not yet" : "—"
                        }
                        F1Text {
                            Layout.fillWidth: true
                            role: "caption"; tone: "secondary"
                            text: index === 0
                                ? (page.seasons.length ? page.seasons.slice(-5)[0].year + "–" + page.seasons.slice(-1)[0].year : page.th ? "Loading…" : "")
                                : modelData[1]?.driver ?? ""
                        }
                    }
                }
            }
        }
    }
}

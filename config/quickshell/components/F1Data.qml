pragma Singleton
import QtQuick
import Quickshell

import "."

// The one F1 store. Responses are normalised on arrival so views never read API JSON:
//   race    { round, season, name, short, circuitId, circuit, locality, country, start, sessions }
//   session { label, start, end }
//   driver  { pos, code, name, last, team, points, wins }      team is always teamKey()
//   team    { pos, team, id, name, points, wins }        id is the Jolpica constructorId
//   result  { pos, code, name, team, time, points, grid, status, dnf, fastest }
// Sources: Jolpica (schedule, results, standings), OpenF1 (latest session, driver
// colours and headshots, weather, flag) and Multiviewer (track outline).
Singleton {
    id: root

    readonly property string jolpica: "https://api.jolpi.ca/ergast/f1/"
    readonly property string openf1: "https://api.openf1.org/v1/"
    readonly property int minute: 60 * 1000
    readonly property int hour: 60 * minute
    readonly property int day: 24 * hour

    // ── State ───────────────────────────────────────────────────

    property date now: new Date()
    property var races: []
    property var winners: ({})          // round -> { code, team }
    property var driverStandings: []
    property var teamStandings: []
    property var lastRace: null          // { round, season, name, short, results }
    property var session: null           // { name, short, results, weather }
    property var people: ({})            // code -> { name, team, colour, headshot }
    property var meeting: null           // { round, flag, circuitKey }
    property var flags: ({})             // round -> country flag url
    property var track: null
    property var history: null           // circuit history for the current weekend
    property var teamSeason: null        // { id, races: [{ round, short, results }], quali: round -> [{ code, pos }], sprint: round -> [result] }
    property var teamHistory: null       // { id, races, debut, wins, firstWin, lastWin, p2, p3, poles, years, seasons: year -> { pos, points, wins } }
    readonly property bool ready: races.length > 0

    // ── Weekend state ───────────────────────────────────────────

    readonly property var weekend: races.find(r => r.sessions[r.sessions.length - 1].end > now) ?? null
    readonly property var sessions: weekend?.sessions ?? []
    readonly property var liveSession: sessions.find(s => s.start <= now && now < s.end) ?? null
    readonly property var nextSession: sessions.find(s => s.start > now) ?? null
    readonly property var lastSession: sessions.filter(s => s.end <= now).slice(-1)[0] ?? null
    readonly property string season: weekend?.season ?? lastRace?.season ?? String(new Date().getFullYear())

    // live: a session is running · soon: next session within 2h · result: fresh results (< 18h)
    // weekend: race weekend within 4 days · idle: between rounds
    readonly property string mode: {
        if (liveSession) return "live"
        if (nextSession && nextSession.start - now < 2 * hour) return "soon"
        if (session && session.ended && now - session.ended < 18 * hour) return "result"
        if (nextSession && nextSession.start - now < 4 * day) return "weekend"
        return "idle"
    }

    readonly property real progress: {
        if (sessions.length < 2) return 0
        const a = sessions[0].start, b = sessions[sessions.length - 1].end
        return Math.max(0, Math.min(1, (now - a) / (b - a)))
    }

    // ── Teams ───────────────────────────────────────────────────

    readonly property var teamAliases: ({ rb: "racingbulls", visacashapprb: "racingbulls", alphatauri: "racingbulls",
        kicksauber: "audi", sauber: "audi", stake: "audi" })
    readonly property var fallbackColours: ({ ferrari: "#e8002d", mercedes: "#27f4d2", mclaren: "#ff8000",
        redbull: "#3671c6", astonmartin: "#229971", alpine: "#00a1e8", williams: "#64c4ff",
        racingbulls: "#6692ff", haas: "#b6babd", audi: "#f50537", cadillac: "#c9a85c" })
    property var teamColours: ({})

    function teamKey(name) {
        const k = String(name ?? "").toLowerCase().replace(/[^a-z]/g, "").replace(/(f1team|formulaoneteam|racing)$/, "")
        return teamAliases[k] ?? k
    }
    function teamColour(team, fallback) { return teamColours[team] ?? fallbackColours[team] ?? fallback ?? F1Hub.ink3 }
    function driverColour(code) { return teamColour(people[code]?.team ?? "") }
    function teamLogo(team) { return TeamAssets.logo(team, season) }
    function teamName(team) { return teamStandings.find(t => t.team === team)?.name ?? team }

    readonly property string myTeam: {
        const t = Theme.themeById(Theme.activeId)
        const id = String(Theme.activeId)
        return teamKey(t?.f1?.constructor ?? (id.startsWith("f1-") ? id.slice(3) : "Ferrari"))
    }
    readonly property var myStanding: teamStandings.find(t => t.team === myTeam) ?? null
    readonly property var myDrivers: driverStandings.filter(d => d.team === myTeam)

    function headshot(code) {
        let u = String(people[code]?.headshot ?? "")
        const dam = u.indexOf("/content/dam/")
        if (dam >= 0) u = "https://media.formula1.com" + u.slice(dam)
        return u.replace(".transform/1col/", ".transform/3col/")
    }

    // ── Formatting ──────────────────────────────────────────────

    function countdown(target) {
        const s = Math.max(0, Math.floor((target - now) / 1000))
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        if (d > 0) return d + "d " + h + "h"
        if (h > 0) return h + "h " + m + "m"
        return m + "m " + (s % 60 < 10 ? "0" : "") + (s % 60) + "s"
    }
    function elapsed(since) {
        const m = Math.max(0, Math.floor((now - since) / minute))
        return m >= 60 ? Math.floor(m / 60) + "h " + (m % 60) + "m" : m + "m"
    }
    function titleCase(name) {
        return String(name ?? "").toLowerCase().replace(/(^|[\s-])(\S)/g, (m, a, b) => a + b.toUpperCase())
    }

    // ── Calendar API (used by ClockChip) ────────────────────────

    readonly property var calendarByDate: {
        const map = {}
        for (const r of races)
            for (const s of r.sessions) {
                const key = dateKey(s.start.getFullYear(), s.start.getMonth(), s.start.getDate())
                ;(map[key] = map[key] ?? []).push({ label: s.label, shortName: r.short + " GP", round: r.round })
            }
        return map
    }
    function dateKey(year, month, d) {
        const pad = n => (n < 10 ? "0" : "") + n
        return year + "-" + pad(month + 1) + "-" + pad(d)
    }
    function eventsOn(year, month, d) { return calendarByDate[dateKey(year, month, d)] ?? [] }
    function dayDetail(year, month, d) {
        const ev = eventsOn(year, month, d)
        if (!ev.length) return null
        return { title: "Round " + ev[0].round + " · " + ev[0].shortName, sessions: ev.map(e => e.label).join("  ·  ") }
    }
    function monthHasEvents(year, month) {
        const n = new Date(year, month + 1, 0).getDate()
        for (let d = 1; d <= n; d++)
            if (eventsOn(year, month, d).length) return true
        return false
    }
    readonly property string nextWeekendLine: weekend
        ? "Next race weekend · Round " + weekend.round + " · " + weekend.short + " GP · "
            + Qt.formatDate(weekend.start, "d MMM") + " · race in " + countdown(weekend.start)
        : ""

    // ── Fetching ────────────────────────────────────────────────

    CachedFetch {
        id: net
        cachePath: Quickshell.env("HOME") + "/.cache/quickshell-f1.json"
    }

    readonly property int cadence: mode === "live" ? 2 * minute : mode === "idle" ? 30 * minute : 10 * minute

    readonly property var sessionKeys: [
        ["FirstPractice", "FP1", 60], ["SecondPractice", "FP2", 60], ["ThirdPractice", "FP3", 60],
        ["SprintQualifying", "Sprint Quali", 45], ["Sprint", "Sprint", 60], ["Qualifying", "Quali", 60]
    ]
    readonly property var sessionShort: ({ "Practice 1": "FP1", "Practice 2": "FP2", "Practice 3": "FP3",
        "Qualifying": "Quali", "Sprint Qualifying": "Sprint Quali", "Sprint Shootout": "Sprint Quali",
        "Sprint": "Sprint", "Race": "Race" })

    function at(o) { return new Date(o.date + "T" + (o.time || "00:00:00Z")) }

    function parseRace(r) {
        const sessions = []
        for (const [key, label, mins] of sessionKeys)
            if (r[key]) {
                const s = at(r[key])
                sessions.push({ label, start: s, end: new Date(s.getTime() + mins * minute) })
            }
        const start = at(r)
        sessions.push({ label: "Race", start, end: new Date(start.getTime() + 2 * hour) })
        sessions.sort((a, b) => a.start - b.start)
        return {
            round: Number(r.round), season: r.season, name: r.raceName, short: r.raceName.replace(" Grand Prix", ""),
            circuitId: r.Circuit.circuitId, circuit: r.Circuit.circuitName,
            locality: r.Circuit.Location.locality, country: r.Circuit.Location.country, start, sessions
        }
    }

    function parseResult(r) {
        return {
            pos: Number(r.position), code: r.Driver.code, name: r.Driver.givenName + " " + r.Driver.familyName,
            last: r.Driver.familyName, team: teamKey(r.Constructor.constructorId), grid: Number(r.grid),
            laps: r.laps, status: r.status, time: r.Time?.time ?? r.status, points: Number(r.points),
            // Retired cars past 90% distance are still classified, so status decides.
            dnf: !/^\d+$/.test(r.positionText ?? r.position) || !/^(Finished|Lapped|\+\d+ Laps?)$/.test(r.status),
            fastest: r.FastestLap?.rank === "1" ? r.FastestLap.Time.time : ""
        }
    }

    function refresh(force) {
        const ttl = force ? 0 : cadence
        const list = j => j.MRData.StandingsTable.StandingsLists[0]
        net.fetch(jolpica + "current.json", force ? 0 : 6 * hour, j => races = (j.MRData.RaceTable.Races ?? []).map(parseRace))
        net.fetch(jolpica + "current/results/1.json?limit=100", ttl, j => {
            const map = {}
            for (const r of j.MRData.RaceTable.Races ?? [])
                map[r.round] = { code: r.Results[0].Driver.code, team: teamKey(r.Results[0].Constructor.constructorId) }
            winners = map
        })
        net.fetch(jolpica + "current/last/results.json", ttl, j => {
            const r = j.MRData.RaceTable.Races[0]
            if (r) lastRace = { round: Number(r.round), season: r.season, name: r.raceName,
                short: r.raceName.replace(" Grand Prix", ""), results: r.Results.map(parseResult) }
        })
        net.fetch(jolpica + "current/driverstandings.json?limit=30", ttl, j => {
            driverStandings = (list(j)?.DriverStandings ?? []).map(s => ({
                pos: Number(s.position), code: s.Driver.code, name: s.Driver.givenName + " " + s.Driver.familyName,
                last: s.Driver.familyName, team: teamKey(s.Constructors[s.Constructors.length - 1]?.constructorId),
                points: Number(s.points), wins: Number(s.wins)
            }))
        })
        net.fetch(jolpica + "current/constructorstandings.json?limit=15", ttl, j => {
            teamStandings = (list(j)?.ConstructorStandings ?? []).map(s => ({
                pos: Number(s.position), team: teamKey(s.Constructor.constructorId), id: s.Constructor.constructorId,
                name: s.Constructor.name.replace(/ F1 Team$/, "").replace(/^RB$/, "Racing Bulls"),
                points: Number(s.points), wins: Number(s.wins)
            }))
        })
        refreshSession(ttl)
    }

    function refreshSession(ttl) {
        net.fetch(openf1 + "sessions?meeting_key=latest", ttl, list => {
            const s = list.filter(s => new Date(s.date_end) < new Date())
                .sort((a, b) => new Date(b.date_start) - new Date(a.date_start))[0]
            if (!s) return
            // Results are amended for a few hours after a session, then final.
            const t = Date.now() - new Date(s.date_end) > 6 * hour ? 30 * day : Math.min(ttl, 10 * minute)
            const base = { name: s.session_name, short: sessionShort[s.session_name] ?? s.session_name,
                ended: new Date(s.date_end), results: [], weather: null }
            net.fetch(openf1 + "drivers?session_key=" + s.session_key, t, drivers => {
                const ppl = {}, colours = {}
                for (const d of drivers) {
                    const team = teamKey(d.team_name)
                    ppl[d.name_acronym] = { name: titleCase(d.full_name), team, colour: "#" + d.team_colour, headshot: d.headshot_url ?? "", number: d.driver_number }
                    if (d.team_colour) colours[team] = "#" + d.team_colour
                }
                people = ppl
                teamColours = colours
                const byNum = {}
                for (const d of drivers) byNum[d.driver_number] = d
                net.fetch(openf1 + "session_result?session_key=" + s.session_key, t, res => {
                    if (!res.length) return
                    const last = v => Array.isArray(v) ? v.filter(x => x !== null).slice(-1)[0] : v
                    base.results = res.filter(r => r.position).sort((a, b) => a.position - b.position).map(r => {
                        const d = byNum[r.driver_number] ?? {}
                        const gap = last(r.gap_to_leader)
                        return {
                            pos: r.position, code: d.name_acronym ?? String(r.driver_number), name: titleCase(d.full_name),
                            team: teamKey(d.team_name),
                            time: r.position === 1 ? lapTime(last(r.duration)) : typeof gap === "number" ? "+" + gap.toFixed(3) : String(gap ?? r.status ?? "")
                        }
                    })
                    session = Object.assign({}, base, { weather: session?.name === base.name ? session.weather : null })
                    net.fetch(openf1 + "weather?session_key=" + s.session_key, t, w => {
                        if (w.length) session = Object.assign({}, session, { weather: w[w.length - 1] })
                    })
                })
            })
        })
    }

    function lapTime(s) {
        if (typeof s !== "number") return ""
        const m = Math.floor(s / 60), rest = (s - m * 60).toFixed(3)
        return m > 0 ? m + ":" + (rest < 10 ? "0" : "") + rest : rest
    }

    // Flag + track outline follow the current weekend.
    onWeekendChanged: {
        if (!weekend || meeting?.round === weekend.round) return
        const w = weekend
        meeting = { round: w.round, flag: "", circuitKey: 0 }
        track = null
        net.fetch(openf1 + "meetings?year=" + w.season, day, list => {
            const meetingFor = r => {
                const raceDay = r.start.toISOString().slice(0, 10)
                return list.find(m => m.date_start.slice(0, 10) <= raceDay && m.date_end.slice(0, 10) >= raceDay)
            }
            const f = {}
            for (const r of races) f[r.round] = meetingFor(r)?.country_flag ?? ""
            flags = f
            const m = meetingFor(w)
            if (!m) return
            meeting = { round: w.round, flag: m.country_flag ?? "", circuitKey: m.circuit_key }
            net.fetch("https://api.multiviewer.app/api/v1/circuits/" + m.circuit_key + "/" + w.season, 30 * day, t => {
                track = { x: t.x, y: t.y, rotation: t.rotation, corners: t.corners, pitLoss: parseFloat(t.pitLoss?.normal) || 0,
                    sectors: [0, 0] }
                loadSectors(m.circuit_key, w.round)
            })
        })
    }

    // Circuit history is only fetched when the Circuit page asks for it.
    function loadHistory() {
        const w = weekend
        if (!w || history?.circuitId === w.circuitId) return
        history = { circuitId: w.circuitId, loading: true }
        net.fetch(jolpica + "circuits/" + w.circuitId + "/results/1.json?limit=100", 3 * day, j => {
            const rs = (j.MRData.RaceTable.Races ?? []).map(r => Object.assign({ season: r.season }, parseResult(r.Results[0])))
            if (!rs.length) { history = { circuitId: w.circuitId, races: 0 }; return }
            const tally = key => {
                const n = {}
                for (const r of rs) n[r[key]] = (n[r[key]] ?? 0) + 1
                const max = Math.max(...Object.values(n))
                const who = Object.keys(n).filter(k => n[k] === max)
                return { count: max, who, team: key === "team" ? who[0] : rs.find(r => r[key] === who[0]).team,
                    names: key === "team" ? who.map(teamName) : who.map(c => rs.find(r => r[key] === c).name) }
            }
            const fromPole = rs.filter(r => r.grid === 1).length
            const lowest = rs.reduce((b, r) => r.grid > 0 && (!b || r.grid > b.grid) ? r : b, null)
            history = {
                circuitId: w.circuitId, races: rs.length, first: rs[0].season, laps: rs[rs.length - 1].laps,
                recent: rs.slice(-5).reverse(), mostWins: tally("name"), mostTeamWins: tally("team"),
                fromPole, lowest
            }
        })
    }

    // My team's season breakdown and all-time record, fetched when the My Team page asks.
    function loadTeam() {
        const id = myStanding?.id
        if (!id) return
        const mine = () => teamSeason?.id === id
        const ttl = cadence
        if (!mine()) teamSeason = { id, races: [], quali: {}, sprint: {} }
        const setSeason = (key, value) => { if (mine()) teamSeason = Object.assign({}, teamSeason, { [key]: value }) }
        const byRound = (races, key, map) => {
            const out = {}
            for (const r of races) out[r.round] = r[key].map(map)
            return out
        }
        const races = j => j.MRData.RaceTable.Races ?? []
        const base = jolpica + "current/constructors/" + id
        net.fetch(base + "/results.json?limit=100", ttl, j => setSeason("races", races(j).map(r => ({
            round: Number(r.round), short: r.raceName.replace(" Grand Prix", ""), results: r.Results.map(parseResult) }))))
        net.fetch(base + "/qualifying.json?limit=100", ttl, j => setSeason("quali",
            byRound(races(j), "QualifyingResults", q => ({ code: q.Driver.code, pos: Number(q.position) }))))
        net.fetch(base + "/sprint.json?limit=100", ttl, j => setSeason("sprint", byRound(races(j), "SprintResults", parseResult)))

        if (teamHistory?.id === id) return
        teamHistory = { id, seasons: {} }
        const ours = () => teamHistory?.id === id
        const record = patch => { if (ours()) teamHistory = Object.assign({}, teamHistory, patch) }
        const all = jolpica + "constructors/" + id
        const total = j => Number(j.MRData.total)
        const win = r => r ? { season: r.season, short: r.raceName.replace(" Grand Prix", ""), driver: r.Results[0].Driver.familyName } : null
        net.fetch(all + "/races.json?limit=1", day, j => {
            const r = races(j)[0]
            record({ races: total(j), debut: r ? { season: r.season, short: r.raceName.replace(" Grand Prix", "") } : null })
        })
        net.fetch(all + "/results/1.json?limit=1", day, j => {
            const wins = total(j)
            record({ wins, firstWin: win(races(j)[0]), lastWin: wins === 1 ? win(races(j)[0]) : null })
            if (wins > 1) net.fetch(all + "/results/1.json?limit=1&offset=" + (wins - 1), day, k => record({ lastWin: win(races(k)[0]) }))
        })
        net.fetch(all + "/results/2.json?limit=1", day, j => record({ p2: total(j) }))
        net.fetch(all + "/results/3.json?limit=1", day, j => record({ p3: total(j) }))
        net.fetch(all + "/qualifying/1.json?limit=1", day, j => record({ poles: total(j) }))
        // The constructors' championship began in 1958; finished seasons never change.
        // Whole-grid tables are shared by every team, so switching teams rarely costs a request.
        net.fetch(all + "/seasons.json?limit=100", day, j => {
            const years = (j.MRData.SeasonTable.Seasons ?? []).map(s => s.season).filter(y => y >= "1958")
            record({ years })
            for (const y of years)
                net.fetch(jolpica + y + "/constructorstandings.json?limit=30", y === season ? ttl : 365 * day, k => {
                    const s = (k.MRData.StandingsTable.StandingsLists[0]?.ConstructorStandings ?? [])
                        .find(c => c.Constructor.constructorId === id)
                    if (s) record({ seasons: Object.assign({}, teamHistory.seasons,
                        { [y]: { pos: Number(s.position), points: Number(s.points), wins: Number(s.wins) } }) })
                })
        })
    }

    // Sector boundaries from timing: where a real car was when its lap's S1 and S2 times elapsed,
    // taken from the most recent completed race at this circuit (OpenF1 shares the outline's coordinates).
    function loadSectors(circuitKey, round) {
        const stillCurrent = () => meeting?.round === round && track
        net.fetch(openf1 + "sessions?circuit_key=" + circuitKey + "&session_name=Race", 7 * day, sessions => {
            const s = sessions.filter(x => new Date(x.date_end) < new Date()).pop()
            if (!s || !stillCurrent()) return
            net.fetch(openf1 + "laps?session_key=" + s.session_key + "&lap_number=10", 365 * day, laps => {
                const lap = laps.find(l => l.duration_sector_1 > 0 && l.duration_sector_2 > 0 && l.date_start && !l.is_pit_out_lap)
                if (!lap || !stillCurrent()) return
                const t0 = new Date(lap.date_start).getTime()
                const t1 = t0 + lap.duration_sector_1 * 1000, t2 = t1 + lap.duration_sector_2 * 1000
                const iso = ms => new Date(ms).toISOString().slice(0, 23)
                net.fetch(openf1 + "location?session_key=" + s.session_key + "&driver_number=" + lap.driver_number
                          + "&date>=" + iso(t1 - 2000) + "&date<=" + iso(t2 + 2000), 365 * day, loc => {
                    if (!loc.length || !stillCurrent()) return
                    const at = ms => loc.reduce((a, b) => Math.abs(new Date(b.date) - ms) < Math.abs(new Date(a.date) - ms) ? b : a)
                    const t = track
                    const nearest = p => {
                        let best = 0, bd = Infinity
                        for (let i = 0; i < t.x.length; i++) {
                            const d = (t.x[i] - p.x) ** 2 + (t.y[i] - p.y) ** 2
                            if (d < bd) { bd = d; best = i }
                        }
                        return best
                    }
                    const b1 = nearest(at(t1)), b2 = nearest(at(t2))
                    if (b1 > 0 && b2 > b1) track = Object.assign({}, t, { sectors: [b1, b2] })
                })
            })
        })
    }

    // ── Clocks ──────────────────────────────────────────────────

    Component.onCompleted: refresh(false)

    Timer {
        interval: F1Hub.open || root.mode === "live" || root.mode === "soon" ? 1000 : 30000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Timer {
        interval: root.cadence
        running: true
        repeat: true
        onTriggered: root.refresh(false)
    }
}

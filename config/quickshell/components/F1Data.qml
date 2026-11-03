pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import "."

Singleton {
    id: root

    readonly property string api: "https://api.jolpi.ca/ergast/f1/current/"
    readonly property string seasonApi: "https://api.jolpi.ca/ergast/f1/current.json"
    readonly property string openf1Api: "https://api.openf1.org/v1/"

    readonly property int minute: 60 * 1000
    readonly property int hour: 60 * minute
    readonly property int day: 24 * hour

    property var lastRace: null
    property var results: []
    property var nextRace: null
    property var seasonRaces: []
    property var calendarByDate: ({})
    property var sessions: []
    property var driverStandings: []
    property var teamStandings: []
    property date now: new Date()

    readonly property date nextStart: nextRace ? new Date(nextRace.date + "T" + (nextRace.time || "00:00:00Z")) : new Date(0)
    readonly property bool raceLive: nextRace !== null && now >= nextStart && now - nextStart < 3 * hour
    readonly property bool raceSoon: nextRace !== null && nextStart - now > 0 && nextStart - now < 3 * day
    readonly property var nextSession: sessions.find(s => s.start > now) ?? null

    CachedFetch {
        id: net
        cachePath: Quickshell.env("HOME") + "/.cache/quickshell-f1.json"
    }

    function fetch(url, ttl, cb) {
        net.fetch(url, ttl, cb)
    }

    Component.onCompleted: refresh()

    // ── Season ──────────────────────────────────────────────────

    readonly property var sessionKeys: [
        ["FirstPractice", "FP1"], ["SecondPractice", "FP2"], ["ThirdPractice", "FP3"],
        ["SprintQualifying", "Sprint Quali"], ["Sprint", "Sprint"], ["Qualifying", "Quali"]
    ]

    function sessionsFromRace(r) {
        if (!r) return []
        const list = []
        for (const [key, label] of sessionKeys)
            if (r[key]) list.push({ label, start: new Date(r[key].date + "T" + (r[key].time || "00:00:00Z")) })
        list.push({ label: "Race", start: new Date(r.date + "T" + (r.time || "00:00:00Z")) })
        return list.sort((a, b) => a.start - b.start)
    }

    function buildCalendar(races) {
        const map = {}
        const add = (dateStr, entry) => {
            if (!dateStr) return
            const key = String(dateStr).slice(0, 10)
            if (!map[key]) map[key] = []
            map[key].push(entry)
        }
        for (const r of races) {
            const shortName = root.shortName(r)
            const round = r.round
            for (const [key, label] of sessionKeys)
                if (r[key]) add(r[key].date, { label, shortName, round })
            add(r.date, { label: "Race", shortName, round })
        }
        return map
    }

    function dateKey(year, month, day) {
        const pad = n => (n < 10 ? "0" : "") + n
        return year + "-" + pad(month + 1) + "-" + pad(day)
    }

    function eventsOn(year, month, day) {
        return calendarByDate[dateKey(year, month, day)] ?? []
    }

    readonly property string nextWeekendLine: {
        const next = nextRace
        if (!next) return ""
        const raceStart = new Date(next.date + "T" + (next.time || "00:00:00Z"))
        void now
        return "Next race weekend · Round " + next.round + " · " + shortName(next)
            + " · " + Qt.formatDate(raceStart, "d MMM")
            + " · race in " + countdown(raceStart)
    }

    function dayDetail(year, month, day) {
        const ev = eventsOn(year, month, day)
        if (!ev.length)
            return null
        const race = ev.find(e => e.label === "Race")
        const round = race?.round ?? ev[0].round
        const gp = race?.shortName ?? ev[0].shortName
        return { title: "Round " + round + " · " + gp, sessions: ev.map(e => e.label).join("  ·  ") }
    }

    function monthHasEvents(year, month) {
        const n = new Date(year, month + 1, 0).getDate()
        for (let d = 1; d <= n; d++)
            if (eventsOn(year, month, d).length) return true
        return false
    }

    function refresh() {
        const ttl = raceLive ? 5 * minute : 30 * minute
        fetch(seasonApi, 6 * hour, j => {
            const races = j.MRData?.RaceTable?.Races ?? []
            seasonRaces = races
            calendarByDate = buildCalendar(races)
        })
        fetch(api + "last/results.json", ttl, j => {
            const r = j.MRData.RaceTable.Races[0]
            if (!r) return
            lastRace = r
            results = r.Results
        })
        fetch(api + "next.json", 6 * hour, j => {
            const r = j.MRData.RaceTable.Races[0] ?? null
            nextRace = r
            sessions = r ? sessionsFromRace(r) : []
        })
        fetch(api + "driverstandings.json?limit=30", ttl, j => {
            const l = j.MRData.StandingsTable.StandingsLists[0]
            driverStandings = l ? l.DriverStandings : []
        })
        fetch(api + "constructorstandings.json?limit=15", ttl, j => {
            const l = j.MRData.StandingsTable.StandingsLists[0]
            teamStandings = l ? l.ConstructorStandings : []
        })
        refreshSession()
        refreshMyTeamHistory()
    }

    // ── Circuit ─────────────────────────────────────────────────

    property string circuitId: ""
    property var circuit: null
    property var track: null
    property var meeting: null

    onNextRaceChanged: {
        if (nextRace && nextRace.Circuit.circuitId !== circuitId) {
            circuitId = nextRace.Circuit.circuitId
            refreshCircuit()
        }
    }

    // Entries are [name, constructorId]; `team` is set only when there's a single leader.
    function tally(list) {
        const counts = {}, teams = {}
        for (const [name, team] of list) {
            counts[name] = (counts[name] ?? 0) + 1
            teams[name] = team
        }
        const max = Math.max(...Object.values(counts))
        const leaders = Object.keys(counts).filter(n => counts[n] === max)
        return { count: max, names: leaders.join(", "), team: leaders.length === 1 ? teams[leaders[0]] : "" }
    }

    // Long gaps between consecutive corners, trimmed for corner exit and braking.
    // An estimate: the FIA's actual straight-mode zones aren't in any free feed.
    function findStraights(t) {
        const n = t.x.length
        const cum = [0]
        for (let i = 1; i < n; i++)
            cum.push(cum[i - 1] + Math.hypot(t.x[i] - t.x[i - 1], t.y[i] - t.y[i - 1]))
        const total = cum[n - 1] + Math.hypot(t.x[0] - t.x[n - 1], t.y[0] - t.y[n - 1])
        const nearest = (px, py) => {
            let best = 0, bd = Infinity
            for (let i = 0; i < n; i++) {
                const d = (t.x[i] - px) ** 2 + (t.y[i] - py) ** 2
                if (d < bd) { bd = d; best = i }
            }
            return best
        }
        const idx = (t.corners ?? []).map(c => nearest(c.trackPosition.x, c.trackPosition.y)).sort((a, b) => a - b)
        if (idx.length < 2) return []
        const at = d => {
            d = ((d % total) + total) % total
            let i = 0
            while (i < n - 1 && cum[i + 1] <= d) i++
            return i
        }
        const zones = []
        for (let k = 0; k < idx.length; k++) {
            const a = cum[idx[k]]
            let b = cum[idx[(k + 1) % idx.length]]
            if (b <= a) b += total
            if (b - a < total * 0.1) continue
            const s = at(a + total * 0.02), e = at(b - total * 0.035)
            if (e >= s) zones.push([s, e])
            else zones.push([s, n - 1], [0, e])
        }
        return zones
    }

    function teamLogo(team) {
        return TeamAssets.logo(team, nextRace?.season ?? lastRace?.season)
    }

    property var podiumNames: ({})

    function addPodiums(pos, races) {
        const names = Object.assign({}, podiumNames)
        names[pos] = races.map(r => [r.Results[0].Driver.givenName + " " + r.Results[0].Driver.familyName, r.Results[0].Constructor.constructorId])
        podiumNames = names
        const all = [].concat(names[1] ?? [], names[2] ?? [], names[3] ?? [])
        if (all.length) circuit = Object.assign({}, circuit, { mostPodiums: tally(all) })
    }

    function refreshCircuit() {
        podiumNames = {}
        const base = "https://api.jolpi.ca/ergast/f1/circuits/" + circuitId + "/"
        circuit = { races: 0, firstYear: "", lastWinner: null, mostWins: null, mostPoles: null, lapRecord: null }
        track = null
        const name = d => d.givenName + " " + d.familyName

        fetch(base + "results/1.json?limit=100", 3 * day, j => {
            const races = j.MRData.RaceTable.Races
            if (!races.length) return
            const last = races[races.length - 1]
            circuit = Object.assign({}, circuit, {
                races: races.length,
                firstYear: races[0].season,
                lastWinner: { season: last.season, name: name(last.Results[0].Driver), team: last.Results[0].Constructor.name },
                mostWins: tally(races.map(r => [name(r.Results[0].Driver), r.Results[0].Constructor.constructorId])),
                mostTeamWins: tally(races.map(r => [r.Results[0].Constructor.name, r.Results[0].Constructor.constructorId])),
                raceLaps: last.Results[0].laps,
                winners: races.reduce((m, r) => (m[r.season] = r.Results[0].Driver.driverId, m), {}),
                recentWinners: races.slice(-5).reverse().map(r => ({
                    season: r.season, code: r.Results[0].Driver.code, name: name(r.Results[0].Driver),
                    team: r.Results[0].Constructor.constructorId, grid: r.Results[0].grid
                })),
                lowestGridWin: races.reduce((best, r) => {
                    const g = Number(r.Results[0].grid)
                    return g > 0 && (!best || g > best.grid)
                        ? { grid: g, name: name(r.Results[0].Driver), season: r.season, team: r.Results[0].Constructor.constructorId } : best
                }, null)
            })
            addPodiums(1, races)
        })
        for (const pos of [2, 3])
            fetch(base + "results/" + pos + ".json?limit=100", 3 * day, j => addPodiums(pos, j.MRData.RaceTable.Races))
        fetch(base + "qualifying/1.json?limit=100", 3 * day, j => {
            const races = j.MRData.RaceTable.Races
            if (!races.length) return
            let record = null
            for (const r of races) {
                const q = r.QualifyingResults[0]
                for (const t of [q.Q1, q.Q2, q.Q3]) {
                    if (!t || !t.includes(":")) continue
                    const [m, s] = t.split(":")
                    const secs = Number(m) * 60 + Number(s)
                    if (!record || secs < record.secs)
                        record = { secs, time: t, name: name(q.Driver), season: r.season, team: q.Constructor.constructorId }
                }
            }
            circuit = Object.assign({}, circuit, {
                mostPoles: tally(races.map(r => [name(r.QualifyingResults[0].Driver), r.QualifyingResults[0].Constructor.constructorId])),
                poles: races.reduce((m, r) => (m[r.season] = r.QualifyingResults[0].Driver.driverId, m), {}),
                qualiRecord: record
            })
        })
        fetch(base + "fastest/1/results.json?limit=100", 3 * day, j => {
            let best = null
            for (const r of j.MRData.RaceTable.Races) {
                const res = r.Results[0]
                const t = res.FastestLap?.Time?.time
                if (!t) continue
                const [m, s] = t.split(":")
                const secs = Number(m) * 60 + Number(s)
                if (!best || secs < best.secs)
                    best = { secs, time: t, name: name(res.Driver), season: r.season, team: res.Constructor.constructorId }
            }
            if (best) circuit = Object.assign({}, circuit, { lapRecord: best })
        })

        const year = nextRace.season
        const raceDay = nextRace.date
        fetch(openf1Api + "meetings?year=" + year, day, meetings => {
            const m = meetings.find(m => m.date_start.slice(0, 10) <= raceDay && m.date_end.slice(0, 10) >= raceDay)
            if (!m) return
            meeting = m
            fetch("https://api.multiviewer.app/api/v1/circuits/" + m.circuit_key + "/" + year, 30 * day, t => {
                const mini = t.miniSectorsIndexes ?? []
                const third = Math.round(mini.length / 3)
                track = {
                    x: t.x, y: t.y, rotation: t.rotation, corners: t.corners, type: m.circuit_type,
                    mini, sectors: [mini[third - 1] ?? 0, mini[third * 2 - 1] ?? 0],
                    straights: findStraights(t)
                }
                fetch(openf1Api + "sessions?meeting_key=" + m.meeting_key, hour, list => {
                    const s = list.find(s => new Date(s.date_end) < new Date())
                    if (!s) return
                    fetch(openf1Api + "laps?session_key=" + s.session_key + "&lap_number=3", 30 * day, laps => {
                        const lap = laps.find(l => l.segments_sector_1 && l.segments_sector_2 && l.segments_sector_3)
                        if (!lap || !track) return
                        const n1 = lap.segments_sector_1.length, n2 = lap.segments_sector_2.length
                        if (n1 + n2 + lap.segments_sector_3.length !== track.mini.length) return
                        track = Object.assign({}, track, { sectors: [track.mini[n1 - 1], track.mini[n1 + n2 - 1]] })
                    })
                })
            })
        })
    }

    // ── Drivers & latest session ────────────────────────────────

    property var driverInfo: ({})

    readonly property var teamColours: {
        const map = {}
        for (const s of driverStandings) {
            const c = driverInfo[s.Driver.code]?.colour
            const team = s.Constructors[s.Constructors.length - 1]?.constructorId
            if (c && team && !map[team]) map[team] = c
        }
        return map
    }

    function driverColour(code) {
        return driverInfo[code]?.colour || Theme.muted
    }

    function headshotCacheKey(code, team) {
        return code + "|" + normTeam(team)
    }

    function headshotUrl(raw) {
        if (!raw) return ""
        let u = String(raw)
        const dam = u.indexOf("/content/dam/")
        if (dam >= 0) u = "https://media.formula1.com" + u.slice(dam)
        return u.replace(".transform/1col/", ".transform/3col/")
    }

    function driverMediaAsset(code) {
        const map = {
            PER: "serper01", PEA: "serper01", BOT: "valbot01", LEC: "chalec01", HAM: "lewham01",
            ANT: "andant01", RUS: "georus01", VER: "maxver01", NOR: "lannor01", PIA: "oscpia01",
            SAI: "carsai01", ALO: "feralo01", STR: "lanstr01", GAS: "piegas01", OCO: "estoco01",
            HUL: "nichul01", HAD: "isahad01", LAW: "liamlaw01", BOR: "gabbor01", BEA: "ollbea01"
        }
        return map[String(code ?? "").toUpperCase()] ?? ""
    }

    function driverAssetSlug(openF1Headshot) {
        const u = String(openF1Headshot)
        let m = u.match(/\/([a-z0-9]+)\.png\.transform/i)
        if (m) return m[1].toLowerCase()
        m = u.match(/\/([a-z0-9]{5,14})\.png/i)
        if (m && m[1] !== "image") return m[1].toLowerCase()
        return ""
    }

    function teamMediaSlug(teamName) {
        const key = normTeam(teamName).replace(/f1team$/, "")
        const map = {
            mercedes: "mercedes", ferrari: "ferrari", mclaren: "mclaren", alpine: "alpine",
            williams: "williams", haas: "haas", astonmartin: "astonmartin", audi: "audi",
            cadillac: "cadillac", redbull: "redbullracing", redbullracing: "redbullracing",
            racingbulls: "racingbulls", rbf1team: "racingbulls", kicksauber: "audi", sauber: "audi"
        }
        return map[key] ?? ""
    }

    // Current-season portraits (OpenF1 dam paths are often last year's suit).
    function seasonDriverPortrait(teamName, openF1Headshot, code) {
        const year = String(nextRace?.season ?? lastRace?.season ?? new Date().getFullYear())
        const team = teamMediaSlug(teamName)
        const asset = driverAssetSlug(openF1Headshot) || driverMediaAsset(code)
        if (!team || !asset) return ""
        const file = year + team + asset + "right.jpg"
        return "https://media.formula1.com/image/upload/c_fill,h_480,f_auto,q_auto,g_faces:center/v1740000001/common/f1/"
            + year + "/" + team + "/" + asset + "/" + file
    }

    function headshotFor(code, teamName) {
        const info = driverInfo[code]
        const team = teamName || info?.team || ""
        const key = headshotCacheKey(code, team)
        const openUrl = info?.headshot ?? headshotCache[key] ?? headshotCache[code] ?? ""
        const seasonal = seasonDriverPortrait(team, openUrl, code)
        if (seasonal) return seasonal
        return headshotUrl(openUrl)
    }

    // Podium / session chips — OpenF1 headshots only (unchanged look).
    function headshot(code) {
        const hit = driverInfo[code]?.headshot
        if (hit) return headshotUrl(hit)
        const key = headshotCacheKey(code, driverInfo[code]?.team ?? "")
        return headshotUrl(headshotCache[key] ?? headshotCache[code] ?? "")
    }

    property var headshotCache: ({})

    function teamColour(constructorId) {
        return teamColours[constructorId] || Theme.muted
    }

    function normTeam(name) {
        return String(name ?? "").toLowerCase().replace(/[^a-z]/g, "")
    }

    function teamEq(a, b) {
        const x = normTeam(a), y = normTeam(b)
        if (!x || !y) return false
        if (x === y || x.includes(y) || y.includes(x)) return true
        // Ergast "Cadillac F1 Team" vs theme "Cadillac", etc.
        const strip = s => s.replace(/f1team$|formulaone$|team$/, "")
        return strip(x) === strip(y) || strip(x).includes(strip(y)) || strip(y).includes(strip(x))
    }

    readonly property string defaultTeamName: "Ferrari"

    function constructorFromThemeId(id) {
        if (!String(id).startsWith("f1-")) return ""
        const slug = String(id).slice(4)
        const names = {
            ferrari: "Ferrari", mercedes: "Mercedes", mclaren: "McLaren", alpine: "Alpine",
            williams: "Williams", haas: "Haas", astonmartin: "Aston Martin", audi: "Audi",
            cadillac: "Cadillac", redbull: "Red Bull Racing", racingbulls: "Racing Bulls"
        }
        return names[slug] ?? slug.charAt(0).toUpperCase() + slug.slice(1)
    }

    readonly property string myTeamName: {
        const id = Theme.activeId
        const t = Theme.themeById(id)
        if (String(id).startsWith("f1-"))
            return t?.f1?.constructor ?? constructorFromThemeId(id)
        return t?.f1?.constructor ?? defaultTeamName
    }

    onMyTeamNameChanged: refreshMyTeamHistory()

    readonly property bool myTeamFromTheme: String(Theme.activeId).startsWith("f1-")
    readonly property string myTeamLogo: {
        const t = Theme.themeById(Theme.activeId)
        return myTeamFromTheme && t ? TeamAssets.themeLogo(t) : teamLogo(myTeamName)
    }

    Connections {
        target: Theme
        function onActiveIdChanged() {
            root.myTeamHistory = { lastWin: null, lastWcc: null, seasonWins: 0, seasonPodiums: 0 }
            root.refreshMyTeamHistory()
        }
    }

    readonly property var myTeamStanding: {
        const n = myTeamName
        if (!n) return null
        for (const s of teamStandings) {
            if (teamEq(s.Constructor.name, n)) return s
        }
        return null
    }

    readonly property string myTeamId: myTeamStanding?.Constructor?.constructorId ?? ""

    readonly property var myDrivers: {
        const n = myTeamName, id = myTeamId
        if (!n && !id) return []
        return driverStandings.filter(s => {
            const c = s.Constructors[s.Constructors.length - 1]
            return c && (id && c.constructorId === id || teamEq(c.name, n))
        })
    }

    // Stable order — both drivers get the same visual weight (not ranked by points).
    readonly property var myDriversEven: myDrivers.slice().sort((a, b) => a.Driver.code.localeCompare(b.Driver.code))

    readonly property var myDriverTiles: {
        const _driversLoaded = driverInfo
        const raceByCode = {}
        for (const r of myLastRaceResults)
            raceByCode[r.Driver.code] = r
        const sessByCode = {}
        for (const r of mySessionResults)
            sessByCode[r.code] = r
        return myDriversEven.map(d => {
            const code = d.Driver.code
            const race = raceByCode[code]
            const sess = sessByCode[code]
            let sub = ""
            if (race)
                sub = "Last race P" + race.position + " · " + race.points + " pts"
            else if (sess)
                sub = (sessionName || "Session") + " P" + sess.position
            return {
                code,
                name: d.Driver.givenName + " " + d.Driver.familyName,
                value: "P" + d.position + " · " + d.points + " pts",
                sub,
                photo: headshotFor(code, myTeamName)
            }
        })
    }

    readonly property real myTeamPoints: Number(myTeamStanding?.points ?? 0)

    readonly property real myTeamPointsGap: {
        if (!myTeamStanding || !teamStandings.length) return 0
        const leader = Number(teamStandings[0]?.points ?? 0)
        return Math.max(0, leader - Number(myTeamStanding.points))
    }

    readonly property var myLastRaceResults: {
        const n = myTeamName, id = myTeamId
        if ((!n && !id) || !results.length) return []
        return results.filter(r => (id && r.Constructor.constructorId === id) || teamEq(r.Constructor.name, n))
    }

    readonly property var mySessionResults: {
        const n = myTeamName
        if (!n) return []
        return sessionResults.filter(r => teamEq(r.team, n))
    }

    readonly property int myTeamRacePoints: myLastRaceResults.reduce((sum, r) => sum + Number(r.points ?? 0), 0)

    property var myTeamHistory: ({ lastWin: null, lastWcc: null, seasonWins: 0, seasonPodiums: 0 })

    function ergastConstructorId(name) {
        const key = normTeam(name || myTeamName)
        if (myTeamId && teamEq(myTeamStanding?.Constructor?.name, name || myTeamName)) return myTeamId
        const map = {
            ferrari: "ferrari", mclaren: "mclaren", mercedes: "mercedes", alpine: "alpine",
            williams: "williams", haas: "haas", astonmartin: "aston_martin", audi: "audi",
            cadillac: "cadillac", redbull: "red_bull", redbullracing: "red_bull",
            racingbulls: "rb", visacashapprb: "rb"
        }
        return map[key] ?? ""
    }

    function refreshMyTeamHistory() {
        const cid = ergastConstructorId(myTeamName)
        if (!cid) {
            myTeamHistory = { lastWin: null, lastWcc: null, seasonWins: 0, seasonPodiums: 0 }
            return
        }
        const ergast = "https://api.jolpi.ca/ergast/f1/"
        const ttl = raceLive ? 5 * minute : 30 * minute
        const seasonNow = Number(lastRace?.season ?? nextRace?.season ?? new Date().getFullYear())
        const tryLastWinYear = year => {
            if (year < 1950) {
                myTeamHistory = Object.assign({}, myTeamHistory, { lastWin: null })
                return
            }
            fetch(ergast + year + "/constructors/" + cid + "/results/1.json", 7 * day, j => {
                const races = j.MRData.RaceTable.Races ?? []
                if (!races.length) {
                    tryLastWinYear(year - 1)
                    return
                }
                const win = races[races.length - 1]
                const res = win?.Results?.[0]
                const driver = res?.Driver
                myTeamHistory = Object.assign({}, myTeamHistory, {
                    lastWin: {
                        season: win.season,
                        round: win.round,
                        raceName: win.raceName,
                        driver: driver ? driver.givenName + " " + driver.familyName : ""
                    }
                })
            })
        }
        tryLastWinYear(seasonNow)
        fetch(ergast + "constructors/" + cid + "/constructorStandings.json?limit=100", 30 * day, j => {
            let lastWcc = null
            for (const list of j.MRData.StandingsTable.StandingsLists ?? []) {
                const s = list.ConstructorStandings?.[0]
                if (s?.position !== "1") continue
                const yr = String(list.season)
                if (!lastWcc || yr > lastWcc) lastWcc = yr
            }
            myTeamHistory = Object.assign({}, myTeamHistory, { lastWcc })
        })
        fetch(ergast + "current/constructors/" + cid + "/results.json?limit=30", ttl, j => {
            const season = String(lastRace?.season ?? nextRace?.season ?? "")
            let wins = 0, podiums = 0
            for (const race of j.MRData.RaceTable.Races ?? []) {
                if (season && race.season !== season) continue
                for (const res of race.Results ?? []) {
                    const pos = Number(res.position)
                    if (pos === 1) wins++
                    if (pos <= 3) podiums++
                }
            }
            myTeamHistory = Object.assign({}, myTeamHistory, { seasonWins: wins, seasonPodiums: podiums })
        })
    }

    readonly property string myLastWinTitle: {
        const w = myTeamHistory.lastWin
        return w ? shortName({ raceName: w.raceName }) : "—"
    }

    readonly property string myLastWinSub: {
        const w = myTeamHistory.lastWin
        if (!w) return ""
        const who = w.driver ? w.driver.split(" ").pop() : ""
        return [who, w.season ? "'" + String(w.season).slice(-2) : ""].filter(Boolean).join(" · ")
    }

    property string sessionName: ""
    property var sessionResults: []
    property var weather: null

    function lapTime(s) {
        if (typeof s !== "number") return ""
        const m = Math.floor(s / 60)
        const rest = (s - m * 60).toFixed(3)
        return m > 0 ? m + ":" + (rest < 10 ? "0" : "") + rest : rest
    }

    function refreshSession() {
        fetch(openf1Api + "sessions?meeting_key=latest", raceLive ? 5 * minute : 15 * minute, list => {
            const done = list.filter(s => new Date(s.date_end) < new Date())
                .sort((a, b) => new Date(b.date_start) - new Date(a.date_start))
            const s = done[0]
            if (!s) return
            // Results can be amended for a few hours after a session; after that they're final.
            const settled = Date.now() - new Date(s.date_end) > 6 * hour
            const ttl = settled ? 30 * day : 10 * minute
            fetch(openf1Api + "weather?session_key=" + s.session_key, ttl, samples => {
                if (samples.length) weather = samples[samples.length - 1]
            })
            fetch(openf1Api + "drivers?session_key=" + s.session_key, ttl, drivers => {
                const byNum = {}
                const info = Object.assign({}, root.driverInfo)
                const cache = Object.assign({}, root.headshotCache)
                for (const d of drivers) {
                    byNum[d.driver_number] = d
                    const code = d.name_acronym
                    const shot = d.headshot_url ?? ""
                    info[code] = { colour: d.team_colour ? "#" + d.team_colour : "", headshot: shot, team: d.team_name }
                    if (shot) {
                        cache[headshotCacheKey(code, d.team_name)] = shot
                        cache[code] = shot
                    }
                }
                driverInfo = info
                headshotCache = cache
                fetch(openf1Api + "session_result?session_key=" + s.session_key + "&position%3C=13", ttl, res => {
                    if (!res.length) return
                    sessionName = s.session_name
                    sessionResults = res.slice().sort((a, b) => a.position - b.position).map(r => {
                        const d = byNum[r.driver_number] ?? {}
                        const best = Array.isArray(r.duration) ? r.duration.filter(x => x).slice(-1)[0] : r.duration
                        return {
                            position: r.position,
                            code: d.name_acronym ?? String(r.driver_number),
                            name: d.full_name ?? "",
                            team: d.team_name ?? "",
                            time: r.position === 1 ? lapTime(best) : (Array.isArray(r.gap_to_leader)
                                ? "+" + (r.gap_to_leader.filter(x => x !== null).slice(-1)[0] ?? 0).toFixed(3)
                                : typeof r.gap_to_leader === "number" ? "+" + r.gap_to_leader.toFixed(3) : String(r.gap_to_leader ?? ""))
                        }
                    })
                })
            })
        })
    }

    // ── Helpers ─────────────────────────────────────────────────

    function countdown(target) {
        let s = Math.max(0, Math.floor((target - now) / 1000))
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "m" : m + "m"
    }

    function shortName(race) {
        return race ? race.raceName.replace(" Grand Prix", " GP") : ""
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Timer {
        interval: root.raceLive ? 5 * root.minute : 15 * root.minute
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}

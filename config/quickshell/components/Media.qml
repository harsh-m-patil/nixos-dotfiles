pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris

// Now Playing store and the media island's UI state. Views read the plain
// properties below; `player` is the raw MprisPlayer, used only for actions.
Singleton {
    id: root

    // ── UI state ────────────────────────────────────────────────────────
    property bool open: false
    property string screen: ""
    function toggle(onScreen) {
        if (open && (!onScreen || onScreen === screen)) { open = false; return }
        show(onScreen)
    }
    function show(onScreen) {
        if (!player) return
        screen = onScreen || Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || ""
        open = true
    }
    onPlayerChanged: if (!player) open = false

    // Islands that are peeking or expanded keep the current player (and position polling) alive.
    property var holders: []
    readonly property bool held: open || holders.some(h => h.active)
    function subscribe(x) { holders = holders.concat([x]) }
    function unsubscribe(x) { holders = holders.filter(y => y !== x) }

    // ── Players ─────────────────────────────────────────────────────────
    readonly property var players: (Mpris.players.values ?? []).filter(p => p && p.trackTitle !== "")
    property var pinned: null
    readonly property var playingPlayer: {
        if (pinned && pinned.isPlaying && players.indexOf(pinned) >= 0) return pinned
        return players.find(p => p.isPlaying) ?? null
    }

    // The island shows while something plays, and lingers briefly after a pause so it can be resumed.
    property var player: null
    onPlayingPlayerChanged: {
        if (playingPlayer) { linger.stop(); player = playingPlayer }
        else linger.restart()
    }
    onPlayersChanged: if (player && players.indexOf(player) < 0) player = playingPlayer
    Component.onCompleted: player = playingPlayer

    Timer {
        id: linger
        interval: 20000
        onTriggered: {
            if (root.playingPlayer) return
            if (root.held) restart()
            else root.player = null
        }
    }

    readonly property int index: players.indexOf(player)
    function select(p) { if (p) { pinned = p; player = p; if (!p.isPlaying) linger.restart() } }
    function step(d) {
        if (players.length < 2) return
        select(players[(Math.max(0, index) + d + players.length) % players.length])
    }

    // ── Track ───────────────────────────────────────────────────────────
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle || "Unknown"
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property string app: player?.identity ?? "Media"
    readonly property real length: player?.length ?? 0
    readonly property real position: player?.position ?? 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0
    readonly property bool canSeek: (player?.canSeek ?? false) && length > 0
    readonly property bool shuffleSupported: player?.shuffleSupported ?? false
    readonly property bool shuffle: player?.shuffle ?? false
    readonly property bool loopSupported: player?.loopSupported ?? false
    readonly property int loop: player?.loopState ?? MprisLoopState.None

    // A small accent pulled from the artwork, for the level and progress fill.
    readonly property color accent: {
        const c = quant.item?.colors
        if (!c || c.length === 0) return Theme.iris
        let best = c[0], score = -1
        for (const col of c) {
            const s = col.hsvSaturation * 0.7 + col.hsvValue * 0.3
            if (s > score) { score = s; best = col }
        }
        return Qt.hsva(best.hsvHue, Math.max(0.45, best.hsvSaturation), Math.max(0.75, best.hsvValue), 1)
    }
    LazyLoader {
        id: quant
        active: root.artUrl !== "" && !root.artUrl.startsWith("data:")
        ColorQuantizer { source: root.artUrl; depth: 3; rescaleSize: 48 }
    }

    // ── Actions ─────────────────────────────────────────────────────────
    function togglePlaying() { if (player?.canTogglePlaying) player.togglePlaying() }
    function next() { if (player?.canGoNext) player.next() }
    function previous() { if (player?.canGoPrevious) player.previous() }
    function seekBy(s) { if (canSeek) player.position = Math.max(0, Math.min(length, position + s)) }
    function seekTo(f) { if (canSeek) player.position = length * Math.max(0, Math.min(1, f)) }
    function toggleShuffle() { if (shuffleSupported) player.shuffle = !player.shuffle }
    function cycleLoop() {
        if (!loopSupported) return
        player.loopState = loop === MprisLoopState.None ? MprisLoopState.Playlist
            : loop === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.playing && root.held
        onTriggered: root.player?.positionChanged()
    }

    IpcHandler {
        target: "media"
        function toggle(): void { root.toggle("") }
        function close(): void { root.open = false }
        function playPause(): void { root.togglePlaying() }
        function next(): void { root.next() }
        function previous(): void { root.previous() }
    }
}

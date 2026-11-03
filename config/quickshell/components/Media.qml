pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property var holders: []
    readonly property bool held: holders.some(h => h.active)
    function subscribe(x) { holders = holders.concat([x]) }
    function unsubscribe(x) { holders = holders.filter(y => y !== x) }

    readonly property var livePlayer: {
        const list = Mpris.players.values ?? []
        for (let i = 0; i < list.length; i++)
            if (list[i]?.isPlaying)
                return list[i]
        for (let i = 0; i < list.length; i++)
            if (list[i] && list[i].trackTitle !== "")
                return list[i]
        return null
    }

    property var player: null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real progress: player && player.length > 0
        ? Math.min(1, player.position / player.length) : 0
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property string line: {
        if (!player)
            return ""
        const artist = player.trackArtist || ""
        return (player.trackTitle || "Unknown") + (artist !== "" ? "  ·  " + artist : "")
    }

    onLivePlayerChanged: {
        if (livePlayer) {
            drop.stop()
            player = livePlayer
        } else {
            drop.restart()
        }
    }
    Component.onCompleted: player = livePlayer

    Timer {
        id: drop
        interval: 2500
        onTriggered: {
            if (!root.livePlayer && !root.held)
                root.player = null
            else if (!root.livePlayer)
                restart()
        }
    }

    Timer {
        interval: 500
        repeat: true
        running: root.playing
        onTriggered: root.player?.positionChanged()
    }
}

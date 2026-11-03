import QtQuick
import Quickshell.Services.Mpris

import "."

// Transport: previous · play/pause · next, with shuffle and repeat when `full`.
Row {
    id: controls
    property bool full: false
    spacing: full ? 14 : 6

    MediaButton {
        anchors.verticalCenter: parent.verticalCenter
        visible: controls.full && Media.shuffleSupported
        icon: "󰒟"; iconSize: 15
        accent: Media.shuffle
        onActivated: Media.toggleShuffle()
    }
    MediaButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "󰒮"; iconSize: controls.full ? 20 : 17
        enabled: Media.player?.canGoPrevious ?? false
        onActivated: Media.previous()
    }
    MediaButton {
        anchors.verticalCenter: parent.verticalCenter
        primary: true
        icon: Media.playing ? "󰏤" : "󰐊"
        iconSize: controls.full ? 22 : 17
        size: controls.full ? 50 : 36
        enabled: Media.player?.canTogglePlaying ?? false
        onActivated: Media.togglePlaying()
    }
    MediaButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "󰒭"; iconSize: controls.full ? 20 : 17
        enabled: Media.player?.canGoNext ?? false
        onActivated: Media.next()
    }
    MediaButton {
        anchors.verticalCenter: parent.verticalCenter
        visible: controls.full && Media.loopSupported
        icon: Media.loop === MprisLoopState.Track ? "󰑘" : "󰑖"; iconSize: 15
        accent: Media.loop !== MprisLoopState.None
        onActivated: Media.cycleLoop()
    }
}

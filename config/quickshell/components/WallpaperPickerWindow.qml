import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

import "."

PickerWindow {
    id: win

    open: Theme.wallPickerOpen
    WlrLayershell.namespace: "quickshell-wallpaper-picker"
    maxWidth: 1600
    previewDelay: 260
    deck.model: walls
    deck.cardWidth: 520
    deck.cardHeight: 325
    deck.spread: 150
    deck.Layout.preferredHeight: 380
    deck.card: wallCard
    hints: [["← →", "browse"], ["Enter", "keep"], ["Tab", "teams"], ["Esc", "cancel"]]

    property string originalPath: ""
    readonly property var team: Theme.current
    readonly property var walls: WallpaperData.poolPaths(team?.wallpaper?.pool ?? "")
    readonly property string selected: walls[currentIndex] ?? ""

    function fileName(p) {
        return p ? p.slice(p.lastIndexOf("/") + 1) : ""
    }

    function syncIndex() {
        currentIndex = Math.max(0, walls.indexOf(WallpaperData.current))
    }

    onWallsChanged: if (visible && !previewPending) syncIndex()

    onOpened: {
        originalPath = WallpaperData.current
        syncIndex()
    }

    onPreviewRequested: {
        if (selected && selected !== WallpaperData.current)
            Theme.setWallpaperPath(selected, true)
    }

    onCancelled: {
        if (originalPath && WallpaperData.current !== originalPath)
            Theme.setWallpaperPath(originalPath, true)
        Theme.wallPickerOpen = false
    }

    onCommitted: {
        if (selected)
            Theme.setWallpaperPath(selected)
        Theme.wallPickerOpen = false
    }

    onExtraKey: event => {
        const k = event.key
        if (k !== Qt.Key_Tab && k !== Qt.Key_Backtab && k !== Qt.Key_T)
            return
        stopPreview()
        Theme.openPicker()
        event.accepted = true
    }

    Text {
        visible: win.walls.length === 0
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: 380
        verticalAlignment: Text.AlignVCenter
        text: WallpaperData.pools && Object.keys(WallpaperData.pools).length === 0
            ? "Loading wallpapers…"
            : "No wallpapers for " + (win.team?.name ?? "this theme")
        color: "#ffffff"
        font.family: Theme.displayFont
        font.pixelSize: 18
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 10
        Image {
            visible: status === Image.Ready
            Layout.preferredHeight: 26
            Layout.preferredWidth: 26 * implicitWidth / Math.max(1, implicitHeight)
            source: TeamAssets.themeLogo(win.team)
            fillMode: Image.PreserveAspectFit
            mipmap: true
        }
        Text {
            text: win.team?.f1?.constructor ?? win.team?.name ?? ""
            color: "#ffffff"
            font.family: Theme.displayFont
            font.pixelSize: 24
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.55)
            font.weight: Font.Bold
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: win.walls.length > 0
        text: (win.currentIndex + 1) + " / " + win.walls.length + "  ·  " + win.fileName(win.selected)
        color: Qt.rgba(1, 1, 1, 0.6)
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    Component {
        id: wallCard

        Rectangle {
            readonly property string path: parent ? parent.modelData : ""
            readonly property bool current: parent ? parent.isCurrent : false

            radius: 16
            color: Theme.surface
            border.width: current ? 3 : 1
            border.color: current ? "#ffffff" : Qt.rgba(1, 1, 1, 0.12)

            Image {
                anchors.fill: parent
                anchors.margins: parent.border.width
                source: WallpaperData.pathToUrl(parent.path)
                sourceSize.width: 1040
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
    }
}

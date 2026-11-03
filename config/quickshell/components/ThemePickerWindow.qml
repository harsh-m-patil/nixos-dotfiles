import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

import "."

PickerWindow {
    id: win

    open: Theme.pickerOpen
    WlrLayershell.namespace: "quickshell-theme-picker"
    deck.model: themes
    deck.cardWidth: 260
    deck.cardHeight: 360
    deck.card: teamCard
    hints: [["← →", "browse"], ["Enter", "apply"], ["Tab", "wallpapers"],
        ["C", classic ? "F1 teams" : "classic themes"], ["Esc", "cancel"]]

    property string originalId: ""
    property string originalWall: ""
    property bool classic: false
    readonly property var themes: Theme.catalog.filter(t => !!t.f1 !== classic)
    readonly property var selected: themes[currentIndex] ?? null

    function setClassic(on) {
        const keep = selected?.id
        classic = on
        const i = themes.findIndex(t => t.id === keep || t.id === Theme.activeId)
        currentIndex = Math.max(0, i)
        previewSoon()
    }

    function preview(t) {
        if (!t)
            return
        if (t.id !== Theme.activeId)
            Theme.setThemeAccentsOnly(t.id)
        const wall = WallpaperData.paths[t.id] ?? ""
        if (wall && wall !== WallpaperData.current)
            Theme.setWallpaperPath(wall, true)
    }

    function toWallpapers() {
        stopPreview()
        const t = selected
        if (t && t.id !== Theme.activeId)
            Theme.setThemeAccentsOnly(t.id)
        Theme.openWallPicker()
    }

    onOpened: {
        originalId = Theme.activeId
        originalWall = WallpaperData.current
        classic = !Theme.current.f1
        currentIndex = Math.max(0, themes.findIndex(t => t.id === Theme.activeId))
    }

    onPreviewRequested: preview(selected)

    onCancelled: {
        if (originalId && Theme.activeId !== originalId)
            Theme.setThemeAccentsOnly(originalId)
        if (originalWall && WallpaperData.current !== originalWall)
            Theme.setWallpaperPath(originalWall, true)
        Theme.pickerOpen = false
    }

    onCommitted: {
        const t = selected
        if (t && t.id !== originalId) {
            if (WallpaperData.paths[t.id])
                preview(t)
            else
                Theme.setTheme(t.id)
        }
        if (t)
            Theme.notifyTheme(t)
        Theme.pickerOpen = false
    }

    onExtraKey: event => {
        const k = event.key
        if (k === Qt.Key_Backtab)
            deck.step(-1)
        else if (k === Qt.Key_Tab || k === Qt.Key_W)
            toWallpapers()
        else if (k === Qt.Key_C)
            setClassic(!classic)
        else
            return
        event.accepted = true
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: win.selected?.f1?.constructor ?? win.selected?.name ?? ""
        color: "#ffffff"
        font.family: Theme.displayFont
        font.pixelSize: 26
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.55)
        font.weight: Font.Bold
    }

    Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: 6
        Repeater {
            model: ["iris", "foam", "pine", "gold", "love", "rose"]
            Rectangle {
                required property string modelData
                width: 12
                height: 12
                radius: 6
                color: win.selected?.colors?.[modelData] ?? "#888888"
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: (win.currentIndex + 1) + " / " + win.themes.length
            + (win.selected?.id === win.originalId ? "  ·  current" : "")
        color: Qt.rgba(1, 1, 1, 0.55)
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    Component {
        id: teamCard

        Rectangle {
            id: cardRoot
            readonly property var t: parent ? parent.modelData : null
            readonly property bool current: parent ? parent.isCurrent : false
            readonly property var c: t?.colors ?? {}
            readonly property color primary: Qt.color(t?.f1?.primary ?? c.iris ?? "#c4a7e7")
            readonly property string logo: TeamAssets.themeLogo(t)

            radius: 16
            clip: true
            color: c.background ?? "#191724"
            border.width: current ? 2 : 1
            border.color: current ? primary : Qt.rgba(1, 1, 1, 0.1)

            Rectangle {
                visible: !!cardRoot.t?.f1
                anchors.fill: parent
                anchors.margins: cardRoot.border.width
                radius: cardRoot.radius - 2
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.alpha(cardRoot.primary, 0.42) }
                    GradientStop { position: 0.6; color: Theme.alpha(cardRoot.primary, 0.08) }
                    GradientStop { position: 1; color: "transparent" }
                }
            }

            Rectangle {
                visible: !!cardRoot.t?.f1
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 14
                width: 48
                height: 4
                radius: 2
                color: cardRoot.primary
            }

            Image {
                id: logoImg
                visible: !!cardRoot.t?.f1 && status === Image.Ready
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -24
                width: parent.width - 64
                height: 120
                source: cardRoot.logo
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                mipmap: true
            }

            Text {
                visible: !!cardRoot.t?.f1 && !logoImg.visible
                anchors.centerIn: logoImg
                width: logoImg.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: cardRoot.t?.f1?.constructor ?? ""
                color: "#ffffff"
                font.family: Theme.displayFont
                font.pixelSize: 26
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.55)
                font.weight: Font.Black
            }

            Column {
                visible: !cardRoot.t?.f1
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -24
                spacing: 9
                Repeater {
                    model: [
                        [["iris", 54], ["foreground", 90]],
                        [["foam", 36], ["gold", 64], ["foreground", 40]],
                        [["love", 70], ["subtle", 76]],
                        [["pine", 40], ["rose", 58], ["muted", 60]]
                    ]
                    Row {
                        required property var modelData
                        required property int index
                        x: index % 2 ? 16 : 0
                        spacing: 7
                        Repeater {
                            model: parent.modelData
                            Rectangle {
                                required property var modelData
                                width: modelData[1]
                                height: 8
                                radius: 4
                                color: cardRoot.c[modelData[0]] ?? "#888888"
                            }
                        }
                    }
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 18
                spacing: 3

                Text {
                    width: parent.width
                    text: cardRoot.t?.f1?.constructor ?? cardRoot.t?.name ?? ""
                    color: cardRoot.t?.f1 ? "#ffffff" : (cardRoot.c.foreground ?? "#e0def4")
                    font.family: Theme.displayFont
                    font.pixelSize: 17
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                Text {
                    text: cardRoot.t?.f1 ? "Formula 1 · " + (cardRoot.t.f1.season ?? "") : "Classic"
                    color: cardRoot.t?.f1 ? Qt.rgba(1, 1, 1, 0.7) : (cardRoot.c.muted ?? "#6e6a86")
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }
    }
}

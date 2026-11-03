import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "."

// The Now Playing island. The bar only holds a placeholder; the shape lives in an
// overlay surface so it can morph in place:
//   compact  artwork thumb, title and a live level meter
//   peek     hover, or a few seconds after the track changes
//   full     click (or `qs ipc call media toggle`): artwork, seek, transport, players
// Hidden entirely when nothing is playing.
Item {
    id: root

    visible: Media.player !== null
    implicitWidth: compact.implicitWidth + 20
    implicitHeight: 28

    readonly property var barWindow: QsWindow.window
    readonly property string screenName: barWindow?.screen?.name ?? ""
    readonly property point origin: {
        void x; void width; void parent?.x; void parent?.parent?.x; void parent?.parent?.width
        const p = mapToItem(null, 0, 0)
        return Qt.point(p.x + (barWindow?.margins?.left ?? 0), p.y + (barWindow?.margins?.top ?? 0))
    }

    property bool hoverPeek: false
    readonly property bool full: Media.open && Media.screen === screenName
    readonly property string state_: full ? "full" : hoverPeek || alert.running ? "peek" : "compact"
    onState_Changed: if (state_ === "compact") settle.restart()
    Timer { id: settle; interval: 450 }

    Timer { id: alert; interval: 6000 }
    Timer { id: intent; interval: 180; onTriggered: root.hoverPeek = true }
    Timer { id: leave; interval: 280; onTriggered: root.hoverPeek = false }

    Connections {
        target: Media
        function onTitleChanged() { if (Media.playing && root.visible) alert.restart() }
    }

    MediaHold { active: root.state_ !== "compact" }

    PanelWindow {
        id: win
        screen: root.barWindow?.screen ?? null
        visible: root.visible && (root.barWindow?.visible ?? true)
        color: "transparent"
        WlrLayershell.namespace: "quickshell-media"
        // Expanded islands sit above their neighbours' pills; drop back once the collapse settles.
        WlrLayershell.layer: root.state_ !== "compact" || settle.running ? WlrLayer.Overlay : WlrLayer.Top
        WlrLayershell.keyboardFocus: root.full ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        IslandClickMask {
            id: clickMask
            panel: win
            fullScreen: root.full
            shape: shape
        }
        mask: clickMask

        Connections {
            target: shape
            function onXChanged() { clickMask.changed() }
            function onYChanged() { clickMask.changed() }
            function onWidthChanged() { clickMask.changed() }
            function onHeightChanged() { clickMask.changed() }
            function onRadiusChanged() { clickMask.changed() }
        }

        readonly property size peekSize: Qt.size(560, peek.implicitHeight + 40)
        readonly property size fullSize: Qt.size(Math.min(width - 16, 780),
            Math.min(height - 48, 680, (expandedLoader.item?.implicitHeight ?? 340) + 42))

        IslandBackdrop {
            id: backdrop
            active: root.full
            shape: shape
            onDismissed: Media.open = false
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: e => e.accepted = root.full && expandedLoader.item && expandedLoader.item.handleKey(e)
        }
        Connections {
            target: root
            function onFullChanged() { if (root.full) keys.forceActiveFocus() }
        }

        RectangularShadow {
            anchors.fill: shape
            radius: shape.radius
            blur: 36
            offset.y: 10
            spread: -4
            color: Qt.rgba(0, 0, 0, 0.4)
            opacity: root.state_ === "compact" ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 240 } }
        }

        Rectangle {
            id: shape
            z: root.full ? 100 : 0
            readonly property real cx: root.origin.x + root.width / 2
            readonly property real tw: root.state_ === "full" ? win.fullSize.width : root.state_ === "peek" ? win.peekSize.width : root.width
            readonly property real th: root.state_ === "full" ? win.fullSize.height : root.state_ === "peek" ? win.peekSize.height : 28

            x: root.state_ === "compact" ? root.origin.x : Math.max(8, Math.min(win.width - tw - 8, cx - tw / 2))
            y: root.origin.y
            width: tw
            height: th
            radius: root.state_ === "compact" ? 14 : 30
            color: F1Hub.surface
            border.width: 1
            border.color: F1Hub.hairline
            clip: true

            Behavior on x { SpringAnimation { spring: 3.4; damping: 0.3; epsilon: 0.3 } }
            Behavior on width { SpringAnimation { spring: 3.4; damping: 0.3; epsilon: 0.3 } }
            Behavior on height { SpringAnimation { spring: 3.4; damping: 0.32; epsilon: 0.3 } }
            Behavior on radius { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }

            HoverHandler {
                cursorShape: root.full ? Qt.ArrowCursor : Qt.PointingHandCursor
                onHoveredChanged: {
                    if (hovered) { leave.stop(); intent.restart() }
                    else { intent.stop(); leave.restart() }
                }
            }
            TapHandler {
                enabled: root.state_ === "compact"
                onTapped: Media.toggle(root.screenName)
            }
            WheelHandler {
                enabled: root.state_ === "compact"
                onWheel: e => Media.seekBy(e.angleDelta.y > 0 ? 5 : -5)
            }

            // Compact: artwork leading, title, level trailing.
            RowLayout {
                id: compact
                x: (shape.width - width) / 2
                height: 28
                spacing: 8
                visible: root.state_ === "compact"
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }

                MediaArt { Layout.preferredWidth: 20; Layout.preferredHeight: 20; radius: 6 }
                F1Text {
                    Layout.maximumWidth: 200
                    text: Media.title
                    role: "callout"
                    font.weight: Font.DemiBold
                    tone: Media.playing ? "primary" : "secondary"
                }
                MediaLevel { maxHeight: 12; barWidth: 2.5; visible: compact.opacity > 0.01 }
            }

            MediaCard {
                id: peek
                z: 2
                x: (shape.width - width) / 2
                y: 20
                width: win.peekSize.width - 44
                opacity: root.state_ === "peek" ? 1 : 0
                scale: root.state_ === "peek" ? 1 : 0.94
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: root.state_ === "peek" ? 260 : 120; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
                onOpenRequested: Media.show(root.screenName)
            }

            // Built on first open, then kept warm.
            Loader {
                id: expandedLoader
                z: root.full ? 0 : -1
                x: (shape.width - width) / 2
                y: 22
                width: win.fullSize.width - 44
                property bool warm: false
                active: root.full || warm
                onLoaded: warm = true
                opacity: root.full ? 1 : 0
                scale: root.full ? 1 : 0.94
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: root.full ? 320 : 120; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }
                sourceComponent: MediaExpanded {}
            }
        }
    }
}

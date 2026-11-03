import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "."

// The status island. A bar placeholder; the shape lives in an overlay surface and morphs:
//   compact  radios and volume as glyphs, battery and CPU as figures
//   peek     hover, or a few seconds after a volume change or low battery
//   full     Control Center (click, or `qs ipc call status toggle`)
Item {
    id: root

    implicitWidth: compact.implicitWidth + 26
    implicitHeight: 28

    readonly property var barWindow: QsWindow.window
    readonly property string screenName: barWindow?.screen?.name ?? ""
    readonly property point origin: {
        void x; void width; void parent?.x; void parent?.parent?.x; void parent?.parent?.width
        const p = mapToItem(null, 0, 0)
        return Qt.point(p.x + (barWindow?.margins?.left ?? 0), p.y + (barWindow?.margins?.top ?? 0))
    }

    property bool hoverPeek: false
    readonly property bool full: StatusData.open && StatusData.screen === screenName
    readonly property string state_: full ? "full" : hoverPeek || alert.running ? "peek" : "compact"
    onState_Changed: if (state_ === "compact") settle.restart()
    Timer { id: settle; interval: 450 }

    SystemSampler { active: true; detailed: root.full }

    Timer { id: alert; interval: 6000 }
    Timer { id: intent; interval: 180; onTriggered: root.hoverPeek = true }
    Timer { id: leave; interval: 280; onTriggered: root.hoverPeek = false }
    Timer { id: settling; interval: 3000; running: true }

    function volumeAlert() { if (!settling.running && !root.full && !root.hoverPeek) alert.restart() }
    Connections {
        target: StatusData
        function onVolumeChanged() { root.volumeAlert() }
        function onMutedChanged() { root.volumeAlert() }
        function onBatteryLowChanged() { if (StatusData.batteryLow) alert.restart() }
    }

    PanelWindow {
        id: win
        screen: root.barWindow?.screen ?? null
        visible: root.barWindow?.visible ?? true
        color: "transparent"
        WlrLayershell.namespace: "quickshell-status"
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

        readonly property int peekPadH: 14
        readonly property int peekPadV: 12
        readonly property size peekSize: Qt.size(
            Math.min(width - 16, Math.max(268, peek.implicitWidth + peekPadH * 2)),
            peek.implicitHeight + peekPadV * 2 + 6)
        readonly property size fullSize: Qt.size(Math.min(width - 16, 620),
            Math.min(height - 48, 720, (panelLoader.item?.implicitHeight ?? 640) + 36))

        IslandBackdrop {
            id: backdrop
            active: root.full
            shape: shape
            onDismissed: StatusData.open = false
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: e => e.accepted = root.full && panelLoader.item && panelLoader.item.handleKey(e)
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
            radius: root.state_ === "compact" ? 14 : root.state_ === "peek" ? 20 : 26
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
                onTapped: StatusData.toggle(root.screenName)
            }
            WheelHandler {
                enabled: root.state_ === "compact"
                onWheel: e => StatusData.setVolume(StatusData.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05))
            }

            // Compact: what's connected on the left, what's draining on the right.
            RowLayout {
                id: compact
                x: (shape.width - width) / 2
                height: 28
                spacing: 9
                visible: root.state_ === "compact"
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }

                component Glyph: Text {
                    color: F1Hub.ink2
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                }

                Row {
                    spacing: 8
                    Glyph { text: StatusData.wifiIcon; color: StatusData.wifiConnected ? F1Hub.ink : F1Hub.ink3 }
                    Glyph { visible: StatusData.btConnected.length > 0; text: "󰂱" }
                    Glyph { text: StatusData.volumeIcon; color: StatusData.muted ? F1Hub.ink3 : F1Hub.ink }
                    Glyph { visible: StatusData.micMuted; text: "󰍭"; color: Theme.love }
                }
                Rectangle { implicitWidth: 1; implicitHeight: 12; color: F1Hub.fillStrong }
                Row {
                    visible: StatusData.hasBattery
                    spacing: 4
                    Glyph {
                        anchors.verticalCenter: parent.verticalCenter
                        text: StatusData.batteryIcon
                        color: StatusData.batteryLow ? Theme.love : StatusData.charging ? Theme.foam : F1Hub.ink2
                    }
                    F1Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(StatusData.batteryLevel * 100) + "%"
                        role: "callout"; numeric: true; font.weight: Font.DemiBold
                        color: StatusData.batteryLow ? Theme.love : F1Hub.ink
                    }
                }
                F1Text {
                    text: "CPU " + Math.round(SystemData.cpu * 100) + "%"
                    role: "callout"; numeric: true
                    tone: "secondary"
                    color: SystemData.cpu > 0.85 ? Theme.love : F1Hub.ink2
                }
            }

            // Peek: levels at a glance.
            StatusPeek {
                id: peek
                z: 2
                x: (shape.width - width) / 2
                y: win.peekPadV
                width: implicitWidth
                opacity: root.state_ === "peek" ? 1 : 0
                scale: root.state_ === "peek" ? 1 : 0.94
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: root.state_ === "peek" ? 260 : 120; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
                onOpenRequested: {
                    StatusData.screen = root.screenName
                    StatusData.open = true
                }
            }

            // Full: Control Center. Built on first open, then kept warm.
            Loader {
                id: panelLoader
                z: root.full ? 0 : -1
                x: (shape.width - width) / 2
                y: win.peekPadV
                width: win.fullSize.width - win.peekPadH * 2
                property bool warm: false
                active: root.full || warm
                onLoaded: warm = true
                opacity: root.full ? 1 : 0
                scale: root.full ? 1 : 0.96
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: root.full ? 320 : 120; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }
                sourceComponent: StatusPanel {}
            }
        }
    }
}

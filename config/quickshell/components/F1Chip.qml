import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "."

// The F1 island. In the bar it's only a placeholder; the black shape lives in an
// overlay surface so it can morph in place between three states:
//   compact  what matters right now (next session, live timer, podium)
//   peek     hover, or a few seconds after a session goes live or results land
//   full     the keyboard-driven hub (click, or `qs ipc call f1 toggle`)
Item {
    id: root

    visible: F1Data.ready
    implicitWidth: compact.implicitWidth + 26
    implicitHeight: 28

    readonly property var barWindow: QsWindow.window
    readonly property string screenName: barWindow?.screen?.name ?? ""
    readonly property point origin: {
        void BarLayout.tick
        void barWindow?.visible
        void x; void y; void width; void height
        void parent?.x; void parent?.parent?.x; void parent?.parent?.width
        return BarLayout.islandOrigin(root, barWindow)
    }

    property bool hoverPeek: false

    onHoverPeekChanged: hoverPeek ? Motion.claim(root) : Motion.unclaim(root)
    readonly property bool full: F1Hub.open && F1Hub.screen === screenName
    readonly property string state_: full ? "full" : hoverPeek || alert.running ? "peek" : "compact"
    onState_Changed: if (state_ === "compact") settle.restart()
    Timer { id: settle; interval: 450 }

    Timer { id: alert; interval: 6000 }
    Timer { id: intent; interval: Motion.instantFor(root) ? 0 : 180; onTriggered: root.hoverPeek = true }
    Timer { id: leave; interval: 280; onTriggered: { root.hoverPeek = false; Motion.release() } }

    Connections {
        target: F1Data
        function onModeChanged() {
            if (F1Data.mode === "live" || F1Data.mode === "result") alert.restart()
        }
    }

    PanelWindow {
        id: win
        screen: root.barWindow?.screen ?? null
        visible: root.visible && (root.barWindow?.visible ?? false)
        color: "transparent"
        WlrLayershell.namespace: "quickshell-f1"
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
        readonly property size fullSize: Qt.size(Math.min(width - 16, 860), Math.min(height - 48, 680))

        IslandBackdrop {
            id: backdrop
            active: root.full
            shape: shape
            onDismissed: F1Hub.open = false
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: e => e.accepted = root.full && hubLoader.item && hubLoader.item.handleKey(e)
        }
        Connections {
            target: root
            function onFullChanged() { if (root.full) keys.forceActiveFocus() }
        }

        Stagger { target: peek; active: root.state_ === "peek" }


        RectangularShadow {
            anchors.fill: shape
            radius: shape.radius
            blur: 36
            offset.y: 10
            spread: -4
            color: Qt.rgba(0, 0, 0, 0.4)
            opacity: root.state_ === "compact" ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: root.state_ === "compact" ? 120 : 180; easing.type: Easing.OutCubic } }
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
            radius: Motion.radius(height, 14)
            color: Motion.islandFill(root.state_ === "compact")
            border.width: 1
            border.color: F1Hub.hairline
            clip: true
            scale: press.pressed ? 0.97 : 1
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

            Behavior on x { enabled: !Motion.reduced; SpringAnimation { spring: Motion.spring(root.state_); damping: Motion.damping(root.state_); epsilon: 0.3 } }
            Behavior on width { enabled: !Motion.reduced; SpringAnimation { spring: Motion.spring(root.state_); damping: Motion.damping(root.state_); epsilon: 0.3 } }
            Behavior on height { enabled: !Motion.reduced; SpringAnimation { spring: Motion.spring(root.state_); damping: Motion.damping(root.state_); epsilon: 0.3 } }

            HoverHandler {
                cursorShape: root.full ? Qt.ArrowCursor : Qt.PointingHandCursor
                onHoveredChanged: {
                    if (hovered) { leave.stop(); intent.restart() }
                    else { intent.stop(); leave.restart() }
                }
            }
            TapHandler {
                id: press
                enabled: root.state_ === "compact"
                onTapped: F1Hub.toggle(root.screenName)
            }

            // Compact: leading label, trailing figure — like a Live Activity.
            RowLayout {
                id: compact
                x: (shape.width - width) / 2
                height: 28
                spacing: 9
                opacity: root.state_ === "compact" ? 1 : 0
                visible: opacity > 0.01
                // Returns once the collapse is under way, so it lands in a pill-sized shape.
                Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.state_ === "compact" ? 50 : 0 } NumberAnimation { duration: root.state_ === "compact" ? 130 : 80; easing.type: Easing.OutCubic } } }

                readonly property string mode: F1Data.mode
                readonly property string label: mode === "live" ? F1Data.liveSession.label
                    : mode === "result" ? F1Data.session.short
                    : mode === "idle" ? (F1Data.weekend?.short ?? "F1")
                    : F1Data.nextSession?.label ?? "F1"
                readonly property string detail: mode === "live" ? F1Data.elapsed(F1Data.liveSession.start)
                    : mode === "result" ? ""
                    : mode === "idle" ? (F1Data.weekend ? F1Data.countdown(F1Data.weekend.sessions[0].start) : "")
                    : F1Data.nextSession ? F1Data.countdown(F1Data.nextSession.start) : ""

                Rectangle {
                    visible: compact.mode === "live"
                    implicitWidth: 7; implicitHeight: 7; radius: 3.5
                    color: Theme.love
                    SequentialAnimation on opacity {
                        running: compact.mode === "live" && !Motion.reduced
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
                    }
                }
                F1Text {
                    text: compact.label
                    role: "callout"
                    font.weight: Font.DemiBold
                    color: compact.mode === "live" ? Theme.love : F1Hub.ink
                }
                F1Text {
                    visible: text !== ""
                    text: compact.detail
                    role: "callout"
                    tone: compact.mode === "soon" ? "primary" : "secondary"
                    numeric: true
                }
                Repeater {
                    model: compact.mode === "result" ? (F1Data.session?.results ?? []).slice(0, 3) : []
                    Row {
                        required property var modelData
                        spacing: 4
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 6; height: 6; radius: 3; color: F1Data.teamColour(modelData.team) }
                        F1Text { text: modelData.code; role: "callout"; numeric: true; font.weight: Font.DemiBold }
                    }
                }
            }

            F1Peek {
                id: peek
                z: 2
                x: (shape.width - width) / 2
                y: win.peekPadV
                width: implicitWidth
                transformOrigin: Item.Top
                opacity: root.state_ === "peek" ? 1 : 0
                scale: root.state_ === "peek" ? 1 : Motion.contentHiddenScale
                visible: opacity > 0.01
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: root.state_ === "peek" ? 40 : 0 }
                        NumberAnimation {
                            duration: root.state_ === "peek" ? Motion.contentFadeInMs : Motion.contentFadeOutMs
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                Behavior on scale {
                    enabled: Motion.contentScaleAnim
                    NumberAnimation { duration: Motion.contentScaleMs; easing.type: Easing.OutQuint }
                }
                onOpenRequested: F1Hub.show(undefined, root.screenName)
            }

            // Full: the hub. Built on first open, then kept warm.
            Loader {
                id: hubLoader
                z: root.full ? 0 : -1
                x: (shape.width - width) / 2
                width: win.fullSize.width
                height: win.fullSize.height
                property bool warm: false
                active: root.full || warm
                onLoaded: warm = true
                transformOrigin: Item.Top
                opacity: root.full ? 1 : 0
                scale: root.full ? 1 : Motion.contentHiddenScale
                visible: opacity > 0.01
                Behavior on opacity {
                    NumberAnimation {
                        duration: root.full ? (Motion.reduced ? 160 : 240) : Motion.contentFadeOutMs
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    enabled: Motion.contentScaleAnim
                    NumberAnimation { duration: Motion.contentScaleMs + 40; easing.type: Easing.OutQuint }
                }
                sourceComponent: F1HubContent {
                    anchors.fill: parent
                    anchors.margins: 22
                    anchors.topMargin: 20
                }
            }
        }
    }
}

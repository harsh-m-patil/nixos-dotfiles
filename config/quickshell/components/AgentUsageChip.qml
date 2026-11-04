import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "."

// The agent usage island. The bar holds a placeholder; the shape lives in an overlay
// surface and morphs in place:
//   compact  limit ring + today's spend
//   peek     hover, or a few seconds after the tightest limit crosses 35% / 15% left
//   full     models, days and limits (click, or `qs ipc call agentUsage toggle`)
Item {
    id: root

    implicitWidth: compact.implicitWidth + 24
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
    readonly property bool full: AgentUsageData.open && AgentUsageData.screen === screenName
    readonly property string state_: full ? "full" : hoverPeek || alert.running ? "peek" : "compact"
    onState_Changed: if (state_ === "compact") settle.restart()
    Timer { id: settle; interval: 450 }

    Timer { id: alert; interval: 6000 }
    Timer { id: intent; interval: Motion.instantFor(root) ? 0 : 180; onTriggered: root.hoverPeek = true }
    Timer { id: leave; interval: 280; onTriggered: { root.hoverPeek = false; Motion.release() } }

    readonly property int band: {
        const t = AgentUsageData.tightest
        return !t ? 0 : t.left <= 15 ? 2 : t.left <= 35 ? 1 : 0
    }
    onBandChanged: if (band > 0 && AgentUsageData.ready) { alert.restart(); if (!Motion.reduced) alertPulse.restart() }

    PanelWindow {
        id: win
        screen: root.barWindow?.screen ?? null
        visible: root.visible && (root.barWindow?.visible ?? false)
        color: "transparent"
        WlrLayershell.namespace: "quickshell-agent-usage"
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
        readonly property size fullSize: Qt.size(Math.min(width - 16, 720), Math.min(height - 48, [480, 450, 360][AgentUsageData.page]))

        IslandBackdrop {
            id: backdrop
            active: root.full
            shape: shape
            onDismissed: AgentUsageData.open = false
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
            // The island opened by itself; a pulse of the limit's colour says why.
            Rectangle {
                id: alertRing
                z: 3
                anchors.fill: parent
                radius: shape.radius
                color: "transparent"
                border.width: 1.5
                border.color: AgentUsageData.accent
                opacity: 0
            }
            SequentialAnimation {
                id: alertPulse
                loops: 2
                PauseAnimation { duration: 200 }
                NumberAnimation { target: alertRing; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { target: alertRing; property: "opacity"; to: 0; duration: 520; easing.type: Easing.OutCubic }
            }

            TapHandler {
                id: press
                enabled: root.state_ === "compact"
                onTapped: AgentUsageData.toggle(root.screenName)
            }

            // Compact: how close the tightest limit is, and what today cost.
            RowLayout {
                id: compact
                x: (shape.width - width) / 2
                height: 28
                spacing: 8
                opacity: root.state_ === "compact" ? 1 : 0
                visible: opacity > 0.01
                // Returns once the collapse is under way, so it lands in a pill-sized shape.
                Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.state_ === "compact" ? 50 : 0 } NumberAnimation { duration: root.state_ === "compact" ? 130 : 80; easing.type: Easing.OutCubic } } }

                AgentUsageRing {
                    visible: AgentUsageData.tightest !== null
                    value: AgentUsageData.tightest ? AgentUsageData.tightest.used / 100 : 0
                    accent: AgentUsageData.accent
                }
                F1Text {
                    visible: AgentUsageData.tightest === null
                    text: "Agents"
                    role: "callout"
                    font.weight: Font.DemiBold
                }
                F1Text {
                    text: AgentUsageData.ready ? Fmt.usd(AgentUsageData.today.cost) : "…"
                    role: "callout"
                    numeric: true
                    font.weight: Font.DemiBold
                    color: root.band === 2 ? Theme.love : F1Hub.ink
                }
            }

            AgentUsagePeek {
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
                onOpenRequested: AgentUsageData.show(root.screenName)
            }

            // Full: built on first open, then kept warm.
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
                sourceComponent: AgentUsageContent {
                    anchors.fill: parent
                    anchors.margins: 16
                    anchors.topMargin: 14
                }
            }
        }
    }
}

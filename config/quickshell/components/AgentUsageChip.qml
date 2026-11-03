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
        void x; void width; void parent?.x; void parent?.parent?.x; void parent?.parent?.width
        const p = mapToItem(null, 0, 0)
        return Qt.point(p.x + (barWindow?.margins?.left ?? 0), p.y + (barWindow?.margins?.top ?? 0))
    }

    property bool hoverPeek: false
    readonly property bool full: AgentUsageData.open && AgentUsageData.screen === screenName
    readonly property string state_: full ? "full" : hoverPeek || alert.running ? "peek" : "compact"
    onState_Changed: if (state_ === "compact") settle.restart()
    Timer { id: settle; interval: 450 }

    Timer { id: alert; interval: 6000 }
    Timer { id: intent; interval: 180; onTriggered: root.hoverPeek = true }
    Timer { id: leave; interval: 280; onTriggered: root.hoverPeek = false }

    readonly property int band: {
        const t = AgentUsageData.tightest
        return !t ? 0 : t.left <= 15 ? 2 : t.left <= 35 ? 1 : 0
    }
    onBandChanged: if (band > 0 && AgentUsageData.ready) alert.restart()

    PanelWindow {
        id: win
        screen: root.barWindow?.screen ?? null
        visible: root.visible && (root.barWindow?.visible ?? true)
        color: "transparent"
        WlrLayershell.namespace: "quickshell-agent-usage"
        // Expanded islands sit above their neighbours' pills; drop back once the collapse settles.
        WlrLayershell.layer: root.state_ !== "compact" || settle.running ? WlrLayer.Overlay : WlrLayer.Top
        WlrLayershell.keyboardFocus: root.full ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        mask: Region { item: root.full ? backdrop : shape }

        readonly property size peekSize: Qt.size(560, peek.implicitHeight + 40)
        readonly property size fullSize: Qt.size(Math.min(width - 16, 820), Math.min(height - 48, [600, 520, 430][AgentUsageData.page]))

        Rectangle {
            id: backdrop
            anchors.fill: parent
            color: "transparent"
            TapHandler { onTapped: AgentUsageData.open = false }
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
                enabled: !root.full
                onTapped: AgentUsageData.toggle(root.screenName)
            }

            // Compact: how close the tightest limit is, and what today cost.
            RowLayout {
                id: compact
                x: (shape.width - width) / 2
                height: 28
                spacing: 8
                opacity: root.state_ === "compact" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }

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
                x: (shape.width - width) / 2
                y: 20
                width: win.peekSize.width - 44
                opacity: root.state_ === "peek" ? 1 : 0
                scale: root.state_ === "peek" ? 1 : 0.94
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: root.state_ === "peek" ? 280 : 120; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
                onOpenRequested: AgentUsageData.show(root.screenName)
            }

            // Full: built on first open, then kept warm.
            Loader {
                id: hubLoader
                x: (shape.width - width) / 2
                width: win.fullSize.width
                height: win.fullSize.height
                property bool warm: false
                active: root.full || warm
                onLoaded: warm = true
                opacity: root.full ? 1 : 0
                scale: root.full ? 1 : 0.94
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: root.full ? 320 : 120; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }
                sourceComponent: AgentUsageContent {
                    anchors.fill: parent
                    anchors.margins: 22
                    anchors.topMargin: 20
                }
            }
        }
    }
}

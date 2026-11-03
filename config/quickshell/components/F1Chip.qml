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
        void x; void width; void parent?.x; void parent?.parent?.x; void parent?.parent?.width
        const p = mapToItem(null, 0, 0)
        return Qt.point(p.x + (barWindow?.margins?.left ?? 0), p.y + (barWindow?.margins?.top ?? 0))
    }

    property bool hoverPeek: false
    readonly property bool full: F1Hub.open && F1Hub.screen === screenName
    readonly property string state_: full ? "full" : hoverPeek || alert.running ? "peek" : "compact"
    onState_Changed: if (state_ === "compact") settle.restart()
    Timer { id: settle; interval: 450 }

    Timer { id: alert; interval: 6000 }
    Timer { id: intent; interval: 180; onTriggered: root.hoverPeek = true }
    Timer { id: leave; interval: 280; onTriggered: root.hoverPeek = false }

    Connections {
        target: F1Data
        function onModeChanged() {
            if (F1Data.mode === "live" || F1Data.mode === "result") alert.restart()
        }
    }

    PanelWindow {
        id: win
        screen: root.barWindow?.screen ?? null
        visible: root.visible && (root.barWindow?.visible ?? true)
        color: "transparent"
        WlrLayershell.namespace: "quickshell-f1"
        // Expanded islands sit above their neighbours' pills; drop back once the collapse settles.
        WlrLayershell.layer: root.state_ !== "compact" || settle.running ? WlrLayer.Overlay : WlrLayer.Top
        WlrLayershell.keyboardFocus: root.full ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        mask: Region { item: root.full ? backdrop : shape }

        readonly property size peekSize: Qt.size(680, peek.implicitHeight + 40)
        readonly property size fullSize: Qt.size(Math.min(width - 16, 860), Math.min(height - 48, 680))

        Rectangle {
            id: backdrop
            anchors.fill: parent
            color: "transparent"
            TapHandler { onTapped: F1Hub.open = false }
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
                onTapped: F1Hub.toggle(root.screenName)
            }

            // Compact: leading label, trailing figure — like a Live Activity.
            RowLayout {
                id: compact
                x: (shape.width - width) / 2
                height: 28
                spacing: 9
                opacity: root.state_ === "compact" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }

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
                        running: compact.mode === "live"
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

            // Peek: the weekend at a glance.
            ColumnLayout {
                id: peek
                x: (shape.width - width) / 2
                y: 20
                width: win.peekSize.width - 44
                spacing: 10
                opacity: root.state_ === "peek" ? 1 : 0
                scale: root.state_ === "peek" ? 1 : 0.94
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: root.state_ === "peek" ? 260 : 120; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }

                F1Hero { large: false; Layout.fillWidth: true }

                Rectangle {
                    id: openButton
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: openRow.implicitWidth + 28
                    implicitHeight: 32
                    radius: 16
                    color: openHover.hovered ? F1Hub.fillStrong : F1Hub.fill
                    border.width: 1
                    border.color: F1Hub.hairline
                    scale: openTap.pressed ? 0.96 : 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutQuint } }

                    Row {
                        id: openRow
                        anchors.centerIn: parent
                        spacing: 8
                        F1Text { anchors.verticalCenter: parent.verticalCenter; text: "Open F1 Hub"; role: "footnote"; font.weight: Font.DemiBold }
                        F1Text { anchors.verticalCenter: parent.verticalCenter; text: "Super ⇧ F"; role: "caption"; tone: "tertiary" }
                    }
                    HoverHandler { id: openHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: openTap; onTapped: F1Hub.show(undefined, root.screenName) }
                }
            }

            // Full: the hub. Built on first open, then kept warm.
            Loader {
                id: hubLoader
                x: (shape.width - width) / 2
                width: win.fullSize.width
                height: win.fullSize.height
                property bool warm: false
                active: root.full || warm
                onLoaded: warm = true
                opacity: root.full ? 1 : 0
                scale: root.full ? 1 : 0.96
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: root.full ? 320 : 120; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }
                sourceComponent: F1HubContent {
                    anchors.fill: parent
                    anchors.margins: 22
                    anchors.topMargin: 20
                }
            }
        }
    }
}

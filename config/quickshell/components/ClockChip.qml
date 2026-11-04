import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "."

// The clock island. The bar holds a placeholder; the shape lives in an overlay
// surface and morphs in place:
//   compact  date + time
//   peek     hover: time with seconds, this week, today's F1 sessions or the next weekend
//   full     click or `qs ipc call clock toggle`: keyboard-driven month calendar
Item {
    id: root

    implicitWidth: compact.implicitWidth + 26
    implicitHeight: 28

    readonly property var barWindow: QsWindow.window
    readonly property string screenName: barWindow?.screen?.name ?? ""
    readonly property point origin: {
        void BarLayout.tick
        void barWindow?.visible
        void x; void y; void width; void height; void state_
        void parent?.x; void parent?.parent?.x; void parent?.parent?.width
        void parent?.parent?.parent?.width
        return BarLayout.islandOrigin(root, barWindow)
    }

    property bool hoverPeek: false

    onHoverPeekChanged: hoverPeek ? Motion.claim(root) : Motion.unclaim(root)
    readonly property bool full: ClockHub.open && ClockHub.screen === screenName
    readonly property string state_: full ? "full" : hoverPeek ? "peek" : "compact"
    onState_Changed: if (state_ === "compact") settle.restart()
    Timer { id: settle; interval: 450 }
    readonly property bool ticking: state_ !== "compact"
    readonly property date now: ClockHub.now
    readonly property bool f1Today: F1Data.eventsOn(now.getFullYear(), now.getMonth(), now.getDate()).length > 0

    onTickingChanged: ClockHub.precise += ticking ? 1 : -1
    Component.onCompleted: if (ticking) ClockHub.precise += 1
    Component.onDestruction: if (ticking) ClockHub.precise -= 1

    Timer { id: intent; interval: Motion.instantFor(root) ? 0 : 180; onTriggered: root.hoverPeek = true }
    Timer { id: leave; interval: 280; onTriggered: { root.hoverPeek = false; Motion.release() } }

    PanelWindow {
        id: win
        screen: root.barWindow?.screen ?? null
        visible: root.barWindow?.visible ?? false
        color: "transparent"
        WlrLayershell.namespace: "quickshell-clock"
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
            Math.min(width - 16, Math.max(268, peekBox.implicitWidth + peekPadH * 2)),
            peekBox.implicitHeight + peekPadV * 2 + 6)
        // Header, weekday row, one 40px row per week, key hints and padding; grows for 6-week months.
        readonly property int weeks: Math.ceil(((new Date(ClockHub.year, ClockHub.month, 1).getDay() + 6) % 7
            + new Date(ClockHub.year, ClockHub.month + 1, 0).getDate()) / 7)
        readonly property size fullSize: Qt.size(Math.min(width - 16, 620),
            Math.min(height - 48, 560, 132 + weeks * 40))

        IslandBackdrop {
            id: backdrop
            active: root.full
            shape: shape
            onDismissed: ClockHub.open = false
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: e => e.accepted = root.full && calLoader.item && calLoader.item.handleKey(e)
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
                onTapped: ClockHub.toggle(root.screenName)
            }

            RowLayout {
                id: compact
                x: (shape.width - width) / 2
                height: 28
                spacing: 8
                opacity: root.state_ === "compact" ? 1 : 0
                visible: opacity > 0.01
                // Returns once the collapse is under way, so it lands in a pill-sized shape.
                Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.state_ === "compact" ? 50 : 0 } NumberAnimation { duration: root.state_ === "compact" ? 130 : 80; easing.type: Easing.OutCubic } } }

                Rectangle {
                    visible: root.f1Today
                    implicitWidth: 6; implicitHeight: 6; radius: 3
                    color: Theme.gold
                }
                F1Text { text: Qt.formatDate(root.now, "ddd d MMM"); role: "callout"; tone: "secondary" }
                F1Text { text: Qt.formatTime(root.now, "hh:mm"); role: "callout"; numeric: true; font.weight: Font.DemiBold }
            }

            ColumnLayout {
                id: peekBox
                z: 2
                x: (shape.width - width) / 2
                y: win.peekPadV
                width: implicitWidth
                spacing: 12
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

                ClockPeek {
                    id: peek
                    Layout.fillWidth: true
                    onOpenCalendar: day => {
                        ClockHub.show(root.screenName)
                        ClockHub.select(day.getFullYear(), day.getMonth(), day.getDate())
                    }
                }
                ClockButton {
                    Layout.alignment: Qt.AlignHCenter
                    z: 50
                    text: "Open Calendar"
                    onClicked: ClockHub.show(root.screenName)
                }
            }

            // Built on first open, then kept warm.
            Loader {
                id: calLoader
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
                sourceComponent: ClockCalendar {
                    anchors.fill: parent
                    anchors.margins: 16
                    anchors.topMargin: 14
                }
            }
        }
    }
}

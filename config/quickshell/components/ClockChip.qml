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
        void x; void width; void state_; void parent?.x; void parent?.parent?.x; void parent?.parent?.width
        void parent?.parent?.parent?.width
        const p = mapToItem(null, 0, 0)
        return Qt.point(p.x + (barWindow?.margins?.left ?? 0), p.y + (barWindow?.margins?.top ?? 0))
    }

    property bool hoverPeek: false
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

    Timer { id: intent; interval: 180; onTriggered: root.hoverPeek = true }
    Timer { id: leave; interval: 280; onTriggered: root.hoverPeek = false }

    PanelWindow {
        id: win
        screen: root.barWindow?.screen ?? null
        visible: root.barWindow?.visible ?? true
        color: "transparent"
        WlrLayershell.namespace: "quickshell-clock"
        // Expanded islands sit above their neighbours' pills; drop back once the collapse settles.
        WlrLayershell.layer: root.state_ !== "compact" || settle.running ? WlrLayer.Overlay : WlrLayer.Top
        WlrLayershell.keyboardFocus: root.full ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        mask: Region { item: root.full ? backdrop : shape }

        readonly property size peekSize: Qt.size(560, peekBox.implicitHeight + 40)
        // Header, weekday row, one 48px row per week, key hints and padding; grows for 6-week months.
        readonly property int weeks: Math.ceil(((new Date(ClockHub.year, ClockHub.month, 1).getDay() + 6) % 7
            + new Date(ClockHub.year, ClockHub.month + 1, 0).getDate()) / 7)
        readonly property size fullSize: Qt.size(Math.min(width - 16, 780), Math.min(height - 48, 680, 166 + weeks * 48))

        Rectangle {
            id: backdrop
            anchors.fill: parent
            color: "transparent"
            TapHandler { onTapped: ClockHub.open = false }
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
                onTapped: ClockHub.toggle(root.screenName)
            }

            RowLayout {
                id: compact
                x: (shape.width - width) / 2
                height: 28
                spacing: 8
                opacity: root.state_ === "compact" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }

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
                x: (shape.width - width) / 2
                y: 20
                width: win.peekSize.width - 44
                spacing: 12
                opacity: root.state_ === "peek" ? 1 : 0
                scale: root.state_ === "peek" ? 1 : 0.94
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: root.state_ === "peek" ? 260 : 120; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }

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
                    text: "Open Calendar"
                    onClicked: ClockHub.show(root.screenName)
                }
            }

            // Built on first open, then kept warm.
            Loader {
                id: calLoader
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
                sourceComponent: ClockCalendar {
                    anchors.fill: parent
                    anchors.margins: 22
                    anchors.topMargin: 20
                }
            }
        }
    }
}

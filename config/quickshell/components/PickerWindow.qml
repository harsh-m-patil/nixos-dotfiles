import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "."

// Full-screen card picker. Browsing debounces into previewRequested; Enter or a
// card click commits, Esc or a backdrop click cancels. Keys the picker doesn't
// handle arrive via extraKey; set event.accepted to consume them.
PanelWindow {
    id: win

    property bool open: false
    property alias deck: deck
    property alias currentIndex: deck.currentIndex
    property int previewDelay: 220
    property real maxWidth: 1400
    property var hints: []
    default property alias info: infoCol.data

    signal opened()
    signal previewRequested()
    signal committed()
    signal cancelled()
    signal extraKey(var event)

    readonly property bool previewPending: live.running

    function previewSoon() {
        live.restart()
    }

    function stopPreview() {
        live.stop()
    }

    visible: open
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }

    onVisibleChanged: {
        live.stop()
        if (!visible)
            return
        opened()
        live.stop()
        keys.forceActiveFocus()
    }

    Timer {
        id: live
        interval: win.previewDelay
        onTriggered: win.previewRequested()
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        opacity: win.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        MouseArea { anchors.fill: parent; onClicked: { live.stop(); win.cancelled() } }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            const k = event.key
            event.accepted = true
            if (k === Qt.Key_Escape) {
                live.stop()
                win.cancelled()
            } else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
                live.stop()
                win.committed()
            } else if (k === Qt.Key_Left || k === Qt.Key_H)
                deck.step(-1, event.isAutoRepeat)
            else if (k === Qt.Key_Right || k === Qt.Key_L)
                deck.step(1, event.isAutoRepeat)
            else if (k === Qt.Key_Home)
                deck.currentIndex = 0
            else if (k === Qt.Key_End)
                deck.currentIndex = deck.count - 1
            else {
                event.accepted = false
                win.extraKey(event)
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, win.maxWidth)
            spacing: 22

            CardDeck {
                id: deck
                visible: count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 420
                onCurrentIndexChanged: if (win.visible) live.restart()
                onActivated: { live.stop(); win.committed() }
            }

            ColumnLayout {
                id: infoCol
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
            }

            PickerHints {
                Layout.alignment: Qt.AlignHCenter
                hints: win.hints
            }
        }
    }
}

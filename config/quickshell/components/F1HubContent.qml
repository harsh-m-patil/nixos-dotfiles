import QtQuick
import QtQuick.Layouts

import "."

// The expanded island: hero, page switcher, lazily loaded pages and key hints.
// handleKey() routes global keys here and offers the rest to the current page.
ColumnLayout {
    id: hub
    spacing: 14
    property bool showHints: false

    readonly property var globalHints: [["1–5", "Pages"], ["r", "Refresh"], ["esc", "Close"]]

    function handleKey(e) {
        const k = e.key, n = F1Hub.pages.length
        const page = pages.itemAt(F1Hub.page)?.item
        if (k === Qt.Key_Escape || k === Qt.Key_Q) F1Hub.open = false
        else if (k >= Qt.Key_1 && k < Qt.Key_1 + n) F1Hub.page = k - Qt.Key_1
        else if (k === Qt.Key_Tab || k === Qt.Key_BracketRight) F1Hub.step(1)
        else if (k === Qt.Key_Backtab || k === Qt.Key_BracketLeft) F1Hub.step(-1)
        else if (k === Qt.Key_R) F1Data.refresh(true)
        else if (k === Qt.Key_Question || (k === Qt.Key_Slash && (e.modifiers & Qt.ShiftModifier))) showHints = !showHints
        else return !!(page && page.handleKey(e))
        return true
    }

    F1Hero { large: false; Layout.fillWidth: true }

    RowLayout {
        Layout.fillWidth: true
        F1Segmented {
            items: F1Hub.pages.map(p => p.name)
            keys: F1Hub.pages.map((p, i) => String(i + 1))
            current: F1Hub.page
            onPicked: i => F1Hub.page = i
        }
        Item { Layout.fillWidth: true }
        F1Text { text: F1Data.ready ? "" : "Loading…"; role: "footnote"; tone: "tertiary" }
        Rectangle {
            implicitWidth: 24; implicitHeight: 24; radius: 12
            color: hub.showHints ? F1Hub.fillStrong : F1Hub.fill
            F1Text { anchors.centerIn: parent; text: "?"; role: "footnote"; tone: "secondary" }
            TapHandler { onTapped: hub.showHints = !hub.showHints }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Pages load on first visit and stay alive; only the current one is visible.
        Repeater {
            id: pages
            model: ["F1OverviewPage.qml", "F1ResultsPage.qml", "F1StandingsPage.qml", "F1CircuitPage.qml", "F1SeasonPage.qml"]
            Loader {
                id: loader
                required property string modelData
                required property int index
                readonly property int offset: index - F1Hub.page
                property bool visited: offset === 0
                anchors.fill: parent
                active: visited
                onOffsetChanged: if (offset === 0) visited = true
                source: modelData
                opacity: offset === 0 ? 1 : 0
                visible: opacity > 0.01
                transform: Translate {
                    x: loader.offset === 0 ? 0 : loader.offset > 0 ? 24 : -24
                    Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
                }
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
        }
    }

    RowLayout {
        visible: hub.showHints
        Layout.fillWidth: true
        F1Keys { hints: pages.itemAt(F1Hub.page)?.item?.hints ?? [] }
        Item { Layout.fillWidth: true }
        F1Keys { hints: hub.globalHints }
    }
}

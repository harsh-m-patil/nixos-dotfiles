import QtQuick
import QtQuick.Layouts

import "."

// The expanded island: hero, page switcher, lazily loaded pages and key hints.
// handleKey() routes global keys here and offers the rest to the current page.
ColumnLayout {
    id: hub
    spacing: 14
    property bool showHints: false

    readonly property var globalHints: [["1–6", "Pages"], ["r", "Refresh"], ["esc", "Close"]]

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

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            visible: flag.status === Image.Ready
            Layout.preferredWidth: 36
            Layout.preferredHeight: 24
            radius: 6
            color: "transparent"
            clip: true
            Image {
                id: flag
                anchors.fill: parent
                source: F1Data.meeting?.flag ?? ""
                sourceSize.width: 72
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            F1Text {
                text: F1Data.weekend ? "Round " + F1Data.weekend.round + "  ·  " + F1Data.weekend.locality : F1Data.season
                role: "caption"; tone: "secondary"; Layout.fillWidth: true
            }
            F1Text { text: F1Data.weekend?.name ?? "Season complete"; role: "title"; Layout.fillWidth: true }
        }
        F1Segmented {
            items: F1Hub.pages.map(p => p.name)
            keys: F1Hub.pages.map((p, i) => String(i + 1))
            current: F1Hub.page
            onPicked: i => F1Hub.page = i
        }
        F1Text { visible: !F1Data.ready; text: "Loading…"; role: "footnote"; tone: "tertiary" }
        Rectangle {
            implicitWidth: 34; implicitHeight: 34; radius: 17
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
            model: ["F1OverviewPage.qml", "F1MyTeamPage.qml", "F1ResultsPage.qml", "F1StandingsPage.qml", "F1CircuitPage.qml", "F1SeasonPage.qml"]
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

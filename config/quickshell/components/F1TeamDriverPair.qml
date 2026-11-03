import QtQuick
import QtQuick.Layouts

import "."

RowLayout {
    id: pairRoot
    property var tiles: []
    property bool compact: false
    property bool stretch: false
    Layout.fillWidth: true
    Layout.fillHeight: stretch
    spacing: 8
    visible: tiles.length > 0
    Repeater {
        model: pairRoot.tiles
        F1TeamDriverTile {
            required property var modelData
            compact: pairRoot.compact && !pairRoot.stretch
            stretch: pairRoot.stretch
            code: modelData.code
            name: modelData.name
            value: modelData.value
            sub: modelData.sub ?? ""
            photo: modelData.photo ?? ""
        }
    }
}

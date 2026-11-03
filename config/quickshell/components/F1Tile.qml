import QtQuick
import QtQuick.Layouts

import "."

// One dashboard widget: a flat rounded tile with an optional caption row.
// Place it in an F1Grid with col/row/colSpan/rowSpan; children stack in a column.
Rectangle {
    id: tile
    property int col: 0
    property int row: 0
    property int colSpan: 1
    property int rowSpan: 1

    property string label
    property string detail
    property int pad: 14
    property bool interactive: false
    property bool selected: false
    default property alias content: body.data
    signal clicked()

    radius: F1Hub.tileRadius
    color: hover.hovered && interactive ? Qt.lighter(F1Hub.fill, 1.4) : F1Hub.fill
    border.width: selected ? 1.5 : 0
    border.color: Theme.alpha(F1Hub.accent, 0.8)
    Behavior on color { ColorAnimation { duration: 120 } }

    scale: tap.pressed ? 0.97 : 1
    Behavior on scale {
        enabled: !Motion.reduced
        SpringAnimation { spring: 6; damping: 0.6; epsilon: 0.002 }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: tile.pad
        spacing: 6

        RowLayout {
            visible: tile.label !== "" || tile.detail !== ""
            Layout.fillWidth: true
            spacing: 8
            F1Text { text: tile.label; role: "footnote"; tone: "secondary"; Layout.fillWidth: true }
            F1Text { text: tile.detail; role: "footnote"; tone: "tertiary"; visible: text !== ""; numeric: true }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
        }
    }

    HoverHandler { id: hover; enabled: tile.interactive }
    TapHandler { id: tap; enabled: tile.interactive; onTapped: tile.clicked() }
}

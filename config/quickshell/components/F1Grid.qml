import QtQuick

import "."

// Fixed CarPlay grid: equal cells, one gutter. Children (F1Tile) declare col/row/colSpan/rowSpan.
Item {
    id: grid
    property int columns: 4
    property int rows: 3
    property real gap: F1Hub.gap
    readonly property real cellW: (width - gap * (columns - 1)) / columns
    readonly property real cellH: (height - gap * (rows - 1)) / rows

    function place() {
        for (let i = 0; i < children.length; i++) {
            const c = children[i]
            if (c.colSpan === undefined) continue
            c.x = c.col * (cellW + gap)
            c.y = c.row * (cellH + gap)
            c.width = c.colSpan * cellW + (c.colSpan - 1) * gap
            c.height = c.rowSpan * cellH + (c.rowSpan - 1) * gap
        }
    }
    onCellWChanged: place()
    onCellHChanged: place()
    onChildrenChanged: place()
    Component.onCompleted: place()
}

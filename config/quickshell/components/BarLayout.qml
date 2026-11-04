pragma Singleton

import Quickshell
import QtQuick

import "."

// Bumped when the bar becomes visible again so island overlays re-read mapToItem().
Singleton {
    id: root

    property int tick: 0

    function bump(): void {
        tick++
    }

    function islandOrigin(item, barWindow): point {
        const p = item.mapToItem(null, 0, 0)
        return Qt.point(p.x + (barWindow?.margins?.left ?? 0), p.y + (barWindow?.margins?.top ?? 0))
    }
}

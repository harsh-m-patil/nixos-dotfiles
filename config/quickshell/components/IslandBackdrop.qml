import QtQuick

import "."

// Full-screen dismiss layer behind the morphing shape. Clicks on the shape (including
// expanded content) must not close — only taps outside the island dismiss (no scrim).
Item {
    id: backdrop

    property bool active: false
    property Item shape
    signal dismissed()

    anchors.fill: parent

    TapHandler {
        id: dismissTap
        enabled: backdrop.active
        onTapped: {
            const p = backdrop.mapToItem(backdrop.shape, dismissTap.point.position.x, dismissTap.point.position.y)
            if (p.x >= 0 && p.x <= backdrop.shape.width && p.y >= 0 && p.y <= backdrop.shape.height)
                return
            backdrop.dismissed()
        }
    }
}

import QtQuick
import Quickshell

// Wayland click-through mask for morphing island PanelWindows.
// Always bind geometry explicitly (never Region.item) so input tracks the morphing
// shape and full-screen expanded mode does not steal hits from island content.
Region {
    id: region

    property Item panel
    property bool fullScreen: false
    property Item shape

    item: null
    x: fullScreen ? 0 : Math.round(shape.x)
    y: fullScreen ? 0 : Math.round(shape.y)
    width: Math.max(0, Math.round(fullScreen ? panel.width : shape.width))
    height: Math.max(0, Math.round(fullScreen ? panel.height : shape.height))
    radius: fullScreen ? 0 : Math.max(0, Math.round(shape.radius))

    onFullScreenChanged: region.changed()
    onShapeChanged: region.changed()
    onPanelChanged: region.changed()
}

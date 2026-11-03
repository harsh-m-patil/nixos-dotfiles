import QtQuick
import Quickshell.Widgets

import "."

// Album artwork, aspect-cropped to a rounded square, with a glyph while it loads.
ClippingRectangle {
    id: art
    property string source: Media.artUrl
    property bool dimmed: !Media.playing

    radius: Math.min(18, Math.round(width * 0.2))
    color: F1Hub.fillStrong

    Text {
        anchors.centerIn: parent
        visible: img.status !== Image.Ready
        text: "󰝚"
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(art.height * 0.42)
        color: F1Hub.ink3
    }

    Image {
        id: img
        anchors.fill: parent
        source: art.source
        sourceSize.width: Math.ceil(art.width * 2)
        sourceSize.height: Math.ceil(art.height * 2)
        fillMode: Image.PreserveAspectCrop
        verticalAlignment: Image.AlignTop
        asynchronous: true
        smooth: true
        opacity: status === Image.Ready ? (art.dimmed ? 0.55 : 1) : 0
        Behavior on opacity { NumberAnimation { duration: 260 } }
    }
}

import QtQuick
import QtQuick.Effects

import "."

// Driver headshot clipped to a circle (Rectangle.clip follows the box, not the radius).
Item {
    id: root
    property string code: ""
    property int size: 72

    implicitWidth: size
    implicitHeight: size

    readonly property bool hasPhoto: code !== "" && F1Data.headshot(code) !== ""

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        visible: !root.hasPhoto
        color: F1Hub.track
    }

    Item {
        id: photoFrame
        width: root.size
        height: root.size
        visible: false
        clip: true

        Image {
            id: photo
            width: parent.width * 1.18
            height: parent.height * 1.35
            x: (parent.width - width) / 2
            y: -parent.height * 0.14
            source: root.hasPhoto ? F1Data.headshot(code) : ""
            sourceSize: Qt.size(400, 400)
            fillMode: Image.PreserveAspectCrop
            verticalAlignment: Image.AlignTop
            horizontalAlignment: Image.AlignHCenter
            asynchronous: true
            smooth: true
            mipmap: true
        }
    }

    Item {
        id: mask
        width: root.size
        height: root.size
        visible: false
        layer.enabled: true
        layer.smooth: true
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "white"
        }
    }

    MultiEffect {
        anchors.fill: photoFrame
        visible: root.hasPhoto && photo.status !== Image.Error
        source: photoFrame
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Theme.alpha(F1Hub.ink, 0.14)
        visible: root.hasPhoto
    }
}

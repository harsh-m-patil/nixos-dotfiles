import QtQuick

import "."

// Fanned row of overlapping cards; the card at currentIndex sits in front, centred.
// `card` is instantiated per item; inside it, `parent.modelData`, `parent.isCurrent`
// and `parent.distance` describe the slot it is shown in.
Item {
    id: deck

    property var model: []
    property int currentIndex: 0
    property real cardWidth: 260
    property real cardHeight: 360
    property real spread: cardWidth * 0.38
    property Component card
    // Held arrow keys flick through cards; keep up with the repeat instead of trailing it.
    property bool rushing: false
    readonly property int stepMs: rushing ? 70 : 180

    signal activated(int index)

    readonly property int count: model ? model.length : 0

    function step(delta, repeat) {
        rushing = !!repeat
        if (count > 0)
            currentIndex = (currentIndex + delta + count) % count
    }

    function offsetOf(i) {
        let d = i - currentIndex
        if (count > 2) {
            if (d > count / 2)
                d -= count
            else if (d < -count / 2)
                d += count
        }
        return d
    }

    Repeater {
        model: deck.model

        Item {
            id: slot
            required property var modelData
            required property int index

            readonly property int offset: deck.offsetOf(index)
            readonly property int distance: Math.abs(offset)
            readonly property bool isCurrent: offset === 0

            width: deck.cardWidth
            height: deck.cardHeight
            x: (deck.width - width) / 2 + offset * deck.spread + Math.sign(offset) * deck.cardWidth * 0.22
            y: (deck.height - height) / 2 + Math.min(distance, 4) * 6
            z: 100 - distance
            scale: Math.max(0.62, 1 - distance * 0.085)
            opacity: distance > 4 ? 0 : 1
            visible: opacity > 0

            Behavior on x { NumberAnimation { duration: deck.stepMs; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: deck.stepMs; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: deck.stepMs; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180 } }

            transform: Rotation {
                origin.x: slot.width / 2
                origin.y: slot.height / 2
                axis { x: 0; y: 1; z: 0 }
                angle: Math.max(-40, Math.min(40, -slot.offset * 14))
                Behavior on angle { NumberAnimation { duration: deck.stepMs; easing.type: Easing.OutCubic } }
            }

            Loader {
                id: loader
                anchors.fill: parent
                sourceComponent: deck.card
                readonly property var modelData: slot.modelData
                readonly property bool isCurrent: slot.isCurrent
                readonly property int distance: slot.distance
            }

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: "#000000"
                opacity: Math.min(0.62, slot.distance * 0.16)
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (slot.isCurrent)
                        deck.activated(slot.index)
                    else
                        deck.currentIndex = slot.index
                }
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        property real acc: 0
        onWheel: event => {
            acc += event.angleDelta.y !== 0 ? event.angleDelta.y : -event.angleDelta.x
            while (acc >= 120) { deck.step(-1); acc -= 120 }
            while (acc <= -120) { deck.step(1); acc += 120 }
        }
    }
}

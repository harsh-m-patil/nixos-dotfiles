import QtQuick

import "."

// macOS-style segmented control with a sliding thumb.
Rectangle {
    id: seg
    property var items: []              // strings
    property int current: 0
    property var keys: []               // optional shortcut label per item
    signal picked(int index)

    implicitWidth: row.implicitWidth + 6
    implicitHeight: 34
    radius: height / 2
    color: F1Hub.fill

    Rectangle {
        readonly property Item target: rep.count > seg.current ? rep.itemAt(seg.current) : null
        x: target ? row.x + target.x : 3
        y: 3
        width: target ? target.width : 0
        height: parent.height - 6
        radius: height / 2
        color: Theme.foreground
        Behavior on x { SpringAnimation { spring: 5; damping: 1.0; epsilon: 0.25 } }
        Behavior on width { SpringAnimation { spring: 5; damping: 1.0; epsilon: 0.25 } }
    }

    Row {
        id: row
        x: 3
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            id: rep
            model: seg.items
            Item {
                required property string modelData
                required property int index
                readonly property bool on: index === seg.current
                readonly property string keyLabel: seg.keys[index] ?? ""
                width: label.implicitWidth + (keyCap.visible ? keyCap.implicitWidth + 6 : 0) + 28
                height: seg.height - 6
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    F1Text {
                        id: label
                        text: parent.parent.modelData
                        role: "footnote"
                        tone: parent.parent.on ? "primary" : "secondary"
                        color: parent.parent.on ? Theme.background : F1Hub.ink2
                        font.weight: parent.parent.on ? Font.DemiBold : Font.Medium
                    }
                    Rectangle {
                        id: keyCap
                        visible: parent.parent.keyLabel !== ""
                        radius: 4
                        color: Theme.alpha(Theme.foreground, parent.parent.on ? 0.18 : 0.1)
                        implicitWidth: key.implicitWidth + 8
                        implicitHeight: key.implicitHeight + 4
                        F1Text {
                            id: key
                            anchors.centerIn: parent
                            text: parent.parent.parent.keyLabel
                            role: "caption"
                            color: parent.parent.parent.on ? Theme.alpha(Theme.background, 0.75) : F1Hub.ink3
                            numeric: true
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                    }
                }
                TapHandler { onTapped: seg.picked(index) }
            }
        }
    }
}

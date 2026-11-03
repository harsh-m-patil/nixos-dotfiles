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
                width: label.implicitWidth + (key.visible ? key.implicitWidth + 6 : 0) + 28
                height: seg.height - 6
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    F1Text {
                        id: label
                        text: parent.parent.modelData
                        role: "footnote"
                        tone: parent.parent.index === seg.current ? "primary" : "secondary"
                        color: parent.parent.index === seg.current ? Theme.background : F1Hub.ink2
                        font.weight: parent.parent.index === seg.current ? Font.DemiBold : Font.Medium
                    }
                    F1Text {
                        id: key
                        visible: (seg.keys[parent.parent.index] ?? "") !== ""
                        text: seg.keys[parent.parent.index] ?? ""
                        role: "caption"
                        tone: "tertiary"
                        numeric: true
                    }
                }
                TapHandler { onTapped: seg.picked(parent.index) }
            }
        }
    }
}

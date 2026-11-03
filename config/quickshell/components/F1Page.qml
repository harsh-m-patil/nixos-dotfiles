import QtQuick
import QtQuick.Layouts

import "."

ColumnLayout {
    property int index
    property int current
    readonly property int offset: index - current
    width: parent.width
    height: parent.height
    spacing: 10
    opacity: offset === 0 ? 1 : 0
    x: offset === 0 ? 0 : offset > 0 ? 40 : -40
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
}

import QtQuick
import QtQuick.Layouts

import "."

ColumnLayout {
    id: root

    property string label: ""
    property real bps: 0
    property color accent: Theme.iris
    property int size: 24

    readonly property var parts: Fmt.rateParts(bps)

    spacing: 2

    MonKey { label: root.label; accent: root.accent }
    MonValue { value: root.parts[0]; unit: root.parts[1]; size: root.size }
}

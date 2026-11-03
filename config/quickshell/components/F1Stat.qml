import QtQuick
import QtQuick.Layouts

import "."

// A small figure: caption, big value, optional footnote. Lives inside an F1Group grid.
ColumnLayout {
    property string label
    property string value
    property string sub
    property color accent: F1Hub.ink
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.margins: 11
    spacing: 2

    F1Text { text: parent.label; role: "footnote"; tone: "secondary"; Layout.fillWidth: true }
    F1Text { text: parent.value || "—"; role: "title2"; color: parent.accent; Layout.fillWidth: true }
    F1Text { text: parent.sub; role: "caption"; tone: "tertiary"; visible: text !== ""; Layout.fillWidth: true }
}

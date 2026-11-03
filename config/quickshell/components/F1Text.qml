import QtQuick

import "."

// Type scale for the F1 hub. Pick a `role`; `tone` picks the label colour.
Text {
    property string role: "body"        // largeTitle · title · title2 · headline · body · callout · footnote · caption
    property string tone: "primary"     // primary · secondary · tertiary
    property bool numeric: false

    readonly property var scale: ({
        largeTitle: [30, Font.Bold, -0.6], title: [22, Font.Bold, -0.4], title2: [17, Font.DemiBold, -0.2],
        headline: [14, Font.DemiBold, -0.1], body: [13, Font.Normal, 0], callout: [12, Font.Normal, 0],
        footnote: [11, Font.Medium, 0], caption: [10, Font.Medium, 0.1]
    })

    color: tone === "secondary" ? F1Hub.ink2 : tone === "tertiary" ? F1Hub.ink3 : F1Hub.ink
    font.family: numeric ? Theme.fontFamily : Theme.displayFont
    font.pixelSize: scale[role][0]
    font.weight: scale[role][1]
    font.letterSpacing: scale[role][2]
    font.features: numeric ? { "tnum": 1 } : {}
    elide: Text.ElideRight
}

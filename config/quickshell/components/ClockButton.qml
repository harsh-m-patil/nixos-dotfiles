import QtQuick

import "."

// A pill button with an optional trailing key hint.
Rectangle {
    id: btn
    property string text
    property string hint
    signal clicked()

    implicitWidth: row.implicitWidth + (text.length > 2 ? 28 : 18)
    implicitHeight: 32
    radius: 16
    color: hover.hovered ? F1Hub.fillStrong : F1Hub.fill
    border.width: 1
    border.color: F1Hub.hairline
    scale: tap.pressed ? 0.96 : 1
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutQuint } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        F1Text { anchors.verticalCenter: parent.verticalCenter; text: btn.text; role: "footnote"; font.weight: Font.DemiBold }
        F1Text { anchors.verticalCenter: parent.verticalCenter; text: btn.hint; role: "caption"; tone: "tertiary"; visible: text !== "" }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: btn.clicked() }
}

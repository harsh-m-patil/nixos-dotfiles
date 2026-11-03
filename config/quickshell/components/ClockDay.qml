import QtQuick

import "."

// One day in a calendar grid: number, today ring, selection fill and an F1 mark
// (a bar on race day, a dot on other session days).
Rectangle {
    id: cell
    property date date
    property bool inMonth: true
    property bool selected: false
    property bool large: false
    readonly property int y_: date.getFullYear()
    readonly property int m_: date.getMonth()
    readonly property int d_: date.getDate()
    readonly property bool isToday: ClockHub.sameDay(date, ClockHub.now)
    readonly property bool f1: F1Data.eventsOn(y_, m_, d_).length > 0
    readonly property bool race: f1 && ClockHub.isRaceDay(y_, m_, d_)
    signal clicked()

    radius: large ? 12 : 10
    color: selected ? Theme.alpha(Theme.iris, 0.16) : hover.hovered ? F1Hub.fill : "transparent"
    border.width: isToday ? 1.5 : 0
    border.color: Theme.iris
    Behavior on color { ColorAnimation { duration: 120 } }

    F1Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: cell.f1 ? -3 : 0
        text: cell.d_
        role: cell.large ? "headline" : "callout"
        numeric: true
        opacity: cell.inMonth ? 1 : 0.55
        color: cell.isToday ? Theme.iris : cell.race ? Theme.gold : cell.inMonth ? F1Hub.ink : F1Hub.ink3
        font.weight: cell.isToday || cell.race || cell.selected ? Font.Bold : Font.Normal
    }

    Rectangle {
        visible: cell.f1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: cell.large ? 7 : 5
        width: cell.race ? 14 : 4
        height: 3
        radius: 1.5
        color: cell.race ? Theme.gold : F1Hub.ink3
        opacity: cell.inMonth ? 1 : 0.45
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: cell.clicked() }
}

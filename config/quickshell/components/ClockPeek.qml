import QtQuick
import QtQuick.Layouts

import "."

// Peek: the time large, this week as a strip, and what's on (today's F1 sessions,
// or the next race weekend).
ColumnLayout {
    id: peek
    signal openCalendar(date day)
    spacing: 8

    readonly property int weekStripWidth: 7 * 34 + 6 * 4 + 12
    implicitWidth: Math.max(weekStripWidth, headerRow.implicitWidth + 8)

    readonly property date now: ClockHub.now
    readonly property var today: ClockHub.sessionsOn(now.getFullYear(), now.getMonth(), now.getDate())
    readonly property var next: F1Data.weekend
    readonly property int daysInYear: new Date(now.getFullYear(), 1, 29).getDate() === 29 ? 366 : 365

    RowLayout {
        id: headerRow
        Layout.fillWidth: true
        spacing: 10

        ColumnLayout {
            spacing: 0
            Row {
                spacing: 1
                F1Text { id: hm; text: Qt.formatTime(peek.now, "hh:mm"); role: "title"; numeric: true }
                F1Text {
                    anchors.baseline: hm.baseline
                    text: Qt.formatTime(peek.now, ":ss")
                    role: "footnote"
                    tone: "tertiary"
                    numeric: true
                }
            }
            F1Text { text: Qt.formatDate(peek.now, "ddd d MMM") + " · " + Qt.formatDate(peek.now, "dddd"); role: "footnote"; tone: "secondary" }
        }
        Item { Layout.fillWidth: true }
        ColumnLayout {
            spacing: 0
            F1Text { Layout.alignment: Qt.AlignRight; text: "Wk " + ClockHub.isoWeek(peek.now); role: "callout"; numeric: true; font.weight: Font.DemiBold }
            F1Text {
                Layout.alignment: Qt.AlignRight
                text: "Day " + ClockHub.dayOfYear(peek.now) + "/" + peek.daysInYear
                role: "caption"
                tone: "tertiary"
                numeric: true
            }
        }
    }

    F1Group {
        Layout.preferredWidth: peek.weekStripWidth
        Layout.fillWidth: true
        pad: 4
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 2
            columnSpacing: 4
            Repeater {
                model: 7
                F1Text {
                    required property int index
                    readonly property date day: {
                        const s = ClockHub.weekStart(peek.now)
                        return new Date(s.getFullYear(), s.getMonth(), s.getDate() + index)
                    }
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(day, "ddd")
                    role: "caption"
                    tone: "tertiary"
                }
            }
            Repeater {
                model: 7
                ClockDay {
                    id: col
                    required property int index
                    readonly property date day: {
                        const s = ClockHub.weekStart(peek.now)
                        return new Date(s.getFullYear(), s.getMonth(), s.getDate() + index)
                    }
                    Layout.preferredWidth: 34
                    implicitHeight: 30
                    date: col.day
                    onClicked: peek.openCalendar(col.day)
                }
            }
        }
    }

    F1Group {
        Layout.fillWidth: true
        visible: peek.today.length > 0 || peek.next !== null
        title: peek.today.length > 0 ? "Today" : "Next race weekend"
        detail: peek.today.length > 0
            ? ClockHub.weekendTitle(peek.now.getFullYear(), peek.now.getMonth(), peek.now.getDate())
            : peek.next ? "Round " + peek.next.round : ""

        Repeater {
            model: peek.today
            ClockEvent {
                required property var modelData
                required property int index
                time: modelData.time
                title: modelData.label
                live: modelData.live
                past: modelData.past
                accent: modelData.race
                value: modelData.past ? "Done" : ""
                separator: index < peek.today.length - 1
            }
        }
        ClockEvent {
            visible: peek.today.length === 0 && peek.next !== null
            time: peek.next ? Qt.formatDate(peek.next.sessions[0].start, "d MMM") : ""
            title: peek.next ? peek.next.short + " GP" : ""
            value: peek.next ? "Race in " + F1Data.countdown(peek.next.start) : ""
            accent: true
            separator: false
        }
    }
}

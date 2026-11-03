import QtQuick
import QtQuick.Layouts

import "."

// Peek: the time large, this week as a strip, and what's on (today's F1 sessions,
// or the next race weekend).
ColumnLayout {
    id: peek
    signal openCalendar(date day)
    spacing: 12

    readonly property date now: ClockHub.now
    readonly property var today: ClockHub.sessionsOn(now.getFullYear(), now.getMonth(), now.getDate())
    readonly property var next: F1Data.weekend
    readonly property int daysInYear: new Date(now.getFullYear(), 1, 29).getDate() === 29 ? 366 : 365

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 14

        ColumnLayout {
            spacing: 0
            Row {
                spacing: 2
                F1Text { id: hm; text: Qt.formatTime(peek.now, "hh:mm"); role: "largeTitle"; numeric: true }
                F1Text {
                    anchors.baseline: hm.baseline
                    text: Qt.formatTime(peek.now, ":ss")
                    role: "title2"
                    tone: "tertiary"
                    numeric: true
                }
            }
            F1Text { text: Qt.formatDate(peek.now, "dddd, d MMMM"); role: "callout"; tone: "secondary" }
        }
        Item { Layout.fillWidth: true }
        ColumnLayout {
            spacing: 2
            F1Text { Layout.alignment: Qt.AlignRight; text: "Week " + ClockHub.isoWeek(peek.now); role: "headline" }
            F1Text {
                Layout.alignment: Qt.AlignRight
                text: "Day " + ClockHub.dayOfYear(peek.now) + " of " + peek.daysInYear
                role: "footnote"
                tone: "tertiary"
                numeric: true
            }
        }
    }

    F1Group {
        Layout.fillWidth: true
        pad: 6
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: 7
                ColumnLayout {
                    id: col
                    required property int index
                    readonly property date day: {
                        const s = ClockHub.weekStart(peek.now)
                        return new Date(s.getFullYear(), s.getMonth(), s.getDate() + index)
                    }
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 2
                    F1Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4
                        text: Qt.formatDate(col.day, "ddd")
                        role: "caption"
                        tone: "tertiary"
                    }
                    ClockDay {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        date: col.day
                        onClicked: peek.openCalendar(col.day)
                    }
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

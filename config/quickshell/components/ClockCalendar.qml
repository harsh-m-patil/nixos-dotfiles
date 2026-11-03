import QtQuick
import QtQuick.Layouts

import "."

// Expanded: the month grid on the left, the selected day's agenda on the right.
// Keyboard: h/l day, j/k week, [ ] month, t today, Enter jumps to the next race, Esc/q close.
ColumnLayout {
    id: cal
    spacing: 14

    readonly property date sel: ClockHub.selected
    readonly property int year: ClockHub.year
    readonly property int month: ClockHub.month
    readonly property date first: new Date(year, month, 1)
    readonly property date gridStart: ClockHub.weekStart(first)
    readonly property int weeks: Math.ceil(((first.getDay() + 6) % 7 + new Date(year, month + 1, 0).getDate()) / 7)
    readonly property var agenda: ClockHub.sessionsOn(year, month, sel.getDate())
    readonly property bool viewingToday: ClockHub.sameDay(sel, ClockHub.now)

    function handleKey(e) {
        const k = e.key
        if (k === Qt.Key_Escape || k === Qt.Key_Q) ClockHub.open = false
        else if (k === Qt.Key_H || k === Qt.Key_Left) ClockHub.moveDays(-1)
        else if (k === Qt.Key_L || k === Qt.Key_Right) ClockHub.moveDays(1)
        else if (k === Qt.Key_K || k === Qt.Key_Up) ClockHub.moveDays(-7)
        else if (k === Qt.Key_J || k === Qt.Key_Down) ClockHub.moveDays(7)
        else if (k === Qt.Key_BracketLeft || k === Qt.Key_PageUp) ClockHub.moveMonths(-1)
        else if (k === Qt.Key_BracketRight || k === Qt.Key_PageDown) ClockHub.moveMonths(1)
        else if (k === Qt.Key_T) ClockHub.today()
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) jumpToRace()
        else if (k === Qt.Key_Question) ClockHub.hints = !ClockHub.hints
        else return false
        return true
    }
    function jumpToRace() {
        const r = F1Data.races.find(r => r.start > new Date(year, month, sel.getDate() + 1))
        if (r) ClockHub.select(r.start.getFullYear(), r.start.getMonth(), r.start.getDate())
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        F1Text { text: ClockHub.monthNames[cal.month]; role: "title" }
        F1Text { text: cal.year; role: "title"; tone: "tertiary"; numeric: true; Layout.fillWidth: true }
        ClockButton { text: "‹"; onClicked: ClockHub.moveMonths(-1) }
        ClockButton { text: "Today"; hint: "T"; opacity: cal.viewingToday ? 0.5 : 1; onClicked: ClockHub.today() }
        ClockButton { text: "›"; onClicked: ClockHub.moveMonths(1) }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 22

        F1Group {
            Layout.preferredWidth: 7 * 52 + 6 * 4 + 16
            Layout.fillHeight: true
            pad: 8

            WheelHandler { onWheel: e => ClockHub.moveMonths(e.angleDelta.y > 0 ? -1 : 1) }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    F1Text {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.topMargin: 2
                        Layout.bottomMargin: 2
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        role: "caption"
                        tone: "tertiary"
                    }
                }
                Repeater {
                    model: cal.weeks * 7
                    ClockDay {
                        required property int index
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        implicitHeight: 44
                        large: true
                        date: new Date(cal.gridStart.getFullYear(), cal.gridStart.getMonth(), cal.gridStart.getDate() + index)
                        inMonth: date.getMonth() === cal.month
                        selected: ClockHub.sameDay(date, cal.sel)
                        onClicked: ClockHub.select(date.getFullYear(), date.getMonth(), date.getDate())
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 300
            spacing: 14

            ColumnLayout {
                Layout.leftMargin: 4
                spacing: 2
                F1Text { text: Qt.formatDate(cal.sel, "dddd"); role: "title2" }
                F1Text {
                    Layout.fillWidth: true
                    text: Qt.formatDate(cal.sel, "d MMMM yyyy") + " · Week " + ClockHub.isoWeek(cal.sel)
                        + (cal.viewingToday ? " · Today" : "")
                    role: "callout"
                    tone: "secondary"
                }
            }

            F1Group {
                Layout.fillWidth: true
                visible: cal.agenda.length > 0
                title: ClockHub.weekendTitle(cal.year, cal.month, cal.sel.getDate())
                Repeater {
                    model: cal.agenda
                    ClockEvent {
                        required property var modelData
                        required property int index
                        time: modelData.time
                        title: modelData.label
                        live: modelData.live
                        past: modelData.past
                        accent: modelData.race
                        value: modelData.past ? "Done" : ""
                        separator: index < cal.agenda.length - 1
                    }
                }
            }

            F1Group {
                Layout.fillWidth: true
                visible: cal.agenda.length === 0
                F1Text {
                    Layout.fillWidth: true
                    Layout.margins: 14
                    text: "Nothing on this day"
                    role: "callout"
                    tone: "tertiary"
                }
            }

            F1Group {
                Layout.fillWidth: true
                visible: F1Data.nextWeekendLine !== ""
                title: "Up next"
                F1Text {
                    Layout.fillWidth: true
                    Layout.margins: 14
                    text: F1Data.nextWeekendLine
                    role: "callout"
                    tone: "secondary"
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                }
                ClockButton {
                    Layout.leftMargin: 10
                    Layout.bottomMargin: 10
                    text: "Show race"
                    hint: "↵"
                    onClicked: cal.jumpToRace()
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.leftMargin: 4
                visible: F1Data.monthHasEvents(cal.year, cal.month)
                spacing: 6
                Rectangle { implicitWidth: 14; implicitHeight: 3; radius: 1.5; color: Theme.gold }
                F1Text { text: "Race"; role: "caption"; tone: "tertiary" }
                Item { implicitWidth: 6 }
                Rectangle { implicitWidth: 4; implicitHeight: 3; radius: 1.5; color: F1Hub.ink3 }
                F1Text { text: "Session"; role: "caption"; tone: "tertiary" }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 20
        F1Keys {
            visible: ClockHub.hints
            hints: [["h l", "Day"], ["j k", "Week"], ["[ ]", "Month"], ["T", "Today"], ["↵", "Next race"], ["Esc", "Close"]]
        }
        F1Text {
            visible: !ClockHub.hints
            anchors.verticalCenter: parent.verticalCenter
            text: "Press ? for keys"
            role: "caption"
            tone: "tertiary"
        }
        TapHandler { onTapped: ClockHub.hints = !ClockHub.hints }
    }
}

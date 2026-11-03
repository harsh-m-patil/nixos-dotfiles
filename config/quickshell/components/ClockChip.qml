import QtQuick
import QtQuick.Layouts

import "."

Island {
    id: root

    property date now: new Date()
    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()
    property int f1SelDay: -1
    property var f1Day: null

    readonly property bool f1DaySelected: f1Day !== null
    readonly property int panelWidth: 7 * 32 + 6 * 4

    readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"]

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Text {
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
        color: Theme.foreground
        text: {
            const d = root.now
            const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            const pad = n => (n < 10 ? "0" : "") + n
            return days[d.getDay()] + " " + pad(d.getDate()) + "  " + pad(d.getHours()) + ":" + pad(d.getMinutes())
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: if (hovered) root.resetView()
    }

    function resetView() {
        viewYear = now.getFullYear()
        viewMonth = now.getMonth()
        clearF1Selection()
    }

    function shiftMonth(delta) {
        let m = viewMonth + delta
        let y = viewYear
        while (m < 0) { m += 12; y-- }
        while (m > 11) { m -= 12; y++ }
        viewMonth = m
        viewYear = y
        clearF1Selection()
    }

    function clearF1Selection() {
        f1SelDay = -1
        f1Day = null
    }

    function toggleF1Day(day) {
        if (f1SelDay === day) {
            clearF1Selection()
            return
        }
        const detail = F1Data.dayDetail(viewYear, viewMonth, day)
        if (!detail) {
            clearF1Selection()
            return
        }
        f1SelDay = day
        f1Day = detail
    }

    BarPopup {
        trigger: root
        triggerHovered: hover.hovered
        contentMinWidth: root.panelWidth

        ColumnLayout {
            Layout.preferredWidth: root.panelWidth
            spacing: 2

            Text {
                text: Qt.formatDateTime(root.now, "hh:mm:ss")
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: 30
                font.weight: Font.Bold
            }
            Text {
                text: Qt.formatDate(root.now, "dddd, d MMMM yyyy")
                color: Theme.iris
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.highlightLow
        }

        RowLayout {
            Layout.preferredWidth: root.panelWidth
            Layout.fillWidth: true

            Text {
                text: root.monthNames[root.viewMonth] + " " + root.viewYear
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
            MediaButton { icon: "󰅁"; onActivated: root.shiftMonth(-1) }
            MediaButton {
                icon: "󰃭"
                visible: root.viewMonth !== root.now.getMonth() || root.viewYear !== root.now.getFullYear()
                accent: true
                onActivated: root.resetView()
            }
            MediaButton { icon: "󰅂"; onActivated: root.shiftMonth(1) }
        }

        GridLayout {
            id: grid
            Layout.preferredWidth: root.panelWidth
            columns: 7
            rowSpacing: 4
            columnSpacing: 4

            readonly property int firstDow: (new Date(root.viewYear, root.viewMonth, 1).getDay() + 6) % 7
            readonly property int daysInMonth: new Date(root.viewYear, root.viewMonth + 1, 0).getDate()
            readonly property int daysPrev: new Date(root.viewYear, root.viewMonth, 0).getDate()

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                Text {
                    required property string modelData
                    required property int index
                    Layout.preferredWidth: 32
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: index >= 5 ? Theme.love : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            Repeater {
                model: 42

                Rectangle {
                    required property int index
                    readonly property int day: index - grid.firstDow + 1
                    readonly property bool inMonth: day >= 1 && day <= grid.daysInMonth
                    readonly property int shownDay: inMonth ? day
                        : day < 1 ? grid.daysPrev + day : day - grid.daysInMonth
                    readonly property bool isToday: inMonth && day === root.now.getDate()
                        && root.viewMonth === root.now.getMonth() && root.viewYear === root.now.getFullYear()
                    readonly property bool weekend: index % 7 >= 5
                    readonly property var f1Events: inMonth
                        ? F1Data.eventsOn(root.viewYear, root.viewMonth, day) : []
                    readonly property bool f1RaceDay: f1Events.some(e => e.label === "Race")
                    readonly property bool f1Weekend: f1Events.length > 0
                    readonly property bool f1Selected: inMonth && f1Weekend && root.f1SelDay === day

                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 30
                    radius: 8
                    color: f1Selected ? Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.22)
                        : isToday ? Theme.iris
                        : (cellHover.hovered && inMonth ? Theme.highlightLow : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }

                    HoverHandler { id: cellHover }

                    TapHandler {
                        enabled: parent.inMonth
                        onTapped: {
                            if (parent.f1Weekend)
                                root.toggleF1Day(parent.day)
                            else
                                root.clearF1Selection()
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: parent.f1Weekend ? -3 : 0
                        text: parent.shownDay
                        color: parent.isToday ? Theme.background
                            : !parent.inMonth ? Theme.highlightMed
                            : parent.f1RaceDay ? Theme.gold
                            : parent.weekend ? Theme.love : Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: parent.isToday || parent.f1RaceDay ? Font.Bold : Font.Normal
                    }

                    Rectangle {
                        visible: parent.f1Weekend
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 3
                        width: parent.f1RaceDay ? 14 : 4
                        height: 3
                        radius: 1.5
                        color: parent.f1RaceDay ? Theme.gold : Theme.iris
                        opacity: parent.inMonth ? 0.95 : 0.35
                    }
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: root.panelWidth
            Layout.maximumWidth: root.panelWidth
            Layout.fillWidth: true
            Layout.topMargin: 6
            visible: root.f1DaySelected || F1Data.nextWeekendLine !== ""
            spacing: 4

            Text {
                Layout.fillWidth: true
                visible: root.f1DaySelected
                text: root.f1Day?.title ?? ""
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                Layout.fillWidth: true
                visible: root.f1DaySelected
                text: root.f1Day?.sessions ?? ""
                color: Theme.gold
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                Layout.fillWidth: true
                visible: !root.f1DaySelected && F1Data.nextWeekendLine !== ""
                text: F1Data.nextWeekendLine
                color: Theme.iris
                font.family: Theme.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: F1Data.monthHasEvents(root.viewYear, root.viewMonth)
            spacing: 6

            Rectangle { implicitWidth: 14; implicitHeight: 3; radius: 1.5; color: Theme.gold }
            Text {
                text: "F1 race"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
            Rectangle { implicitWidth: 4; implicitHeight: 3; radius: 1.5; color: Theme.iris }
            Text {
                text: "session"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
            Item { Layout.fillWidth: true }
        }

        WheelHandler {
            onWheel: event => root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
        }
    }
}

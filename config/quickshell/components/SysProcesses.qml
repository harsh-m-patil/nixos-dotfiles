import QtQuick
import QtQuick.Layouts

import "."

ColumnLayout {
    id: page

    property string sortKey: "cpu"
    property bool sortDesc: true
    property alias query: search.text

    readonly property var d: SystemData
    readonly property var rows: {
        const q = query.trim().toLowerCase()
        const r = d.procList.filter(p => q === "" || p.name.toLowerCase().includes(q) || p.pid.startsWith(q))
        const k = sortKey, dir = sortDesc ? -1 : 1
        r.sort((a, b) => {
            if (k === "name")
                return dir * a.name.localeCompare(b.name)
            if (k === "pid")
                return dir * (parseInt(a.pid) - parseInt(b.pid))
            return dir * (a[k] - b[k]) || b.mem - a.mem
        })
        return r
    }
    readonly property real topCpu: rows.reduce((m, p) => Math.max(m, p.cpu), 0.02)

    function focusSearch() {
        search.forceActiveFocus()
        search.selectAll()
    }

    function sortBy(key) {
        if (sortKey === key)
            sortDesc = !sortDesc
        else {
            sortKey = key
            sortDesc = key !== "name"
        }
    }

    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            implicitWidth: 300
            implicitHeight: 34
            radius: 8
            color: Theme.surface
            border.width: 1
            border.color: search.activeFocus ? Theme.alpha(Theme.iris, 0.6) : Theme.highlightLow

            Text {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "󰍉"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 14
            }
            TextInput {
                id: search
                anchors.left: searchIcon.right
                anchors.right: clear.left
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.foreground
                selectionColor: Theme.alpha(Theme.iris, 0.35)
                selectedTextColor: Theme.foreground
                font.family: Theme.displayFont
                font.pixelSize: 12
                clip: true
                Text {
                    visible: !search.text && !search.activeFocus
                    text: "Filter by name or PID   Ctrl+F"
                    color: Theme.muted
                    font: search.font
                }
            }
            Text {
                id: clear
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                visible: search.text !== ""
                text: "󰅖"
                color: clearArea.containsMouse ? Theme.foreground : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 13
                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: search.text = ""
                }
            }
        }

        Text {
            text: page.query.trim() === ""
                ? page.d.procList.length + " processes"
                : page.rows.length + " of " + page.d.procList.length + " processes"
            color: Theme.subtle
            font.family: Theme.displayFont
            font.pixelSize: 12
        }

        Item { Layout.fillWidth: true }

        MonKey { label: "CPU"; value: Math.round(page.d.cpu * 100) + "%"; accent: Theme.iris }
        MonKey { label: "Memory"; value: Fmt.gb(page.d.memUsed); accent: Theme.foam }
    }

    MonPanel {
        Layout.fillHeight: true
        padding: 8

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            MonProcRow {
                header: true
                sortable: true
                sortKey: page.sortKey
                sortDesc: page.sortDesc
                onSortRequested: key => page.sortBy(key)
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.highlightLow }

            Flickable {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: rowsCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: rowsCol
                    width: list.width
                    spacing: 0

                    Repeater {
                        model: 200
                        MonProcRow {
                            required property int index
                            p: page.rows[index] ?? null
                            cpuScale: page.topCpu
                        }
                    }
                }

                Text {
                    visible: page.rows.length === 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 40
                    text: page.d.procList.length === 0 ? "Sampling processes…" : "No processes match “" + page.query + "”"
                    color: Theme.muted
                    font.family: Theme.displayFont
                    font.pixelSize: 12
                }
            }
        }

        Rectangle {
            parent: list
            visible: list.contentHeight > list.height
            x: list.width - 4
            y: list.visibleArea.yPosition * list.height
            width: 3
            height: list.visibleArea.heightRatio * list.height
            radius: 1.5
            color: Theme.highlightMed
        }
    }
}

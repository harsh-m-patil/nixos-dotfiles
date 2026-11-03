import QtQuick
import QtQuick.Layouts

import "."

ColumnLayout {
    id: root
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "Theme"
            color: Theme.muted
            font.family: Theme.displayFont
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 0.4
        }

        Text {
            Layout.fillWidth: true
            text: Theme.current.f1?.constructor ?? Theme.current.name ?? ""
            color: Theme.foreground
            font.family: Theme.displayFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Rectangle {
            Layout.preferredWidth: browseText.implicitWidth + 18
            Layout.preferredHeight: 24
            radius: 8
            color: browseMa.containsMouse ? Theme.alpha(Theme.iris, 0.25) : Theme.alpha(Theme.iris, 0.12)
            border.width: 1
            border.color: Theme.iris
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                id: browseText
                anchors.centerIn: parent
                text: "󰏘  Browse"
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: browseMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Theme.openPicker()
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: Theme.catalog

            Rectangle {
                id: swatch
                required property var modelData
                readonly property bool active: modelData.id === Theme.activeId

                width: 22
                height: 22
                radius: 11
                color: modelData.colors?.background ?? "#191724"
                border.width: active ? 2 : 1
                border.color: active ? Theme.foreground : (swatchMa.containsMouse ? Theme.subtle : Theme.highlightMed)

                Rectangle {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    radius: 5
                    color: swatch.modelData.f1?.primary ?? swatch.modelData.colors?.iris ?? "#c4a7e7"
                }

                MouseArea {
                    id: swatchMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Theme.setTheme(swatch.modelData.id)
                        Theme.notifyTheme(swatch.modelData)
                    }
                }
            }
        }
    }
}

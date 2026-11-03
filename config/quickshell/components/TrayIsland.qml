import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import "."

Island {
    hPad: 4

    RowLayout {
        spacing: 8

        Repeater {
            model: SystemTray.items

            delegate: Item {
                required property var modelData
                implicitWidth: 15
                implicitHeight: 15

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 15
                    source: modelData.icon
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate()
                            return
                        }

                        if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
                            if (!modelData.hasMenu) {
                                if (mouse.button === Qt.RightButton)
                                    modelData.secondaryActivate()
                                else
                                    modelData.activate()
                                return
                            }

                            const point = parent.QsWindow.contentItem.mapFromItem(parent, mouse.x, mouse.y)
                            modelData.display(parent.QsWindow.window, point.x, point.y)
                            return
                        }

                        modelData.activate()
                    }
                    onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }
    }
}

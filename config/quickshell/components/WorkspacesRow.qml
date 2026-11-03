import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland._Ipc

import "."

Island {
    hPad: 2

    RowLayout {
        spacing: 0
        Repeater {
            model: 5
            delegate: Rectangle {
                id: wsBtn
                required property int index
                readonly property int wsId: index + 1
                readonly property bool active: Hyprland.focusedWorkspace
                    && Hyprland.focusedWorkspace.id === wsId
                property bool hovered: false

                implicitWidth: 22
                implicitHeight: 22
                radius: 7
                color: active ? Theme.iris : (hovered ? Theme.highlightMed : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: wsId
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: active
                    color: active ? Theme.background : Theme.foreground
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: wsBtn.hovered = true
                    onExited: wsBtn.hovered = false
                    onClicked: Hyprland.dispatch("workspace " + wsId)
                    onWheel: wheel => {
                        if (wheel.angleDelta.y > 0)
                            Hyprland.dispatch("workspace e-1")
                        else if (wheel.angleDelta.y < 0)
                            Hyprland.dispatch("workspace e+1")
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland._Ipc

import "."

Island {
    visible: titleText.length > 0
    opacity: visible ? 1 : 0
    color: Motion.islandFill(true)
    border.color: F1Hub.hairline

    readonly property string titleText: {
        const t = Hyprland.activeToplevel
        if (!t || !t.title)
            return ""
        return t.title.length > 50 ? t.title.slice(0, 50) + "…" : t.title
    }

    Text {
        text: titleText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: F1Hub.ink2
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.maximumWidth: 320
    }
}

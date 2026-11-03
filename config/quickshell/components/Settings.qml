pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// ~/.config/dotfiles/settings.json, generated from dotfiles.settings by home-manager.
Singleton {
    id: root

    readonly property var defaults: ({
        bar: {
            left: ["workspaces", "windowTitle"],
            center: ["media", "clock"],
            right: ["tray", "status"]
        }
    })

    property var data: ({})
    readonly property var bar: Object.assign({}, defaults.bar, data.bar ?? {})
    readonly property bool reducedMotion: data.reducedMotion ?? false

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/dotfiles/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.data = JSON.parse(text()) ?? {}
            } catch (e) {
                console.warn("Settings: invalid settings.json:", e)
            }
        }
        onLoadFailed: root.data = {}
    }
}

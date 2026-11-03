pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Which monitor has the workspace peek open from the keyboard (Super+Tab).
Singleton {
    id: root

    property bool open: false
    property string screen: ""

    function toggle(onScreen) {
        if (open && (!onScreen || onScreen === screen)) { open = false; return }
        screen = onScreen || Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || ""
        open = true
    }

    IpcHandler {
        target: "workspaces"
        function toggle(): void { root.toggle() }
        function close(): void { root.open = false }
    }
}

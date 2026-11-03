pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// UI state for the F1 island, shared by every bar's island, IPC and the hub pages.
Singleton {
    id: hub

    property bool open: false
    property string screen: ""          // monitor whose island is expanded to the hub
    property int page: 0
    readonly property var pages: [
        { name: "Overview", icon: "󰋜" },
        { name: "Results", icon: "󰔸" },
        { name: "Standings", icon: "󰓒" },
        { name: "Circuit", icon: "󰈼" },
        { name: "Season", icon: "󰃭" }
    ]

    // Island palette, derived from the global (team) theme.
    readonly property color surface: Theme.background
    readonly property color ink: Theme.foreground
    readonly property color ink2: Theme.subtle
    readonly property color ink3: Theme.muted
    // CarPlay-style tiles: filled grey on a near-black island, no outlines.
    readonly property color fill: Theme.alpha(Theme.foreground, 0.07)
    readonly property color fillStrong: Theme.alpha(Theme.foreground, 0.13)
    readonly property color hairline: Theme.alpha(Theme.foreground, 0.06)
    readonly property int tileRadius: 16

    function toggle(onScreen) {
        if (open && (!onScreen || onScreen === screen)) { open = false; return }
        show(undefined, onScreen)
    }
    function show(p, onScreen) {
        if (p !== undefined) page = Math.max(0, Math.min(pages.length - 1, p))
        screen = onScreen || Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || ""
        open = true
    }
    function step(d) { page = (page + d + pages.length) % pages.length }
}

//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

import "components"

ShellRoot {
    IpcHandler {
        target: "bar"

        function toggle(): void {
            for (let i = 0; i < barScope.bars.length; i++) {
                const win = barScope.bars[i]
                win.barVisible = !win.barVisible
            }
        }
    }

    IpcHandler {
        target: "sysmon"

        function toggle(): void {
            SystemData.windowOpen = !SystemData.windowOpen
        }

        function tab(index: int): void {
            SystemData.tab = Math.max(0, Math.min(3, index))
            SystemData.windowOpen = true
        }
    }

    IpcHandler {
        target: "theme"

        function list(): string {
            return JSON.stringify(Theme.catalog.map(t => ({ id: t.id, name: t.name })))
        }

        function listF1(): string {
            return JSON.stringify(Theme.f1Themes().map(t => ({
                id: t.id,
                name: t.name,
                constructor: t.f1?.constructor ?? ""
            })))
        }

        function get(): string {
            return Theme.activeId
        }

        function set(id: string): void {
            Theme.setTheme(id)
        }

        function cycle(): string {
            return Theme.cycleNextF1()
        }

        function cycleAll(): string {
            return Theme.cycleNext()
        }

        function togglePicker(): void {
            Theme.togglePicker()
        }

        function openPicker(): void {
            Theme.openPicker()
        }

        function cycleWallpaper(): void {
            Theme.cycleWallpaper()
        }

        function toggleWallpaperPicker(): void {
            Theme.toggleWallPicker()
        }
    }

    IpcHandler {
        target: "f1"

        function toggle(): void { F1Hub.toggle() }
        function open(page: int): void { F1Hub.show(page) }
        function refresh(): void { F1Data.refresh(true) }
    }

    SystemWindow {}
    ThemePickerWindow {}
    WallpaperPickerWindow {}

    QtObject {
        id: barScope
        property var bars: []
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData

            screen: modelData
            WlrLayershell.namespace: "quickshell-bar"
            property bool barVisible: true
            visible: barVisible

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: 4
                left: 6
                right: 6
            }

            implicitHeight: 28
            exclusiveZone: implicitHeight + margins.top
            color: "transparent"

            Component.onCompleted: {
                barScope.bars.push(barWindow)
            }

            TopBar {
                anchors.fill: parent
            }
        }
    }
}

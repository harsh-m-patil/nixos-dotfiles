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
            barScope.setVisible(!barScope.visible)
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
        property bool visible: true

        function dismissIslands(): void {
            ClockHub.open = false
            F1Hub.open = false
            Media.open = false
            StatusData.open = false
            WorkspacesData.open = false
            AgentUsageData.open = false
            if (Motion.owner)
                Motion.owner.hoverPeek = false
            Motion.owner = null
            Motion.release()
        }

        function setVisible(on: bool): void {
            if (!on)
                dismissIslands()
            visible = on
            if (on)
                barRelayout.restart()
        }
    }

    Timer {
        id: barRelayout
        interval: 0
        onTriggered: {
            BarLayout.bump()
            barRelayoutFollow.restart()
        }
    }

    Timer {
        id: barRelayoutFollow
        interval: 50
        onTriggered: BarLayout.bump()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData

            screen: modelData
            WlrLayershell.namespace: "quickshell-bar"
            visible: barScope.visible

            onVisibleChanged: if (visible)
                barRelayout.restart()

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
            exclusiveZone: barScope.visible ? implicitHeight + margins.top : 0
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

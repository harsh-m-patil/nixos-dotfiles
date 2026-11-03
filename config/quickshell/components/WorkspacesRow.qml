import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland._Ipc

import "."

// The workspace island. The bar holds a placeholder; the shape lives in an overlay
// surface and morphs in place:
//   compact  workspace pills (dimmed when empty)
//   peek     hover, or Super+Tab: every workspace with apps; j/k or arrows move the preview
Item {
    id: root

    readonly property int count: 5
    implicitWidth: pills.implicitWidth + 4
    implicitHeight: 28

    readonly property var barWindow: QsWindow.window
    readonly property string screenName: barWindow?.screen?.name ?? ""
    readonly property point origin: {
        void x; void width; void state_; void parent?.x; void parent?.parent?.x; void parent?.parent?.width
        void parent?.parent?.parent?.width
        const p = mapToItem(null, 0, 0)
        return Qt.point(p.x + (barWindow?.margins?.left ?? 0), p.y + (barWindow?.margins?.top ?? 0))
    }

    property bool hoverPeek: false
    readonly property bool keyboardPeek: WorkspacesData.open && WorkspacesData.screen === screenName

    function syncMotion() {
        if (hoverPeek || keyboardPeek) Motion.claim(root)
        else Motion.unclaim(root)
    }
    onHoverPeekChanged: syncMotion()
    readonly property string state_: keyboardPeek || hoverPeek ? "peek" : "compact"
    onState_Changed: {
        if (state_ === "compact") { settle.restart(); previewId = 0; focusRow = -1 }
        else Hyprland.refreshToplevels()
    }
    Timer { id: settle; interval: 450 }

    // Longer intent than the clock: the pills are clicked often and shouldn't bloom on a pass-over.
    Timer { id: intent; interval: Motion.instantFor(root) ? 0 : 420; onTriggered: root.hoverPeek = true }
    Timer { id: leave; interval: 280; onTriggered: { root.hoverPeek = false; Motion.release() } }

    readonly property int activeId: Hyprland.focusedWorkspace?.id ?? 0
    property int previewId: 0
    property int focusRow: -1
    onPreviewIdChanged: if (previewId) Hyprland.refreshToplevels()
    onFocusRowChanged: if (keyboardPeek) syncPreview()
    onKeyboardPeekChanged: {
        syncMotion()
        if (keyboardPeek) {
            intent.stop()
            leave.stop()
            focusRow = Math.max(0, Math.min(count - 1, activeId - 1))
            syncPreview()
            keys.forceActiveFocus()
        } else if (!hoverPeek) previewId = 0
    }

    // Per workspace: [{ app, count }] in first-seen order.
    readonly property var apps: {
        const out = []
        for (let i = 0; i < count; i++) out.push([])
        for (const t of Hyprland.toplevels.values) {
            const ws = t.workspace?.id ?? 0
            if (ws < 1 || ws > count) continue
            const app = t.lastIpcObject?.class || t.wayland?.appId || "window"
            const list = out[ws - 1]
            const hit = list.find(e => e.app === app)
            if (hit) hit.count++
            else list.push({ app: app, count: 1 })
        }
        return out
    }
    // A window landed on a workspace you aren't looking at.
    signal arrived(int ws)
    property var lastCounts: []
    onAppsChanged: {
        const counts = apps.map(l => l.reduce((n, e) => n + e.count, 0))
        if (lastCounts.length === counts.length)
            counts.forEach((n, i) => { if (n > lastCounts[i] && i + 1 !== activeId) arrived(i + 1) })
        lastCounts = counts
    }

    function windowsOn(ws) { return apps[ws - 1].reduce((n, e) => n + e.count, 0) }
    function prettyApp(app) {
        const s = app.split(".").pop().replace(/[-_]/g, " ")
        return s.charAt(0).toUpperCase() + s.slice(1)
    }

    function go(ws) {
        if (ws < 1 || ws > count) return
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + ws + " })")
    }
    function focusedWorkspaceId() {
        if (focusRow >= 0) return focusRow + 1
        if (activeId >= 1 && activeId <= count) return activeId
        return 1
    }
    function syncPreview() {
        const list = apps[focusRow] ?? []
        previewId = list.length ? focusRow + 1 : 0
    }
    function confirmFocus() {
        if (!keyboardPeek) return false
        go(focusedWorkspaceId())
        WorkspacesData.open = false
        return true
    }
    function handleKey(e) {
        const k = e.key, t = e.text
        if (k === Qt.Key_Escape) { WorkspacesData.open = false; return true }
        if (k === Qt.Key_Down || t === "j") { focusRow = Math.min(count - 1, focusRow + 1); return true }
        if (k === Qt.Key_Up || t === "k") { focusRow = Math.max(0, focusRow - 1); return true }
        if (k === Qt.Key_Return || k === Qt.Key_Enter) return confirmFocus()
        if (k === Qt.Key_Space) return confirmFocus()
        const n = Number(t)
        if (n >= 1 && n <= count) {
            go(n)
            WorkspacesData.open = false
            return true
        }
        return false
    }
    function step(wheel) {
        if (wheel.angleDelta.y > 0) Hyprland.dispatch('hl.dsp.focus({ workspace = "e-1" })')
        else if (wheel.angleDelta.y < 0) Hyprland.dispatch('hl.dsp.focus({ workspace = "e+1" })')
    }

    PanelWindow {
        id: win
        screen: root.barWindow?.screen ?? null
        visible: root.barWindow?.visible ?? true
        color: "transparent"
        WlrLayershell.namespace: "quickshell-workspaces"
        WlrLayershell.layer: root.state_ !== "compact" || settle.running ? WlrLayer.Overlay : WlrLayer.Top
        WlrLayershell.keyboardFocus: root.keyboardPeek ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        IslandClickMask {
            id: clickMask
            panel: win
            shape: shape
        }
        mask: clickMask

        Connections {
            target: shape
            function onXChanged() { clickMask.changed() }
            function onYChanged() { clickMask.changed() }
            function onWidthChanged() { clickMask.changed() }
            function onHeightChanged() { clickMask.changed() }
            function onRadiusChanged() { clickMask.changed() }
        }

        readonly property int peekPadH: 14
        readonly property int peekPadV: 12
        readonly property size peekSize: Qt.size(
            Math.min(width - 16, Math.max(280, peekBox.implicitWidth + peekPadH * 2)),
            peekBox.implicitHeight + peekPadV * 2)

        Stagger { target: peekBox; active: root.state_ === "peek" }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                if (!root.keyboardPeek) return
                if (root.handleKey(event)) event.accepted = true
            }
            Keys.onReturnPressed: event => {
                if (root.confirmFocus()) event.accepted = true
            }
            Keys.onEnterPressed: event => {
                if (root.confirmFocus()) event.accepted = true
            }
        }

        RectangularShadow {
            anchors.fill: shape
            radius: shape.radius
            blur: 36
            offset.y: 10
            spread: -4
            color: Qt.rgba(0, 0, 0, 0.4)
            opacity: root.state_ === "compact" ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: root.state_ === "compact" ? 120 : 180; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            id: shape
            readonly property bool peek: root.state_ === "peek"
            readonly property real tw: peek ? win.peekSize.width : root.width
            readonly property real th: peek ? win.peekSize.height : 28

            // Anchored to the island's left edge so it grows rightward from the screen corner.
            x: Math.max(8, Math.min(win.width - tw - 8, root.origin.x))
            y: root.origin.y
            width: tw
            height: th
            radius: Motion.radius(height, Theme.islandRadius)
            color: F1Hub.surface
            border.width: 1
            border.color: F1Hub.hairline
            clip: true

            Behavior on x { enabled: !Motion.reduced; SpringAnimation { spring: Motion.spring(root.state_); damping: Motion.damping(root.state_); epsilon: 0.3 } }
            Behavior on width { enabled: !Motion.reduced; SpringAnimation { spring: Motion.spring(root.state_); damping: Motion.damping(root.state_); epsilon: 0.3 } }
            Behavior on height { enabled: !Motion.reduced; SpringAnimation { spring: Motion.spring(root.state_); damping: Motion.damping(root.state_); epsilon: 0.3 } }

            HoverHandler {
                onHoveredChanged: {
                    if (hovered) { leave.stop(); intent.restart() }
                    else { intent.stop(); leave.restart() }
                }
            }
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: e => root.step(e)
            }

            // One highlight that slides between pills, so a switch reads as a direction, not a blink.
            Rectangle {
                visible: root.activeId >= 1 && root.activeId <= root.count && pills.visible
                opacity: pills.opacity
                x: pills.x + (root.activeId - 1) * 22
                y: 3
                width: 22
                height: 22
                radius: 7
                color: Theme.iris
                // Switched from the keyboard constantly; anything slower trails the keypress.
                Behavior on x { enabled: !Motion.reduced; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }

            RowLayout {
                id: pills
                x: 2
                height: 28
                spacing: 0
                visible: opacity > 0.01
                opacity: shape.peek ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                Repeater {
                    model: root.count
                    delegate: Rectangle {
                        id: wsBtn
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property bool active: root.activeId === wsId
                        readonly property bool occupied: root.apps[index].length > 0

                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 7
                        color: !active && pillHover.hovered ? Theme.highlightMed : "transparent"
                        scale: pillTap.pressed ? 0.94 : 1
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                        Text {
                            anchors.centerIn: parent
                            text: wsBtn.wsId
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: wsBtn.active
                            color: wsBtn.active ? Theme.background : wsBtn.occupied ? Theme.foreground : Theme.muted
                        }
                        Rectangle {
                            id: pillFlash
                            z: -1
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.alpha(Theme.iris, 0.35)
                            opacity: 0
                        }
                        SequentialAnimation {
                            id: pillFlashAnim
                            NumberAnimation { target: pillFlash; property: "opacity"; to: 1; duration: 120; easing.type: Easing.OutCubic }
                            NumberAnimation { target: pillFlash; property: "opacity"; to: 0; duration: 700; easing.type: Easing.OutCubic }
                        }
                        Connections {
                            target: root
                            function onArrived(ws) { if (ws === wsBtn.wsId && !Motion.reduced) pillFlashAnim.restart() }
                        }

                        HoverHandler { id: pillHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { id: pillTap; onTapped: root.go(wsBtn.wsId) }
                    }
                }
            }

            ColumnLayout {
                id: peekBox
                x: win.peekPadH
                y: win.peekPadV
                // Target width, not the animating shape's, so the peek lays out once per open.
                width: win.peekSize.width - win.peekPadH * 2
                spacing: 10
                opacity: shape.peek ? 1 : 0
                scale: shape.peek ? 1 : 0.97
                transformOrigin: Item.TopLeft
                visible: opacity > 0.01
                Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.state_ === "peek" ? 40 : 0 } NumberAnimation { duration: shape.peek ? 200 : 100; easing.type: Easing.OutCubic } } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 0
                    readonly property var focused: Hyprland.activeToplevel
                    F1Text {
                        Layout.fillWidth: true
                        text: "Workspace " + root.activeId
                        role: "title2"
                    }
                    F1Text {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 340
                        text: parent.focused?.title
                            ? root.prettyApp(parent.focused.lastIpcObject?.class || parent.focused.wayland?.appId || "") + " · " + parent.focused.title
                            : "No focused window"
                        role: "footnote"
                        tone: "secondary"
                    }
                }

                F1Group {
                    Layout.fillWidth: true
                    pad: 4

                    Repeater {
                        model: root.count
                        delegate: Rectangle {
                            id: row
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property bool active: root.activeId === wsId
                            readonly property var list: root.apps[index]

                            readonly property bool focused: root.keyboardPeek && root.focusRow === index

                            Layout.fillWidth: true
                            implicitHeight: 34
                            implicitWidth: rowLayout.implicitWidth + 16
                            radius: 10
                            color: rowHover.hovered || row.focused ? F1Hub.fill : "transparent"
                            scale: rowTap.pressed ? 0.98 : 1
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                            RowLayout {
                                id: rowLayout
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 10
                                spacing: 10

                                Rectangle {
                                    implicitWidth: 22; implicitHeight: 22; radius: 7
                                    color: row.active ? Theme.iris : "transparent"
                                    border.width: row.active ? 0 : 1
                                    border.color: F1Hub.hairline
                                    F1Text {
                                        anchors.centerIn: parent
                                        text: row.wsId
                                        role: "callout"
                                        numeric: true
                                        font.weight: Font.DemiBold
                                        color: row.active ? Theme.background : row.list.length ? F1Hub.ink : F1Hub.ink3
                                    }
                                }
                                F1Text {
                                    Layout.fillWidth: true
                                    Layout.maximumWidth: 260
                                    text: row.list.length
                                        ? row.list.map(e => root.prettyApp(e.app) + (e.count > 1 ? " ×" + e.count : "")).join("  ·  ")
                                        : "Empty"
                                    role: "callout"
                                    tone: row.list.length ? "primary" : "tertiary"
                                }
                                F1Text {
                                    visible: row.list.length > 0
                                    text: root.windowsOn(row.wsId)
                                    role: "caption"
                                    tone: "tertiary"
                                    numeric: true
                                }
                            }
                            HoverHandler {
                                id: rowHover
                                cursorShape: Qt.PointingHandCursor
                                // Sticky: resizing the surface for the preview can drop hover for a frame.
                                onHoveredChanged: if (hovered && !root.keyboardPeek) root.previewId = row.list.length ? row.wsId : 0
                            }
                            TapHandler {
                                id: rowTap
                                onTapped: {
                                    root.go(row.wsId)
                                    if (root.keyboardPeek) WorkspacesData.open = false
                                }
                            }

                            Rectangle {
                                id: rowFlash
                                z: -1
                                anchors.fill: parent
                                radius: parent.radius
                                color: Theme.alpha(Theme.iris, 0.18)
                                opacity: 0
                            }
                            SequentialAnimation {
                                id: rowFlashAnim
                                NumberAnimation { target: rowFlash; property: "opacity"; to: 1; duration: 120; easing.type: Easing.OutCubic }
                                NumberAnimation { target: rowFlash; property: "opacity"; to: 0; duration: 700; easing.type: Easing.OutCubic }
                            }
                            Connections {
                                target: root
                                function onArrived(ws) { if (ws === row.wsId && !Motion.reduced) rowFlashAnim.restart() }
                            }
                        }
                    }
                }

                // Hovered workspace, rebuilt from per-window captures at their layout positions.
                Item {
                    id: preview
                    readonly property var mon: Hyprland.monitorFor(win.screen)
                    readonly property real monX: mon?.x ?? 0
                    readonly property real monY: mon?.y ?? 0
                    readonly property real monW: (mon?.width ?? 1920) / (mon?.scale ?? 1)
                    readonly property real monH: (mon?.height ?? 1080) / (mon?.scale ?? 1)
                    readonly property real k: width / monW
                    readonly property bool shown: root.previewId > 0 && shape.peek

                    Layout.fillWidth: true
                    Layout.preferredHeight: shown ? width * monH / monW : 0
                    Layout.bottomMargin: shown ? 0 : -peekBox.spacing
                    opacity: shown ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    // Swapping workspaces dips through a light blur so the change reads as one surface updating.
                    property real swap: 0
                    Connections {
                        target: root
                        function onPreviewIdChanged() { if (preview.shown && !Motion.reduced) swapAnim.restart() }
                    }
                    NumberAnimation { id: swapAnim; target: preview; property: "swap"; from: 1; to: 0; duration: 150; easing.type: Easing.OutCubic }

                    Rectangle {
                        anchors.fill: parent
                        opacity: 1 - preview.swap * 0.5
                        layer.enabled: preview.swap > 0
                        layer.effect: MultiEffect { blurEnabled: true; blur: preview.swap * 0.25; blurMax: 16 }
                        radius: 12
                        color: F1Hub.fill
                        border.width: 1
                        border.color: F1Hub.hairline
                        clip: true

                        Repeater {
                            model: preview.shown
                                ? Hyprland.toplevels.values.filter(t => t.workspace?.id === root.previewId && t.wayland)
                                : []
                            delegate: ScreencopyView {
                                required property var modelData
                                readonly property var ipc: modelData.lastIpcObject ?? {}
                                x: ((ipc.at?.[0] ?? 0) - preview.monX) * preview.k
                                y: ((ipc.at?.[1] ?? 0) - preview.monY) * preview.k
                                width: (ipc.size?.[0] ?? 0) * preview.k
                                height: (ipc.size?.[1] ?? 0) * preview.k
                                captureSource: modelData.wayland
                                live: true
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts

import "."

// Widgets per section come from Settings.bar (dotfiles.settings.bar).
// Unlisted widgets are never created, so their data singletons stay idle.
Item {
    id: root

    readonly property var widgets: ({
        workspaces: workspaces,
        windowTitle: windowTitle,
        media: media,
        clock: clock,
        f1: f1,
        agentUsage: agentUsage,
        tray: tray,
        status: status
    })

    Component { id: workspaces; WorkspacesRow {} }
    Component { id: windowTitle; WindowTitle {} }
    Component { id: media; MediaIsland {} }
    Component { id: clock; ClockChip {} }
    Component { id: f1; F1Chip {} }
    Component { id: agentUsage; AgentUsageChip {} }
    Component { id: tray; TrayIsland {} }
    Component { id: status; StatusRow {} }

    component Section: RowLayout {
        property var ids: []
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: parent.ids
            Loader {
                required property string modelData
                sourceComponent: root.widgets[modelData] ?? null
                Component.onCompleted: if (!root.widgets[modelData]) console.warn("TopBar: unknown widget", modelData)
            }
        }
    }

    Section {
        anchors.left: parent.left
        ids: Settings.bar.left
    }

    Section {
        anchors.horizontalCenter: parent.horizontalCenter
        ids: Settings.bar.center
    }

    Section {
        anchors.right: parent.right
        ids: Settings.bar.right
    }
}

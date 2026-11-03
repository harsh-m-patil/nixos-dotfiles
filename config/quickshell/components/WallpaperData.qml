pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var paths: ({})
    property var pools: ({})
    readonly property string current: currentFile.text().trim()

    FileView {
        id: currentFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell/wallpaper-path"
        watchChanges: true
        onFileChanged: reload()
    }

    function fileUrl(themeId) {
        const p = paths[themeId]
        if (!p)
            return ""
        return pathToUrl(p)
    }

    function pathToUrl(path) {
        if (!path)
            return ""
        return "file://" + path
    }

    function poolPaths(pool) {
        const list = pools[pool]
        return Array.isArray(list) ? list : []
    }

    function refresh() {
        if (!loadProc.running)
            loadProc.running = true
    }

    Process {
        id: loadProc
        command: ThemeApplier.command(["--wallpaper-data"])
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const doc = JSON.parse(text.trim() || "{}")
                    root.paths = doc.previews ?? {}
                    root.pools = doc.pools ?? {}
                } catch (e) {
                    root.paths = {}
                    root.pools = {}
                }
            }
        }
    }

    Component.onCompleted: refresh()
}

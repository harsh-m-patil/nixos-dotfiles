pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Sole owner of apply-theme.sh. Jobs run one at a time; a newer job of the
// same kind replaces one still waiting, so rapid previews collapse to the last.
Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/apply-theme.sh"

    property var queue: []
    property var job: null

    function applyTheme(id, skipWallpaper) {
        const args = [id]
        if (skipWallpaper === true)
            args.push("--no-wallpaper")
        enqueue("theme", args, null)
    }

    function setWallpaper(path, quiet) {
        if (!path)
            return
        const args = ["--set-wallpaper"]
        if (quiet === true)
            args.push("--no-promote")
        args.push(path)
        enqueue("wallpaper", args, quiet === true ? null : wallpaperChanged)
    }

    function cycleWallpaper() {
        enqueue("cycle", ["--cycle-wallpaper"], wallpaperChanged)
    }

    function ensure() {
        enqueue("ensure", ["--ensure"], null)
    }

    function notify(label) {
        Quickshell.execDetached(["hyprctl", "notify", "1", "2500", "0", "Theme", label])
    }

    function wallpaperChanged(output) {
        const name = output.trim().split("\n").pop()
        if (name)
            notify("Wallpaper · " + name)
        WallpaperData.refresh()
    }

    function command(args) {
        return ["env", "PATH=/run/current-system/sw/bin:" + Quickshell.env("PATH"), script].concat(args)
    }

    function enqueue(kind, args, onDone) {
        queue = queue.filter(j => j.kind !== kind).concat([{ kind: kind, args: args, onDone: onDone }])
        kick()
    }

    function kick() {
        if (proc.running || queue.length === 0)
            return
        job = queue[0]
        queue = queue.slice(1)
        proc.command = command(job.args)
        proc.running = true
    }

    Process {
        id: proc
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const done = root.job?.onDone
                if (done)
                    done(text)
            }
        }
        onExited: Qt.callLater(root.kick)
    }
}

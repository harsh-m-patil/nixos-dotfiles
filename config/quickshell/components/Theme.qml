pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configDir: Quickshell.env("HOME") + "/.config/quickshell"
    readonly property string catalogPath: configDir + "/themes.json"
    readonly property string statePath: Quickshell.env("HOME") + "/.local/state/quickshell/theme-state.json"
    property string activeId: "rose-pine"
    property var catalog: []
    property var current: ({})
    property bool pickerOpen: false
    property bool wallPickerOpen: false
    readonly property string fontFamily: "GeistMono Nerd Font Propo"
    readonly property string displayFont: "Geist"
    readonly property int fontSize: 13
    readonly property int islandRadius: 10
    readonly property real islandAlpha: 0.92

    function col(key, fallback) {
        const c = current.colors?.[key]
        return Qt.color(c || fallback)
    }

    readonly property color background: col("background", "#191724")
    readonly property color foreground: col("foreground", "#e0def4")
    readonly property color surface: col("surface", "#1f1d2e")
    readonly property color overlay: col("overlay", "#26233a")
    readonly property color muted: col("muted", "#6e6a86")
    readonly property color subtle: col("subtle", "#908caa")
    readonly property color iris: col("iris", "#c4a7e7")
    readonly property color foam: col("foam", "#9ccfd8")
    readonly property color pine: col("pine", "#31748f")
    readonly property color gold: col("gold", "#f6c177")
    readonly property color love: col("love", "#eb6f92")
    readonly property color rose: col("rose", "#ebbcba")
    readonly property color highlightLow: col("highlightLow", "#2a283e")
    readonly property color highlightMed: col("highlightMed", "#403d52")

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function load(v) { return v > 0.85 ? love : v > 0.6 ? gold : v > 0.3 ? iris : foam }

    function themeById(id) {
        for (let i = 0; i < catalog.length; i++)
            if (catalog[i].id === id)
                return catalog[i]
        return null
    }

    function syncCurrent() {
        current = themeById(activeId) || themeById("rose-pine") || {}
    }

    function setTheme(id, skipWallpaper, ephemeral) {
        if (!themeById(id))
            return
        activeId = id
        syncCurrent()
        if (ephemeral !== true)
            persistState()
        ThemeApplier.applyTheme(id, skipWallpaper)
    }

    function setThemeAccentsOnly(id) {
        setTheme(id, true, true)
    }

    function setWallpaperPath(path, quiet) {
        ThemeApplier.setWallpaper(path, quiet)
    }

    function openWallPicker() {
        pickerOpen = false
        wallPickerOpen = true
        WallpaperData.refresh()
    }

    function toggleWallPicker() {
        if (wallPickerOpen)
            wallPickerOpen = false
        else
            openWallPicker()
    }

    function f1Themes() {
        const out = []
        for (let i = 0; i < catalog.length; i++) {
            const t = catalog[i]
            if (t?.id?.startsWith("f1-") || t?.f1)
                out.push(t)
        }
        return out
    }

    function notifyTheme(theme) {
        const label = theme.f1?.constructor
            ? theme.f1.constructor
            : (theme.name ?? theme.id)
        showNotify(label)
        return label
    }

    function showNotify(label) {
        ThemeApplier.notify(label)
    }

    function cycleNext() {
        if (catalog.length === 0)
            return ""
        let idx = 0
        for (let i = 0; i < catalog.length; i++) {
            if (catalog[i].id === activeId) {
                idx = i
                break
            }
        }
        const next = catalog[(idx + 1) % catalog.length]
        setTheme(next.id)
        return notifyTheme(next)
    }

    function cycleNextF1() {
        const f1 = f1Themes()
        if (f1.length === 0)
            return ""
        let idx = -1
        for (let i = 0; i < f1.length; i++) {
            if (f1[i].id === activeId) {
                idx = i
                break
            }
        }
        const next = idx < 0 ? f1[0] : f1[(idx + 1) % f1.length]
        setTheme(next.id)
        return notifyTheme(next)
    }

    function togglePicker() {
        if (pickerOpen)
            pickerOpen = false
        else
            openPicker()
    }

    function openPicker() {
        wallPickerOpen = false
        pickerOpen = true
        WallpaperData.refresh()
    }

    function cycleWallpaper() {
        ThemeApplier.cycleWallpaper()
    }

    function persistState() {
        stateFile.setText(JSON.stringify({ id: activeId }))
    }

    FileView {
        id: catalogFile
        path: root.catalogPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.loadCatalog()
    }

    FileView {
        id: stateFile
        path: root.statePath
        onLoaded: root.loadState()
    }

    function loadCatalog() {
        try {
            const doc = JSON.parse(catalogFile.text())
            catalog = doc.themes || []
        } catch (e) {
            catalog = []
        }
        loadState()
    }

    function loadState() {
        try {
            const o = JSON.parse(stateFile.text())
            if (o.id && themeById(o.id))
                activeId = o.id
        } catch (e) {}
        syncCurrent()
    }

    Component.onCompleted: {
        if (catalogFile.text)
            loadCatalog()
        else
            catalogFile.reload()
        ThemeApplier.ensure()
    }
}

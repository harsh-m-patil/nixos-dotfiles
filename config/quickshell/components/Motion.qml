pragma Singleton

import Quickshell
import QtQuick

import "."

// Shared motion for the morphing bar islands.
Singleton {
    id: root

    readonly property bool reduced: Settings.reducedMotion

    // Hover opens carry no flick momentum — critically damped. Collapse stays slightly snappier.
    function spring(state) { return state === "compact" ? 9 : 7 }
    function damping(state) { return state === "compact" ? 0.92 : 1.0 }

    // Passive telemetry needles: fast settle, no overshoot.
    readonly property real gaugeSpring: 10
    readonly property real gaugeDamping: 1.0

    // Island inner content (peek / full panels): top-anchored; scale only when motion is on.
    readonly property real contentHiddenScale: reduced ? 1 : 0.97
    readonly property bool contentScaleAnim: !reduced
    readonly property int contentFadeInMs: reduced ? 160 : 200
    readonly property int contentFadeOutMs: reduced ? 120 : 100
    readonly property int contentScaleMs: reduced ? 0 : 180

    function islandFill(compact) {
        return compact
            ? Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 1)
            : Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.92)
    }

    // Corner radius follows the live height so corners and size settle together.
    function radius(height, compactRadius) {
        return compactRadius + (26 - compactRadius) * Math.max(0, Math.min(1, (height - 28) / 300))
    }

    // After one island collapses, the next hover (on any island) opens without the intent delay.
    readonly property bool warm: warmTimer.running
    function release() { warmTimer.restart() }
    Timer { id: warmTimer; interval: 600 }

    // One hover peek at a time: moving onto a neighbour hands the peek over instantly.
    property Item owner: null
    function instantFor(island) { return warm || (owner !== null && owner !== island) }
    function claim(island) {
        if (owner && owner !== island) owner.hoverPeek = false
        owner = island
    }
    function unclaim(island) { if (owner === island) owner = null }
}

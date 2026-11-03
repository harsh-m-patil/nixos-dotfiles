import QtQuick

import "."

// Fades `target`'s children in one after another each time `active` turns on.
// Children must not bind their own opacity; it is driven from here.
Item {
    id: stagger

    property Item target
    property bool active: false
    property int delay: 40
    property int step: 25
    property int maxSteps: 6

    property var anims: []
    visible: false

    onActiveChanged: if (active) run()

    Component {
        id: fade
        SequentialAnimation {
            id: a
            property Item item
            property int wait
            PauseAnimation { duration: a.wait }
            NumberAnimation { target: a.item; property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
        }
    }

    function run() {
        for (const a of anims) { a.stop(); a.destroy() }
        anims = []
        if (!target) return
        if (Motion.reduced) {
            for (const c of target.children) {
                if (c.implicitHeight <= 0 && c.height <= 0) continue
                c.opacity = 1
            }
            return
        }
        let i = 0
        for (const c of target.children) {
            if (c.implicitHeight <= 0 && c.height <= 0) continue
            const a = fade.createObject(stagger, { item: c, wait: delay + Math.min(i++, maxSteps) * step })
            a.start()
            anims.push(a)
        }
    }
}

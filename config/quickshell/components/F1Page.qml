import QtQuick

// Base for hub pages. The window offers each key to the current page first;
// return true from handleKey to consume it. `hints` feed the footer.
Item {
    property var hints: []
    function handleKey(event) { return false }

    // j/k/↑/↓ → -1/+1, 0 otherwise
    function vertical(event) {
        const k = event.key
        return k === Qt.Key_J || k === Qt.Key_Down ? 1 : k === Qt.Key_K || k === Qt.Key_Up ? -1 : 0
    }
    function horizontal(event) {
        const k = event.key
        return k === Qt.Key_L || k === Qt.Key_Right ? 1 : k === Qt.Key_H || k === Qt.Key_Left ? -1 : 0
    }
    function clamp(v, n) { return Math.max(0, Math.min(n - 1, v)) }
}

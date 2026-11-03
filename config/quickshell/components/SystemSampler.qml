import QtQuick

import "."

// Declare one wherever SystemData is shown; sampling runs while any is active.
QtObject {
    property bool active: false
    property bool detailed: false

    Component.onCompleted: SystemData.subscribe(this)
    Component.onDestruction: SystemData.unsubscribe(this)
}

import QtQuick

import "."

QtObject {
    property bool active: false
    Component.onCompleted: Media.subscribe(this)
    Component.onDestruction: Media.unsubscribe(this)
}

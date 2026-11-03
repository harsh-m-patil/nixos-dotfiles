import QtQuick
import QtQuick.Layouts

import "."

// The status peek: connection line on top, four level meters, and the way into Control Center.
ColumnLayout {
    id: peek
    spacing: 12
    signal openRequested()

    component Meter: ColumnLayout {
        property string icon
        property string label
        property real level: 0
        property string value
        property color accent: F1Hub.ink
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.margins: 12
        spacing: 6
        RowLayout {
            spacing: 6
            Text { text: parent.parent.icon; color: F1Hub.ink2; font.family: Theme.fontFamily; font.pixelSize: 13 }
            F1Text { text: parent.parent.label; role: "footnote"; tone: "secondary"; Layout.fillWidth: true }
        }
        F1Text { text: parent.value; role: "title2"; numeric: true; color: parent.accent }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: F1Hub.fillStrong
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, parent.parent.level))
                height: parent.height
                radius: 2
                color: parent.parent.accent
                Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text { text: StatusData.wifiIcon; color: F1Hub.ink; font.family: Theme.fontFamily; font.pixelSize: 16 }
        F1Text { text: StatusData.wifiDetail; role: "headline" }
        F1Text {
            visible: Network.connected
            text: "↓ " + Fmt.rate(Network.rxRate) + "  ↑ " + Fmt.rate(Network.txRate)
            role: "footnote"; tone: "tertiary"; numeric: true
        }
        Item { Layout.fillWidth: true }
        F1Text { text: StatusData.outputName; role: "footnote"; tone: "secondary"; Layout.maximumWidth: 220 }
    }

    F1Group {
        Layout.fillWidth: true
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Meter {
                visible: StatusData.hasBattery
                icon: StatusData.batteryIcon; label: StatusData.charging ? "Charging" : "Battery"
                level: StatusData.batteryLevel
                value: Math.round(StatusData.batteryLevel * 100) + "%"
                accent: StatusData.batteryLow ? Theme.love : StatusData.charging ? Theme.foam : F1Hub.ink
            }
            Meter {
                icon: StatusData.volumeIcon; label: StatusData.muted ? "Muted" : "Volume"
                level: StatusData.muted ? 0 : StatusData.volume
                value: StatusData.muted ? "Off" : Math.round(StatusData.volume * 100) + "%"
            }
            Meter {
                icon: "󰍛"; label: "CPU"
                level: SystemData.cpu
                value: Math.round(SystemData.cpu * 100) + "%"
                accent: SystemData.cpu > 0.85 ? Theme.love : F1Hub.ink
            }
            Meter {
                icon: "󰘚"; label: "Memory"
                level: SystemData.memFraction
                value: Math.round(SystemData.memFraction * 100) + "%"
                accent: SystemData.memFraction > 0.9 ? Theme.love : F1Hub.ink
            }
        }
    }

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: openRow.implicitWidth + 28
        implicitHeight: 32
        radius: 16
        color: openHover.hovered ? F1Hub.fillStrong : F1Hub.fill
        border.width: 1
        border.color: F1Hub.hairline
        scale: openTap.pressed ? 0.96 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutQuint } }
        F1Text { id: openRow; anchors.centerIn: parent; text: "Open Control Center"; role: "footnote"; font.weight: Font.DemiBold }
        HoverHandler { id: openHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: openTap; onTapped: peek.openRequested() }
    }
}

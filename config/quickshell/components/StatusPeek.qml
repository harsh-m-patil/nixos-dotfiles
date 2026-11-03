import QtQuick
import QtQuick.Layouts

import "."

// Status peek — a mini instrument cluster: CPU and memory dials around a link readout,
// indicator lamps, then battery and volume meters and the open pill.
ColumnLayout {
    id: peek
    spacing: 8
    signal openRequested()

    implicitWidth: 340

    component Lamp: Text {
        property bool on: false
        property color accent: Theme.iris
        color: on ? accent : F1Hub.ink3
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        HudGauge {
            Layout.preferredWidth: 112
            Layout.preferredHeight: 100
            label: "CPU"
            value: SystemData.cpu
            accent: Theme.iris
            sub: SystemData.temp > 0 ? Fmt.deg(SystemData.temp) : ""
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Download"
                color: F1Hub.ink3
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Fmt.rate(Network.rxRate)
                color: F1Hub.ink
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 110
                text: StatusData.wifiDetail
                color: F1Hub.ink2
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                spacing: 9
                Lamp { text: StatusData.wifiIcon; on: StatusData.wifiConnected }
                Lamp { text: StatusData.btOn ? "󰂯" : "󰂲"; on: StatusData.btConnected.length > 0 }
                Lamp { text: StatusData.micMuted ? "󰍭" : "󰍬"; on: StatusData.hasMic; accent: StatusData.micMuted ? Theme.love : Theme.iris }
                Lamp { text: "󰈐"; on: SystemData.fans.some(f => f > 0); visible: SystemData.fans.length > 0 }
            }
        }

        HudGauge {
            Layout.preferredWidth: 112
            Layout.preferredHeight: 100
            label: "Memory"
            value: SystemData.memFraction
            redline: 0.9
            accent: Theme.foam
            sub: Fmt.gb(SystemData.memUsed)
        }
    }

    HudBar {
        visible: StatusData.hasBattery
        implicitHeight: 30
        segments: 16
        interactive: false
        icon: StatusData.batteryIcon
        label: StatusData.charging ? "Chg" : "Bat"
        value: StatusData.batteryLevel
        accent: StatusData.batteryLow ? Theme.love : Theme.iris
    }
    HudBar {
        implicitHeight: 30
        segments: 16
        icon: StatusData.volumeIcon
        label: StatusData.muted ? "Mute" : "Vol"
        value: StatusData.volume
        dimmed: StatusData.muted
        onMoved: v => StatusData.setVolume(v)
        onIconTapped: StatusData.toggleMute()
    }

    ClockButton {
        Layout.alignment: Qt.AlignHCenter
        text: "Control Center"
        onClicked: peek.openRequested()
    }
}

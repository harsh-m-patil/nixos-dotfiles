pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string percent: ""

    function read() {
        if (!reader.running)
            reader.running = true
    }

    Process {
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=backlight"]
        running: true
        stdout: SplitParser {
            onRead: root.read()
        }
    }

    Process {
        id: reader
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,\"\",$4); print $4}'"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.percent = text.trim()
        }
    }

    Component.onCompleted: read()
}

import QtQuick
import Quickshell.Io

Item {
    id: root

    required property var theme
    property bool hasBattery: false
    property int percent: 100
    property bool charging: false

    implicitWidth: hasBattery ? row.implicitWidth + 12 : 0
    implicitHeight: theme.barHeight

    function _icon() {
        if (root.charging) return "battery_charging_full";
        if (root.percent >= 95) return "battery_full";
        if (root.percent >= 80) return "battery_6_bar";
        if (root.percent >= 60) return "battery_5_bar";
        if (root.percent >= 40) return "battery_4_bar";
        if (root.percent >= 20) return "battery_3_bar";
        if (root.percent >= 10) return "battery_2_bar";
        return "battery_alert";
    }

    Process {
        id: pollProc
        running: true
        command: ["bash", "-lc",
            "b=$(ls /sys/class/power_supply/ 2>/dev/null | grep -m1 '^BAT'); " +
            "if [ -z \"$b\" ]; then echo NONE; exit 0; fi; " +
            "cat /sys/class/power_supply/$b/capacity 2>/dev/null; " +
            "cat /sys/class/power_supply/$b/status 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n");
                if (lines[0] === "NONE" || lines.length < 2) {
                    root.hasBattery = false;
                    return;
                }
                root.hasBattery = true;
                root.percent = parseInt(lines[0]) || 0;
                root.charging = lines[1].trim() === "Charging";
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: pollProc.running = true }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4
        visible: root.hasBattery

        Text {
            text: root._icon()
            font.family: root.theme.iconFontFamily
            font.pixelSize: root.theme.iconFontSize
            color: (!root.charging && root.percent <= 15) ? root.theme.danger : root.theme.text
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.percent + "%"
            color: root.theme.subtext
            font.pixelSize: root.theme.fontSizeSmall
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

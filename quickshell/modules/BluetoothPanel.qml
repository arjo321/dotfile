import QtQuick
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root

    required property var theme
    required property var ui

    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: Math.min(340, screen ? screen.width : 340)
    implicitHeight: screen ? screen.height : 900
    focusable: false
    visible: ui.openPanel === "bluetooth"

    // No mask: whole window catches clicks so clicking outside the card closes this panel.

    MouseArea {
        anchors.fill: parent
        onClicked: root.ui.closePanels()
    }

    property bool btEnabled: false
    property var devices: []

    function refresh() {
        powerCheck.running = true;
        listProc.running = true;
    }

    Process {
        id: powerCheck
        running: false
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.btEnabled = this.text.indexOf("Powered: yes") !== -1
        }
    }

    Process {
        id: listProc
        running: false
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n");
                var list = [];
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue;
                    // format: "Device AA:BB:CC:DD:EE:FF Some Name"
                    var parts = lines[i].split(" ");
                    if (parts.length < 3) continue;
                    var mac = parts[1];
                    var name = parts.slice(2).join(" ");
                    list.push({ mac: mac, name: name });
                }
                root.devices = list;
            }
        }
    }

    Process { id: toggleProc; running: false }
    function toggleBluetooth() {
        toggleProc.command = ["bluetoothctl", "power", root.btEnabled ? "off" : "on"];
        toggleProc.running = true;
        refreshTimer.restart();
    }

    Process { id: connectProc; running: false }
    function connectTo(mac) {
        connectProc.command = ["bluetoothctl", "connect", mac];
        connectProc.running = true;
    }

    Timer { id: refreshTimer; interval: 1200; onTriggered: root.refresh() }
    Timer { interval: 8000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Rectangle {
        id: card
        width: 300
        height: Math.min(360, 120 + (root.devices.length * 34))
        radius: root.theme.radius
        color: root.theme.bg
        border.color: root.theme.border
        border.width: 1
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.theme.barHeight + root.theme.gap
        anchors.rightMargin: root.theme.gap

        // Absorbs clicks on blank space within the card so they don't fall
        // through to the outer background catcher and close the panel.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Row {
                width: parent.width
                Text {
                    width: parent.width - 42
                    text: "Bluetooth"
                    color: root.theme.text
                    font.pixelSize: root.theme.fontSize
                    font.bold: true
                }
                ToggleSwitch {
                    theme: root.theme
                    checked: root.btEnabled
                    onToggled: root.toggleBluetooth()
                }
            }

            Rectangle { width: parent.width; height: 1; color: root.theme.border }

            Text {
                visible: root.devices.length === 0
                text: "No paired devices"
                color: root.theme.subtext
                font.pixelSize: root.theme.fontSizeSmall
            }

            ListView {
                width: parent.width
                height: parent.height - 60
                clip: true
                model: root.devices
                spacing: 4

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 30
                    radius: root.theme.radiusSmall
                    color: devMouse.containsMouse ? root.theme.cardHover : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: "bluetooth"
                            font.family: root.theme.iconFontFamily
                            color: root.theme.subtext
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            width: parent.width - 30
                            text: modelData.name
                            color: root.theme.text
                            font.pixelSize: root.theme.fontSizeSmall
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: devMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.connectTo(modelData.mac)
                    }
                }
            }
        }
    }

    Component.onCompleted: refresh()
}

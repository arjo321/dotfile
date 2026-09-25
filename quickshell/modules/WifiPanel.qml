import QtQuick
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root

    required property var theme
    required property var ui

    // Spans the whole screen (same pattern as Dashboard) so a click
    // anywhere outside the card — not just in the side column — closes it.
    anchors { top: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitHeight: screen ? screen.height : 900
    focusable: false
    visible: ui.openPanel === "wifi"

    // No mask: whole window catches clicks so clicking outside the card closes this panel.

    MouseArea {
        anchors.fill: parent
        onClicked: root.ui.closePanels()
    }

    property bool wifiEnabled: true
    property var networks: []

    function refresh() {
        radioCheck.running = true;
        scanProc.running = true;
    }

    Process {
        id: radioCheck
        running: false
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = this.text.trim() === "enabled"
        }
    }

    Process {
        id: scanProc
        running: false
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n");
                var list = [];
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue;
                    var parts = lines[i].split(":");
                    if (parts.length < 3 || !parts[1]) continue;
                    list.push({ inUse: parts[0] === "*", ssid: parts[1], signal: parts[2] });
                }
                root.networks = list;
            }
        }
    }

    Process {
        id: toggleProc
        running: false
    }
    function toggleWifi() {
        toggleProc.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"];
        toggleProc.running = true;
        refreshTimer.restart();
    }

    Process {
        id: connectProc
        running: false
    }
    function connectTo(ssid) {
        connectProc.command = ["nmcli", "device", "wifi", "connect", ssid];
        connectProc.running = true;
        refreshTimer.restart();
    }

    Timer { id: refreshTimer; interval: 1500; onTriggered: root.refresh() }
    Timer { interval: 8000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Rectangle {
        id: card
        width: 300
        height: Math.min(360, 120 + (root.networks.length * 34))
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
                    text: "Wi-Fi"
                    color: root.theme.text
                    font.pixelSize: root.theme.fontSize
                    font.bold: true
                }
                ToggleSwitch {
                    theme: root.theme
                    checked: root.wifiEnabled
                    onToggled: root.toggleWifi()
                }
            }

            Rectangle { width: parent.width; height: 1; color: root.theme.border }

            ListView {
                width: parent.width
                height: parent.height - 60
                clip: true
                model: root.networks
                spacing: 4

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 30
                    radius: root.theme.radiusSmall
                    color: netMouse.containsMouse ? root.theme.cardHover : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: modelData.inUse ? "●" : "○"
                            color: modelData.inUse ? root.theme.good : root.theme.subtext
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            width: parent.width - 70
                            text: modelData.ssid
                            color: root.theme.text
                            font.pixelSize: root.theme.fontSizeSmall
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.signal + "%"
                            color: root.theme.subtext
                            font.pixelSize: root.theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: netMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.connectTo(modelData.ssid)
                    }
                }
            }
        }
    }

    Component.onCompleted: refresh()
}

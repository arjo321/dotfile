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
    visible: ui.openPanel === "power"

    // No mask: whole window catches clicks so clicking outside the card closes this panel.

    MouseArea {
        anchors.fill: parent
        onClicked: root.ui.closePanels()
    }

    Process { id: actionProc; running: false }
    function run(cmd) {
        actionProc.command = ["bash", "-lc", cmd];
        actionProc.running = true;
        root.ui.closePanels();
    }

    readonly property var actions: [
        { label: "Lock", icon: "lock", cmd: "hyprlock" },
        { label: "Suspend", icon: "bedtime", cmd: "systemctl suspend" },
        { label: "Restart", icon: "restart_alt", cmd: "systemctl reboot" },
        { label: "Shut down", icon: "power_settings_new", cmd: "systemctl poweroff" },
        { label: "Log out", icon: "logout", cmd: "hyprctl dispatch exit" }
    ]

    Rectangle {
        id: card
        width: 300
        height: 60 + root.actions.length * 44
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
            spacing: 8

            Text { text: "Power"; color: root.theme.text; font.pixelSize: root.theme.fontSize; font.bold: true }
            Rectangle { width: parent.width; height: 1; color: root.theme.border }

            Repeater {
                model: root.actions

                Rectangle {
                    id: actionRow
                    required property var modelData
                    width: parent.width
                    height: 36
                    radius: root.theme.radiusSmall
                    color: actionMouse.containsMouse ? root.theme.cardHover : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 12
                        Text {
                            text: actionRow.modelData.icon
                            font.family: root.theme.iconFontFamily
                            font.pixelSize: 17
                            color: root.theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: actionRow.modelData.label
                            color: root.theme.text
                            font.pixelSize: root.theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.run(actionRow.modelData.cmd)
                    }
                }
            }
        }
    }
}

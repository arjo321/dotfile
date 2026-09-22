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
    implicitWidth: Math.min(240, screen ? screen.width : 240)
    implicitHeight: screen ? screen.height : 900
    focusable: false
    visible: ui.openPanel === "trayMenu" && ui.trayMenuItem !== null

    MouseArea {
        anchors.fill: parent
        onClicked: root.ui.closePanels()
    }

    Process { id: endTaskProc; running: false }

    Rectangle {
        id: card
        width: 220
        height: 112
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
            anchors.margins: 12
            spacing: 6

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.ui.trayMenuItem ? (root.ui.trayMenuItem.title || root.ui.trayMenuItem.id || "App") : ""
                color: root.theme.text
                font.pixelSize: root.theme.fontSizeSmall
                font.bold: true
            }
            Rectangle { width: parent.width; height: 1; color: root.theme.border }

            Rectangle {
                width: parent.width; height: 30; radius: root.theme.radiusSmall
                color: openMouse.containsMouse ? root.theme.cardHover : "transparent"
                Row {
                    anchors.fill: parent; anchors.leftMargin: 8; spacing: 10
                    Text { text: "open_in_new"; font.family: root.theme.iconFontFamily; font.pixelSize: 15; color: root.theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Open"; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    id: openMouse
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.ui.trayMenuItem) root.ui.trayMenuItem.activate();
                        root.ui.closePanels();
                    }
                }
            }

            Rectangle {
                width: parent.width; height: 30; radius: root.theme.radiusSmall
                color: endMouse.containsMouse ? root.theme.cardHover : "transparent"
                Row {
                    anchors.fill: parent; anchors.leftMargin: 8; spacing: 10
                    Text { text: "close"; font.family: root.theme.iconFontFamily; font.pixelSize: 15; color: root.theme.danger; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "End Task"; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    id: endMouse
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Best-effort: tray items don't expose a PID, only
                        // an app-provided "id" (usually the app's name), so
                        // this matches by name via pkill. It can occasionally
                        // miss or over-match — there's no fully reliable way
                        // to map a tray icon to a process from this protocol.
                        if (root.ui.trayMenuItem) {
                            var name = root.ui.trayMenuItem.id || root.ui.trayMenuItem.title || "";
                            if (name.length > 0) {
                                endTaskProc.command = ["bash", "-lc", "pkill -f " + JSON.stringify(name)];
                                endTaskProc.running = true;
                            }
                        }
                        root.ui.closePanels();
                    }
                }
            }
        }
    }
}

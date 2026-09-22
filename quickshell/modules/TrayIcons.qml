import QtQuick
import Quickshell.Services.SystemTray

Row {
    id: root
    required property var theme
    required property var ui
    property var window: null
    
    spacing: 4

    Repeater {
        model: SystemTray.items.values
        Rectangle {
            id: trayItem
            required property var modelData
            width: 24
            height: 24
            radius: 6
            color: trayMouse.containsMouse ? root.theme.cardHover : "transparent"

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: trayItem.modelData.icon
                sourceSize: Qt.size(16, 16)
                smooth: true
            }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        // Always force the custom End Task menu to open
                        root.ui.trayMenuItem = trayItem.modelData;
                        root.ui.openPanel = "trayMenu";
                    } else if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.secondaryActivate();
                    } else {
                        trayItem.modelData.activate();
                    }
                }
            }
        }
    }
}
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

PanelWindow {
    id: root

    required property var theme
    required property var ui
    required property var notifServer

    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: Math.min(340, screen ? screen.width : 340)
    implicitHeight: screen ? screen.height : 900
    focusable: false
    visible: ui.openPanel === "notifications"

    // No mask: whole window catches clicks so clicking outside the card closes this panel.

    MouseArea {
        anchors.fill: parent
        onClicked: root.ui.closePanels()
    }

    Rectangle {
        id: card
        width: 320
        height: Math.min(420, 90 + (root.notifServer.trackedNotifications.values.length * 74))
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
                    width: parent.width - 70
                    text: "Notifications"
                    color: root.theme.text
                    font.pixelSize: root.theme.fontSize
                    font.bold: true
                }
                Text {
                    visible: root.notifServer.trackedNotifications.values.length > 0
                    text: "Clear all"
                    color: root.theme.accent
                    font.pixelSize: root.theme.fontSizeSmall
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var items = root.notifServer.trackedNotifications.values.slice();
                            for (var j = 0; j < items.length; j++) items[j].dismiss();
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: root.theme.border }

            Text {
                visible: root.notifServer.trackedNotifications.values.length === 0
                text: "No notifications"
                color: root.theme.subtext
                font.pixelSize: root.theme.fontSizeSmall
            }

            ListView {
                width: parent.width
                height: parent.height - 60
                clip: true
                spacing: 6
                model: root.notifServer.trackedNotifications.values

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 68
                    radius: root.theme.radiusSmall
                    color: root.theme.card
                    clip: true

                    Rectangle {
                        width: 3
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        radius: 1.5
                        color: modelData.urgency === NotificationUrgency.Critical ? root.theme.danger
                             : modelData.urgency === NotificationUrgency.Low ? root.theme.subtext
                             : root.theme.accent
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        anchors.leftMargin: 14
                        spacing: 8

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 6
                            color: root.theme.accentDim
                            clip: true
                            anchors.top: parent.top

                            Image {
                                anchors.fill: parent
                                anchors.margins: 4
                                source: modelData.image.length > 0 ? modelData.image : ""
                                visible: status === Image.Ready
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }
                            AppIcon {
                                theme: root.theme
                                anchors.fill: parent
                                visible: modelData.image.length === 0
                                iconName: modelData.appIcon || ""
                                size: 13
                            }
                        }

                        Column {
                            width: parent.width - 28 - 24 - 16
                            spacing: 1
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: modelData.appName.length > 0 ? modelData.appName : "Notification"
                                color: root.theme.subtext
                                font.pixelSize: root.theme.fontSizeSmall - 2
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: modelData.summary
                                color: root.theme.text
                                font.pixelSize: root.theme.fontSizeSmall
                                font.bold: true
                            }
                            Text {
                                width: parent.width
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                text: modelData.body
                                color: root.theme.subtext
                                font.pixelSize: root.theme.fontSizeSmall - 1
                            }
                        }

                        Text {
                            text: "close"
                            color: root.theme.subtext
                            font.family: root.theme.iconFontFamily
                            font.pixelSize: 14
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

PanelWindow {
    id: root

    required property var theme
    required property var config
    required property var notifServer

    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: Math.min(340, screen ? screen.width : 340)
    implicitHeight: screen ? screen.height : 900
    focusable: false
    visible: true

    mask: Region { item: stack }

    property var toasts: []

    function _urgencyColor(n) {
        if (n.urgency === NotificationUrgency.Critical) return root.theme.danger;
        if (n.urgency === NotificationUrgency.Low) return root.theme.subtext;
        return root.theme.accent;
    }

    function pushToast(n) {
        var entry = { notif: n, id: Date.now() + Math.random() };
        root.toasts = root.toasts.concat([entry]);
        // Critical notifications stay until dismissed; everything else times out.
        if (n.urgency !== NotificationUrgency.Critical) {
            var timer = toastTimerComponent.createObject(root, { entryId: entry.id });
            timer.start();
        }
    }

    function removeToast(id) {
        root.toasts = root.toasts.filter(function (t) { return t.id !== id; });
    }

    Component {
        id: toastTimerComponent
        Timer {
            property var entryId
            interval: 6000
            repeat: false
            onTriggered: { root.removeToast(entryId); destroy(); }
        }
    }

    Connections {
        target: root.notifServer
        function onNotification(notification) {
            notification.tracked = true;
            if (!root.config.dndEnabled) root.pushToast(notification);
        }
    }

    Column {
        id: stack
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.theme.barHeight + root.theme.gap
        anchors.rightMargin: root.theme.gap
        spacing: 8
        width: 300

        Repeater {
            model: root.toasts

            Rectangle {
                id: toastCard
                required property var modelData
                width: parent.width
                implicitHeight: contentCol.implicitHeight + 24
                radius: root.theme.radius
                color: root.theme.bg
                border.color: root.theme.border
                border.width: 1

                Rectangle {
                    // Urgency indicator
                    width: 3
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    radius: 1.5
                    color: root._urgencyColor(toastCard.modelData.notif)
                }

                MouseArea {
                    // Dismiss-on-click for the card background. Declared
                    // BEFORE contentRow (below it in stacking order) so the
                    // action buttons inside contentRow — declared after,
                    // thus on top — get first claim on their own clicks.
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.removeToast(toastCard.modelData.id)
                }

                Row {
                    id: contentRow
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    anchors.leftMargin: 16
                    spacing: 10

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 8
                        color: root.theme.accentDim
                        anchors.top: parent.top
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 5
                            source: toastCard.modelData.notif.image.length > 0 ? toastCard.modelData.notif.image : ""
                            visible: status === Image.Ready
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                        AppIcon {
                            theme: root.theme
                            anchors.fill: parent
                            visible: toastCard.modelData.notif.image.length === 0
                            iconName: toastCard.modelData.notif.appIcon || ""
                            size: 16
                        }
                    }

                    Column {
                        id: contentCol
                        width: parent.width - 46
                        spacing: 2

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: toastCard.modelData.notif.appName.length > 0
                                  ? toastCard.modelData.notif.appName : "Notification"
                            color: root.theme.subtext
                            font.pixelSize: root.theme.fontSizeSmall - 2
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: toastCard.modelData.notif.summary
                            color: root.theme.text
                            font.pixelSize: root.theme.fontSizeSmall
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            maximumLineCount: 3
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            text: toastCard.modelData.notif.body
                            color: root.theme.subtext
                            font.pixelSize: root.theme.fontSizeSmall - 1
                        }

                        Row {
                            width: parent.width
                            spacing: 6
                            visible: toastCard.modelData.notif.actions.length > 0
                            topPadding: 4

                            Repeater {
                                model: toastCard.modelData.notif.actions
                                Rectangle {
                                    required property var modelData
                                    width: actionLabel.implicitWidth + 16
                                    height: 24
                                    radius: root.theme.radiusSmall
                                    color: actionMouse.containsMouse ? root.theme.cardHover : root.theme.card
                                    Text {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: parent.modelData.text
                                        color: root.theme.accent
                                        font.pixelSize: root.theme.fontSizeSmall - 1
                                    }
                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            parent.modelData.invoke();
                                            root.removeToast(toastCard.modelData.id);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

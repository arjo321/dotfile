import QtQuick

Item {
    id: root

    required property var theme
    property real value: 0.5   // 0..1
    property string icon: ""
    property bool muted: false

    signal moved(real value)
    signal iconClicked()

    implicitWidth: 44

    function _setFromY(y) {
        var ratio = 1 - Math.max(0, Math.min(1, y / track.height));
        root.value = ratio;
        root.moved(ratio);
    }

    Column {
        anchors.fill: parent
        spacing: 6

        Rectangle {
            id: track
            width: 6
            height: parent.height - 58
            radius: 3
            color: root.theme.border
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height * (root.muted ? 0 : root.value)
                radius: parent.radius
                color: root.muted ? root.theme.subtext : root.theme.accent

                Behavior on height { NumberAnimation { duration: 100 } }
            }

            Rectangle {
                width: 16
                height: 16
                radius: 8
                color: "#ffffff"
                x: (track.width - width) / 2
                y: track.height - (track.height * (root.muted ? 0 : root.value)) - height / 2
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -10
                cursorShape: Qt.PointingHandCursor
                onPressed: (mouse) => root._setFromY(mouse.y - 10)
                onPositionChanged: (mouse) => { if (pressed) root._setFromY(mouse.y - 10); }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.muted ? "muted" : Math.round(root.value * 100) + "%"
            color: root.muted ? root.theme.danger : root.theme.subtext
            font.pixelSize: root.theme.fontSizeSmall - 1
        }

        Rectangle {
            width: 28
            height: 28
            radius: 14
            anchors.horizontalCenter: parent.horizontalCenter
            color: iconMouse.containsMouse ? root.theme.cardHover : "transparent"

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: root.theme.iconFontFamily
                font.pixelSize: 16
                color: root.muted ? root.theme.danger : root.theme.subtext
            }

            MouseArea {
                id: iconMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }
    }
}

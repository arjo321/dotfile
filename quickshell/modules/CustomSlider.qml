import QtQuick

Item {
    id: root

    required property var theme
    property real value: 0.5   // 0..1
    property color trackColor: theme ? theme.border : "#3a3350"
    property color fillColor: theme ? theme.accent : "#ab97f0"
    property string icon: ""

    signal moved(real value)

    implicitHeight: 26

    function _setFromX(x) {
        var ratio = Math.max(0, Math.min(1, x / bar.width));
        root.value = ratio;
        root.moved(ratio);
    }

    Row {
        anchors.fill: parent
        spacing: 8

        Text {
            visible: root.icon.length > 0
            text: root.icon
            color: root.theme.subtext
            font.family: root.theme ? root.theme.iconFontFamily : undefined
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            id: bar
            width: parent.width - (root.icon.length > 0 ? 26 : 0)
            height: 6
            radius: 3
            color: root.trackColor
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: bar.width * root.value
                height: parent.height
                radius: parent.radius
                color: root.fillColor
            }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: "#ffffff"
                y: (bar.height - height) / 2
                x: Math.max(0, Math.min(bar.width - width, bar.width * root.value - width / 2))
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onPressed: (mouse) => root._setFromX(mouse.x - 6)
                onPositionChanged: (mouse) => {
                    if (pressed) root._setFromX(mouse.x - 6);
                }
            }
        }
    }
}

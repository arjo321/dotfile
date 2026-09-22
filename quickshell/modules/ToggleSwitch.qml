import QtQuick

Rectangle {
    id: root

    required property var theme
    property bool checked: false
    signal toggled(bool value)

    width: 42
    height: 24
    radius: height / 2
    color: checked ? theme.accent : theme.border

    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        id: knob
        width: 18
        height: 18
        radius: 9
        color: "#ffffff"
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 3 : 3

        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }
}

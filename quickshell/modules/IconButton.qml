import QtQuick

Rectangle {
    id: root

    required property var theme
    property string label: ""
    property real fontSize: theme ? theme.fontSize : 13
    property bool active: false
    property bool showBadge: false
    property int badgeCount: 0

    signal clicked()

    property bool isIcon: true

    implicitWidth: Math.max(28, txt.implicitWidth + 14)
    implicitHeight: 26
    radius: theme ? theme.radiusSmall : 10
    color: active ? theme.accent : (mouse.containsMouse ? theme.pillHover : "transparent")

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: txt
        anchors.centerIn: parent
        text: root.label
        color: root.active ? root.theme.bg : root.theme.text
        font.pixelSize: root.isIcon ? root.theme.iconFontSize : root.fontSize
        font.family: root.isIcon ? root.theme.iconFontFamily : undefined
    }

    Rectangle {
        visible: root.showBadge && root.badgeCount > 0
        width: 15
        height: 15
        radius: 8
        color: root.theme.danger
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -4
        anchors.rightMargin: -4

        Text {
            anchors.centerIn: parent
            text: root.badgeCount > 9 ? "9+" : String(root.badgeCount)
            color: "#1b1725"
            font.pixelSize: 9
            font.bold: true
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

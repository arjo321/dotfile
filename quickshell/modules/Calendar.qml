import QtQuick

Item {
    id: root
    required property var theme

    property var _today: new Date()
    property int viewYear: _today.getFullYear()
    property int viewMonth: _today.getMonth() // 0-11

    function _daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate();
    }
    function _firstWeekday(y, m) {
        return new Date(y, m, 1).getDay(); // 0 = Sunday
    }
    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear -= 1; }
        else viewMonth -= 1;
    }
    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear += 1; }
        else viewMonth += 1;
    }

    implicitWidth: 260
    implicitHeight: 230

    Column {
        anchors.fill: parent
        spacing: 8

        Row {
            width: parent.width
            height: 22

            Rectangle {
                width: 24; height: 22; radius: 6
                color: prevMouse.containsMouse ? root.theme.cardHover : "transparent"
                Text { anchors.centerIn: parent; text: "‹"; color: root.theme.text; font.pixelSize: 15 }
                MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.prevMonth() }
            }

            Text {
                width: parent.width - 48
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().monthName(root.viewMonth, Locale.LongFormat) + " " + root.viewYear
                color: root.theme.text
                font.pixelSize: root.theme.fontSize
                font.bold: true
                height: 22
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: 24; height: 22; radius: 6
                color: nextMouse.containsMouse ? root.theme.cardHover : "transparent"
                Text { anchors.centerIn: parent; text: "›"; color: root.theme.text; font.pixelSize: 15 }
                MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.nextMonth() }
            }
        }

        Grid {
            columns: 7
            columnSpacing: 2
            rowSpacing: 2
            width: parent.width

            Repeater {
                model: ["S", "M", "T", "W", "T", "F", "S"]
                Text {
                    width: (parent.width - 12) / 7
                    height: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: root.theme.subtext
                    font.pixelSize: root.theme.fontSizeSmall
                }
            }

            Repeater {
                model: root._firstWeekday(root.viewYear, root.viewMonth)
                Item {
                    width: (parent.width - 12) / 7
                    height: 26
                }
            }

            Repeater {
                model: root._daysInMonth(root.viewYear, root.viewMonth)
                Rectangle {
                    id: dayCell
                    required property int index
                    property int dayNum: index + 1
                    property bool isToday: dayNum === root._today.getDate()
                                            && root.viewMonth === root._today.getMonth()
                                            && root.viewYear === root._today.getFullYear()

                    width: (parent.width - 12) / 7
                    height: 26
                    radius: 8
                    color: isToday ? root.theme.accent : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: String(dayCell.dayNum)
                        color: dayCell.isToday ? root.theme.bg : root.theme.text
                        font.pixelSize: root.theme.fontSizeSmall
                        font.bold: dayCell.isToday
                    }
                }
            }
        }
    }
}

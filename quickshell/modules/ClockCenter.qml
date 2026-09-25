import QtQuick

Rectangle {
    id: root

    required property var theme
    required property var config

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 26
    radius: theme.radiusSmall
    // Rice: the pill tints with the accent (instead of the plain card
    // color) while hovered, so it reads as part of the wallpaper palette.
    color: {
        if (!hoverArea.containsMouse) return "transparent";
        Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.16)
    }

    Behavior on color { ColorAnimation { duration: 120 } }

    property string _now: ""

    // Hover/click state for the bar to wire into the dashboard.
    readonly property bool hovered: hoverArea.containsMouse
    signal clicked

    function _fmt() {
        var d = new Date();
        var h = d.getHours();
        var m = d.getMinutes();
        var s = d.getSeconds();
        var ampm = "";
        if (!config.use24h) {
            ampm = h >= 12 ? " PM" : " AM";
            h = h % 12;
            if (h === 0) h = 12;
        }
        var hh = (h < 10 ? "0" : "") + h;
        var mm = (m < 10 ? "0" : "") + m;
        var ss = (s < 10 ? "0" : "") + s;
        var t = hh + ":" + mm + (config.showSeconds ? (":" + ss) : "") + ampm;
        var weekday = config.showWeekday ? (Qt.locale().dayName(d.getDay(), Locale.ShortFormat) + "  ") : "";
        return weekday + t;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._now = root._fmt()
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root._now
        color: hoverArea.containsMouse ? root.theme.accent : root.theme.text
        font.pixelSize: root.theme.fontSize
        font.family: "monospace"
        font.bold: true

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

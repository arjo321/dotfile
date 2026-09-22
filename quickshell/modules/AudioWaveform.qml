import QtQuick

Row {
    id: root

    required property var theme
    property bool playing: false
    property int barCount: 4
    property real barWidth: 3
    readonly property var _peaks: [14, 9, 16, 11]

    spacing: 3
    height: 16

    Repeater {
        model: root.barCount

        Rectangle {
            id: bar
            required property int index
            width: root.barWidth
            radius: root.barWidth / 2
            color: root.theme.accent
            anchors.bottom: parent.bottom
            height: 4

            SequentialAnimation {
                running: root.playing
                loops: Animation.Infinite

                NumberAnimation {
                    target: bar
                    property: "height"
                    to: root._peaks[bar.index % root._peaks.length]
                    duration: 300 + (bar.index % 3) * 70
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: bar
                    property: "height"
                    to: 4 + (bar.index % 2) * 2
                    duration: 260 + (bar.index % 4) * 50
                    easing.type: Easing.InOutSine
                }
            }

            Behavior on height {
                enabled: !root.playing
                NumberAnimation { duration: 150 }
            }
        }
    }
}

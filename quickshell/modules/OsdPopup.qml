import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

PanelWindow {
    id: root

    required property var theme

    anchors { bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: screen ? screen.width : 1280
    implicitHeight: 140
    focusable: false
    visible: hideTimer.running

    mask: Region { item: card }

    property string kind: "volume"   // "volume" | "mute" | "brightness"
    property real level: 0.5

    function show(kind, level) {
        root.kind = kind;
        root.level = Math.max(0, Math.min(1, level));
        hideTimer.restart();
    }

    Timer { id: hideTimer; interval: 1500 }

    property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    Connections {
        target: root.sink ? root.sink.audio : null
        function onVolumeChanged() {
            if (root.sink && root.sink.audio && !root.sink.audio.muted)
                root.show("volume", root.sink.audio.volume);
        }
        function onMutedChanged() {
            if (root.sink && root.sink.audio)
                root.show(root.sink.audio.muted ? "mute" : "volume", root.sink.audio.volume);
        }
    }

    function showBrightness(v) { root.show("brightness", v); }

    Rectangle {
        id: card
        width: 220
        height: 64
        radius: root.theme.radius
        color: root.theme.bg
        border.color: root.theme.border
        border.width: 1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.theme.gap * 2

        opacity: hideTimer.running ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Row {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text {
                text: root.kind === "brightness" ? "brightness_6"
                      : root.kind === "mute" ? "volume_off" : "volume_up"
                color: root.theme.accent
                font.family: root.theme.iconFontFamily
                font.pixelSize: 20
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: parent.width - 32
                height: 6
                radius: 3
                color: root.theme.border
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: parent.width * (root.kind === "mute" ? 0 : root.level)
                    height: parent.height
                    radius: parent.radius
                    color: root.theme.accent

                    Behavior on width { NumberAnimation { duration: 120 } }
                }
            }
        }
    }
}

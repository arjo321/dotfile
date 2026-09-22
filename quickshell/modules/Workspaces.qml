import QtQuick
import Quickshell.Hyprland

Row {
    id: root
    required property var theme
    spacing: 6

    function _isNormal(ws) {
        return ws.id > 0;
    }

    Repeater {
        model: Hyprland.workspaces.values.filter(root._isNormal)

        Rectangle {
            id: wsItem
            required property var modelData

            width: modelData.active ? 26 : 20
            height: 20
            radius: 8
            color: modelData.active ? root.theme.accent : (wsMouse.containsMouse ? root.theme.cardHover : root.theme.card)

            Behavior on width { NumberAnimation { duration: 120 } }
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: wsItem.modelData.name ?? String(wsItem.modelData.id)
                color: wsItem.modelData.active ? root.theme.bg : root.theme.subtext
                font.pixelSize: 11
                font.bold: wsItem.modelData.active
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Hyprland 0.55+ with a hyprland.lua config routes ALL
                    // external `hyprctl dispatch` calls through its Lua
                    // interpreter, so the classic plain-string dispatcher
                    // ("workspace 3") no longer works and errors with
                    // something like: attempt to perform arithmetic on a
                    // nil value (global 'workspace'). This is an upstream,
                    // ecosystem-wide breaking change (it also broke Waybar),
                    // not specific to this shell. We try the new Lua-call
                    // syntax first since it matches recent Hyprland; if your
                    // Hyprland reports a "hl.dispatch" Lua error still, or
                    // if you're on a traditional (non .lua) hyprland.conf,
                    // switch the line below to the classic form instead:
                    //   Hyprland.dispatch("workspace " + wsItem.modelData.id)
                    Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsItem.modelData.id + " })");
                }
            }
        }
    }
}

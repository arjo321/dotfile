import QtQuick
import Quickshell

FloatingWindow {
    id: root

    required property var theme
    required property var config
    required property var ui

    title: "Shell Settings"
    implicitWidth: 760
    implicitHeight: 560
    minimumSize: Qt.size(680, 480)
    color: theme.bg
    visible: false

    // Two-way sync (not a declarative binding) so this still works correctly
    // after the window is closed via its own OS close button.
    Connections {
        target: root.ui
        function onSettingsOpenChanged() { root.visible = root.ui.settingsOpen; }
    }
    onVisibleChanged: {
        if (root.ui.settingsOpen !== root.visible) root.ui.settingsOpen = root.visible;
    }

    SettingsPage {
        anchors.fill: parent
        theme: root.theme
        config: root.config
        ui: root.ui
    }
}

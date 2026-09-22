import QtQuick

QtObject {
    id: ui

    // Hover-driven dashboard (opens when hovering the center clock)
    property bool clockHovered: false
    property bool dashboardHovered: false
    property bool dashboardOpen: false

    // Click-toggled overlay panels. Only one of these is open at a time.
    // Valid values: "" | "wifi" | "bluetooth" | "notifications" | "launcher"
    // ("power" was removed — the power icon launches wlogout directly now)
    property string openPanel: ""

    // The Settings app is a real floating window, independent of openPanel.
    property bool settingsOpen: false

    // Set by TrayIcons.qml right before opening the "trayMenu" panel, for
    // tray items that don't provide their own native context menu.
    property var trayMenuItem: null

    // Best-effort detected system login picture (SDDM/GDM/AccountsService),
    // populated once at startup by shell.qml. Used as the dashboard profile
    // picture unless config.profileImagePath overrides it.
    property string detectedProfilePath: ""

    // The dashboard and the click-panels are mutually exclusive. They live
    // in different corners at different widths, so on anything narrower
    // than ~1400px they can visually collide if both are allowed open at
    // once — this guarantees that never happens, regardless of monitor size.
    function togglePanel(name) {
        var next = (ui.openPanel === name) ? "" : name;
        ui.openPanel = next;
        if (next !== "") {
            ui.clockHovered = false;
            ui.dashboardHovered = false;
            ui._closeTimer.stop();
            ui.dashboardOpen = false;
        }
    }

    function closePanels() {
        ui.openPanel = "";
    }

    // Used by the click-outside-to-close background catcher in Dashboard.qml.
    // Also resets the hover flags so it doesn't just reopen on the next
    // hover re-evaluation.
    function closeDashboard() {
        ui.clockHovered = false;
        ui.dashboardHovered = false;
        ui._closeTimer.stop();
        ui.dashboardOpen = false;
    }

    property Timer _closeTimer: Timer {
        interval: 300
        onTriggered: ui.dashboardOpen = false
    }

    function _updateDashboard() {
        if (ui.clockHovered || ui.dashboardHovered) {
            ui._closeTimer.stop();
            ui.openPanel = "";      // close any click-panel before the dashboard opens
            ui.dashboardOpen = true;
        } else {
            ui._closeTimer.restart();
        }
    }

    onClockHoveredChanged: _updateDashboard()
    onDashboardHoveredChanged: _updateDashboard()
}

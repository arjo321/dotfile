import QtQuick

QtObject {
    id: ui

    // Hover-driven dashboard. Opening is hover-INTENT based (see
    // _openTimer below): the pointer has to rest on the clock for a
    // moment, so sweeping the mouse across the bar never pops it open.
    property bool clockHovered: false
    property bool dashboardHovered: false
    property bool dashboardOpen: false

    // Click-toggled overlay panels. Only one of these is open at a time.
    // Valid values: "" | "wifi" | "bluetooth" | "notifications" | "launcher"
    // | "trayMenu" | "power" (wlogout fallback)
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

    // Hover intent: only open after the pointer has stayed put for a beat.
    property Timer _openTimer: Timer {
        interval: 180
        onTriggered: {
            if (ui.clockHovered || ui.dashboardHovered) {
                ui._closeTimer.stop();
                ui.openPanel = "";      // close any click-panel first
                ui.dashboardOpen = true;
            }
        }
    }

    // Clicking the clock pins/unpins the dashboard (hover still works too).
    function toggleDashboard() {
        ui._openTimer.stop();
        ui._closeTimer.stop();
        ui.dashboardOpen = !ui.dashboardOpen;
        if (ui.dashboardOpen) ui.openPanel = "";
    }

    function _updateDashboard() {
        if (ui.clockHovered || ui.dashboardHovered) {
            ui._closeTimer.stop();
            if (ui.dashboardOpen) {
                ui._openTimer.stop();
                ui.openPanel = "";      // close any click-panel before the dashboard opens
            } else {
                ui._openTimer.start();  // dwell before opening
            }
        } else {
            ui._openTimer.stop();
            ui._closeTimer.restart();
        }
    }

    onClockHoveredChanged: _updateDashboard()
    onDashboardHoveredChanged: _updateDashboard()
}

import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root
    required property var theme
    required property var config
    required property var ui

    property int currentTab: 0

    readonly property var tabs: [
        { label: "Appearance", icon: "palette" },
        { label: "Clock & Bar", icon: "schedule" },
        { label: "Notifications", icon: "notifications" },
        { label: "Connectivity", icon: "wifi" },
        { label: "Power", icon: "power_settings_new" },
        { label: "System", icon: "memory" },
        { label: "Shortcuts", icon: "keyboard" },
        { label: "About", icon: "info" }
    ]

    Process { id: shellProc; running: false }

    Row {
        anchors.fill: parent

        // ---------------- Sidebar ----------------
        Rectangle {
            width: 170
            height: parent.height
            color: root.theme.bgAlt

            Column {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                anchors.topMargin: 16
                spacing: 4

                Repeater {
                    model: root.tabs
                    Rectangle {
                        id: tabRow
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 36
                        radius: root.theme.radiusSmall
                        color: root.currentTab === index ? root.theme.accent
                               : (tabMouse.containsMouse ? root.theme.cardHover : "transparent")

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            spacing: 10
                            Text {
                                text: tabRow.modelData.icon
                                font.family: root.theme.iconFontFamily
                                font.pixelSize: 16
                                color: root.currentTab === tabRow.index ? root.theme.bg : root.theme.subtext
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: tabRow.modelData.label
                                font.pixelSize: root.theme.fontSizeSmall
                                color: root.currentTab === tabRow.index ? root.theme.bg : root.theme.text
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = tabRow.index
                        }
                    }
                }
            }
        }

        // ---------------- Content ----------------
        Item {
            width: parent.width - 170
            height: parent.height

            // ---- Appearance ----
            Flickable {
                visible: root.currentTab === 0
                anchors.fill: parent
                anchors.margins: 24
                contentWidth: width
                contentHeight: appearanceColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: appearanceColumn
                    width: parent.width
                    spacing: 16

                    Text { text: "Appearance"; color: root.theme.text; font.pixelSize: 18; font.bold: true }

                    Row {
                        width: 320
                        height: 26
                        Text {
                            width: parent.width - 50
                            text: "Wallpaper colors (matugen)"
                            color: root.theme.text
                            font.pixelSize: root.theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        ToggleSwitch {
                            theme: root.theme
                            checked: root.config.wallpaperColors
                            anchors.verticalCenter: parent.verticalCenter
                            onToggled: (v) => root.config.wallpaperColors = v
                        }
                    }
                    Text {
                        text: root.config.wallpaperColors
                              ? "Bar and panels take their colors from the wallpaper's dark tones and recolor on every wallpaper change."
                              : "Off — using the fixed built-in palette."
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall - 1
                    }

                    Text { text: "Accent color"; color: root.theme.subtext; font.pixelSize: root.theme.fontSizeSmall; topPadding: 8 }
                    Row {
                        spacing: 10
                        opacity: (root.config.wallpaperColors && root.config.accentFromWallpaper) ? 0.35 : 1
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Repeater {
                            model: ["#ab97f0", "#7ac3f0", "#7adba0", "#f0c97a", "#f0797a", "#f07ad6"]
                            Rectangle {
                                required property string modelData
                                width: 32; height: 32; radius: 16
                                color: modelData
                                border.width: root.config.accentColor === modelData ? 3 : 0
                                border.color: root.theme.text
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.config.accentColor = parent.modelData;
                                        root.config.accentFromWallpaper = false;
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: 90; height: 32; radius: root.theme.radiusSmall; color: root.theme.card
                            TextInput {
                                anchors.fill: parent; anchors.margins: 8
                                text: root.config.accentColor
                                color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall; clip: true
                                onEditingFinished: {
                                    if (/^#[0-9a-fA-F]{6}$/.test(text)) {
                                        root.config.accentColor = text;
                                        root.config.accentFromWallpaper = false;
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        visible: root.config.wallpaperColors
                        width: 320
                        height: 26
                        Text {
                            width: parent.width - 50
                            text: "Accent from wallpaper"
                            color: root.theme.text
                            font.pixelSize: root.theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        ToggleSwitch {
                            theme: root.theme
                            checked: root.config.accentFromWallpaper
                            anchors.verticalCenter: parent.verticalCenter
                            onToggled: (v) => root.config.accentFromWallpaper = v
                        }
                    }
                    Text {
                        visible: root.config.wallpaperColors && root.config.accentFromWallpaper
                        text: "Accent follows the wallpaper — click a swatch above to switch to a fixed accent."
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall - 1
                    }

                    Text {
                        text: "UI scale (" + Math.round(root.config.uiScale * 100) + "%)   resizes the whole shell"
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall
                        topPadding: 8
                    }
                    CustomSlider {
                        theme: root.theme
                        width: 260
                        value: (root.config.uiScale - 0.8) / 0.7
                        onMoved: (v) => root.config.uiScale = Math.round((0.8 + v * 0.7) * 20) / 20
                    }

                    Text {
                        text: "Profile picture (leave blank to use your system login picture)"
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall
                        topPadding: 8
                    }
                    Rectangle {
                        width: 320; height: 30; radius: root.theme.radiusSmall
                        color: root.theme.card
                        TextInput {
                            anchors.fill: parent
                            anchors.margins: 8
                            text: root.config.profileImagePath
                            color: root.theme.text
                            font.pixelSize: root.theme.fontSizeSmall
                            clip: true
                            onEditingFinished: root.config.profileImagePath = text
                        }
                    }
                    Text {
                        text: ui.detectedProfilePath.length > 0
                              ? "Detected: " + ui.detectedProfilePath
                              : "No system login picture found (checked ~/.face and AccountsService)"
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall - 1
                    }

                    Text {
                        text: "Bar background opacity"
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall
                        topPadding: 8
                    }
                    CustomSlider {
                        theme: root.theme
                        width: 260
                        value: root.config.barOpacity
                        onMoved: (v) => root.config.barOpacity = v
                    }

                    Text {
                        text: "Weather location (lat, lon, label)"
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall
                        topPadding: 8
                    }
                    Row {
                        spacing: 8
                        Rectangle {
                            width: 90; height: 30; radius: root.theme.radiusSmall; color: root.theme.card
                            TextInput {
                                anchors.fill: parent; anchors.margins: 8
                                text: String(root.config.weatherLat)
                                color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall; clip: true
                                onEditingFinished: { var v = parseFloat(text); if (!isNaN(v)) root.config.weatherLat = v; }
                            }
                        }
                        Rectangle {
                            width: 90; height: 30; radius: root.theme.radiusSmall; color: root.theme.card
                            TextInput {
                                anchors.fill: parent; anchors.margins: 8
                                text: String(root.config.weatherLon)
                                color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall; clip: true
                                onEditingFinished: { var v = parseFloat(text); if (!isNaN(v)) root.config.weatherLon = v; }
                            }
                        }
                        Rectangle {
                            width: 120; height: 30; radius: root.theme.radiusSmall; color: root.theme.card
                            TextInput {
                                anchors.fill: parent; anchors.margins: 8
                                text: root.config.weatherCity
                                color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall; clip: true
                                onEditingFinished: root.config.weatherCity = text
                            }
                        }
                    }

                    Text {
                        text: "Wallpaper folder"
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall
                        topPadding: 8
                    }
                    Rectangle {
                        width: 300; height: 30; radius: root.theme.radiusSmall
                        color: root.theme.card
                        TextInput {
                            anchors.fill: parent
                            anchors.margins: 8
                            text: root.config.wallpaperDir
                            color: root.theme.text
                            font.pixelSize: root.theme.fontSizeSmall
                            clip: true
                            onEditingFinished: root.config.wallpaperDir = text
                        }
                    }

                    Text {
                        text: "Cava Desktop Visualizer"
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall
                        topPadding: 8
                    }
                    Row {
                        width: 320
                        height: 26
                        Text {
                            width: parent.width - 50
                            text: "Run Cava in background"
                            color: root.theme.text
                            font.pixelSize: root.theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        ToggleSwitch {
                            id: cavaToggle
                            theme: root.theme
                            property bool isOn: false
                            checked: isOn
                            anchors.verticalCenter: parent.verticalCenter
                            onToggled: (v) => {
                                isOn = v;
                                if (v) {
                                    Hyprland.dispatch("hl.exec_cmd(\"sleep 2 && foot --app-id=window-bg -o colors-dark.alpha=0.0 -e sh -c 'sleep 1 && cava'\")");
                                } else {
                                    shellProc.command = ["bash", "-c", "pkill foot"];
                                    shellProc.running = true;
                                }
                            }
                        }
                    }
                }
            }

            // ---- Clock & Bar ----
            Flickable {
                visible: root.currentTab === 1
                anchors.fill: parent
                anchors.margins: 24
                contentWidth: width
                contentHeight: clockBarColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: clockBarColumn
                    width: parent.width
                    spacing: 14

                    Text { text: "Clock & Bar"; color: root.theme.text; font.pixelSize: 18; font.bold: true }

                    Repeater {
                        model: [
                            { label: "24-hour clock", key: "use24h" },
                            { label: "Show seconds", key: "showSeconds" },
                            { label: "Show weekday", key: "showWeekday" }
                        ]
                        Row {
                            required property var modelData
                            width: 320
                            height: 26
                            Text {
                                width: parent.width - 50
                                text: modelData.label
                                color: root.theme.text
                                font.pixelSize: root.theme.fontSizeSmall
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            ToggleSwitch {
                                theme: root.theme
                                checked: root.config[modelData.key]
                                anchors.verticalCenter: parent.verticalCenter
                                onToggled: (v) => root.config[modelData.key] = v
                            }
                        }
                    }

                    Text { text: "Bar position"; color: root.theme.subtext; font.pixelSize: root.theme.fontSizeSmall; topPadding: 6 }
                    Row {
                        spacing: 8
                        Repeater {
                            model: ["top", "bottom"]
                            Rectangle {
                                required property string modelData
                                width: 90; height: 30
                                radius: root.theme.radiusSmall
                                color: root.config.barPosition === modelData ? root.theme.accent : root.theme.card
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    color: root.config.barPosition === parent.modelData ? root.theme.bg : root.theme.text
                                    font.pixelSize: root.theme.fontSizeSmall
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.config.barPosition = parent.modelData
                                }
                            }
                        }
                    }

                    // Bar inset: drives the bar's margins AND the spacing of
                    // every popout panel, so they all stay flush with it.
                    Text {
                        text: "Bar margin & gap (" + Math.round(root.config.barGap) + "px)"
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall
                        topPadding: 10
                    }
                    CustomSlider {
                        theme: root.theme
                        width: 260
                        // Maps 0-30 pixels onto the 0.0 - 1.0 slider value
                        value: root.config.barGap / 30.0
                        onMoved: (v) => root.config.barGap = Math.round(v * 30)
                    }

                    Text {
                        text: "Bar icons   choose what shows up in the bar"
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall
                        topPadding: 10
                    }
                    Grid {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 6
                        Repeater {
                            model: [
                                { label: "App launcher", key: "barShowLauncher" },
                                { label: "Workspaces", key: "barShowWorkspaces" },
                                { label: "Media controls", key: "barShowMedia" },
                                { label: "System tray", key: "barShowTray" },
                                { label: "Volume", key: "barShowVolume" },
                                { label: "Wi-Fi", key: "barShowWifi" },
                                { label: "Bluetooth", key: "barShowBluetooth" },
                                { label: "Notifications", key: "barShowNotifications" },
                                { label: "Power", key: "barShowPower" },
                                { label: "Settings", key: "barShowSettings" },
                                { label: "Battery", key: "showBattery" },
                                { label: "Idle inhibitor (keep-awake)", key: "showIdleInhibitor" }
                            ]
                            Row {
                                required property var modelData
                                width: 150
                                height: 26
                                Text {
                                    width: parent.width - 46
                                    text: modelData.label
                                    color: root.theme.text
                                    font.pixelSize: root.theme.fontSizeSmall
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                ToggleSwitch {
                                    theme: root.theme
                                    checked: root.config[modelData.key]
                                    anchors.verticalCenter: parent.verticalCenter
                                    onToggled: (v) => root.config[modelData.key] = v
                                }
                            }
                        }
                    }
                }
            }

            // ---- Notifications ----
            Column {
                visible: root.currentTab === 2
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                Text { text: "Notifications"; color: root.theme.text; font.pixelSize: 18; font.bold: true }

                Repeater {
                    model: [
                        { label: "Do Not Disturb", key: "dndEnabled" },
                        { label: "Notification sound", key: "notifSoundEnabled" }
                    ]
                    Row {
                        required property var modelData
                        width: 320
                        height: 26
                        Text {
                            width: parent.width - 50
                            text: modelData.label
                            color: root.theme.text
                            font.pixelSize: root.theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        ToggleSwitch {
                            theme: root.theme
                            checked: root.config[modelData.key]
                            anchors.verticalCenter: parent.verticalCenter
                            onToggled: (v) => root.config[modelData.key] = v
                        }
                    }
                }

                Text {
                    text: "If notifications never appear, another daemon (mako/dunst/swaync)\nis probably already registered   disable it in your Hyprland autostart,\nthen restart Quickshell. Only one app can own the notification service\nat a time; this shell can't override that."
                    color: root.theme.subtext
                    font.pixelSize: root.theme.fontSizeSmall - 1
                    wrapMode: Text.Wrap
                    width: 380
                    topPadding: 10
                }

                Process { id: testNotifProc; running: false }
                Rectangle {
                    width: 160; height: 30; radius: root.theme.radiusSmall
                    color: testNotifMouse.containsMouse ? root.theme.cardHover : root.theme.card
                    Text { anchors.centerIn: parent; text: "Send test notification"; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall }
                    MouseArea {
                        id: testNotifMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            testNotifProc.command = ["notify-send", "Test notification", "If you see this as a toast, notifications are working."];
                            testNotifProc.running = true;
                        }
                    }
                }
                Text {
                    text: "If it appears in your system tray/another popup instead of this shell,\nthat confirms another daemon has the notification service."
                    color: root.theme.subtext
                    font.pixelSize: root.theme.fontSizeSmall - 1
                    wrapMode: Text.Wrap
                    width: 380
                }
            }

            // ---- Connectivity ----
            Column {
                visible: root.currentTab === 3
                anchors.fill: parent
                anchors.margins: 24
                spacing: 12

                Text { text: "Connectivity"; color: root.theme.text; font.pixelSize: 18; font.bold: true }
                Text {
                    text: "Wi-Fi and Bluetooth have their own quick panels from the bar icons.\nUse the buttons below to open them from here too."
                    color: root.theme.subtext
                    font.pixelSize: root.theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    width: 380
                }

                Row {
                    spacing: 10
                    topPadding: 6
                    Rectangle {
                        width: 110; height: 32; radius: root.theme.radiusSmall; color: root.theme.card
                        Text { anchors.centerIn: parent; text: "Wi-Fi"; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.ui.togglePanel("wifi") }
                    }
                    Rectangle {
                        width: 110; height: 32; radius: root.theme.radiusSmall; color: root.theme.card
                        Text { anchors.centerIn: parent; text: "Bluetooth"; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.ui.togglePanel("bluetooth") }
                    }
                }
            }

            // ---- Power ----
            Column {
                visible: root.currentTab === 4
                anchors.fill: parent
                anchors.margins: 24
                spacing: 10

                Text { text: "Power"; color: root.theme.text; font.pixelSize: 18; font.bold: true }

                Rectangle {
                    width: 160; height: 34; radius: root.theme.radiusSmall
                    color: wlogoutMouse.containsMouse ? root.theme.accentDim : root.theme.accent
                    Text { anchors.centerIn: parent; text: "Open wlogout"; color: root.theme.bg; font.pixelSize: root.theme.fontSizeSmall; font.bold: true }
                    MouseArea {
                        id: wlogoutMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { shellProc.command = ["wlogout"]; shellProc.running = true; }
                    }
                }

                Text {
                    text: "Same as the power icon in the bar. The actions below run directly,\nwithout wlogout, in case you ever need a fallback."
                    color: root.theme.subtext
                    font.pixelSize: root.theme.fontSizeSmall - 1
                    wrapMode: Text.Wrap
                    width: 380
                }

                Repeater {
                    model: [
                        { label: "Lock screen", cmd: ["hyprlock"] },
                        { label: "Suspend", cmd: ["systemctl", "suspend"] },
                        { label: "Restart", cmd: ["systemctl", "reboot"] },
                        { label: "Shut down", cmd: ["systemctl", "poweroff"] },
                        { label: "Log out of Hyprland", cmd: ["hyprctl", "dispatch", "exit"] }
                    ]
                    Rectangle {
                        required property var modelData
                        width: 220; height: 32
                        radius: root.theme.radiusSmall
                        color: powerMouse.containsMouse ? root.theme.cardHover : root.theme.card
                        Text { anchors.centerIn: parent; text: parent.modelData.label; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall }
                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { shellProc.command = parent.modelData.cmd; shellProc.running = true; }
                        }
                    }
                }
            }

            // ---- System ----
            Column {
                visible: root.currentTab === 5
                anchors.fill: parent
                anchors.margins: 24
                spacing: 10

                Text { text: "System"; color: root.theme.text; font.pixelSize: 18; font.bold: true }

                Process {
                    id: sysInfoProc
                    running: true
                    command: ["bash", "-lc", "echo \"$(hostname)\"; uname -srm; uptime -p 2>/dev/null || echo unknown"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            var lines = this.text.trim().split("\n");
                            sysInfoText.hostname = lines[0] || "unknown";
                            sysInfoText.kernel = lines[1] || "unknown";
                            sysInfoText.uptime = lines[2] || "unknown";
                        }
                    }
                }
                QtObject {
                    id: sysInfoText
                    property string hostname: "loading"
                    property string kernel: "loading"
                    property string uptime: "loading"
                }

                Repeater {
                    model: [
                        { label: "Hostname", value: sysInfoText.hostname },
                        { label: "Kernel", value: sysInfoText.kernel },
                        { label: "Uptime", value: sysInfoText.uptime }
                    ]
                    Row {
                        required property var modelData
                        width: 380; height: 22; spacing: 8
                        Text { width: 90; text: modelData.label; color: root.theme.subtext; font.pixelSize: root.theme.fontSizeSmall }
                        Text { text: modelData.value; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall }
                    }
                }

                Rectangle {
                    width: 100; height: 28; radius: root.theme.radiusSmall; color: root.theme.card
                    Text { anchors.centerIn: parent; text: "Refresh"; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sysInfoProc.running = true }
                }
            }

            // ---- Shortcuts ----
            Column {
                visible: root.currentTab === 6
                anchors.fill: parent
                anchors.margins: 24
                spacing: 10

                Text { text: "Shortcuts"; color: root.theme.text; font.pixelSize: 18; font.bold: true }
                Text {
                    text: "These are this shell's own interactions   your actual key bindings\nlive in Hyprland's config, not here."
                    color: root.theme.subtext
                    font.pixelSize: root.theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    width: 420
                }

                Repeater {
                    model: [
                        { action: "Open dashboard", how: "Hover the center clock" },
                        { action: "Open app launcher", how: "Click the apps icon (top-left)" },
                        { action: "Open Wi-Fi / Bluetooth", how: "Click their bar icons" },
                        { action: "Notification history", how: "Click the bell icon" },
                        { action: "Power menu", how: "Click the power icon" },
                        { action: "Launch a highlighted app", how: "Enter, in the app launcher search" },
                        { action: "Close the app launcher", how: "Esc, in the search box" }
                    ]
                    Row {
                        required property var modelData
                        width: 420; height: 24; spacing: 8
                        Text { width: 200; text: modelData.action; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall }
                        Text { text: modelData.how; color: root.theme.subtext; font.pixelSize: root.theme.fontSizeSmall }
                    }
                }
            }

            // ---- About ----
            Column {
                visible: root.currentTab === 7
                anchors.fill: parent
                anchors.margins: 24
                spacing: 10

                Text { text: "About this shell"; color: root.theme.text; font.pixelSize: 18; font.bold: true }
                Text {
                    text: "A Quickshell + Hyprland desktop shell inspired by DankMaterialShell:\nbar, tabbed dashboard (Overview/Media/Wallpapers/Weather/Settings),\nWi-Fi/Bluetooth/notification popups, an OSD, and this settings page.\n\nConfig lives at ~/.config/quickshell   edit modules/Theme.qml\nfor colors, or settings.json for saved preferences."
                    color: root.theme.subtext
                    font.pixelSize: root.theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    width: 400
                }
            }
        }
    }
}
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

PanelWindow {
    id: root
    required property var theme
    required property var config
    required property var ui
    required property var notifServer

    anchors {
        top: config.barPosition === "top"
        bottom: config.barPosition === "bottom"
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Auto
    
    // THIS CONTROLS THE SPACE BETWEEN THE BAR AND YOUR APPS:
    // Change the "+ 4" to a higher number (like + 10) for more space, 
    // or a lower number (like + 0) for less space.
    implicitHeight: root.theme.barHeight + root.theme.gap
    
    color: "transparent"

    property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    readonly property var audioPlayers: Mpris.players.values
    function _autoPlayerIndex() {
        for (var i = 0; i < root.audioPlayers.length; i++) {
            var p = root.audioPlayers[i];
            var name = ((p.identity || "") + " " + (p.desktopEntry || "")).toLowerCase();
            if (name.indexOf("spotify") !== -1) return i;
        }
        return root.audioPlayers.length > 0 ? 0 : -1;
    }
    property var player: _autoPlayerIndex() >= 0 ? audioPlayers[_autoPlayerIndex()] : null

    property bool idleInhibited: false
    Process {
        id: idleInhibitProc
        running: root.idleInhibited
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=Quickshell",
                  "--why=User requested", "sleep", "infinity"]
        onExited: (exitCode) => {
            if (exitCode === 127) root.idleInhibited = false;
        }
    }
    Process {
        id: wlogoutProc
        running: false
        command: ["bash", "-lc", "wlogout"]
        onExited: (exitCode) => {
            if (exitCode === 127) root.ui.togglePanel("power");
        }
    }

    // --- ONE CONTINUOUS UNIFIED BAR ---
    Rectangle {
        id: barContent
        
        // Lock the bar to the top with a strict height so it never squishes
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.theme.barHeight
        
        // This margin pushes the bar away from the top/left/right edges of your monitor
        anchors.topMargin: root.theme.gap
        anchors.leftMargin: root.theme.gap
        anchors.rightMargin: root.theme.gap
        
        radius: height / 2
        color: root.theme.pill

        // ---------- Left: launcher + workspaces ----------
        Row {
            id: leftGroup
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            IconButton {
                visible: root.config.barShowLauncher
                theme: root.theme
                label: "apps"
                active: root.ui.openPanel === "launcher"
                onClicked: root.ui.togglePanel("launcher")
                anchors.verticalCenter: parent.verticalCenter
            }
            Workspaces { 
                visible: root.config.barShowWorkspaces
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ---------- Right: media mini, tray, system icons ----------
        Row {
            id: rightGroup
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Row {
                visible: root.config.barShowMedia && root.player !== null
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Text {
                    text: "skip_previous"
                    color: (root.player && root.player.canGoPrevious) ? root.theme.text : root.theme.subtext
                    font.family: root.theme.iconFontFamily
                    font.pixelSize: root.theme.iconFontSize
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                    }
                }
                Text {
                    text: (root.player && root.player.isPlaying) ? "pause" : "play_arrow"
                    color: root.theme.accent
                    font.family: root.theme.iconFontFamily
                    font.pixelSize: root.theme.iconFontSize
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                    }
                }
                Text {
                    text: "skip_next"
                    color: (root.player && root.player.canGoNext) ? root.theme.text : root.theme.subtext
                    font.family: root.theme.iconFontFamily
                    font.pixelSize: root.theme.iconFontSize
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player && root.player.canGoNext) root.player.next()
                    }
                }
            }

            TrayIcons { 
                visible: root.config.barShowTray
                theme: root.theme
                ui: root.ui
                anchors.verticalCenter: parent.verticalCenter 
            }

            BatteryIndicator { 
                id: battery
                visible: root.config.showBattery && battery.hasBattery
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter 
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Row {
                    visible: root.config.barShowVolume
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    IconButton {
                        theme: root.theme
                        label: (root.sink && root.sink.audio && root.sink.audio.muted) ? "volume_off" : "volume_up"
                        onClicked: {
                            if (root.sink && root.sink.ready && root.sink.audio)
                                root.sink.audio.muted = !root.sink.audio.muted;
                        }
                    }
                    Text {
                        text: (root.sink && root.sink.audio && !root.sink.audio.muted)
                              ? Math.round(root.sink.audio.volume * 100) + "%" : "muted"
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                IconButton {
                    theme: root.theme
                    label: "wifi"
                    visible: root.config.barShowWifi
                    active: root.ui.openPanel === "wifi"
                    onClicked: root.ui.togglePanel("wifi")
                }
                IconButton {
                    theme: root.theme
                    label: "bluetooth"
                    visible: root.config.barShowBluetooth
                    active: root.ui.openPanel === "bluetooth"
                    onClicked: root.ui.togglePanel("bluetooth")
                }
                IconButton {
                    theme: root.theme
                    label: root.config.dndEnabled ? "do_not_disturb_on" : "notifications"
                    visible: root.config.barShowNotifications
                    showBadge: !root.config.dndEnabled
                    badgeCount: root.notifServer.trackedNotifications.values.length
                    active: root.ui.openPanel === "notifications"
                    onClicked: root.ui.togglePanel("notifications")
                }
                IconButton {
                    theme: root.theme
                    label: "power_settings_new"
                    visible: root.config.barShowPower
                    onClicked: wlogoutProc.running = true
                }
                IconButton {
                    theme: root.theme
                    label: root.idleInhibited ? "motion_photos_paused" : "coffee"
                    visible: root.config.showIdleInhibitor
                    active: root.idleInhibited
                    onClicked: root.idleInhibited = !root.idleInhibited
                }
                IconButton {
                    theme: root.theme
                    label: "settings"
                    visible: root.config.barShowSettings
                    active: root.ui.settingsOpen
                    onClicked: root.ui.settingsOpen = !root.ui.settingsOpen
                }
            }
        }

        // ---------- Center: waveform + clock ----------
        property real sideWidth: Math.max(leftGroup.width, rightGroup.width) + 20
        Item {
            id: middleRegion
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: barContent.sideWidth
            anchors.rightMargin: barContent.sideWidth
            clip: true

            Row {
                id: centerRow
                anchors.centerIn: parent
                spacing: 10
                
                AudioWaveform {
                    theme: root.theme
                    playing: root.player !== null && root.player.isPlaying
                    visible: root.player !== null && root.player.isPlaying
                    anchors.verticalCenter: parent.verticalCenter
                }
                ClockCenter {
                    theme: root.theme
                    config: root.config
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            HoverHandler {
                onHoveredChanged: root.ui.clockHovered = hovered
            }
        }
    }
}
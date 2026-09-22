//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "./modules"

ShellRoot {
    id: shellRoot

    Theme { id: theme }
    UiState { id: ui }

    // Live-apply the persisted accent color and UI scale onto the theme.
    Binding { target: theme; property: "accent"; value: config.accentColor }
    Binding { target: theme; property: "scale"; value: config.uiScale }

    // Best-effort detection of the system login picture (SDDM/GDM/
    // AccountsService/lightdm conventions), used as the dashboard profile
    // picture unless the person sets a custom path in Settings.
    Process {
        running: true
        command: ["bash", "-lc",
            "for f in \"$HOME/.face\" \"$HOME/.face.icon\" " +
            "\"/var/lib/AccountsService/icons/$USER\" " +
            "\"/usr/share/sddm/faces/$USER.face.icon\" " +
            "\"/usr/share/sddm/faces/$USER.face\"; do " +
            "[ -f \"$f\" ] && echo \"$f\" && break; done"]
        stdout: StdioCollector {
            onStreamFinished: ui.detectedProfilePath = this.text.trim()
        }
    }

    FileView {
        id: settingsFile
        path: Quickshell.shellDir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: config
            property bool use24h: true
            property bool showSeconds: false
            property bool showWeekday: true
            property string barPosition: "top"
            property real barOpacity: 0.85
            property bool notifSoundEnabled: true
            property bool dndEnabled: false
            property string accentColor: "#ab97f0"
            property string wallpaperDir: "~/Pictures/Wallpapers"
            property string lastWallpaper: ""
            property real weatherLat: 26.7271
            property real weatherLon: 88.3953
            property string weatherCity: "Siliguri"
            property real uiScale: 1.0
            property string profileImagePath: ""
            property bool barShowLauncher: true
            property bool barShowWorkspaces: true
            property bool barShowMedia: true
            property bool barShowTray: true
            property bool barShowVolume: true
            property bool barShowWifi: true
            property bool barShowBluetooth: true
            property bool barShowNotifications: true
            property bool barShowPower: true
            property bool barShowSettings: true
            property bool showBattery: true
            property bool showIdleInhibitor: true
        }
    }

    NotificationServer {
        id: notifServer
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: (notification) => {
            notification.tracked = true;
            if (config.notifSoundEnabled && !config.dndEnabled) soundProc.running = true;
        }
    }

    Process {
        id: soundProc
        running: false
        command: ["paplay", "/usr/share/sounds/freedesktop/stereo/message.oga"]
    }

    Bar {
        theme: theme
        config: config
        ui: ui
        notifServer: notifServer
    }

    Dashboard {
        theme: theme
        config: config
        ui: ui
        osd: osdPopup
    }

    WifiPanel {
        theme: theme
        ui: ui
    }

    AppLauncher {
        theme: theme
        ui: ui
    }

    BluetoothPanel {
        theme: theme
        ui: ui
    }

    PowerMenuPanel {
        theme: theme
        ui: ui
    }

    TrayContextMenu {
        theme: theme
        ui: ui
    }

    NotificationPanel {
        theme: theme
        ui: ui
        notifServer: notifServer
    }

    NotificationToasts {
        theme: theme
        config: config
        notifServer: notifServer
    }

    OsdPopup {
        id: osdPopup
        theme: theme
    }

    SettingsApp {
        theme: theme
        config: config
        ui: ui
    }
}

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
    required property var osd

    anchors {
        top: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitHeight: screen ? screen.height : 900
    focusable: false
    visible: ui.dashboardOpen

    // No mask here on purpose: the whole window catches clicks now, so a
    // click anywhere outside the card closes the dashboard (the click is
    // consumed, same as any normal dropdown/menu   it doesn't also reach
    // whatever's underneath, which matches how click-outside-to-close
    // works everywhere else).

    property int currentTab: 0

    readonly property var tabs: [
        { label: "Overview", icon: "grid_view" },
        { label: "Audio", icon: "graphic_eq" },
        { label: "Media", icon: "music_note" },
        { label: "Wallpapers", icon: "image" },
        { label: "Weather", icon: "wb_sunny" },
        { label: "Settings", icon: "settings" }
    ]

    // The profile picture shown on Overview: an explicit override in
    // Settings wins, otherwise the auto-detected system login picture,
    // otherwise no image at all (falls back to an initial-letter avatar).
    readonly property string profileImage: config.profileImagePath.length > 0
        ? config.profileImagePath : ui.detectedProfilePath

    // One shared weather state for the whole dashboard   both the Overview
    // card and the Weather tab point at this, so fetching once (from
    // either place) updates both and neither ever needs a second refresh.
    WeatherState {
        id: weatherState
        config: root.config
    }

    // ---- Pipewire volume + mic ----
    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source] }

    // Audio tab media player: auto-picks Spotify if it's among the active
    // MPRIS players (checked by identity/desktopEntry), otherwise the
    // first available player. A manual pick (clicking a chip) overrides
    // this until the player list changes.
    readonly property var audioPlayers: Mpris.players.values
    property int manualPlayerIndex: -1

    function _autoPlayerIndex() {
        for (var i = 0; i < root.audioPlayers.length; i++) {
            var p = root.audioPlayers[i];
            var name = ((p.identity || "") + " " + (p.desktopEntry || "")).toLowerCase();
            if (name.indexOf("spotify") !== -1) return i;
        }
        return root.audioPlayers.length > 0 ? 0 : -1;
    }

    readonly property int effectivePlayerIndex:
        (root.manualPlayerIndex >= 0 && root.manualPlayerIndex < root.audioPlayers.length)
        ? root.manualPlayerIndex : root._autoPlayerIndex()

    readonly property var effectivePlayer:
        root.effectivePlayerIndex >= 0 ? root.audioPlayers[root.effectivePlayerIndex] : null

    // ---- Brightness (best effort via brightnessctl) ----
    property real brightness: 0.7
    property int _curBrightness: 0

    Process {
        id: brightnessGet
        running: root.visible
        command: ["brightnessctl", "g"]
        stdout: StdioCollector {
            onStreamFinished: {
                var cur = parseInt(this.text.trim());
                if (!isNaN(cur)) { brightnessMaxGet.running = true; root._curBrightness = cur; }
            }
        }
    }

    Process {
        id: brightnessMaxGet
        running: false
        command: ["brightnessctl", "m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split(",");
                var max = parts.length > 2 ? parseInt(parts[2]) : 0;
                if (max > 0) root.brightness = root._curBrightness / max;
            }
        }
    }

    Process { id: brightnessSet; running: false }
    function setBrightness(v) {
        var pct = Math.round(v * 100);
        brightnessSet.command = ["brightnessctl", "s", pct + "%"];
        brightnessSet.running = true;
        if (root.osd) root.osd.showBrightness(v);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.ui.closeDashboard()
    }

    Rectangle {
        id: card
        width: Math.min(740, root.width - 32)
        height: Math.min(520, root.height - root.theme.barHeight - 24)
        radius: root.theme.radius
        color: root.theme.bg
        border.color: root.theme.border
        border.width: 1
        clip: true

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.theme.barHeight + root.theme.gap

        HoverHandler {
            onHoveredChanged: root.ui.dashboardHovered = hovered
        }

        // Absorbs clicks on blank space within the card (margins, gaps
        // between cards, the tab bar background, etc.) so they don't fall
        // through to the outer background catcher and accidentally close
        // the dashboard. Actual interactive content below still gets
        // priority for its own clicks since it's declared after this.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            spacing: 0

            // ---------------- Tab bar ----------------
            Row {
                width: parent.width
                height: 60
                spacing: 0

                Repeater {
                    model: root.tabs
                    Item {
                        id: tabItem
                        required property var modelData
                        required property int index
                        width: card.width / root.tabs.length
                        height: parent.height

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tabItem.modelData.icon
                                font.family: root.theme.iconFontFamily
                                font.pixelSize: 18
                                color: root.currentTab === tabItem.index ? root.theme.accent : root.theme.subtext
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tabItem.modelData.label
                                font.pixelSize: root.theme.fontSizeSmall
                                font.bold: root.currentTab === tabItem.index
                                color: root.currentTab === tabItem.index ? root.theme.accent : root.theme.subtext
                            }
                        }

                        Rectangle {
                            visible: root.currentTab === tabItem.index
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 28
                            height: 2
                            radius: 1
                            color: root.theme.accent
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = tabItem.index
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: root.theme.border }

            // ---------------- Tab content ----------------
            Item {
                width: parent.width
                height: parent.height - 61

                // ============ Overview (decluttered: no sliders here   see Audio tab) ============
                Column {
                    visible: root.currentTab === 0
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Row {
                        width: parent.width
                        height: 120
                        spacing: 12

                        // Time / date card
                        Rectangle {
                            width: (parent.width - 24) / 3
                            height: parent.height
                            radius: root.theme.radiusSmall
                            color: root.theme.card
                            clip: true

                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Qt.formatDateTime(new Date(), root.config.use24h ? "HH:mm" : "hh:mm AP")
                                    color: root.theme.text
                                    font.pixelSize: root.theme.fontSizeLarge
                                    font.bold: true
                                    font.family: "monospace"
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Qt.formatDateTime(new Date(), "MMM dd")
                                    color: root.theme.subtext
                                    font.pixelSize: root.theme.fontSizeSmall
                                }
                            }
                        }

                        // Weather card (compact)
                        Rectangle {
                            width: (parent.width - 24) / 3
                            height: parent.height
                            radius: root.theme.radiusSmall
                            color: root.theme.card
                            clip: true

                            WeatherWidget {
                                theme: root.theme
                                config: root.config
                                state: weatherState
                                compact: true
                                anchors.fill: parent
                            }
                        }

                        // Profile card   system login picture, a custom
                        // override, or an initial-letter avatar as fallback.
                        Rectangle {
                            width: (parent.width - 24) / 3
                            height: parent.height
                            radius: root.theme.radiusSmall
                            color: root.theme.card
                            clip: true

                            Row {
                                anchors.centerIn: parent
                                spacing: 10

                                Rectangle {
                                    id: avatarFrame
                                    width: 52
                                    height: 52
                                    radius: 26
                                    color: root.theme.accentDim
                                    anchors.verticalCenter: parent.verticalCenter
                                    clip: true

                                    Image {
                                        id: avatarImg
                                        anchors.fill: parent
                                        visible: status === Image.Ready
                                        source: root.profileImage.length > 0 ? "file://" + root.profileImage : ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: avatarImg.status !== Image.Ready
                                        text: (Quickshell.env("USER") || "?").substring(0, 1).toUpperCase()
                                        color: root.theme.bg
                                        font.pixelSize: 20
                                        font.bold: true
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text {
                                        text: Quickshell.env("USER") || "user"
                                        color: root.theme.text
                                        font.pixelSize: root.theme.fontSize
                                        font.bold: true
                                    }
                                    Text {
                                        text: "on Hyprland"
                                        color: root.theme.subtext
                                        font.pixelSize: root.theme.fontSizeSmall
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: parent.height - 120 - 12
                        spacing: 12

                        // Calendar card   roomier now that sliders moved to their own tab
                        Rectangle {
                            width: (parent.width - 12) * 0.58
                            height: parent.height
                            radius: root.theme.radiusSmall
                            color: root.theme.card
                            clip: true

                            Calendar {
                                theme: root.theme
                                anchors.centerIn: parent
                                width: parent.width - 32
                                height: parent.height - 24
                            }
                        }

                        // Media card
                        Rectangle {
                            width: (parent.width - 12) * 0.42
                            height: parent.height
                            radius: root.theme.radiusSmall
                            color: root.theme.card
                            clip: true

                            MediaPlayerWidget {
                                theme: root.theme
                                anchors.fill: parent
                                anchors.margins: 12
                            }
                        }
                    }
                }

                // ============ Audio (dedicated tab) ============
                Item {
                    visible: root.currentTab === 1
                    anchors.fill: parent
                    anchors.margins: 24

                    Column {
                        id: audioHeaderCol
                        width: parent.width
                        spacing: 16

                        Text { text: "Audio & Brightness"; color: root.theme.text; font.pixelSize: 18; font.bold: true }

                        Row {
                            width: parent.width
                            height: 170
                            spacing: 40

                            VerticalSlider {
                                theme: root.theme
                                width: 60
                                height: parent.height
                                icon: (root.sink && root.sink.audio && root.sink.audio.muted) ? "volume_off" : "volume_up"
                                muted: !!(root.sink && root.sink.audio && root.sink.audio.muted)
                                value: root.sink && root.sink.audio ? root.sink.audio.volume : 0.5
                                onMoved: (v) => {
                                    if (root.sink && root.sink.ready && root.sink.audio) {
                                        root.sink.audio.muted = false;
                                        root.sink.audio.volume = v;
                                    }
                                }
                                onIconClicked: {
                                    if (root.sink && root.sink.ready && root.sink.audio)
                                        root.sink.audio.muted = !root.sink.audio.muted;
                                }
                            }

                            VerticalSlider {
                                theme: root.theme
                                width: 60
                                height: parent.height
                                icon: (root.source && root.source.audio && root.source.audio.muted) ? "mic_off" : "mic"
                                muted: !!(root.source && root.source.audio && root.source.audio.muted)
                                value: root.source && root.source.audio ? root.source.audio.volume : 0.5
                                onMoved: (v) => {
                                    if (root.source && root.source.ready && root.source.audio) {
                                        root.source.audio.muted = false;
                                        root.source.audio.volume = v;
                                    }
                                }
                                onIconClicked: {
                                    if (root.source && root.source.ready && root.source.audio)
                                        root.source.audio.muted = !root.source.audio.muted;
                                }
                            }

                            VerticalSlider {
                                theme: root.theme
                                width: 60
                                height: parent.height
                                icon: "brightness_6"
                                value: root.brightness
                                onMoved: (v) => root.setBrightness(v)
                            }

                            Column {
                                spacing: 6
                                width: parent.width - 3 * 60 - 120

                                Text { text: "Output device"; color: root.theme.subtext; font.pixelSize: root.theme.fontSizeSmall }
                                Text {
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    text: (root.sink && root.sink.description) ? root.sink.description : "Default output"
                                    color: root.theme.text
                                    font.pixelSize: root.theme.fontSizeSmall
                                }

                                Text { text: "Input device"; color: root.theme.subtext; font.pixelSize: root.theme.fontSizeSmall; topPadding: 10 }
                                Text {
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    text: (root.source && root.source.description) ? root.source.description : "Default input"
                                    color: root.theme.text
                                    font.pixelSize: root.theme.fontSizeSmall
                                }
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: root.theme.border }
                    }

                    // Cava Visualizer Card
                    Rectangle {
                        anchors.top: audioHeaderCol.bottom
                        anchors.topMargin: 16
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        radius: root.theme.radiusSmall
                        color: root.theme.card
                        clip: true

                        CavaVisualizer {
                            theme: root.theme
                            anchors.fill: parent
                            anchors.margins: 20
                            bars: 36
                        }
                    }
                }

                // ============ Media (full-size) ============
                Column {
                    visible: root.currentTab === 2
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 12

                    Row {
                        width: parent.width
                        spacing: 10
                        visible: root.audioPlayers.length > 1

                        Text {
                            text: "Now Playing:"
                            color: root.theme.subtext
                            font.pixelSize: root.theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Repeater {
                            model: root.audioPlayers
                            Rectangle {
                                id: mediaTabPlayerChip
                                required property var modelData
                                required property int index
                                width: mediaTabChipLabel.implicitWidth + 20
                                height: 26
                                radius: 13
                                color: root.effectivePlayerIndex === index ? root.theme.accent : root.theme.card

                                Text {
                                    id: mediaTabChipLabel
                                    anchors.centerIn: parent
                                    text: mediaTabPlayerChip.modelData.identity || mediaTabPlayerChip.modelData.desktopEntry || "Player"
                                    color: root.effectivePlayerIndex === index ? root.theme.bg : root.theme.text
                                    font.pixelSize: root.theme.fontSizeSmall - 1
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.manualPlayerIndex = mediaTabPlayerChip.index
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: parent.height - (root.audioPlayers.length > 1 ? 38 : 0)
                        radius: root.theme.radiusSmall
                        color: root.theme.card
                        clip: true

                        MediaPlayerWidget {
                            theme: root.theme
                            large: true
                            player: root.effectivePlayer
                            anchors.centerIn: parent
                            width: parent.width - 60
                            height: parent.height - 40
                        }
                    }
                }

                // ============ Wallpapers ============
                Column {
                    visible: root.currentTab === 3
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    WallpaperGrid {
                        theme: root.theme
                        config: root.config
                        width: parent.width
                        height: parent.height
                    }
                }

                // ============ Weather (full-size) ============
                Column {
                    visible: root.currentTab === 4
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Rectangle {
                        width: parent.width
                        height: parent.height
                        radius: root.theme.radiusSmall
                        color: root.theme.card
                        clip: true

                        WeatherWidget {
                            theme: root.theme
                            config: root.config
                            state: weatherState
                            compact: false
                            anchors.fill: parent
                        }
                    }
                }

                // ============ Settings (shared with the standalone app) ============
                Item {
                    visible: root.currentTab === 5
                    anchors.fill: parent

                    SettingsPage {
                        anchors.fill: parent
                        theme: root.theme
                        config: root.config
                        ui: root.ui
                    }
                }
            }
        }
    }
}
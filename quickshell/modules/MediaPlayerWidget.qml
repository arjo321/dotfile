import QtQuick
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects 

Item {
    id: root
    required property var theme
    property bool large: false

    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    implicitHeight: large ? 260 : 72
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

    // --- BULLETPROOF SPOTIFY SYNC ---
    property real displayPos: 0
    property real lastPos: -1

    Timer {
        interval: 1000 
        running: root.large && root.player !== null && root.player.isPlaying
        repeat: true
        onTriggered: {
            if (root.player) {
                var actualPos = root.player.position || 0;
                
                // If Spotify actually sent an update, resync our timer
                if (actualPos !== root.lastPos && actualPos > 0) {
                    root.lastPos = actualPos;
                    root.displayPos = actualPos;
                } else {
                    // Otherwise, fake it locally based on the detected time scale
                    var len = root.player.length || 0;
                    if (len > 10000000) {
                        root.displayPos += 1000000; // Microseconds
                    } else if (len > 10000) {
                        root.displayPos += 1000;    // Milliseconds
                    } else {
                        root.displayPos += 1;       // Seconds
                    }
                }
            }
        }
    }

    // Reset when track changes to avoid ghost times
    Connections {
        target: root.player
        function onTrackArtUrlChanged() {
            root.displayPos = 0;
            root.lastPos = -1;
        }
    }

    // Blurred Background
    Image {
        anchors.fill: parent
        source: root.player ? root.player.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        visible: root.player && root.player.trackArtUrl !== ""
        asynchronous: true
        opacity: 0.15 
        scale: 1.1 
    }

    Rectangle {
        anchors.fill: parent
        color: root.theme.bg
        opacity: 0.8
    }

    Row {
        anchors.fill: parent
        anchors.margins: root.large ? 16 : 8
        spacing: root.large ? 24 : 16
        visible: root.player !== null

        // 1. PERFECT CIRCLE CD ART
        Item {
            width: root.large ? 228 : 56
            height: width 
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: maskRect
                anchors.fill: parent
                radius: width / 2
                visible: false 
            }

            Image {
                id: artImage
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false 
            }

            OpacityMask {
                id: cdArt
                anchors.fill: parent
                source: artImage
                maskSource: maskRect
                visible: root.player && root.player.trackArtUrl !== ""

                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 6000 
                    running: root.player && root.player.isPlaying
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: root.theme.border
                visible: root.player && root.player.trackArtUrl !== ""
            }

            Rectangle {
                width: root.large ? 32 : 12
                height: width
                radius: width / 2
                anchors.centerIn: parent
                color: root.theme.bg
                border.width: 1
                border.color: root.theme.border
                visible: root.player && root.player.trackArtUrl !== ""
            }

            Text {
                anchors.centerIn: parent
                text: "music_note"
                color: root.theme.subtext
                font.family: root.theme.iconFontFamily
                font.pixelSize: root.large ? 48 : 22
                visible: !root.player || root.player.trackArtUrl === ""
            }
        }

        // 2. Track Info & Controls
        Column {
            id: infoColumn
            width: parent.width - (root.large ? 228 : 56) - (root.large ? 24 : 16)
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.large ? 12 : 4

            // SMART TIME FORMATTER: Auto-detects seconds, milliseconds, or microseconds
            function formatTime(val) {
                if (!val || isNaN(val) || val <= 0) return "0:00";
                
                var totalSeconds = val;
                if (val > 10000000) { 
                    totalSeconds = Math.floor(val / 1000000); 
                } else if (val > 10000) {
                    totalSeconds = Math.floor(val / 1000);
                } else {
                    totalSeconds = Math.floor(val);
                }
                
                var minutes = Math.floor(totalSeconds / 60);
                var seconds = totalSeconds % 60;
                return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
            }

            Column {
                width: parent.width
                spacing: 2
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.player ? (root.player.trackTitle || "Unknown Title") : ""
                    color: root.theme.text
                    font.pixelSize: root.large ? 24 : root.theme.fontSize
                    font.bold: true
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.player ? (root.player.trackArtist || "Unknown Artist") : ""
                    color: root.theme.subtext
                    font.pixelSize: root.large ? 16 : root.theme.fontSizeSmall
                }
            }

            // Fixed Progress Bar
            Column {
                width: parent.width
                visible: root.large && root.player && root.player.length > 0
                spacing: 6
                
                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: root.theme.border

                    Rectangle {
                        width: root.player && root.player.length > 0 
                               ? Math.min(parent.width, parent.width * (root.displayPos / root.player.length)) 
                               : 0
                        height: parent.height
                        radius: parent.radius
                        color: root.theme.accent
                        
                        Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
                    }
                }
                
                Row {
                    width: parent.width
                    Text {
                        text: infoColumn.formatTime(root.displayPos)
                        color: root.theme.subtext
                        font.pixelSize: 12
                    }
                    Item { width: parent.width - parent.children[0].width - parent.children[2].width; height: 1 } 
                    Text {
                        text: infoColumn.formatTime(root.player ? root.player.length : 0)
                        color: root.theme.subtext
                        font.pixelSize: 12
                    }
                }
            }

            // Controls
            Row {
                spacing: root.large ? 24 : 16
                topPadding: root.large ? 8 : 4
                anchors.horizontalCenter: root.large ? parent.horizontalCenter : undefined

                Text {
                    id: prevBtn
                    text: "skip_previous"
                    color: (root.player && root.player.canGoPrevious) ? (prevMouse.containsMouse ? root.theme.accent : root.theme.text) : root.theme.border
                    font.family: root.theme.iconFontFamily
                    font.pixelSize: root.large ? 32 : 20
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        anchors.margins: -10
                        hoverEnabled: true
                        cursorShape: (root.player && root.player.canGoPrevious) ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                    }
                }

                Text {
                    id: playBtn
                    text: (root.player && root.player.isPlaying) ? "pause" : "play_arrow"
                    color: playMouse.containsMouse ? Qt.lighter(root.theme.accent, 1.2) : root.theme.accent
                    font.family: root.theme.iconFontFamily
                    font.pixelSize: root.large ? 38 : 22
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        anchors.margins: -10
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                    }
                }

                Text {
                    id: nextBtn
                    text: "skip_next"
                    color: (root.player && root.player.canGoNext) ? (nextMouse.containsMouse ? root.theme.accent : root.theme.text) : root.theme.border
                    font.family: root.theme.iconFontFamily
                    font.pixelSize: root.large ? 32 : 20
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        anchors.margins: -10
                        hoverEnabled: true
                        cursorShape: (root.player && root.player.canGoNext) ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (root.player && root.player.canGoNext) root.player.next()
                    }
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        visible: root.player === null
        spacing: 8
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "music_off"
            color: root.theme.border
            font.family: root.theme.iconFontFamily
            font.pixelSize: root.large ? 32 : 24
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No Media Playing"
            color: root.theme.subtext
            font.pixelSize: root.theme.fontSizeSmall
            font.bold: true
        }
    }
}

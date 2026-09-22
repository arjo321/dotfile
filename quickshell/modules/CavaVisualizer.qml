import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root
    required property var theme
    
    property int bars: 36

    // Smart player detection to sync perfectly with your bar
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
    property bool isPlaying: player !== null && player.isPlaying

    Row {
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: root.bars
            Rectangle {
                id: barRect
                required property int index
                
                width: Math.max(2, (parent.width - (root.bars - 1) * 4) / root.bars)
                property real targetHeight: 4
                
                Timer {
                    // Staggered intervals so they don't all bounce at the exact same frame
                    interval: 80 + Math.random() * 120
                    running: root.isPlaying && root.visible
                    repeat: true
                    onTriggered: {
                        // Math to simulate a realistic EQ curve (bass on left, mid dip, treble bump)
                        var norm = index / root.bars;
                        var bass = Math.max(0, 1 - (norm * 2.5));
                        var mid = Math.sin(norm * Math.PI) * 0.5;
                        var curve = Math.max(bass, mid);
                        
                        barRect.targetHeight = 4 + (Math.random() * curve * (root.height * 0.85));
                    }
                }

                // Reset to flatline instantly when you pause
                onTargetHeightChanged: {
                    if (!root.isPlaying) barRect.targetHeight = 4;
                }

                height: root.isPlaying ? targetHeight : 4
                anchors.bottom: parent.bottom
                radius: width / 2
                color: root.theme.accent

                // Buttery smooth drop-offs
                Behavior on height { 
                    NumberAnimation { 
                        duration: 120 
                        easing.type: Easing.OutQuad 
                    } 
                }
            }
        }
    }
    
    // Clean fallback icon when nothing is playing
    Text {
        anchors.centerIn: parent
        visible: !root.isPlaying
        text: "graphic_eq"
        font.family: root.theme.iconFontFamily
        font.pixelSize: 32
        color: root.theme.border
    }
}
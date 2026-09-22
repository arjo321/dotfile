import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property var theme
    required property var config

    property var files: []
    property bool loading: false
    property string applying: ""
    property string lastError: ""
    property string activeDir: ""

    function _dir() {
        var d = root.config.wallpaperDir || "";
        if (d.length === 0) return "";
        if (d.indexOf("~") === 0) d = Quickshell.env("HOME") + d.substring(1);
        return d;
    }
    
    function _basename(p) {
        var parts = p.split("/");
        return parts[parts.length - 1];
    }

    function refresh() {
        root.lastError = "";
        root.loading = true;
        var configured = root._dir();
        var candidates = [];
        if (configured.length > 0) candidates.push(configured);
        
        var home = Quickshell.env("HOME");
        candidates.push(home + "/Pictures/Wallpapers", home + "/Wallpapers",
                         home + "/.config/wallpapers", "/usr/share/backgrounds");
                         
        scanProc.command = ["bash", "-lc",
            "for d in " + candidates.map(d => JSON.stringify(d)).join(" ") + "; do " +
            "  m=$(ls -1 \"$d\" 2>/dev/null | grep -iE '\\.(jpg|jpeg|png|webp)$'); " +
            "  if [ -n \"$m\" ]; then echo \"DIR:$d\"; echo \"$m\"; break; fi; " +
            "done"];
        scanProc.running = true;
    }

    

    Process {
        id: scanProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                var lines = this.text.trim().length ? this.text.trim().split("\n") : [];
                if (lines.length === 0 || lines[0].indexOf("DIR:") !== 0) {
                    root.files = [];
                    root.activeDir = root._dir();
                    return;
                }
                var d = lines[0].substring(4);
                root.activeDir = d;
                root.files = lines.slice(1).map(function (f) { return d + "/" + f; });
            }
        }
    }

    Process {
        id: applyProc
        running: false
        property string targetPath: ""
        onExited: (exitCode) => {
            root.applying = "";
            if (exitCode !== 0) root.lastError = "Couldn't set wallpaper — is awww installed? (awww-daemon must be running)";
            else root.config.lastWallpaper = applyProc.targetPath;
        }
    }

    function apply(path) {
        root.applying = path;
        root.lastError = "";
        applyProc.targetPath = path;
        applyProc.command = ["bash", "-lc",
            "command -v awww >/dev/null 2>&1 || exit 1; " +
            "pgrep -x awww-daemon >/dev/null 2>&1 || (awww-daemon >/dev/null 2>&1 & sleep 0.4); " +
            "awww img " + JSON.stringify(path)];
        applyProc.running = true;
    }

    // ---------------- UI Layout ----------------

    // 1. Sleeker Header with better breathing room
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 56 // Increased for better touch/click targets
        
        Column {
            anchors.left: parent.left
            anchors.right: refreshBtn.left
            anchors.margins: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            
            Text {
                width: parent.width
                text: root.activeDir.length ? root.activeDir : "No wallpaper folder set"
                color: root.theme.text
                font.pixelSize: root.theme.fontSizeSmall + 2
                font.bold: true
                elide: Text.ElideMiddle
            }
            Text {
                visible: root.files.length > 0
                text: root.files.length + (root.files.length === 1 ? " image" : " images")
                    + (root.activeDir !== root._dir() ? " • Showing fallback folder" : "")
                color: root.theme.subtext
                font.pixelSize: root.theme.fontSizeSmall - 1
            }
        }

        Rectangle {
            id: refreshBtn
            width: 90; height: 32; radius: root.theme.radiusSmall
            anchors.right: parent.right
            anchors.margins: 12
            anchors.verticalCenter: parent.verticalCenter
            color: refreshMouse.containsMouse ? root.theme.cardHover : root.theme.card
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            Text { 
                anchors.centerIn: parent
                text: root.loading ? "Loading…" : "Refresh"
                color: root.theme.text
                font.pixelSize: root.theme.fontSizeSmall 
            }
            MouseArea { 
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.refresh() 
            }
        }
    }

    Rectangle {
        id: divider
        anchors.top: header.bottom
        width: parent.width
        height: 1
        color: root.theme.card
    }

    // 2. Centered, Polished Empty State
    Item {
        id: emptyState
        anchors.top: divider.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: !root.loading && (root.files.length === 0 || root.lastError.length > 0)

        Column {
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 400)
            spacing: 16

            Text {
                text: root.lastError.length > 0 ? root.lastError : (root._dir().length === 0 ? "Set a folder to pick wallpapers from:" : "No images found in that folder.")
                color: root.lastError.length > 0 ? root.theme.danger : root.theme.subtext
                font.pixelSize: root.theme.fontSizeSmall + 1
                wrapMode: Text.Wrap
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                Rectangle {
                    width: 250; height: 36; radius: root.theme.radiusSmall
                    color: root.theme.card
                    border.color: root.theme.subtext
                    border.width: 1
                    TextInput {
                        anchors.fill: parent
                        anchors.margins: 10
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.config.wallpaperDir
                        color: root.theme.text
                        font.pixelSize: root.theme.fontSizeSmall
                        clip: true
                        onEditingFinished: { root.config.wallpaperDir = text; root.refresh(); }
                    }
                }
                Rectangle {
                    width: 80; height: 36; radius: root.theme.radiusSmall
                    color: root.theme.accent
                    Text { 
                        anchors.centerIn: parent; text: "Apply"
                        color: root.theme.bg; font.pixelSize: root.theme.fontSizeSmall; font.bold: true 
                    }
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.refresh() 
                    }
                }
            }
        }
    }

    // 3. Optimized GridView with 16:9 Aspect Ratio
    GridView {
        anchors.top: divider.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        clip: true
        visible: !emptyState.visible
        
        // Much better aspect ratio for wallpapers (approx 16:9)
        cellWidth: 220
        cellHeight: 150
        model: root.files

        delegate: Item {
            id: cell
            required property var modelData
            width: GridView.view.cellWidth
            height: GridView.view.cellHeight

            property bool isActive: root.config.lastWallpaper === cell.modelData

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Rectangle {
                    id: card
                    width: parent.width
                    height: parent.height - capText.height - 8
                    radius: root.theme.radiusSmall
                    color: root.theme.card
                    clip: true
                    
                    // Smoother focus outline
                    border.width: cell.isActive ? 2 : 0
                    border.color: root.theme.accent

                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    scale: cellMouse.containsMouse ? 1.04 : 1.0

                    Image {
                        anchors.fill: parent
                        source: "file://" + encodeURI(cell.modelData)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        // CRITICAL PERFORMANCE FIX: Downsample images so the grid doesn't lag
                        sourceSize: Qt.size(240, 160)
                    }

                    Rectangle {
                        visible: cell.isActive
                        width: 24; height: 24; radius: 12
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        color: root.theme.accent
                        Text {
                            anchors.centerIn: parent
                            text: "check"
                            font.family: root.theme.iconFontFamily
                            font.pixelSize: 14
                            color: root.theme.bg
                        }
                    }

                    Rectangle {
                        visible: root.applying === cell.modelData
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, 0.6)
                        Text { 
                            anchors.centerIn: parent; text: "Applying…"
                            color: "#ffffff"; font.pixelSize: root.theme.fontSizeSmall; font.bold: true 
                        }
                    }

                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.apply(cell.modelData)
                    }
                }

                Text {
                    id: capText
                    width: parent.width
                    text: root._basename(cell.modelData)
                    color: cell.isActive ? root.theme.accent : root.theme.text
                    font.pixelSize: root.theme.fontSizeSmall - 1
                    font.bold: cell.isActive
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    Component.onCompleted: refresh()
}

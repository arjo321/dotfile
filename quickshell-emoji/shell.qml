import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "emojis.js" as Emoji

// Standalone emoji picker — deliberately its OWN config, separate from the
// bar in ~/.config/quickshell:
//
//   qs -p ~/.config/quickshell-emoji     (toggle.sh does this for you)
//
// Differences from the bar on purpose:
//   - fixed violet palette (the bar follows the wallpaper; this doesn't)
//   - centered overlay-layer card, not an edge bar
//   - own fonts: Noto Color Emoji when available, bundled Twemoji fallback,
//     and Adwaita Sans for UI
//
// Toggled from toggle.sh, which writes a timestamp to
// ~/.cache/emoji-shell/cmd — the FileView below watches it, so the already
// running instance just flips open/closed (no restart, no IPC daemon).
// Hyprland binds: SUPER + . and SUPER + SHIFT + E.
ShellRoot {
    id: root

    // ---- fixed palette: deliberately not wallpaper-driven ------------------
    readonly property color scrimCol: "#b3090612"
    readonly property color cardTop: "#1a1526"
    readonly property color cardBottom: "#140f21"
    readonly property color fadeCol: "#161123"   // matches card mid-tone
    readonly property color line: "#2e2545"
    readonly property color accent: "#b48bff"
    readonly property color accent2: "#ff7ac8"
    readonly property color fg: "#efeaff"
    readonly property color sub: "#9a8fc4"
    readonly property color pill: "#241c3a"
    readonly property color pillHover: "#312851"
    readonly property string uiFont: "Adwaita Sans"
    readonly property string monoFont: "JetBrainsMono Nerd Font Mono"

    FontLoader {
        id: emojiFont
        source: "fonts/TwemojiMozilla.ttf"
    }

    // ---- open / close state -------------------------------------------------
    property bool open: false
    property bool closing: false
    property real progress: 0          // 0..1 entrance/exit progress

    // Compact by default; these two values are the only size knobs.
    readonly property int pickerWidth: 520
    readonly property int pickerHeight: 500

    function show() {
        closing = false;
        exitAnim.stop();
        open = true;
        query = "";
        cat = "";
        progress = 0;
        if (grid) {
            grid.currentIndex = 0;
            grid.contentY = 0;
        }
        enterAnim.restart();
        Qt.callLater(function() { searchInput.forceActiveFocus(); });
    }

    function hide() {
        if (!open || closing)
            return;
        closing = true;
        enterAnim.stop();
        exitAnim.from = progress;
        exitAnim.restart();
    }

    function toggle() {
        if (open && !closing)
            hide();
        else
            show();
    }

    NumberAnimation {
        id: enterAnim
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: 110
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: exitAnim
        target: root
        property: "progress"
        to: 0
        duration: 80
        easing.type: Easing.InCubic
        onFinished: {
            root.closing = false;
            root.open = false;
        }
    }

    // ---- filter state -------------------------------------------------------
    property string query: ""
    property string cat: ""

    readonly property var filtered: {
        var q = query.trim().toLowerCase();
        return Emoji.data.filter(function(x) {
            if (cat.length > 0 && x.c !== cat)
                return false;
            if (q.length === 0)
                return true;
            return x.n.toLowerCase().indexOf(q) !== -1 || x.k.indexOf(q) !== -1;
        });
    }

    // Selected entry for the footer preview, bounds-safe.
    readonly property var selected: {
        var i = grid ? grid.currentIndex : -1;
        return (i >= 0 && i < filtered.length) ? filtered[i] : null;
    }

    onQueryChanged: resetSelection()
    onCatChanged: resetSelection()

    function resetSelection() {
        if (!grid)
            return;
        grid.currentIndex = 0;
        Qt.callLater(function() { grid.contentY = 0; });
    }

    // ---- insert into the focused text field --------------------------------
    // The picker closes before the helper dispatches the paste shortcut. That
    // gives Hyprland time to return keyboard focus to Discord, Instagram, a
    // browser, or whichever text field was active before the picker opened.
    property string pendingEmoji: ""

    Process {
        id: insertProc
        running: false
    }

    Timer {
        id: insertTimer
        interval: 35
        onTriggered: {
            if (root.pendingEmoji.length === 0)
                return;
            if (insertProc.running)
                insertProc.running = false;
            insertProc.command = [
                "bash",
                Quickshell.shellDir + "/insert-emoji.sh",
                root.pendingEmoji
            ];
            insertProc.running = true;
            root.pendingEmoji = "";
        }
    }

    function insert(emoji) {
        if (!emoji || emoji.length === 0)
            return;

        // No exit animation here: insertion should feel immediate.
        enterAnim.stop();
        exitAnim.stop();
        closing = false;
        open = false;
        progress = 0;
        pendingEmoji = emoji;
        insertTimer.restart();
    }

    // ---- keybind IPC: toggle.sh writes a fresh timestamp here ---------------
    // Only a real inotify change flips the palette (the initial load never
    // does), so startup timing can't cause a spurious open.
    property bool pendingCmdChange: false

    FileView {
        id: cmdFile
        path: Quickshell.env("HOME") + "/.cache/emoji-shell/cmd"
        watchChanges: true
        onFileChanged: {
            root.pendingCmdChange = true;
            reload();
        }
        onLoaded: {
            if (root.pendingCmdChange) {
                root.pendingCmdChange = false;
                root.toggle();
            }
        }
    }

    // ---- the window ---------------------------------------------------------
    PanelWindow {
        id: win

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        focusable: true
        visible: root.open
        implicitWidth: screen ? screen.width : 1440
        implicitHeight: screen ? screen.height : 900

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-emoji"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: {
            if (visible)
                Qt.callLater(function() { searchInput.forceActiveFocus(); });
        }

        // Dim backdrop; clicking outside the card closes the picker.
        Rectangle {
            id: scrim
            z: -2
            anchors.fill: parent
            color: root.scrimCol
            opacity: root.progress

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }
        }

        Rectangle {
            id: card
            z: -1
            width: Math.min(root.pickerWidth, win.width - 24)
            height: Math.min(root.pickerHeight, win.height - 24)
            anchors.centerIn: parent
            radius: 20
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.cardTop }
                GradientStop { position: 1.0; color: root.cardBottom }
            }
            border.color: root.line
            border.width: 1
            clip: true
            opacity: root.progress
            scale: 0.95 + 0.05 * root.progress

            // Accent halo behind the card (rice).
            RectangularGlow {
                anchors.fill: parent
                z: -1
                glowRadius: 28
                spread: 0.16
                cornerRadius: 24
                color: root.accent
                opacity: 0.22 * root.progress
            }

            // Absorbs clicks on blank card space so they don't reach the
            // scrim underneath and close the picker.
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // ---- title row ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "emoji"
                        font.family: root.uiFont
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: root.accent
                    }
                    Text {
                        text: "pick · insert"
                        font.family: root.uiFont
                        font.pixelSize: 11
                        color: root.sub
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.filtered.length + " / " + Emoji.data.length
                        font.family: root.monoFont
                        font.pixelSize: 10
                        color: root.sub
                    }
                }

                // Accent gradient hairline (same idea as the bar's).
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    radius: 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.accent }
                        GradientStop { position: 1.0; color: root.accent2 }
                    }
                    opacity: 0.85
                }

                // ---- search box ----
                Rectangle {
                    id: searchBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 10
                    color: root.pill
                    border.color: searchInput.activeFocus ? root.accent : "transparent"
                    border.width: 1

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "🔍"
                            font.family: emojiFont.name
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: searchInput
                            width: parent.width - 25 - 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.fg
                            selectionColor: root.accent
                            selectedTextColor: "#17122a"
                            font.family: root.uiFont
                            font.pixelSize: 13
                            clip: true

                            onTextChanged: root.query = text

                            Keys.onPressed: (event) => {
                                var n = root.filtered.length;
                                if (event.key === Qt.Key_Escape) {
                                    if (text.length > 0)
                                        clear();
                                    else
                                        root.hide();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (root.selected)
                                        root.insert(root.selected.e);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down
                                           || event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                                    if (n > 0) {
                                        var cols = Math.max(1, Math.floor(grid.width / grid.cellHeight));
                                        var i = grid.currentIndex;
                                        if (event.key === Qt.Key_Left) i -= 1;
                                        else if (event.key === Qt.Key_Right) i += 1;
                                        else if (event.key === Qt.Key_Down) i += cols;
                                        else i -= cols;
                                        i = Math.max(0, Math.min(n - 1, i));
                                        grid.currentIndex = i;
                                        grid.positionViewAtIndex(i, GridView.Contain);
                                    }
                                    event.accepted = true;
                                }
                            }

                            Text {
                                visible: searchInput.text.length === 0
                                text: "search " + Emoji.data.length + " emoji…"
                                color: root.sub
                                font.family: root.uiFont
                                font.pixelSize: 13
                                width: parent.width
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // ---- category chips ----
                Flow {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [{ id: "", label: "all" }].concat(Emoji.categories)

                        delegate: Rectangle {
                            id: chip
                            required property int index
                            required property var modelData

                            readonly property bool active: root.cat === modelData.id
                            height: 26
                            radius: 13
                            width: chipLabel.implicitWidth + 20
                            color: active ? root.accent
                                  : (chipMouse.containsMouse ? root.pillHover : root.pill)

                            Text {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: chip.modelData.label
                                font.family: root.uiFont
                                font.pixelSize: 11
                                font.weight: chip.active ? Font.DemiBold : Font.Normal
                                color: chip.active ? "#17122a" : root.fg
                            }

                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.cat = chip.modelData.id
                            }
                        }
                    }
                }

                // ---- grid ----
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    GridView {
                        id: grid
                        anchors.fill: parent
                        clip: true
                        model: root.filtered
                        boundsBehavior: Flickable.StopAtBounds
                        cellHeight: 42
                        cellWidth: {
                            var cols = Math.max(1, Math.floor(width / 42));
                            return width / cols;
                        }
                        highlightMoveDuration: 60

                        delegate: Rectangle {
                            id: cell
                            required property int index
                            required property var modelData

                            width: grid.cellWidth
                            height: grid.cellHeight
                            radius: 10
                            color: grid.currentIndex === cell.index ? root.pillHover : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: cell.modelData.e
                                font.family: emojiFont.name
                                font.pixelSize: 22
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: grid.currentIndex = cell.index
                                onClicked: {
                                    grid.currentIndex = cell.index;
                                    root.insert(cell.modelData.e);
                                }
                            }
                        }

                        highlight: Rectangle {
                            width: grid.cellWidth
                            height: grid.cellHeight
                            radius: 10
                            color: "transparent"
                            border.color: root.accent
                            border.width: 2
                        }
                    }

                    // Soft fades so clipped rows don't cut hard.
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 14
                        visible: grid.contentY > 0
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.fadeCol }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
                        }
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 14
                        visible: grid.contentHeight > grid.height
                            && grid.contentY < grid.contentHeight - grid.height
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                            GradientStop { position: 1.0; color: root.fadeCol }
                        }
                    }

                    Text {
                        visible: root.filtered.length === 0
                        anchors.centerIn: parent
                        text: "nothing matches “" + root.query + "”"
                        color: root.sub
                        font.family: root.uiFont
                        font.pixelSize: 13
                    }
                }

                // ---- footer ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "↑↓←→ move · ↵ insert · esc close"
                        font.family: root.monoFont
                        font.pixelSize: 10
                        color: root.sub
                    }
                    Item { Layout.fillWidth: true }
                    Row {
                        spacing: 8
                        visible: root.selected !== null

                        Text {
                            text: root.selected ? root.selected.e : ""
                            font.family: emojiFont.name
                            font.pixelSize: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.selected ? root.selected.n : ""
                            color: root.sub
                            font.family: root.uiFont
                            font.pixelSize: 11
                            width: Math.min(implicitWidth, 130)
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

        }
    }
}

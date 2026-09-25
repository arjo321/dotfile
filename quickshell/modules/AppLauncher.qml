import QtQuick
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root

    required property var theme
    required property var ui

    // Spans the whole screen (same pattern as Dashboard) so a click
    // anywhere outside the card — not just in the left column — closes it.
    anchors { top: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitHeight: screen ? screen.height : 900
    focusable: true
    visible: ui.openPanel === "launcher"

    // No mask: whole window catches clicks so clicking outside the card closes this panel.

    MouseArea {
        anchors.fill: parent
        onClicked: root.ui.closePanels()
    }

    property var apps: []
    property string query: ""
    readonly property var filtered: query.length === 0 ? apps
        : apps.filter(function (a) { return a.name.toLowerCase().indexOf(query.toLowerCase()) !== -1; })

    onVisibleChanged: if (visible) { root.refresh(); root.query = ""; searchInput.forceActiveFocus(); }

    function refresh() {
        listProc.running = true;
    }

    Process {
        id: listProc
        running: false
        command: ["bash", "-lc",
            "for f in /usr/share/applications/*.desktop /usr/local/share/applications/*.desktop \"$HOME/.local/share/applications/\"*.desktop; do " +
            "[ -f \"$f\" ] || continue; " +
            "nd=$(grep -m1 '^NoDisplay=' \"$f\" | cut -d= -f2-); " +
            "[ \"$nd\" = \"true\" ] && continue; " +
            "n=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); " +
            "e=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2-); " +
            "i=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2-); " +
            "[ -z \"$n\" ] && continue; [ -z \"$e\" ] && continue; " +
            "printf '%s\\t%s\\t%s\\n' \"$n\" \"$e\" \"$i\"; " +
            "done | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().length ? this.text.trim().split("\n") : [];
                var list = [];
                var seen = {};
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("\t");
                    if (parts.length < 2) continue;
                    var name = parts[0];
                    if (seen[name]) continue;
                    seen[name] = true;
                    // Strip desktop-entry field codes (%f %F %u %U %i %c %k etc.)
                    var exec = parts[1].replace(/%[a-zA-Z%]/g, "").trim();
                    var icon = parts.length > 2 ? parts[2] : "";
                    list.push({ name: name, exec: exec, icon: icon });
                }
                list.sort(function (a, b) { return a.name.localeCompare(b.name); });
                root.apps = list;
            }
        }
    }

    Process { id: launchProc; running: false }
    function launch(exec) {
        launchProc.command = ["bash", "-lc", exec + " & disown"];
        launchProc.running = true;
        root.ui.togglePanel("launcher");
    }

    Rectangle {
        id: card
        // Fixed width (the old window was a 380px column and the card
        // derived its width from it; the window now spans the screen).
        width: Math.min(364, parent.width - 16)
        height: Math.min(460, root.height - root.theme.barHeight - 24)
        radius: root.theme.radius
        color: root.theme.bg
        border.color: root.theme.border
        border.width: 1
        clip: true
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: root.theme.barHeight + root.theme.gap
        anchors.leftMargin: root.theme.gap

        // Absorbs clicks on blank space within the card so they don't fall
        // through to the outer background catcher and close the panel.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Rectangle {
                width: parent.width
                height: 36
                radius: root.theme.radiusSmall
                color: root.theme.card

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "search"
                        font.family: root.theme.iconFontFamily
                        font.pixelSize: 16
                        color: root.theme.subtext
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    TextInput {
                        id: searchInput
                        width: parent.width - 30
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.theme.text
                        font.pixelSize: root.theme.fontSize
                        onTextChanged: root.query = text
                        Keys.onReturnPressed: if (root.filtered.length > 0) root.launch(root.filtered[0].exec)
                        Keys.onEscapePressed: root.ui.togglePanel("launcher")

                        Text {
                            visible: searchInput.text.length === 0
                            text: "Search apps…"
                            color: root.theme.subtext
                            font.pixelSize: root.theme.fontSize
                        }
                    }
                }
            }

            Text {
                visible: root.apps.length === 0
                text: "No applications found."
                color: root.theme.subtext
                font.pixelSize: root.theme.fontSizeSmall
            }

            ListView {
                width: parent.width
                height: parent.height - 46
                clip: true
                spacing: 2
                model: root.filtered

                delegate: Rectangle {
                    id: appRow
                    required property var modelData
                    width: ListView.view.width
                    height: 34
                    radius: root.theme.radiusSmall
                    color: appMouse.containsMouse ? root.theme.cardHover : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        AppIcon {
                            theme: root.theme
                            iconName: appRow.modelData.icon || ""
                            size: 15
                            width: 22; height: 22
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            width: parent.width - 42
                            text: appRow.modelData.name
                            color: root.theme.text
                            font.pixelSize: root.theme.fontSizeSmall
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: appMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launch(appRow.modelData.exec)
                    }
                }
            }
        }
    }
}

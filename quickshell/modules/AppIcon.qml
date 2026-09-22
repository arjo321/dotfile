import QtQuick

Item {
    id: root

    required property var theme
    property string iconName: ""   // value from a .desktop Icon= field: a bare name or an absolute path
    property int size: 20

    property var _candidates: []
    property int _idx: 0

    function _buildCandidates(name) {
        if (name.length === 0) return [];
        if (name.indexOf("/") === 0) return [name];
        return [
            "/usr/share/icons/hicolor/128x128/apps/" + name + ".png",
            "/usr/share/icons/hicolor/64x64/apps/" + name + ".png",
            "/usr/share/icons/hicolor/48x48/apps/" + name + ".png",
            "/usr/share/icons/hicolor/scalable/apps/" + name + ".svg",
            "/usr/share/pixmaps/" + name + ".png",
            "/usr/share/pixmaps/" + name + ".svg",
            "/usr/share/icons/Adwaita/48x48/apps/" + name + ".png",
            "/usr/share/icons/Adwaita/scalable/apps/" + name + ".svg",
            "/usr/share/icons/breeze/apps/48/" + name + ".svg",
            "/usr/share/icons/hicolor/128x128/apps/" + name + ".svg"
        ];
    }

    function _tryNext() {
        if (root._idx < root._candidates.length) {
            img.source = "file://" + root._candidates[root._idx];
        } else {
            img.source = "";
        }
    }

    onIconNameChanged: {
        root._candidates = root._buildCandidates(root.iconName);
        root._idx = 0;
        root._tryNext();
    }
    Component.onCompleted: {
        root._candidates = root._buildCandidates(root.iconName);
        root._idx = 0;
        root._tryNext();
    }

    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: status === Image.Ready
        onStatusChanged: {
            if (status === Image.Error) {
                root._idx += 1;
                root._tryNext();
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !img.visible
        text: "apps"
        font.family: root.theme.iconFontFamily
        font.pixelSize: root.size
        color: root.theme.subtext
    }
}

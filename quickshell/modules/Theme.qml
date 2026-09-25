import QtQuick

QtObject {
    // Background colors
    property color bg: "#1b1725"
    property color bgAlt: "#221c30"
    property color card: "#2a2438"
    property color cardHover: "#332c46"
    property color border: "#3a3350"

    // Accent / text. `accent` is overridden from the wallpaper palette
    // (see shell.qml), and `accentDim` follows it as a darker shade so
    // hover states stay in sync with whatever the wallpaper picked.
    property color accent: "#ab97f0"
    readonly property color accentDim: Qt.darker(accent, 1.35)
    property color text: "#eae6f7"
    property color subtext: "#9d94b8"
    property color danger: "#f0797a"
    property color good: "#7adba0"

    // Global UI scale — a multiplier applied to every metric below, so the
    // whole shell can be sized up/down relative to other application
    // windows without editing each component individually. Set via
    // Settings > Appearance, bound in from config.uiScale in shell.qml.
    property real scale: 1.0

    // Metrics (all derived from scale, so changing `scale` resizes the
    // entire shell consistently)
    property int radius: Math.round(16 * scale)
    property int radiusSmall: Math.round(10 * scale)
    property int barHeight: Math.round(34 * scale)
    property int gap: Math.round(8 * scale)
    property int fontSize: Math.round(13 * scale)
    property int fontSizeSmall: Math.round(11 * scale)
    property int fontSizeLarge: Math.round(30 * scale)

    // Icons: bundled locally (modules/fonts/MaterialSymbolsRounded.ttf) via
    // FontLoader so icons render correctly regardless of what's installed on
    // the system — no separate font install required.
    property FontLoader iconFontLoader: FontLoader {
        source: "fonts/MaterialSymbolsRounded.ttf"
    }
    property string iconFontFamily: iconFontLoader.name || "Material Symbols Rounded"
    property int iconFontSize: Math.round(16 * scale)

    // Capsule "pill" grouping used for bar sections (end-4 dots-hyprland
    // look). `pill` is overridden from the wallpaper palette; the hover
    // shade is derived from it so the bar tint is followed consistently.
    property color pill: "#2a2438"
    readonly property color pillHover: Qt.lighter(pill, 1.22)

    // The fixed, hand-picked palette — used verbatim when Settings →
    // "Wallpaper colors" is switched off (see the Bindings in shell.qml).
    readonly property QtObject fixed: QtObject {
        property color bg: "#1b1725"
        property color bgAlt: "#221c30"
        property color card: "#2a2438"
        property color cardHover: "#332c46"
        property color border: "#3a3350"
        property color pill: "#2a2438"
        property color accent: "#ab97f0"
        property color text: "#eae6f7"
        property color subtext: "#9d94b8"
        property color danger: "#f0797a"
    }
}

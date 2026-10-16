pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color bg: Qt.rgba(0.043, 0.043, 0.07, 0.86)
    readonly property color bgSolid: "#0e0e16"
    readonly property color surface: "#1e1e2e"
    readonly property color surface2: "#313244"
    readonly property color muted: "#45475a"
    readonly property color dim: "#7f849c"
    readonly property color fg: "#bac2de"
    readonly property color accent: "#91ffff"
    readonly property color red: "#f38ba8"
    readonly property color yellow: "#f9e2af"
    readonly property color green: "#a6e3a1"
    readonly property color mauve: "#cba6f7"

    readonly property string font: "IosevkaCustom Nerd Font Extended"
    readonly property int fontSize: 14
    readonly property int iconSize: 17

    readonly property color wbFg: "#45475a"
    readonly property color slate1: "#1e1e2e"
    readonly property int wbHeight: 28
    readonly property int wbRadius: 10

    readonly property int gap: 6
    readonly property int barHeight: 32
    readonly property int sideWidth: 52
    readonly property int sidePad: 6
    readonly property int sideButton: sideWidth - 2 * sidePad
    readonly property int sideRadius: 12
    readonly property int fillet: 16
    readonly property int bottomHeight: 32
}

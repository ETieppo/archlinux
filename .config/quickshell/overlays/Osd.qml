import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs
import qs.components

PanelWindow {
    id: root

    property string kind: "volume"
    property bool shown: false
    property bool armed: false
    property real reveal: shown ? 1 : 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property int prof: PowerProfiles.profile
    readonly property real value: kind === "profile" ? (prof === PowerProfile.PowerSaver ? 0.2 : prof === PowerProfile.Performance ? 1 : 0.6)
        : kind === "volume" ? (muted ? 0 : vol) : kind === "brightness" ? Sys.brightness / 100 : KbdLight.bright / KbdLight.max
    readonly property string glyph: kind === "profile" ? (prof === PowerProfile.PowerSaver ? "󰌪" : prof === PowerProfile.Performance ? "󰓅" : "󰾅")
        : kind === "volume" ? (muted ? "󰝟" : vol < 0.33 ? "󰕿" : vol < 0.66 ? "󰖀" : "󰕾")
        : kind === "brightness" ? "󰃠" : "󰌌"
    readonly property color tint: kind === "profile" ? (prof === PowerProfile.PowerSaver ? Theme.green : prof === PowerProfile.Performance ? Theme.red : Theme.accent)
        : kind === "keyboard" ? KbdLight.color : muted && kind === "volume" ? Theme.muted : Theme.accent

    function show(k) {
        if (!armed)
            return;
        kind = k;
        shown = true;
        hideTimer.restart();
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    color: "transparent"
    visible: reveal > 0
    implicitWidth: 58
    implicitHeight: 240 + 2 * Theme.fillet
    mask: Region {}

    Behavior on reveal { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    PwObjectTracker {
        objects: [root.sink]
    }

    Timer {
        running: true
        interval: 2500
        onTriggered: root.armed = true
    }
    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: root.shown = false
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
    }
    Connections {
        target: Sys
        function onBrightnessChanged() { root.show("brightness"); }
    }
    Connections {
        target: PowerProfiles
        function onProfileChanged() { root.show("profile"); }
    }
    Connections {
        target: KbdLight
        function onBrightChanged() { root.show("keyboard"); }
    }

    Item {
        width: parent.width
        height: parent.height
        x: (1 - root.reveal) * width

        EdgeShape {
            anchors.fill: parent
            edge: "right"
            fillet: Theme.fillet
            radius: 20
            fill: Qt.alpha(Theme.bgSolid, 0.95)
            stroke: Qt.alpha(root.tint, 0.3)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: Theme.fillet + 14
            anchors.bottomMargin: Theme.fillet + 12
            spacing: 10

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.kind === "profile" ? (root.prof === PowerProfile.PowerSaver ? "eco" : root.prof === PowerProfile.Performance ? "max" : "bal") : Math.round(root.value * 100)
                font.pixelSize: 12
                color: root.tint
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                implicitWidth: 10
                radius: 5
                color: Theme.surface2

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(width, parent.height * Math.min(1, root.value))
                    radius: 5
                    color: root.tint
                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -3
                        width: 16
                        height: 16
                        radius: 8
                        color: root.tint
                        opacity: 0.35
                    }
                }
            }

            Icon {
                Layout.alignment: Qt.AlignHCenter
                text: root.glyph
                color: root.tint
                font.pixelSize: 20
            }
        }
    }
}

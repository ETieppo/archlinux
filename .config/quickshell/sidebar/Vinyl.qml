import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs

SideButton {
    id: root

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false
    property real t: 0

    visible: player !== null
    implicitHeight: 62
    tip: player ? `${player.trackTitle || "Sem título"}\n${player.trackArtist || player.identity}\n\n󰐎 clique · 󰒭 rolar` : ""

    onClicked: m => m.button === Qt.RightButton ? player?.raise() : player?.togglePlaying()
    onWheel: d => d > 0 ? player?.previous() : player?.next()

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    PwNodePeakMonitor {
        id: peak
        node: Pipewire.defaultAudioSink
        enabled: root.playing && root.visible
    }

    Timer {
        interval: 60
        repeat: true
        running: root.playing && root.visible
        onTriggered: root.t += 0.06
    }

    Rectangle {
        id: disc
        anchors.horizontalCenter: parent.horizontalCenter
        y: 3
        width: 38
        height: 38
        radius: 19
        color: "#08080c"
        border.width: 1
        border.color: root.playing ? Qt.alpha(Theme.accent, 0.6) : Theme.muted

        Repeater {
            model: 3
            Rectangle {
                required property int index
                anchors.centerIn: parent
                width: 34 - index * 4
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.alpha(Theme.fg, 0.07)
            }
        }

        ClippingRectangle {
            anchors.centerIn: parent
            width: 20
            height: 20
            radius: 10
            color: Theme.mauve

            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(64, 64)
                asynchronous: true
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 4
            height: 4
            radius: 2
            color: "#08080c"
        }

        Rectangle {
            x: 6
            y: 5
            width: 9
            height: 2
            radius: 1
            rotation: -40
            color: Qt.alpha("white", 0.18)
        }

        FrameAnimation {
            running: root.playing && root.visible
            onTriggered: disc.rotation = (disc.rotation + frameTime * 100) % 360
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        height: 14
        spacing: 2

        Repeater {
            model: 6
            Rectangle {
                required property int index
                readonly property real wobble: 0.45 + 0.55 * Math.abs(Math.sin(root.t * (1.3 + index * 0.71) + index * 1.7))
                anchors.bottom: parent.bottom
                width: 3
                radius: 1.5
                height: root.playing ? Math.max(2, Math.min(14, 2 + 18 * peak.peak * wobble)) : 2
                color: Qt.rgba(0.57 + index * 0.05, 1 - index * 0.06, 1, 1)
                Behavior on height { NumberAnimation { duration: 70 } }
            }
        }
    }
}

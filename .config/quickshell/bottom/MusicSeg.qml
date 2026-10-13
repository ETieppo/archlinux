import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs
import qs.components

Seg {
    id: root

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real length: player?.lengthSupported ? player.length : 0
    readonly property bool seekable: (player?.canSeek ?? false) && length > 0
    property real t: 0

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    progress: length > 0 && player?.positionSupported ? player.position / length : 0
    tint: playing ? Theme.accent : Theme.dim
    knob: seekable
    tip: player ? `${player.trackTitle || "Untitled"}\n${player.trackArtist || player.identity}\n\n󰐎 click · 󰒭 scroll skips · 󰍽 right-click opens` + (seekable ? "\ndrag the bar to seek" : "") : ""

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    PwNodePeakMonitor {
        id: peak
        node: Pipewire.defaultAudioSink
        enabled: root.playing
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.player.positionChanged()
    }

    Timer {
        interval: 60
        repeat: true
        running: root.playing
        onTriggered: root.t += 0.06
    }

    Row {
        id: eq
        anchors.verticalCenter: parent.verticalCenter
        height: 12
        spacing: 2

        Repeater {
            model: 4
            Rectangle {
                required property int index
                readonly property real wobble: 0.45 + 0.55 * Math.abs(Math.sin(root.t * (1.3 + index * 0.71) + index * 1.7))
                anchors.bottom: parent.bottom
                width: 2.5
                radius: 1.25
                height: root.playing ? Math.max(2, Math.min(12, 2 + 16 * peak.peak * wobble)) : 2
                color: root.player ? Qt.rgba(0.57 + index * 0.06, 1 - index * 0.07, 1, 1) : Theme.muted
                Behavior on height { NumberAnimation { duration: 70 } }
            }
        }
    }

    Label {
        anchors.left: eq.right
        anchors.leftMargin: 9
        anchors.right: time.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        font.pixelSize: 12
        textFormat: Text.StyledText
        color: root.player ? Theme.fg : Theme.dim
        text: !root.player ? "nothing playing" : (root.player.trackTitle || root.player.identity) + (root.player.trackArtist ? `<font color="${Theme.dim}"> · ${root.player.trackArtist}</font>` : "")
    }

    Label {
        id: time
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 11
        color: root.playing ? Theme.accent : Theme.dim
        text: root.length > 0 ? `${root.fmt(root.player.position)} / ${root.fmt(root.length)}` : root.player && !root.playing ? "paused" : ""
    }

    MouseArea {
        anchors.fill: parent
        anchors.bottomMargin: 10
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.player ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: m => m.button === Qt.RightButton ? root.player?.raise() : root.player?.togglePlaying()
        onWheel: w => w.angleDelta.y > 0 ? root.player?.previous() : root.player?.next()
    }

    MouseArea {
        x: 0
        y: root.track.y - 6
        width: root.width
        height: root.height - y
        enabled: root.seekable
        cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
        function seek(mx) {
            root.player.position = Math.max(0, Math.min(1, mx / width)) * root.length;
        }
        onPressed: m => seek(m.x)
        onPositionChanged: m => pressed && seek(m.x)
    }
}

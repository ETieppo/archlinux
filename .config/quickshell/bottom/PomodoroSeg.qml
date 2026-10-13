import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.components

Seg {
    id: root

    property int workMin: 25
    property int breakMin: 5
    property bool onBreak: false
    property bool ticking: false
    property int cycles: 0
    property int remaining: workMin * 60
    readonly property int total: (onBreak ? breakMin : workMin) * 60
    readonly property bool idle: !ticking && remaining === total
    readonly property color tone: onBreak ? Theme.green : Theme.red

    function fmt(s) {
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    function reset() {
        ticking = false;
        onBreak = false;
        remaining = workMin * 60;
    }

    progress: idle ? 0 : remaining / total
    tint: tone
    fillOpacity: ticking ? 1 : 0.45
    tip: idle ? `Pomodoro · ${workMin} min\n󰐊 click · 󰑐 right-click\n󰒭 scroll adjusts` : `${onBreak ? "Break" : "Focus"} · ${fmt(remaining)}${ticking ? "" : " (paused)"}\n${cycles} cycle(s) today`

    Icon {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        text: "󱎫"
        font.pixelSize: 14
        color: root.idle ? Theme.muted : root.tone
    }

    Label {
        anchors.left: glyph.right
        anchors.leftMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 12
        font.bold: !root.idle
        color: root.idle ? Theme.dim : root.tone
        opacity: root.ticking || root.idle ? 1 : 0.6
        text: root.idle ? `${root.workMin} min` : `${root.onBreak ? "break" : "focus"} ${root.fmt(root.remaining)}`
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => {
            if (m.button === Qt.RightButton)
                root.reset();
            else
                root.ticking = !root.ticking;
        }
        onWheel: w => {
            if (!root.idle)
                return;
            root.workMin = Math.max(5, Math.min(90, root.workMin + (w.angleDelta.y > 0 ? 5 : -5)));
            root.remaining = root.workMin * 60;
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.ticking
        onTriggered: {
            if (--root.remaining > 0)
                return;
            if (!root.onBreak)
                root.cycles++;
            root.onBreak = !root.onBreak;
            root.remaining = root.total;
            Quickshell.execDetached(["notify-send", "-a", "Pomodoro", "-u", "critical",
                root.onBreak ? "Break time 󰾴" : "Back to focus 󰔟",
                root.onBreak ? `Breathe. ${root.breakMin} minutes.` : `${root.workMin} minutes of focus.`]);
        }
    }

    IpcHandler {
        target: "pomodoro"
        function toggle(): void {
            root.ticking = !root.ticking;
        }
        function reset(): void {
            root.reset();
        }
    }
}

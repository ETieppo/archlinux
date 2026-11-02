import QtQuick
import Quickshell
import qs
import qs.components

Seg {
    id: root

    readonly property color tone: Pomodoro.onBreak ? Theme.green : Theme.red

    function fmt(s) {
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    progress: Pomodoro.idle ? 0 : Pomodoro.remaining / Pomodoro.total
    tint: tone
    fillOpacity: Pomodoro.ticking ? 1 : 0.45
    tip: Pomodoro.idle ? `Pomodoro · ${Pomodoro.workMin} min\n󰐊 click · 󰑐 right-click\n󰒭 scroll adjusts` : `${Pomodoro.onBreak ? "Break" : "Focus"} · ${fmt(Pomodoro.remaining)}${Pomodoro.ticking ? "" : " (paused)"}\n${Pomodoro.cycles} cycle(s) today`

    Icon {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        text: "󱎫"
        font.pixelSize: 14
        color: Pomodoro.idle ? Theme.muted : root.tone
    }

    Label {
        anchors.left: glyph.right
        anchors.leftMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 12
        font.bold: !Pomodoro.idle
        color: Pomodoro.idle ? Theme.dim : root.tone
        opacity: Pomodoro.ticking || Pomodoro.idle ? 1 : 0.6
        text: Pomodoro.idle ? `${Pomodoro.workMin} min` : `${Pomodoro.onBreak ? "break" : "focus"} ${root.fmt(Pomodoro.remaining)}`
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => {
            if (m.button === Qt.RightButton)
                Pomodoro.reset();
            else
                Pomodoro.toggle();
        }
        onWheel: w => Pomodoro.adjustWorkMinutes(w.angleDelta.y > 0 ? 5 : -5)
    }
}

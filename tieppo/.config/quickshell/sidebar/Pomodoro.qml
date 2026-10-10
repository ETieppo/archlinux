import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.components

SideButton {
    id: root

    property int workMin: 25
    property int breakMin: 5
    property bool onBreak: false
    property bool ticking: false
    property int cycles: 0
    property int remaining: workMin * 60
    readonly property int total: (onBreak ? breakMin : workMin) * 60
    readonly property bool idle: !ticking && remaining === total

    function fmt(s) {
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    function reset() {
        ticking = false;
        onBreak = false;
        remaining = workMin * 60;
    }

    implicitHeight: 44
    active: ticking
    tip: idle ? `Pomodoro · ${workMin} min\n󰐊 clique · 󰑐 botão direito\n󰒭 rolar ajusta` : `${onBreak ? "Pausa" : "Foco"} · ${fmt(remaining)}${ticking ? "" : " (pausado)"}\n${cycles} ciclo(s) hoje`

    onClicked: m => {
        if (m.button === Qt.RightButton)
            reset();
        else
            ticking = !ticking;
    }
    onWheel: d => {
        if (!idle)
            return;
        workMin = Math.max(5, Math.min(90, workMin + (d > 0 ? 5 : -5)));
        remaining = workMin * 60;
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
                root.onBreak ? "Hora da pausa 󰾴" : "De volta ao foco 󰔟",
                root.onBreak ? `Respira. ${root.breakMin} minutos.` : `${root.workMin} minutos de foco.`]);
        }
    }

    Ring {
        anchors.fill: parent
        anchors.margins: 1
        thickness: 2.5
        value: root.idle ? 0 : 1 - root.remaining / root.total
        color: root.onBreak ? Theme.green : Theme.red
    }

    Icon {
        anchors.centerIn: parent
        visible: root.idle
        text: "󱎫"
        color: Theme.red
        font.pixelSize: 19
    }

    Label {
        anchors.centerIn: parent
        visible: !root.idle
        text: root.remaining >= 60 ? Math.ceil(root.remaining / 60) : root.remaining
        font.pixelSize: 14
        color: root.onBreak ? Theme.green : Theme.red
        opacity: root.ticking ? 1 : 0.5
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

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int workMin: 25
    property int breakMin: 5
    property bool onBreak: false
    property bool ticking: false
    property int cycles: 0
    property int remaining: workMin * 60
    readonly property int total: (onBreak ? breakMin : workMin) * 60
    readonly property bool idle: !ticking && remaining === total

    function toggle() {
        ticking = !ticking;
    }

    function reset() {
        ticking = false;
        onBreak = false;
        remaining = workMin * 60;
    }

    function adjustWorkMinutes(delta) {
        if (!idle)
            return;
        workMin = Math.max(5, Math.min(90, workMin + delta));
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
            Notifs.send("Pomodoro",
                root.onBreak ? "Break time 󰾴" : "Back to focus 󰔟",
                root.onBreak ? `Breathe. ${root.breakMin} minutes.` : `${root.workMin} minutes of focus.`,
                "critical");
        }
    }

    IpcHandler {
        target: "pomodoro"
        function toggle(): void {
            root.toggle();
        }
        function reset(): void {
            root.reset();
        }
    }
}

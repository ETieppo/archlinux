pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string _last: ""
    property real since: Store.kbd.since ?? 0
    property int bright: Store.kbd.bright ?? 4
    property string mode: Store.kbd.mode ?? "sky"
    property color fixedColor: Store.kbd.color ?? "#91ffff"

    readonly property int max: 4
    readonly property int hold: 3600000
    readonly property string dir: "/sys/class/leds/rgb:kbd_backlight"
    readonly property color skyColor: Qt.hsva(Sky.hue / 360, 1, 1, 1)
    readonly property bool sleeping: Sky.sleeping
    readonly property real night: Sky.night
    readonly property var presets: [
        { c: "#ff2020", led: [255, 3, 3] },
        { c: "#ff6a00", led: [255, 37, 0] },
        { c: "#ffd000", led: [255, 163, 0] },
        { c: "#ffff90", led: [255, 255, 255] },
        { c: "#a0ff40", led: [74, 255, 255] },
        { c: "#30ff40", led: [6, 255, 12] },
        { c: "#20c0b0", led: [3, 20, 255] },
        { c: "#91ffff", led: [9, 10, 255] },
        { c: "#2050ff", led: [0, 0, 255] },
        { c: "#8a2be2", led: [12, 0, 255] },
        { c: "#ff60b0", led: [66, 5, 196] },
        { c: "#ff2060", led: [255, 1, 76] },
        { c: "#ffffff", led: [25, 10, 255] }
    ]
    readonly property var preset: presets.find(p => Qt.colorEqual(p.c, fixedColor)) ?? null
    readonly property color color: mode === "sky" ? skyColor : mix(fixedColor, Qt.rgba(1, 0, 0, 1), evening)
    readonly property real evening: {
        const a = Sky.frac(Sky.hues[Sky.hues.length - 2][0]), b = Sky.frac(Sky.hues[Sky.hues.length - 1][0]);
        const s = Sky.span(a, Sky.progress), len = Sky.span(a, b);
        return night > 0 ? 1 : s < len ? s / len : 0;
    }
    readonly property real dim: {
        const ref = Store.nightSaved * Sys.brightnessMax / 100;
        return ref > 0 && Sys.brightnessRaw > 0 ? Math.max(0.04, Math.min(1, Sys.brightnessRaw / ref)) : 1;
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    function apply() {
        Quickshell.execDetached(["sh", "-c", `echo "${rgb()}" > ${dir}/multi_intensity; echo ${bright} > ${dir}/brightness`]);
        Store.kbd = {
            bright,
            mode,
            since,
            color: fixedColor.toString()
        };
    }

    function rgb() {
        const lin = c => [c.r, c.g, c.b].map(v => Math.pow(v, 2.2) * 255);
        const v = mode === "sky" ? lin(skyColor) : (preset?.led ?? lin(fixedColor)).map((x, i) => x + ((i ? 0 : 255) - x) * evening);
        return v.map(x => Math.round(x * dim)).join(" ");
    }

    function setBright(v) {
        bright = Math.max(0, Math.min(max, v));
        touch();
        apply();
    }

    function setColor(c) {
        mode = "fixed";
        fixedColor = c;
        if (bright === 0)
            bright = max;
        touch();
        apply();
    }

    function followSky() {
        mode = "sky";
        if (bright === 0)
            bright = max;
        since = 0;
        revert.stop();
        apply();
    }

    function touch() {
        since = Date.now();
        revert.interval = hold;
        revert.restart();
    }

    function restore() {
        mode = "sky";
        bright = max;
        since = 0;
        apply();
    }

    function resume() {
        const left = since + hold - Date.now();
        if (since > 0 && left > 0) {
            revert.interval = left;
            revert.restart();
        } else if (mode !== "sky" || bright !== max) {
            restore();
        }
    }

    Timer {
        id: revert
        onTriggered: root.restore()
    }

    Connections {
        target: Ui
        function onAutoAll() {
            revert.stop();
            if (root.since > 0 || root.mode !== "sky" || root.bright !== root.max)
                root.restore();
        }
    }

    Timer {
        running: root.bright > 0
        interval: 5000
        repeat: true
        onTriggered: {
            const c = root.rgb();
            if (c !== root._last) {
                root._last = c;
                root.apply();
            }
        }
    }

    Timer {
        running: true
        interval: 800
        onTriggered: {
            root.apply();
            root.resume();
        }
    }

    IpcHandler {
        target: "kbd"
        function up(): void {
            root.setBright(root.bright + 1);
        }
        function down(): void {
            root.setBright(root.bright - 1);
        }
        function sky(): void {
            root.followSky();
        }
    }
}

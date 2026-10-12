pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dir: "/sys/class/leds/rgb:kbd_backlight"
    readonly property int max: 4
    property int bright: Store.kbd.bright ?? 4
    property string mode: Store.kbd.mode ?? "sky"
    property color fixedColor: Store.kbd.color ?? "#91ffff"

    readonly property color skyColor: {
        const c = Sky.colorAt(Sky.progress);
        const m = Math.max(c.r, c.g, c.b, 0.01);
        return Qt.rgba(c.r / m, c.g / m, c.b / m, 1);
    }
    readonly property bool sleeping: Sky.sleeping
    readonly property color color: sleeping ? "#ff0000" : mode === "sky" ? skyColor : fixedColor
    readonly property int outBright: sleeping && bright > 0 ? 1 : bright
    onSleepingChanged: apply()

    readonly property var presets: ["#91ffff", "#ff2020", "#ff6a00", "#ffd000", "#30ff40", "#2050ff", "#8a2be2", "#ff1493", "#ffffff"]

    function apply() {
        const led = v => Math.round(Math.pow(v, 2.2) * 255);
        const r = led(color.r), g = led(color.g), b = led(color.b);
        Quickshell.execDetached(["sh", "-c", `echo "${r} ${g} ${b}" > ${dir}/multi_intensity; echo ${outBright} > ${dir}/brightness`]);
        Store.kbd = { bright, mode, color: fixedColor.toString() };
    }

    function setBright(v) {
        bright = Math.max(0, Math.min(max, v));
        apply();
    }

    function setColor(c) {
        mode = "fixed";
        fixedColor = c;
        if (bright === 0)
            bright = max;
        apply();
    }

    function followSky() {
        mode = "sky";
        if (bright === 0)
            bright = max;
        apply();
    }

    property string _lastSky: ""
    Timer {
        running: root.mode === "sky"
        interval: 60000
        repeat: true
        onTriggered: {
            const c = root.skyColor.toString();
            if (c !== root._lastSky) {
                root._lastSky = c;
                root.apply();
            }
        }
    }

    Timer {
        running: true
        interval: 800
        onTriggered: root.apply()
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

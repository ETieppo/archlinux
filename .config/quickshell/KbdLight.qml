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

    // modo céu: segue a matiz do horário (Sky.hues); cor fixa: vai para o vermelho junto com o fim da tarde
    readonly property color skyColor: Qt.hsva(Sky.hue / 360, 1, 1, 1)
    readonly property bool sleeping: Sky.sleeping
    readonly property real night: Sky.night
    readonly property real evening: {
        const a = Sky.frac(Sky.hues[Sky.hues.length - 2][0]), b = Sky.frac(Sky.hues[Sky.hues.length - 1][0]);
        return night > 0 ? 1 : Math.max(0, Math.min(1, Sky.span(a, Sky.progress) / Sky.span(a, b)));
    }
    readonly property color color: mode === "sky" ? skyColor : mix(fixedColor, Qt.rgba(1, 0, 0, 1), evening)
    // à noite cai para ~1/4 da intensidade junto com a tela
    readonly property real dim: 1 - 0.75 * night

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    readonly property var presets: ["#91ffff", "#ff2020", "#ff6a00", "#ffd000", "#30ff40", "#2050ff", "#8a2be2", "#ff1493", "#ffffff"]

    function apply() {
        Quickshell.execDetached(["sh", "-c", `echo "${rgb()}" > ${dir}/multi_intensity; echo ${bright} > ${dir}/brightness`]);
        Store.kbd = { bright, mode, color: fixedColor.toString() };
    }

    function rgb() {
        const led = v => Math.round(Math.pow(v, 2.2) * dim * 255);
        return `${led(color.r)} ${led(color.g)} ${led(color.b)}`;
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

    property string _last: ""
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

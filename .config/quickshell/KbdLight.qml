pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string _last: ""
    property real since: Store.kbd.since ?? 0
    property int bright: Store.kbd.bright ?? autoBright

    readonly property int max: 100
    readonly property int hold: 3600000
    readonly property var presetPercents: [0, 5, 25, 50, 100]
    readonly property int step: Math.max(5, Math.ceil(max / Math.max(1, Hardware.keyboardLightMax)))
    readonly property int autoBright: Hardware.isMac ? 5 : max
    readonly property bool followsScreen: !Hardware.isMac
    readonly property bool restingAtNight: bright === 0 && night > 0
    readonly property string levelText: bright === 0 ? "off" : `${bright}%`
    readonly property string dir: Hardware.keyboardLightPath
    readonly property bool present: dir !== ""
    readonly property bool supportsColor: Hardware.keyboardLightRgb
    readonly property color skyColor: Qt.hsva(Sky.hue / 360, 1, 1, 1)
    readonly property color color: supportsColor ? skyColor : Theme.fg
    readonly property bool sleeping: Sky.sleeping
    readonly property real night: Sky.night
    readonly property var presets: {
        const byLevel = new Map();
        for (const percent of presetPercents)
            byLevel.set(hardwareLevel(percent, 1), percent);
        return [...byLevel.values()];
    }
    readonly property real dim: {
        if (!followsScreen)
            return 1;
        const ref = Store.nightSaved * Sys.brightnessMax / 100;
        return ref > 0 && Sys.brightnessRaw > 0 ? Math.max(0.04, Math.min(1, Sys.brightnessRaw / ref)) : 1;
    }

    function hardwareLevel(percent, scale) {
        return percent === 0 ? 0 : Math.max(1, Math.round(Hardware.keyboardLightMax * percent / max * scale));
    }

    function rgb() {
        return [skyColor.r, skyColor.g, skyColor.b].map(v => Math.round(Math.pow(v, 2.2) * 255 * dim)).join(" ");
    }

    function writeCommand() {
        return supportsColor ? `echo "${rgb()}" > ${dir}/multi_intensity; echo ${hardwareLevel(bright, 1)} > ${dir}/brightness` : `echo ${hardwareLevel(bright, dim)} > ${dir}/brightness`;
    }

    function apply() {
        if (!present)
            return;
        _last = writeCommand();
        Quickshell.execDetached(["sh", "-c", _last]);
        Store.kbd = {
            bright,
            since
        };
    }

    function setBright(v) {
        bright = Math.max(0, Math.min(max, v));
        if (restingAtNight || bright === autoBright)
            clearManual();
        else
            touch();
        apply();
    }

    function stepBright(direction) {
        setBright(Math.round((bright + direction * step) / step) * step);
    }

    function clearManual() {
        since = 0;
        revert.stop();
    }

    function touch() {
        since = Date.now();
        revert.interval = hold;
        revert.restart();
    }

    function restore() {
        bright = autoBright;
        clearManual();
        apply();
    }

    function resume() {
        const left = since + hold - Date.now();
        if (since > 0 && left > 0) {
            revert.interval = left;
            revert.restart();
        } else if (restingAtNight) {
            clearManual();
            apply();
        } else {
            restore();
        }
    }

    onNightChanged: {
        if (night <= 0 && bright === 0 && since === 0)
            restore();
    }

    Timer {
        id: revert
        onTriggered: root.restore()
    }

    Connections {
        target: Ui
        function onAutoAll() {
            if (root.restingAtNight)
                root.clearManual();
            else
                root.restore();
        }
    }

    Timer {
        running: root.present && root.bright > 0
        interval: 5000
        repeat: true
        onTriggered: {
            if (root.writeCommand() !== root._last)
                root.apply();
        }
    }

    Timer {
        running: Hardware.ready
        interval: 800
        onTriggered: {
            root.apply();
            root.resume();
        }
    }

    IpcHandler {
        target: "kbd"
        function up(): void {
            root.stepBright(1);
        }
        function down(): void {
            root.stepBright(-1);
        }
    }
}

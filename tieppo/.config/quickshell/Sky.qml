pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property real lat: -23.5
    readonly property real lng: -46.6

    readonly property date now: clock.date
    readonly property real progress: (now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds()) / 86400
    readonly property var sun: times(now)
    readonly property real sunrise: sun[0]
    readonly property real sunset: sun[1]
    readonly property bool isDay: progress > sunrise && progress < sunset

    property real sleepStart: 22.5 / 24
    property real sleepEnd: 8.5 / 24
    readonly property bool sleeping: sleepStart > sleepEnd ? (progress >= sleepStart || progress < sleepEnd) : (progress >= sleepStart && progress < sleepEnd)

    FileView {
        path: Quickshell.env("HOME") + "/.config/gammastep/config.ini"
        onLoaded: {
            const t = k => {
                const m = text().match(new RegExp(`^${k}=(\\d+):(\\d+)`, "m"));
                return m ? (Number(m[1]) * 60 + Number(m[2])) / 1440 : null;
            };
            root.sleepStart = t("dusk-time") ?? root.sleepStart;
            root.sleepEnd = t("dawn-time") ?? root.sleepEnd;
        }
    }

    readonly property var stops: [
        [0, "#2b2d63"],
        [Math.max(0.01, sunrise - 0.05), "#4a4290"],
        [sunrise, "#fab387"],
        [sunrise + 0.06, "#89dceb"],
        [(sunrise + sunset) / 2, "#91ffff"],
        [sunset - 0.06, "#89b4fa"],
        [sunset, "#f38ba8"],
        [Math.min(0.99, sunset + 0.05), "#6a4a9a"],
        [1, "#2b2d63"]
    ]

    readonly property color body: isDay ? colorAt(progress) : "#b4befe"

    function fmt(frac) {
        const m = Math.round(frac * 1440);
        return `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
    }

    function colorAt(p) {
        for (let i = 1; i < stops.length; i++) {
            const [a, ca] = stops[i - 1], [b, cb] = stops[i];
            if (p <= b) {
                const t = b > a ? (p - a) / (b - a) : 0;
                const x = Qt.color(ca), y = Qt.color(cb);
                return Qt.rgba(x.r + (y.r - x.r) * t, x.g + (y.g - x.g) * t, x.b + (y.b - x.b) * t, 1);
            }
        }
        return Qt.color(stops[stops.length - 1][1]);
    }

    function times(d) {
        const rad = Math.PI / 180;
        const day = Math.floor((d - new Date(d.getFullYear(), 0, 0)) / 86400000);
        const g = 2 * Math.PI / 365 * (day - 1);
        const eqt = 229.18 * (0.000075 + 0.001868 * Math.cos(g) - 0.032077 * Math.sin(g) - 0.014615 * Math.cos(2 * g) - 0.040849 * Math.sin(2 * g));
        const decl = 0.006918 - 0.399912 * Math.cos(g) + 0.070257 * Math.sin(g) - 0.006758 * Math.cos(2 * g) + 0.000907 * Math.sin(2 * g) - 0.002697 * Math.cos(3 * g) + 0.00148 * Math.sin(3 * g);
        const ha = Math.acos(Math.cos(90.833 * rad) / (Math.cos(lat * rad) * Math.cos(decl)) - Math.tan(lat * rad) * Math.tan(decl)) / rad;
        const tz = -d.getTimezoneOffset();
        return [(720 - 4 * (lng + ha) - eqt + tz) / 1440, (720 - 4 * (lng - ha) - eqt + tz) / 1440];
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}

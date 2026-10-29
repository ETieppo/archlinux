pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var dusk: [21.5 / 24, 21.5 / 24]
    property var dawn: [8.5 / 24, 8.5 / 24]
    readonly property real lat: -23.5
    readonly property real lng: -46.6
    readonly property date now: clock.date
    readonly property real progress: (now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds()) / 86400
    readonly property var sun: times(now)
    readonly property real sunrise: sun[0]
    readonly property real sunset: sun[1]
    readonly property bool isDay: progress > sunrise && progress < sunset
    readonly property var hues: [
        ["07:00", 360],
        ["08:30", 330],
        ["10:00", 295],
        ["11:30", 265],
        ["13:00", 225],
        ["14:30", 190],
        ["16:00", 160],
        ["17:30", 120],
        ["19:00", 75],
        ["20:00", 50],
        ["20:30", 41.5],
        ["21:00", 33],
        ["21:30", 11],
        ["21:45", 0]
    ]
    readonly property var dimming: [
        ["20:00", 1],
        ["20:30", 0.85],
        ["21:00", 0.75],
        ["21:30", 0.65],
        ["21:45", 0.6]
    ]
    readonly property real bedtime: frac(dimming[dimming.length - 1][0])
    readonly property real dimMin: 60
    readonly property real wakeMin: 60
    readonly property real hue: hueAt(progress)
    readonly property real night: nightAt(progress)
    readonly property real screen: screenAt(progress)
    readonly property bool rising: span(dawn[0], progress) < wakeMin / 1440
    readonly property bool sleeping: night >= 1

    function span(a, b) {
        return ((b - a) % 1 + 1) % 1;
    }

    function frac(hm) {
        const [h, m] = hm.split(":").map(Number);
        return (h * 60 + m) / 1440;
    }

    function hueAt(p) {
        const n = hues.length;
        for (let i = 0; i < n; i++) {
            const [ta, ha] = hues[i], [tb, hb] = hues[(i + 1) % n];
            const a = frac(ta), len = span(a, frac(tb));
            if (span(a, p) < len) {
                const d = ((hb - ha) % 360 + 540) % 360 - 180;
                return ((ha + d * span(a, p) / len) % 360 + 360) % 360;
            }
        }
        return hues[0][1] % 360;
    }

    function screenAt(p) {
        const start = frac(dimming[0][0]);
        if (span(start, p) > span(start, bedtime))
            return span(bedtime, p) < span(bedtime, dawn[0]) ? dimming[dimming.length - 1][1] : 1;
        for (let i = 1; i < dimming.length; i++) {
            const [ta, va] = dimming[i - 1], [tb, vb] = dimming[i];
            const a = frac(ta), len = span(a, frac(tb));
            if (span(a, p) <= len)
                return va + (vb - va) * span(a, p) / len;
        }
        return 1;
    }

    function nightAt(p) {
        const d = dimMin / 1440, w = wakeMin / 1440;
        if (span(bedtime, p) < d)
            return span(bedtime, p) / d;
        if (span(dawn[0], p) < w)
            return 1 - span(dawn[0], p) / w;
        return span(bedtime, p) < span(bedtime, dawn[0]) ? 1 : 0;
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/gammastep/config.ini"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const t = k => {
                const m = text().match(new RegExp(`^${k}=\\s*(\\d+):(\\d+)(?:\\s*-\\s*(\\d+):(\\d+))?`, "m"));
                if (!m)
                    return null;
                const a = (Number(m[1]) * 60 + Number(m[2])) / 1440;
                return [a, m[3] !== undefined ? (Number(m[3]) * 60 + Number(m[4])) / 1440 : a];
            };
            root.dusk = t("dusk-time") ?? root.dusk;
            root.dawn = t("dawn-time") ?? root.dawn;
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

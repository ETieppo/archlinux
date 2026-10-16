import QtQuick
import Quickshell
import qs

Scope {
    id: root

    readonly property int dim: 5
    property int lastSet: -1
    property bool manual: false
    property bool restoring: false

    function target(base, scale, f) {
        const lo = Sys.brightnessMax * dim / 100, hi = Sys.brightnessMax * base * scale / 100;
        return hi <= lo ? Math.round(hi) : Math.round(hi * Math.pow(lo / hi, f));
    }

    function ease(cur, t) {
        const lo = Math.floor(cur * 0.96), hi = Math.ceil(cur / 0.96) + 1;
        return Math.max(lo, Math.min(hi, t));
    }

    function set(v) {
        Sys.fading = v !== Sys.brightnessRaw;
        Sys.setBrightnessRaw(v);
        lastSet = v;
    }

    function step() {
        const max = Sys.brightnessMax, cur = Sys.brightnessRaw, f = Sky.night, scale = Sky.screen;
        if (max <= 0)
            return;
        Sys.fading = false;
        if (f <= 0 && scale >= 1) {
            const t = Store.nightSaved >= 0 ? target(Store.nightSaved, 1, 0) : -1;
            if (t > cur && !manual) {
                set(ease(cur, t));
                return;
            }
            Store.nightSaved = -1;
            lastSet = -1;
            manual = false;
            restoring = false;
            return;
        }
        if (Store.nightSaved < 0)
            Store.nightSaved = Math.round(100 * cur / max);
        if (lastSet >= 0 && cur - lastSet > max / 200)
            manual = true;
        const t = target(Store.nightSaved, scale, f);
        const pending = restoring ? t !== cur : Sky.rising ? t > cur : (!manual && t < cur);
        if (pending) {
            set(ease(cur, t));
            return;
        }
        restoring = false;
        if (!manual)
            lastSet = cur;
    }

    function resume() {
        manual = false;
        restoring = true;
        lastSet = Sys.brightnessRaw;
        step();
    }

    Timer {
        id: revert
        interval: 3600000
        onTriggered: root.resume()
    }

    Connections {
        target: Sys
        function onBrightnessRawChanged() {
            if (root.manual && Sys.brightnessRaw !== root.lastSet) {
                revert.restart();
                Ui.screenManualAt = Date.now();
            }
        }
    }

    onManualChanged: {
        Ui.screenManualAt = manual ? Date.now() : 0;
        manual ? revert.restart() : revert.stop();
    }

    Connections {
        target: Ui
        function onAutoAll() {
            root.resume();
        }
    }

    Timer {
        running: true
        interval: 10000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.step()
    }
}

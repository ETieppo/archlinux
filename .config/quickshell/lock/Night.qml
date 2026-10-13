import QtQuick
import Quickshell
import qs

Scope {
    id: root

    readonly property int dim: 5
    // Store.nightSaved: brilho (%) de antes do anoitecer, -1 durante o dia
    property int lastSet: -1
    property bool manual: false

    // interpola em escala logarítmica para a mudança parecer uniforme ao olho
    function target(base, f) {
        const lo = Sys.brightnessMax * dim / 100, hi = Sys.brightnessMax * base / 100;
        return hi <= lo ? Math.round(hi) : Math.round(hi * Math.pow(lo / hi, f));
    }

    // no máximo ~4% de mudança por passo (10 s), para nunca cair ou subir de uma vez
    function ease(cur, t) {
        const lo = Math.floor(cur * 0.96), hi = Math.ceil(cur / 0.96) + 1;
        return Math.max(lo, Math.min(hi, t));
    }

    function set(v) {
        Sys.setBrightnessRaw(v);
        lastSet = v;
    }

    function step() {
        const max = Sys.brightnessMax, cur = Sys.brightnessRaw, f = Sky.night;
        if (max <= 0)
            return;
        if (f <= 0) {
            // volta aos poucos ao brilho de antes do anoitecer
            const t = Store.nightSaved >= 0 ? target(Store.nightSaved, 0) : -1;
            if (t > cur && !manual) {
                set(ease(cur, t));
                return;
            }
            Store.nightSaved = -1;
            lastSet = -1;
            manual = false;
            return;
        }
        if (Store.nightSaved < 0)
            Store.nightSaved = Math.round(100 * cur / max);
        // se o usuário aumentou o brilho, para de escurecer até amanhecer
        if (lastSet >= 0 && cur - lastSet > max / 200)
            manual = true;
        const t = target(Store.nightSaved, f);
        // anoitecer/noite só escurece (e respeita ajuste manual); amanhecer só clareia
        if (Sky.rising ? t > cur : (!manual && t < cur))
            set(ease(cur, t));
        else if (!manual)
            lastSet = cur;
    }

    Timer {
        running: true
        interval: 10000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.step()
    }
}

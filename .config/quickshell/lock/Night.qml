import QtQuick
import Quickshell
import qs

Scope {
    id: root

    readonly property int dim: 5

    function enter() {
        if (Store.nightSaved < 0 && Sys.brightness > dim) {
            Store.nightSaved = Sys.brightness;
            Sys.setBrightness(dim);
        }
    }

    function leave() {
        if (Store.nightSaved >= 0)
            Sys.setBrightness(Store.nightSaved);
        Store.nightSaved = -1;
    }

    Connections {
        target: Sky
        function onSleepingChanged() {
            if (Sky.sleeping)
                root.enter();
            else
                root.leave();
        }
    }

    Timer {
        running: true
        interval: 3000
        onTriggered: Sky.sleeping ? root.enter() : root.leave()
    }
}

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs

Scope {
    id: root

    readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)
    property real savedBrightness: -1

    function dpms(on) {
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.dpms({ action = "${on ? "enable" : "disable"}" })`]);
    }

    IdleMonitor {
        enabled: !root.playing && !Ui.locked
        timeout: 300
        onIsIdleChanged: {
            if (isIdle) {
                root.savedBrightness = Sys.brightness;
                Sys.setBrightness(Math.min(Sys.brightness, 15));
            } else if (root.savedBrightness >= 0) {
                Sys.setBrightness(root.savedBrightness);
                root.savedBrightness = -1;
            }
        }
    }

    IdleMonitor {
        enabled: !root.playing
        timeout: 360
        onIsIdleChanged: if (isIdle) Ui.lock()
    }

    IdleMonitor {
        enabled: !root.playing
        timeout: 480
        onIsIdleChanged: root.dpms(!isIdle)
    }

    IdleMonitor {
        enabled: Ui.locked
        timeout: 30
        onIsIdleChanged: root.dpms(!isIdle)
    }

    IdleMonitor {
        enabled: !root.playing && UPower.onBattery
        timeout: 900
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["systemctl", "suspend"])
    }

    Connections {
        target: Ui
        function onLockedChanged() {
            if (!Ui.locked && root.savedBrightness >= 0) {
                Sys.setBrightness(root.savedBrightness);
                root.savedBrightness = -1;
            }
        }
    }
}

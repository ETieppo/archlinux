import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs

Scope {
    id: root

    property string buffer: ""
    property bool busy: false
    property bool failed: false
    property int fails: 0

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
    readonly property var bat: UPower.displayDevice
    readonly property int pct: Math.round((bat?.percentage ?? 0) <= 1 ? (bat?.percentage ?? 0) * 100 : bat.percentage)
    readonly property string status: [
        bat?.isPresent ? `󰁹 ${pct}%` : "",
        Sys.netType === "none" ? "󰤮" : Sys.netType === "wifi" ? `󰤨 ${Sys.netName}` : "󰈀",
        player ? `󰎈 ${player.trackTitle}` : ""
    ].filter(s => s).join("     ")

    function submit() {
        if (busy || buffer === "")
            return;
        busy = true;
        failed = false;
        pam.start();
    }

    onBufferChanged: if (buffer !== "") failed = false

    Connections {
        target: Ui
        function onLockedChanged() {
            root.buffer = "";
            root.failed = false;
        }
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellPath("pam")
        config: "password.conf"

        onPamMessage: {
            if (responseRequired)
                respond(root.buffer);
        }
        onCompleted: result => {
            root.busy = false;
            root.buffer = "";
            if (result === PamResult.Success) {
                Ui.locked = false;
            } else {
                root.failed = true;
                root.fails++;
            }
        }
        onError: err => {
            root.busy = false;
            root.buffer = "";
            root.failed = true;
            root.fails++;
        }
    }

    WlSessionLock {
        locked: Ui.locked

        WlSessionLockSurface {
            color: "black"
            LockSurface {
                lock: root
                wallpaper: Ui.wallpaper
                userName: Quickshell.env("USER")
                status: root.status
            }
        }
    }
}

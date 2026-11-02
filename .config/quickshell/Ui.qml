pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    property bool nightLight: false
    property real nightOffAt: 0
    property real screenManualAt: 0
    property bool locked: false
    property bool launcherOpen: false
    property string wallpaper: Quickshell.env("HOME") + "/.local/share/wallpapers/alone.png"
    property string lastColor: ""
    property bool powerOpen: false
    property bool selecting: false
    property string _geom: ""

    FileView {
        path: Quickshell.env("HOME") + "/.config/hypr/hyprpaper.conf"
        onLoaded: {
            const m = text().match(/^\s*path\s*=\s*(.+)$/m);
            if (m)
                root.wallpaper = m[1].trim();
        }
    }

    function lock() {
        locked = true;
    }

    function cycleProfile(back) {
        const order = PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced];
        const n = order.length;
        PowerProfiles.profile = order[(order.indexOf(PowerProfiles.profile) + (back ? n - 1 : 1)) % n];
    }

    IpcHandler {
        target: "power"
        function cycle(): void {
            root.cycleProfile(false);
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            root.lock();
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.launcherOpen = !root.launcherOpen;
        }
    }

    function toggleNightLight() {
        if (nightLight)
            Quickshell.execDetached(["pkill", "-x", "gammastep"]);
        else
            Quickshell.execDetached(["gammastep"]);
        nightLight = !nightLight;
        nightOffAt = nightLight ? 0 : Date.now();
        if (nightLight)
            nightRevert.stop();
        else
            nightRevert.restart();
    }

    signal autoAll()

    function restoreAuto() {
        if (!nightLight)
            nightRevert.triggered();
        nightRevert.stop();
        autoAll();
    }

    Timer {
        id: nightRevert
        interval: 3600000
        onTriggered: {
            if (!root.nightLight) {
                Quickshell.execDetached(["sh", "-c", "pkill -x gammastep; gammastep"]);
                root.nightLight = true;
            }
            root.nightOffAt = 0;
        }
    }

    function pickColor() {
        picker.running = true;
    }

    function screenshot(region) {
        if (region)
            selecting = true;
        else
            _shoot("");
    }

    function captureRegion(x, y, w, h) {
        _geom = `${x},${y} ${w}x${h}`;
        selecting = false;
        shotDelay.restart();
    }

    function _shoot(geom) {
        screenshotCapture.file = `${Quickshell.env("HOME")}/${Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss")}.png`;
        screenshotCapture.command = ["sh", "-c", geom ? 'grim -g "$1" "$2" && wl-copy < "$2"' : 'sleep 0.3; grim "$2" && wl-copy < "$2"', "_", geom, screenshotCapture.file];
        screenshotCapture.running = true;
    }

    Process {
        id: screenshotCapture
        property string file: ""
        onExited: exitCode => {
            if (exitCode === 0)
                Notifs.send("Screenshot", "Screenshot saved", "Copied to clipboard", "normal", file);
        }
    }

    Timer {
        id: shotDelay
        interval: 120
        onTriggered: root._shoot(root._geom)
    }

    IpcHandler {
        target: "screenshot"
        function region(): void {
            root.screenshot(true);
        }
        function full(): void {
            root.screenshot(false);
        }
        function cancel(): void {
            root.selecting = false;
        }
    }

    Process {
        id: picker
        command: ["hyprpicker", "-a", "-f", "hex"]
        stdout: StdioCollector {
            onStreamFinished: {
                const c = this.text.trim();
                if (/^#[0-9a-fA-F]{6}$/.test(c))
                    root.lastColor = c;
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "pgrep -x gammastep >/dev/null && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.nightLight = this.text.trim() === "on";
                if (!root.nightLight) {
                    root.nightOffAt = Date.now();
                    nightRevert.restart();
                }
            }
        }
    }
}

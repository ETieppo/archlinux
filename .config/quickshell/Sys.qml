pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0
    property var cpuHistory: []
    property real mem: 0
    property real memUsed: 0
    property real memTotal: 0
    property int temp: 0
    property int disk: 0
    property string diskInfo: ""
    property int gpu: 0
    property real brightness: 0
    property int brightnessRaw: 0
    property int brightnessMax: 0
    property string netType: "none"
    property bool wifiEnabled: true
    property string netName: ""
    property string netIf: ""
    property string netIp: ""
    property real netFreq: 0
    property int netSignal: 0
    property int updates: 0
    property string updatesInfo: ""
    property string updatesText: ""
    property string updatesTip: ""

    property var _prevCpu: null
    readonly property string _bl: "/sys/class/backlight/intel_backlight"

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            thermal.reload();
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: bl.reload()
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: slow.running = true
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: net.running = true
    }

    Timer {
        interval: 3600 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkUpdates()
    }

    function checkUpdates() {
        upd.running = true;
    }

    IpcHandler {
        target: "sys"
        function updates(): void {
            root.checkUpdates();
        }
        function brightness(): void {
            bl.reload();
        }
    }

    function refreshNet() {
        net.running = true;
    }

    function setBrightness(pct) {
        const v = Math.max(1, Math.min(100, Math.round(pct)));
        brightness = v;
        Quickshell.execDetached(["brightnessctl", "-q", "set", v + "%"]);
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root._prevCpu) {
                const dt = total - root._prevCpu.total;
                const di = idle - root._prevCpu.idle;
                root.cpu = dt > 0 ? Math.round(100 * (1 - di / dt)) : 0;
                root.cpuHistory = [...root.cpuHistory, root.cpu].slice(-30);
            }
            root._prevCpu = { total, idle };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(t.match(/MemTotal:\s+(\d+)/)[1]);
            const avail = Number(t.match(/MemAvailable:\s+(\d+)/)[1]);
            root.memTotal = total / 1048576;
            root.memUsed = (total - avail) / 1048576;
            root.mem = Math.round(100 * (total - avail) / total);
        }
    }

    FileView {
        id: thermal
        path: "/sys/class/thermal/thermal_zone1/temp"
        onLoaded: root.temp = Math.round(Number(text()) / 1000)
    }

    function setBrightnessRaw(v) {
        brightnessRaw = v;
        Quickshell.execDetached(["brightnessctl", "-q", "set", String(v)]);
    }

    FileView {
        id: blMax
        path: root._bl + "/max_brightness"
    }

    FileView {
        id: bl
        path: root._bl + "/brightness"
        onLoaded: {
            const max = Number(blMax.text());
            if (max > 0) {
                root.brightnessMax = max;
                root.brightnessRaw = Number(text());
                root.brightness = Math.round(100 * root.brightnessRaw / max);
            }
        }
    }

    Process {
        id: slow
        command: ["sh", "-c", "df -h --output=pcent,used,size / | tail -1; nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.trim().split("\n");
                const d = l[0].trim().split(/\s+/);
                root.disk = parseInt(d[0]);
                root.diskInfo = `${d[1]} usados de ${d[2]} em /`;
                root.gpu = parseInt(l[1]) || 0;
            }
        }
    }

    Process {
        id: net
        command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status; echo ---; nmcli radio wifi; echo ---; nmcli -t -f IN-USE,SIGNAL,FREQ device wifi list --rescan no; echo ---; ip -o -4 addr show scope global | awk '{print $2, $4}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [devs, radio, wifi, addrs] = this.text.split("---\n");
                const up = devs.trim().split("\n").map(l => l.split(":")).filter(f => f[2] === "connected");
                const c = up.find(f => f[1] === "ethernet") ?? up.find(f => f[1] === "wifi");
                root.wifiEnabled = (radio ?? "").trim() !== "disabled";
                root.netType = c ? c[1] : "none";
                root.netIf = c ? c[0] : "";
                root.netName = c ? c.slice(3).join(":") : "";
                const cur = (wifi ?? "").trim().split("\n").find(l => l.startsWith("*:"));
                root.netSignal = cur ? parseInt(cur.split(":")[1]) : 0;
                root.netFreq = cur ? parseInt(cur.split(":")[2]) / 1000 : 0;
                const a = (addrs ?? "").trim().split("\n").map(l => l.split(" ")).find(f => f[0] === root.netIf);
                root.netIp = a ? a[1] : "";
            }
        }
    }

    Process {
        id: upd
        command: [Quickshell.shellPath("scripts/update"), "module"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(this.text);
                    const tip = (j.tooltip ?? "").replace(/<[^>]+>/g, "");
                    root.updatesInfo = tip;
                    root.updatesText = j.text ?? "";
                    root.updatesTip = j.tooltip ?? "";
                    root.updates = (tip.match(/\d+/g) ?? []).reduce((a, b) => a + Number(b), 0);
                } catch (e) {
                    root.updates = 0;
                }
            }
        }
    }
}

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
  property real brightness: 0
  property int brightnessRaw: 0
  property int brightnessMax: 0
  property bool fading: false
  property string netType: "none"
  property bool wifiEnabled: true
  property string netName: ""
  property string netIf: ""
  property string netIp: ""
  property real netFreq: 0
  property int netSignal: 0
  property var cores: []
  property var coreFreqs: []
  property var cpuTopology: []
  property string loadAvg: ""
  property var dgpu: null
  property var igpu: null
  property string dgpuState: "absent"
  readonly property int gpu: dgpu?.util ?? 0
  readonly property int gpuTemp: dgpu?.temp ?? 0
  property var temps: []
  property int updates: 0
  property string updatesInfo: ""
  property string updatesText: ""
  property string updatesTip: ""

  property var _prevCpu: null
  property var _prevCores: []
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
      loadavg.reload();
      sensors.running = true;
      freqs.running = true;
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: gpuProbe.running = true
  }

  function parseCpuList(list) {
    return list.trim().split(",").filter(Boolean).reduce((ids, part) => {
      const [lo, hi] = part.split("-").map(Number);
      return ids.concat(Array.from({
        length: (hi ?? lo) - lo + 1
      }, (_, i) => lo + i));
    }, []);
  }

  Process {
    id: topology
    running: true
    command: ["sh", "-c", "grep -H . /sys/devices/system/cpu/cpu[0-9]*/topology/core_cpus_list /sys/devices/cpu_core/cpus 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = this.text.trim().split("\n");
        const perfLine = lines.find(l => l.startsWith("/sys/devices/cpu_core/cpus:"));
        const perf = new Set(perfLine ? root.parseCpuList(perfLine.split(":")[1]) : []);
        const siblings = [];
        for (const l of lines) {
          const m = l.match(/cpu(\d+)\/topology\/core_cpus_list:(.+)$/);
          if (m)
            siblings[Number(m[1])] = root.parseCpuList(m[2]);
        }
        const kindOf = id => perf.size === 0 ? "C" : perf.has(id) ? "P" : "E";
        const coreIndex = {};
        root.cpuTopology = siblings.map((sib, id) => {
          const kind = kindOf(id);
          const leader = sib[0];
          const index = coreIndex[kind] ?? (coreIndex[kind] = new Map());
          if (!index.has(leader))
            index.set(leader, index.size);
          const core = index.get(leader);
          const rank = sib.indexOf(id);
          return {
            id,
            kind,
            core,
            rank,
            name: sib.length > 1 ? `${kind}${core}.${rank}` : `${kind}${core}`
          };
        }).filter(Boolean);
      }
    }
  }

  Process {
    id: freqs
    command: ["sh", "-c", "grep -H . /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = [];
        for (const l of this.text.trim().split("\n")) {
          const m = l.match(/cpu(\d+)\/cpufreq\/scaling_cur_freq:(\d+)/);
          if (m)
            out[Number(m[1])] = Math.round(Number(m[2]) / 1000);
        }
        root.coreFreqs = Array.from(out, v => v ?? 0);
      }
    }
  }

  Process {
    id: gpuProbe
    command: [Quickshell.shellPath("scripts/gpu")]
    stdout: StdioCollector {
      onStreamFinished: root.parseGpu(this.text)
    }
  }

  function parseGpu(text) {
    const num = s => {
      const n = parseFloat(s);
      return Number.isFinite(n) ? n : null;
    };
    let igpu = null;
    let dgpu = null;
    let state = "absent";
    for (const line of text.trim().split("\n")) {
      const [key, ...rest] = line.split(" ");
      const value = rest.join(" ");
      if (key === "igpu") {
        const [freq, maxFreq] = rest.map(Number);
        igpu = maxFreq > 0 ? {
          freq,
          maxFreq
        } : null;
      } else if (key === "dgpu") {
        state = value;
      } else if (key === "nvidia") {
        const f = value.split(",").map(x => x.trim());
        dgpu = {
          util: num(f[0]) ?? 0,
          memUtil: num(f[1]) ?? 0,
          enc: num(f[2]),
          dec: num(f[3]),
          vramUsed: num(f[4]) ?? 0,
          vramTotal: num(f[5]) ?? 0,
          temp: Math.round(num(f[6]) ?? 0),
          power: num(f[7]),
          clock: num(f[8]) ?? 0,
          pstate: f[9] ?? "",
          name: f.slice(10).join(", ")
        };
      }
    }
    root.igpu = igpu;
    root.dgpu = state === "suspended" ? null : dgpu;
    root.dgpuState = state;
  }

  Process {
    id: sensors
    command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name); for t in $h/temp*_input; do [ -f \"$t\" ] || continue; echo \"$n|$(cat ${t%_input}_label 2>/dev/null)|$(cat $t)\"; done; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        const rows = this.text.trim().split("\n").map(l => l.split("|")).filter(r => r.length === 3).map(r => ({
              dev: r[0],
              label: r[1],
              t: Math.round(Number(r[2]) / 1000)
            }));
        const pick = (dev, label) => rows.find(r => r.dev === dev && (!label || r.label === label))?.t;
        const cores = rows.filter(r => r.dev === "coretemp" && r.label.startsWith("Core")).map(r => r.t);
        const nvme = rows.filter(r => r.dev === "nvme");
        root.temps = [
          {
            name: "CPU package",
            t: pick("coretemp", "Package id 0")
          },
          {
            name: "Hottest core",
            t: cores.length ? Math.max(...cores) : undefined
          },
          {
            name: "GPU",
            t: root.gpuTemp || undefined
          },
          ...nvme.map((r, i) => ({
                name: `SSD ${i + 1}`,
                t: r.t
              })),
          {
            name: "Wi-Fi",
            t: pick("iwlwifi_1")
          },
          {
            name: "Ethernet",
            t: rows.find(r => r.dev.startsWith("r8169"))?.t
          },
          {
            name: "Board",
            t: pick("acpitz")
          }
        ].filter(x => x.t !== undefined);
      }
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
      root._prevCpu = {
        total,
        idle
      };
      const per = text().split("\n").filter(l => /^cpu\d/.test(l)).map(l => {
        const v = l.trim().split(/\s+/).slice(1).map(Number);
        return {
          total: v.reduce((a, b) => a + b, 0),
          idle: v[3] + v[4]
        };
      });
      root.cores = per.map((c, i) => {
        const p = root._prevCores[i];
        const dt = p ? c.total - p.total : 0;
        return dt > 0 ? Math.round(100 * (1 - (c.idle - p.idle) / dt)) : 0;
      });
      root._prevCores = per;
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
    id: loadavg
    path: "/proc/loadavg"
    onLoaded: root.loadAvg = text().trim().split(/\s+/).slice(0, 3).join(" ")
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
    command: ["sh", "-c", "df -h --output=pcent,used,size / | tail -1"]
    stdout: StdioCollector {
      onStreamFinished: {
        const d = this.text.trim().split(/\s+/);
        root.disk = parseInt(d[0]);
        root.diskInfo = `${d[1]} used of ${d[2]} on /`;
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

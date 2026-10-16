pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int delay: 1500
    property var jobs: []
    property var last: null
    property var ended: ({})
    property real now: Date.now()
    readonly property var live: jobs.filter(j => now - j.start >= delay)
    readonly property var job: live.length ? live[live.length - 1] : null
    readonly property real elapsed: job ? now - job.start : 0
    readonly property real progress: job && job.est > 0 ? Math.min(0.97, elapsed / job.est) : -1

    function key(cmd, cwd) {
        return `${cwd}\n${cmd}`;
    }

    function estimate(k) {
        const d = [...(Store.runs[k]?.d ?? [])].sort((a, b) => a - b);
        return d.length ? d[Math.floor(d.length / 2)] : 0;
    }

    function record(k, dur) {
        const runs = Object.assign({}, Store.runs);
        runs[k] = {
            d: [...(runs[k]?.d ?? []), dur].slice(-5),
            t: Date.now()
        };
        const keys = Object.keys(runs);
        if (keys.length > 150)
            keys.sort((a, b) => runs[a].t - runs[b].t).slice(0, keys.length - 150).forEach(x => delete runs[x]);
        Store.runs = runs;
    }

    function fmt(ms) {
        const s = Math.floor(ms / 1000);
        if (s < 60)
            return `${s}s`;
        const m = Math.floor(s / 60), r = String(s % 60).padStart(2, "0");
        return m < 60 ? `${m}:${r}` : `${Math.floor(m / 60)}:${String(m % 60).padStart(2, "0")}:${r}`;
    }

    function start(id, cmd, cwd) {
        if (ended[id] !== undefined) {
            const e = Object.assign({}, ended);
            delete e[id];
            ended = e;
            return;
        }
        now = Date.now();
        jobs = [...jobs, {
            id,
            cmd,
            cwd,
            pid: id.split("-")[0],
            start: now,
            est: estimate(key(cmd, cwd))
        }];
    }

    function end(id, status) {
        const j = jobs.find(x => x.id === id);
        const t = Date.now();
        if (!j) {
            const e = {};
            for (const k in ended)
                if (t - ended[k] < 10000)
                    e[k] = ended[k];
            e[id] = t;
            ended = e;
            return;
        }
        jobs = jobs.filter(x => x !== j);
        const dur = t - j.start;
        if (dur < delay)
            return;
        last = {
            cmd: j.cmd,
            status,
            dur,
            at: t
        };
        if (status === 0)
            record(key(j.cmd, j.cwd), dur);
        if (dur >= 60000)
            Quickshell.execDetached(["notify-send", "-a", "Terminal", status === 0 ? `Finished in ${fmt(dur)}` : status === 130 ? `Interrupted after ${fmt(dur)}` : `Failed after ${fmt(dur)} (exit ${status})`, j.cmd]);
    }

    Timer {
        interval: 250
        repeat: true
        running: root.jobs.length > 0 || (root.last !== null && root.now - root.last.at < 600000)
        onTriggered: root.now = Date.now()
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.jobs.length > 0
        onTriggered: {
            alive.command = ["sh", "-c", "for p; do [ -d /proc/$p ] || echo $p; done", "_", ...new Set(root.jobs.map(j => j.pid))];
            alive.running = true;
        }
    }

    Process {
        id: alive
        stdout: StdioCollector {
            onStreamFinished: {
                const dead = this.text.split("\n").filter(s => s);
                if (dead.length)
                    root.jobs = root.jobs.filter(j => !dead.includes(j.pid));
            }
        }
    }

    IpcHandler {
        target: "term"
        function start(id: string, cmd: string, cwd: string): void {
            root.start(id, cmd, cwd);
        }
        function end(id: string, status: int): void {
            root.end(id, status);
        }
    }
}

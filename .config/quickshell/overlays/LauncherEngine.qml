import QtQuick
import Quickshell
import qs

QtObject {
    id: root

    property string query: ""
    property int limit: 10
    readonly property var apps: {
        const seen = new Set();
        return DesktopEntries.applications.values.filter(e => !e.noDisplay && !seen.has(e.id) && seen.add(e.id));
    }
    readonly property var results: {
        const q = query.trim();
        if (q.startsWith(">")) {
            const cmd = q.slice(1).trim();
            return cmd ? [{ kind: "run", name: cmd }] : [];
        }
        const out = [];
        const looksMath = q.startsWith("=") || (/^[\d\s.,+\-*/()^%]+$/.test(q) && /[+\-*/^%]/.test(q));
        if (looksMath) {
            const v = calc(q.replace(/^=/, ""));
            if (v !== null)
                out.push({ kind: "calc", name: String(v) });
            if (q.startsWith("="))
                return out;
        }
        const ql = q.toLowerCase();
        const scored = apps.map(e => ({ e, s: score(e, ql) })).filter(x => x.s > 0);
        scored.forEach(x => x.s += Math.min(30, (Store.usage[x.e.id] ?? 0) * 3));
        scored.sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name));
        return out.concat(scored.slice(0, limit).map(x => ({ kind: "app", entry: x.e, name: x.e.name })));
    }

    function score(e, q) {
        const n = e.name.toLowerCase();
        if (!q)
            return 1;
        if (n.startsWith(q))
            return 100;
        if (n.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 80;
        if (n.includes(q))
            return 60;
        const extra = [e.genericName, e.comment, e.id, ...(e.keywords ?? [])].join(" ").toLowerCase();
        if (extra.includes(q))
            return 40;
        let i = 0;
        for (const ch of n)
            if (ch === q[i])
                i++;
        return i === q.length ? 15 : 0;
    }

    function calc(expr) {
        const fns = ["sqrt", "sin", "cos", "tan", "asin", "acos", "atan", "log", "ln", "exp", "abs", "floor", "ceil", "round", "pow", "min", "max", "pi", "e"];
        const e = expr.replace(/,/g, ".").replace(/\^/g, "**").replace(/π/g, "pi").replace(/×/g, "*").replace(/÷/g, "/");
        if (!/^[\d\s+\-*/%().a-z]+$/i.test(e) || !(e.match(/[a-z]+/gi) ?? []).every(w => fns.includes(w.toLowerCase())))
            return null;
        try {
            const f = new Function(...fns, `return (${e.toLowerCase()});`);
            const r = f(Math.sqrt, Math.sin, Math.cos, Math.tan, Math.asin, Math.acos, Math.atan, Math.log10, Math.log, Math.exp, Math.abs, Math.floor, Math.ceil, Math.round, Math.pow, Math.min, Math.max, Math.PI, Math.E);
            return typeof r === "number" && isFinite(r) ? +r.toPrecision(12) : null;
        } catch (err) {
            return null;
        }
    }

    function iconFor(name) {
        return name ? Quickshell.iconPath(name, true) : "";
    }

    function activate(item) {
        if (!item)
            return;
        if (item.kind === "app") {
            Store.bump(item.entry.id);
            item.entry.execute();
        } else if (item.kind === "calc") {
            Quickshell.clipboardText = item.name;
        } else if (item.kind === "run") {
            Quickshell.execDetached(["sh", "-c", item.name]);
        }
    }
}

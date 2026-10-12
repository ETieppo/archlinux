import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.components

PanelWindow {
    id: root

    readonly property bool open: Ui.launcherOpen
    readonly property int maxBubbles: 28
    readonly property int blobR: 40
    readonly property int surface: 64 // liquid surface height above screen bottom
    readonly property real poolY: height - surface + 30
    // lava palette, blended where bubbles merge
    readonly property list<color> palette: [Theme.accent, "#89b4fa", Theme.mauve, "#94e2d5"]
    readonly property real exposure: 0.5
    readonly property color liquidTop: palette[0]
    readonly property color liquidRim: "#d4fbff"
    property real reveal: open ? 1 : 0
    property real time: 0
    property string query: ""
    property int current: 0
    property var slotOf: ({})
    property point lastPointer: Qt.point(-1, -1)

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: reveal > 0

    Behavior on reveal { NumberAnimation { duration: root.open ? 350 : 750; easing.type: Easing.InOutCubic } }

    NumberAnimation on time {
        from: 0
        to: 100000
        duration: 100000 * 1000
        loops: Animation.Infinite
        running: root.visible
    }

    onOpenChanged: {
        if (!open)
            return;
        input.text = "";
        current = 0;
        input.forceActiveFocus();
    }
    onQueryChanged: current = 0
    onShownChanged: reslot()

    function close() {
        Ui.launcherOpen = false;
    }

    function hash(s) {
        let h = 2166136261;
        for (let i = 0; i < s.length; i++)
            h = Math.imul(h ^ s.charCodeAt(i), 16777619);
        return (h >>> 0) / 4294967296;
    }

    function iconFor(name) {
        return name ? Quickshell.iconPath(name, true) : "";
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
        return out.concat(scored.slice(0, maxBubbles).map(x => ({ kind: "app", entry: x.e, name: x.e.name })));
    }

    // apps currently floating as bubbles, by entry id -> index in results
    readonly property var rank: {
        const m = {};
        results.forEach((r, i) => {
            if (r.kind === "app")
                m[r.entry.id] = i;
        });
        return m;
    }
    readonly property var shown: results.filter(r => r.kind === "app").map(r => r.entry.id)

    // scattered anchor points: one jittered cell each, in a shuffled order
    readonly property var slots: {
        const W = width - 160, H = height - surface - 220;
        if (W <= 0 || H <= 0)
            return [];
        const cols = 7, rows = 4, cw = W / cols, ch = H / rows;
        let seed = 7;
        const rnd = () => {
            seed = (seed * 16807) % 2147483647;
            return seed / 2147483647;
        };
        const out = [];
        for (let r = 0; r < rows; r++)
            for (let c = 0; c < cols; c++)
                out.push({
                    x: 80 + (c + 0.5 + (rnd() - 0.5) * 0.5) * cw + (r % 2 ? cw * 0.25 : -cw * 0.25),
                    y: 90 + (r + 0.5 + (rnd() - 0.5) * 0.45) * ch
                });
        for (let i = out.length - 1; i > 0; i--) {
            const j = Math.floor(rnd() * (i + 1));
            [out[i], out[j]] = [out[j], out[i]];
        }
        return out;
    }

    // apps keep their slot while visible; newcomers take a free one
    function reslot() {
        const next = {}, used = new Set();
        for (const id of shown)
            if (slotOf[id] !== undefined) {
                next[id] = slotOf[id];
                used.add(slotOf[id]);
            }
        const free = slots.map((_, i) => i).filter(i => !used.has(i));
        for (const id of shown)
            if (next[id] === undefined && free.length)
                next[id] = free.splice(Math.floor(hash(id) * free.length), 1)[0];
        slotOf = next;
    }
    onSlotsChanged: {
        slotOf = {};
        reslot();
    }

    function posOf(r) {
        const s = r?.kind === "app" ? slots[slotOf[r.entry.id]] : null;
        return s ?? null;
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
        close();
    }

    // jump to the nearest bubble in direction (dx, dy)
    function spatial(dx, dy) {
        const from = posOf(results[current]);
        if (!from) {
            if (results.length)
                current = Math.max(0, Math.min(results.length - 1, current + dx + dy));
            return;
        }
        let best = -1, bestScore = Infinity;
        results.forEach((r, i) => {
            const p = posOf(r);
            if (!p || i === current)
                return;
            const vx = p.x - from.x, vy = p.y - from.y;
            const along = vx * dx + vy * dy;
            if (along <= 0)
                return;
            const s = along + 2.5 * Math.abs(vx * dy - vy * dx);
            if (s < bestScore) {
                bestScore = s;
                best = i;
            }
        });
        if (best >= 0)
            current = best;
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.open && root.visible
        onCleared: root.close()
    }

    component AppIcon: Item {
        id: ai
        property string icon: ""
        property string name: ""
        property int size: 40
        readonly property string path: root.iconFor(icon)

        implicitWidth: size
        implicitHeight: size

        IconImage {
            anchors.fill: parent
            visible: ai.path !== ""
            source: ai.path
        }
        Text {
            anchors.centerIn: parent
            visible: ai.path === ""
            text: ai.name.charAt(0).toUpperCase()
            font.family: Theme.font
            font.pixelSize: ai.size * 0.6
            font.bold: true
            color: Theme.bgSolid
        }
    }

    // backdrop
    Rectangle {
        anchors.fill: parent
        opacity: root.reveal
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.bgSolid, 0.93) }
            GradientStop { position: 1; color: Qt.alpha("#05050a", 0.98) }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // metaball field (density + hue + selection), rendered offscreen
    Item {
        id: field
        anchors.fill: parent

        // the pool the bubbles rise from and drain into
        Rectangle {
            width: parent.width
            height: root.surface * 2
            y: parent.height - height + (1 - root.reveal) * root.surface * 2
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 2 / 3, 0, 0) }
                GradientStop { position: 1; color: Qt.rgba(0, 2 / 3, 0, 1) }
            }
        }

        // waves on the surface
        Repeater {
            model: 14
            LavaDrop {
                required property int index
                readonly property real ph: index * 1.913
                cx: (index + 0.5) / 14 * field.width + Math.sin(root.time * 0.23 + ph) * 50
                cy: root.poolY + 6 + Math.sin(root.time * 0.4 + ph * 2.1) * 12 + (1 - root.reveal) * 120
                hue: 1 + index % 3
                r: (34 + 18 * Math.sin(ph * 3.3)) * (0.7 + 0.3 * Math.sin(root.time * 0.3 + ph))
            }
        }

        // free lava blobs rising and sinking like a lamp
        Repeater {
            model: 5
            LavaDrop {
                required property int index
                readonly property real ph: index * 2.371
                readonly property real period: 26 + index * 7
                // 0 at the pool, 1 near the top
                readonly property real h: 0.5 - 0.5 * Math.cos((root.time / period) * 2 * Math.PI + ph)
                cx: field.width * (0.12 + 0.19 * index) + Math.sin(root.time * 0.17 + ph) * 70
                hue: (index * 3) % 4
                cy: root.poolY + 20 - h * (field.height * 0.82) + (1 - root.reveal) * 200
                r: (46 + index * 9) * (0.55 + 0.45 * Math.min(1, h * 4)) * Math.min(1, root.reveal * 2)
            }
        }
    }

    ShaderEffect {
        anchors.fill: parent
        opacity: Math.min(1, root.reveal * 1.5)
        fragmentShader: Qt.resolvedUrl("lava/lava.frag.qsb")
        property var source: ShaderEffectSource {
            sourceItem: field
            hideSource: true
            mipmap: true
            smooth: true
            format: ShaderEffectSource.RGBA16F
        }
        property real time: root.time
        property real threshold: 0.5
        property size texel: Qt.size(1 / Math.max(1, width), 1 / Math.max(1, height))
        property color c0: root.palette[0]
        property color c1: root.palette[1]
        property color c2: root.palette[2]
        property color c3: root.palette[3]
        property color deep: "#07070d"
        property real exposure: root.exposure
    }

    // fizz: tiny bubbles climbing out of the pool
    Repeater {
        model: 22
        Rectangle {
            id: fizz
            required property int index
            readonly property real ph: Math.abs(Math.sin(index * 12.9898 + 78.233) * 43758.5453) % 1
            readonly property real period: 7 + ph * 9
            readonly property real k: ((root.time + ph * period) % period) / period
            width: 3 + Math.round(ph * 7)
            height: width
            radius: width / 2
            x: ph * root.width + Math.sin(root.time * 1.3 + index) * 8
            y: root.poolY - 10 - k * root.height * (0.45 + ph * 0.45)
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(root.liquidRim, 0.55)
            opacity: root.reveal * Math.min(1, k * 6) * (1 - k)
        }
    }

    // one bubble per app: its drop lives in the field, its icon on top
    Repeater {
        model: root.apps

        Item {
            id: bub
            required property var modelData
            required property int index
            readonly property string appId: modelData.id
            readonly property int rk: root.rank[appId] ?? -1
            readonly property var slot: root.slots[root.slotOf[appId]] ?? null
            readonly property bool live: root.open && rk >= 0 && slot !== null
            readonly property bool current: rk === root.current && live
            readonly property real ph: root.hash(appId) * 6.283
            property real ax: root.hash(appId + "x") * root.width
            property real ay: root.height * 0.5
            property real lift: live ? 1 : 0
            property real grow: current ? 1.22 : hover.containsMouse ? 1.1 : 1
            readonly property real cx: ax + Math.sin(root.time * 0.31 + ph) * 9
            readonly property real cy: root.poolY + (ay + Math.sin(root.time * 0.43 + ph * 1.7) * 14 - root.poolY) * lift
            readonly property real r: root.blobR * grow * (0.3 + 0.7 * lift)

            onSlotChanged: if (slot) {
                ax = slot.x;
                ay = slot.y;
            }
            Component.onCompleted: if (slot) {
                ax = slot.x;
                ay = slot.y;
            }

            Behavior on lift {
                NumberAnimation {
                    duration: bub.live ? 900 + (bub.index % 7) * 90 : 650 + (bub.index % 5) * 60
                    easing.type: bub.live ? Easing.OutCubic : Easing.InCubic
                }
            }
            Behavior on grow { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

            LavaDrop {
                parent: field
                cx: bub.cx
                cy: bub.cy
                r: bub.lift > 0.01 ? bub.r : 0
                hue: Math.floor(root.hash(bub.appId + "hue") * 4)
                hot: bub.current ? 1 : 0
                Behavior on hot { NumberAnimation { duration: 260 } }
            }

            AppIcon {
                readonly property real s: Math.round(bub.r * 1.05)
                x: bub.cx - s / 2
                y: bub.cy - s / 2
                size: s
                icon: bub.modelData.icon ?? ""
                name: bub.modelData.name
                opacity: Math.max(0, bub.lift * 1.6 - 0.6)
                visible: opacity > 0
            }

            // name tag for the selected / hovered bubble
            Rectangle {
                readonly property bool on: (bub.current || hover.containsMouse) && bub.lift > 0.9
                x: bub.cx - width / 2
                y: bub.cy + bub.r + 16
                width: tag.implicitWidth + 20
                height: 24
                radius: 12
                color: Qt.alpha(Theme.bgSolid, 0.85)
                border.width: 1
                border.color: Qt.alpha(root.liquidTop, 0.3)
                opacity: on ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 160 } }

                Label {
                    id: tag
                    anchors.centerIn: parent
                    text: bub.modelData.name
                    font.pixelSize: 12
                    color: Theme.fg
                }
            }

            MouseArea {
                id: hover
                readonly property real d: bub.r * 2
                x: bub.cx - d / 2
                y: bub.cy - d / 2
                width: d
                height: d
                enabled: bub.live
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // bubbles drift under a parked cursor: only a real pointer move selects
                onPositionChanged: mouse => {
                    const g = mapToItem(null, mouse.x, mouse.y);
                    if (g.x !== root.lastPointer.x || g.y !== root.lastPointer.y) {
                        root.lastPointer = Qt.point(g.x, g.y);
                        root.current = bub.rk;
                    }
                }
                onClicked: root.activate(root.results[bub.rk])
            }
        }
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.42
        visible: root.query.trim() !== "" && root.results.length === 0
        opacity: root.reveal
        text: "nada por aqui"
        color: Theme.dim
        font.pixelSize: 18
    }

    // search capsule floating on the surface
    Rectangle {
        id: capsule
        readonly property var cur: root.results[root.current]
        anchors.horizontalCenter: parent.horizontalCenter
        width: 560
        height: 50
        radius: 25
        y: root.height - root.surface - height / 2 + (1 - root.reveal) * 140
        color: Qt.alpha(Theme.bgSolid, 0.78)
        border.width: 1
        border.color: Qt.alpha(root.liquidRim, input.text ? 0.55 : 0.25)
        Behavior on border.color { ColorAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            onClicked: input.forceActiveFocus()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 12

            Icon {
                text: root.query.startsWith(">") ? "" : root.query.startsWith("=") || capsule.cur?.kind === "calc" ? "󰃬" : "󰍉"
                color: root.liquidTop
            }

            TextInput {
                id: input
                Layout.fillWidth: true
                color: Theme.fg
                selectionColor: Qt.alpha(root.liquidTop, 0.4)
                font.family: Theme.font
                font.pixelSize: 16
                font.bold: true
                focus: true
                clip: true
                onTextChanged: root.query = text

                Text {
                    visible: !input.text
                    text: "buscar"
                    color: Theme.muted
                    font: input.font
                }

                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape)
                        root.close();
                    else if (e.key === Qt.Key_Down)
                        root.spatial(0, 1);
                    else if (e.key === Qt.Key_Up)
                        root.spatial(0, -1);
                    else if (e.key === Qt.Key_Right)
                        root.spatial(1, 0);
                    else if (e.key === Qt.Key_Left)
                        root.spatial(-1, 0);
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                        root.activate(capsule.cur);
                    else
                        return;
                    e.accepted = true;
                }
            }

            Label {
                Layout.maximumWidth: 240
                visible: text !== ""
                text: capsule.cur?.kind === "calc" ? "= " + capsule.cur.name : capsule.cur?.kind === "run" ? "↵ executar" : input.text ? capsule.cur?.name ?? "" : ""
                color: capsule.cur?.kind === "calc" ? root.liquidTop : Theme.dim
                font.pixelSize: capsule.cur?.kind === "calc" ? 16 : 13
                elide: Text.ElideRight
            }
        }
    }
}

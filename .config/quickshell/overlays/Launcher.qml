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
    readonly property int maxBubbles: 80
    readonly property int blobR: 40
    readonly property int surface: 64
    readonly property real poolY: height - surface + 30
    readonly property list<color> palette: ["#00e5ff", "#ff2bc2", "#7b2cff", "#1f5bff"]
    readonly property real exposure: 0.62
    readonly property color liquidTop: palette[0]
    readonly property color liquidRim: "#8ff3ff"
    property real reveal: open ? 1 : 0
    property real time: 0
    property string query: ""
    property int current: 0
    property bool normalMode: false
    property var slotOf: ({})
    property point lastPointer: Qt.point(-1, -1)
    property point pointer: Qt.point(-1, -1)
    property real kick: 0
    property real crownX: width / 2
    property real crownY: height / 2
    readonly property bool crownOn: open && results[current]?.kind === "app"

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
        normalMode = false;
        input.forceActiveFocus();
    }
    onQueryChanged: {
        current = 0;
        kickAnim.restart();
    }

    NumberAnimation {
        id: kickAnim
        target: root
        property: "kick"
        from: 1
        to: 0
        duration: 700
        easing.type: Easing.OutCubic
    }
    onShownChanged: reslot()

    readonly property var magnets: {
        const out = [];
        if (pointer.y >= 0)
            out.push({ x: pointer.x, s: Math.exp(-Math.max(0, poolY - pointer.y) / 380), w: 105, h: 210 });
        if (crownOn)
            out.push({ x: crownX, s: 0.8 * Math.exp(-Math.max(0, poolY - crownY) / 520), w: 85, h: 560 });
        for (let k = 0; k < 3; k++)
            out.push({
                x: width * (0.5 + 0.46 * Math.sin(time * 0.045 * (k + 1) + k * 2.3)),
                s: Math.max(0, Math.sin(time * 0.09 * (k + 1.4) + k * 1.7)),
                w: 70 + k * 25,
                h: 95 + k * 20
            });
        return out;
    }

    function fieldAt(x) {
        let f = 0, lean = 0;
        for (const m of magnets) {
            const g = m.s * m.h * Math.exp(-Math.pow((x - m.x) / m.w, 2));
            f += g;
            lean += g * (m.x - x) / m.w;
        }
        return { f, lean: f > 1 ? lean / f : 0 };
    }

    function close() {
        Ui.launcherOpen = false;
    }

    function hash(s) {
        let h = 2166136261;
        for (let i = 0; i < s.length; i++)
            h = Math.imul(h ^ s.charCodeAt(i), 16777619);
        return (h >>> 0) / 4294967296;
    }

    function rnd(i, salt) {
        const v = Math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
        return v - Math.floor(v);
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

    readonly property var rank: {
        const m = {};
        results.forEach((r, i) => {
            if (r.kind === "app")
                m[r.entry.id] = i;
        });
        return m;
    }
    readonly property var shown: results.filter(r => r.kind === "app").map(r => r.entry.id)

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

    function navigateByKey(key) {
        if (key === Qt.Key_Down)
            spatial(0, 1);
        else if (key === Qt.Key_Up)
            spatial(0, -1);
        else if (key === Qt.Key_Right)
            spatial(1, 0);
        else if (key === Qt.Key_Left)
            spatial(-1, 0);
        else if (key === Qt.Key_Return || key === Qt.Key_Enter)
            activate(results[current]);
        else
            return false;
        return true;
    }

    function handleInsertKey(key) {
        if (key === Qt.Key_Escape) {
            normalMode = true;
            return true;
        }
        return navigateByKey(key);
    }

    function handleNormalKey(key) {
        if (key === Qt.Key_Escape)
            close();
        else if (key === Qt.Key_H)
            spatial(-1, 0);
        else if (key === Qt.Key_J)
            spatial(0, 1);
        else if (key === Qt.Key_K)
            spatial(0, -1);
        else if (key === Qt.Key_L)
            spatial(1, 0);
        else if (key === Qt.Key_I || key === Qt.Key_A || key === Qt.Key_Slash)
            normalMode = false;
        else
            navigateByKey(key);
        return true;
    }

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

    Rectangle {
        anchors.fill: parent
        opacity: root.reveal
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.bgSolid, 0.93) }
            GradientStop { position: 1; color: Qt.alpha("#05050a", 0.98) }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: m => root.pointer = Qt.point(m.x, m.y)
            onExited: root.pointer = Qt.point(-1, -1)
            onClicked: root.close()
        }
    }

    Item {
        id: field
        anchors.fill: parent

        Rectangle {
            width: parent.width
            height: root.surface * 2
            y: parent.height - height + (1 - root.reveal) * root.surface * 2
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 2 / 3, 0, 0) }
                GradientStop { position: 1; color: Qt.rgba(0, 2 / 3, 0, 1) }
            }
        }

        Repeater {
            model: 22
            LavaDrop {
                required property int index
                readonly property real ph: root.rnd(index, 8) * 6.283
                cx: (index + 0.5 + (root.rnd(index, 9) - 0.5) * 0.9) / 22 * field.width + Math.sin(root.time * 0.17 + ph) * 30
                cy: root.poolY + 16 + Math.sin(root.time * 0.33 + ph * 2.1) * 6 + (1 - root.reveal) * 120
                hue: 1 + index % 3
                r: (24 + 20 * root.rnd(index, 10)) * (0.8 + 0.2 * Math.sin(root.time * 0.27 + ph))
            }
        }

        Repeater {
            model: 46
            LavaDrop {
                required property int index
                readonly property real ph: root.rnd(index, 1) * 6.283
                readonly property real size: Math.pow(root.rnd(index, 2), 1.6)
                readonly property real period: 24 + root.rnd(index, 3) * 46
                readonly property real h: 0.5 - 0.5 * Math.cos((root.time / period) * 2 * Math.PI + ph)
                cx: field.width * (0.03 + 0.94 * root.rnd(index, 4)) + Math.sin(root.time * (0.08 + 0.12 * (1 - size)) + ph) * 60
                hue: index % 4
                cy: root.poolY + 20 - h * (field.height * (0.55 + 0.35 * root.rnd(index, 5))) + (1 - root.reveal) * 200
                r: (11 + 44 * size) * (0.55 + 0.45 * Math.min(1, h * 4)) * Math.min(1, root.reveal * 2)
            }
        }

        Repeater {
            model: 72
            IronSpike {
                required property int index
                readonly property real rnd: root.rnd(index, 6)
                readonly property var fld: root.fieldAt(bx)
                bx: (index + 0.5 + (rnd - 0.5) * 0.8) / 72 * field.width
                by: root.height - root.surface + 14 + (1 - root.reveal) * 140
                springy: root.visible
                target: Math.max(0, (fld.f + root.kick * fld.f * 0.6) * (0.62 + 0.38 * root.rnd(index, 7)) * (0.9 + 0.1 * Math.sin(root.time * 1.1 + rnd * 9)) - 14) * root.reveal
                angle: Math.max(-16, Math.min(16, fld.lean * 14)) + Math.sin(root.time * 1.3 + rnd * 7) * 2.5
                wid: 14 + len * 0.36
            }
        }

        Item {
            id: crown
            property real scale2: root.crownOn ? 1 : 0
            property real vx: 0
            property real vy: 0
            Behavior on scale2 { NumberAnimation { duration: 380; easing.type: Easing.OutBack } }

            FrameAnimation {
                running: root.visible
                onTriggered: {
                    const dt = Math.min(frameTime, 0.05);
                    crown.vx += ((root.crownX - crown.x) * 55 - crown.vx * 11) * dt;
                    crown.vy += ((root.crownY - crown.y) * 55 - crown.vy * 11) * dt;
                    crown.x += crown.vx * dt;
                    crown.y += crown.vy * dt;
                }
            }

            LavaDrop {
                cx: 0
                cy: 0
                r: 25 * crown.scale2
                hue: 1
                hot: 1
            }

            Repeater {
                model: 11
                IronSpike {
                    required property int index
                    bx: 0
                    by: 0
                    key: 1
                    hot: 1
                    wid: 22
                    angle: index * 360 / 11 + root.time * 9
                    len: (46 + 14 * Math.sin(root.time * 1.7 + index * 1.9) + root.kick * 18) * crown.scale2
                }
            }
        }
    }

    ShaderEffect {
        anchors.fill: parent
        opacity: Math.min(1, root.reveal * 1.5)
        fragmentShader: Qt.resolvedUrl("lava/iron.frag.qsb")
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
        property color deep: "#040407"
        property real exposure: root.exposure
    }

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
            property real grow: current ? 1.2 : hover.containsMouse ? 1.08 : 1
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

            Binding {
                target: root
                property: "crownX"
                value: bub.cx
                when: bub.current
            }
            Binding {
                target: root
                property: "crownY"
                value: bub.cy
                when: bub.current
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
                onPositionChanged: mouse => {
                    const g = mapToItem(null, mouse.x, mouse.y);
                    if (g.x !== root.lastPointer.x || g.y !== root.lastPointer.y) {
                        root.lastPointer = Qt.point(g.x, g.y);
                        root.pointer = Qt.point(g.x, g.y);
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
        text: "nothing here"
        color: Theme.dim
        font.pixelSize: 18
    }

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
                readOnly: root.normalMode
                onTextChanged: root.query = text

                Text {
                    visible: !input.text
                    text: "search"
                    color: Theme.muted
                    font: input.font
                }

                Keys.onPressed: e => {
                    e.accepted = root.normalMode ? root.handleNormalKey(e.key) : root.handleInsertKey(e.key);
                }
            }

            Label {
                visible: root.normalMode
                text: "NORMAL"
                color: root.liquidTop
                font.pixelSize: 12
                font.bold: true
            }

            Label {
                Layout.maximumWidth: 240
                visible: text !== ""
                text: capsule.cur?.kind === "calc" ? "= " + capsule.cur.name : capsule.cur?.kind === "run" ? "↵ run" : input.text ? capsule.cur?.name ?? "" : ""
                color: capsule.cur?.kind === "calc" ? root.liquidTop : Theme.dim
                font.pixelSize: capsule.cur?.kind === "calc" ? 16 : 13
                elide: Text.ElideRight
            }
        }
    }
}

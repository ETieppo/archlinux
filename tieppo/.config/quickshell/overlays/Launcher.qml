import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.components

PanelWindow {
    id: root

    readonly property bool open: Ui.launcherOpen
    readonly property string mode: Ui.launcherMode
    readonly property int bodyWidth: 720
    readonly property int pad: 18
    readonly property int cols: 7
    readonly property int cellW: Math.floor((bodyWidth - 2 * pad) / cols)
    readonly property int cellH: 96
    readonly property int gridRows: 3
    readonly property int rowH: 50
    readonly property int listRows: 6
    readonly property bool gridMode: mode === "apps" && query.trim() === ""
    property real reveal: open ? 1 : 0
    property var clips: []
    property string query: ""
    property int current: 0

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: reveal > 0
    implicitWidth: bodyWidth + 2 * Theme.fillet
    implicitHeight: col.implicitHeight + pad + 6

    Behavior on reveal { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    onOpenChanged: {
        if (!open)
            return;
        input.text = "";
        current = 0;
        if (mode === "clipboard")
            clipProc.running = true;
        input.forceActiveFocus();
    }
    onModeChanged: {
        current = 0;
        if (mode === "clipboard")
            clipProc.running = true;
    }
    onQueryChanged: current = 0
    onCurrentChanged: {
        grid.positionViewAtIndex(current, GridView.Contain);
        list.positionViewAtIndex(current, ListView.Contain);
    }

    function close() {
        Ui.launcherOpen = false;
    }

    function setMode(m) {
        Ui.launcherMode = m;
        input.text = "";
        input.forceActiveFocus();
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
        if (mode === "clipboard") {
            const ql = q.toLowerCase();
            return clips.filter(c => !ql || c.text.toLowerCase().includes(ql)).map(c => ({
                kind: "clip",
                id: c.id,
                name: c.image ? "Imagem" : c.text,
                sub: c.image ? c.text.replace(/^\[\[ binary data /, "").replace(/ \]\]$/, "") : "",
                glyph: c.image ? "" : "󰅌",
                image: c.image
            }));
        }
        if (q.startsWith(">")) {
            const cmd = q.slice(1).trim();
            return cmd ? [{ kind: "run", name: cmd, sub: "Executar no shell  ·  Shift+Enter abre no terminal", glyph: "" }] : [];
        }
        const out = [];
        const looksMath = q.startsWith("=") || (/^[\d\s.,+\-*/()^%]+$/.test(q) && /[+\-*/^%]/.test(q));
        if (looksMath) {
            const v = calc(q.replace(/^=/, ""));
            if (v !== null)
                out.push({ kind: "calc", name: String(v), sub: "Enter copia o resultado", glyph: "󰃬" });
            if (q.startsWith("="))
                return out;
        }
        const ql = q.toLowerCase();
        const scored = apps.map(e => ({ e, s: score(e, ql) })).filter(x => x.s > 0);
        scored.forEach(x => x.s += Math.min(30, (Store.usage[x.e.id] ?? 0) * 3));
        scored.sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name));
        return out.concat(scored.map(x => ({
            kind: "app",
            entry: x.e,
            name: x.e.name,
            sub: x.e.comment || x.e.genericName || "",
            icon: x.e.icon
        })));
    }

    function activate(item, shift) {
        if (!item)
            return;
        if (item.kind === "app") {
            Store.bump(item.entry.id);
            item.entry.execute();
        } else if (item.kind === "calc") {
            Quickshell.clipboardText = item.name;
        } else if (item.kind === "run") {
            Quickshell.execDetached(shift ? ["ghostty", "-e", "sh", "-c", item.name + "; exec $SHELL"] : ["sh", "-c", item.name]);
        } else if (item.kind === "clip") {
            Quickshell.execDetached(["sh", "-c", `cliphist decode ${item.id} | wl-copy`]);
        }
        close();
    }

    function move(d) {
        const n = results.length;
        if (n)
            current = Math.max(0, Math.min(n - 1, current + d));
    }

    Process {
        id: clipProc
        command: ["sh", "-c", "cliphist list | head -n 200"]
        stdout: StdioCollector {
            onStreamFinished: root.clips = this.text.split("\n").filter(l => l.includes("\t")).map(l => {
                const i = l.indexOf("\t");
                const text = l.slice(i + 1);
                return { id: l.slice(0, i), text, image: /^\[\[ binary data .*(png|jpe?g|webp|bmp|gif)/i.test(text) };
            })
        }
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
        Rectangle {
            anchors.fill: parent
            visible: ai.path === ""
            radius: ai.size * 0.3
            color: Theme.surface2
            Label {
                anchors.centerIn: parent
                text: ai.name.charAt(0).toUpperCase()
                font.pixelSize: ai.size * 0.45
                color: Theme.accent
            }
        }
    }

    Item {
        id: body
        width: parent.width
        height: parent.height
        y: (1 - root.reveal) * height
        opacity: Math.min(1, root.reveal * 2)

        EdgeShape {
            anchors.fill: parent
            edge: "bottom"
            fillet: Theme.fillet
            fill: Theme.bg
        }

        ColumnLayout {
            id: col
            x: Theme.fillet + root.pad
            y: root.pad
            width: root.bodyWidth - 2 * root.pad
            spacing: 14

            Item {
                Layout.fillWidth: true
                implicitHeight: 40

                Underline {
                    anchors.fill: parent
                    color: input.text ? Theme.accent : Qt.alpha(Theme.accent, 0.5)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 6
                    anchors.bottomMargin: 2
                    spacing: 12

                    Icon {
                        text: root.mode === "clipboard" ? "󰅌" : root.query.startsWith(">") ? "" : root.query.startsWith("=") ? "󰃬" : "󰍉"
                        color: Theme.accent
                    }

                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        color: Theme.fg
                        selectionColor: Qt.alpha(Theme.accent, 0.4)
                        font.family: Theme.font
                        font.pixelSize: 16
                        font.bold: true
                        focus: true
                        clip: true
                        onTextChanged: root.query = text

                        Text {
                            visible: !input.text
                            text: root.mode === "clipboard" ? "Buscar no histórico…" : "Buscar…   = calcular   > comando"
                            color: Theme.muted
                            font: input.font
                        }

                        Keys.onPressed: e => {
                            const grid = root.gridMode;
                            if (e.key === Qt.Key_Escape) {
                                root.close();
                            } else if (e.key === Qt.Key_Down) {
                                root.move(grid ? root.cols : 1);
                            } else if (e.key === Qt.Key_Up) {
                                root.move(grid ? -root.cols : -1);
                            } else if (grid && e.key === Qt.Key_Right && !input.text) {
                                root.move(1);
                            } else if (grid && e.key === Qt.Key_Left && !input.text) {
                                root.move(-1);
                            } else if (e.key === Qt.Key_PageDown) {
                                root.move(grid ? root.cols * root.gridRows : root.listRows);
                            } else if (e.key === Qt.Key_PageUp) {
                                root.move(grid ? -root.cols * root.gridRows : -root.listRows);
                            } else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) {
                                root.setMode(root.mode === "apps" ? "clipboard" : "apps");
                            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                root.activate(root.results[root.current], e.modifiers & Qt.ShiftModifier);
                            } else if (e.key === Qt.Key_Delete && e.modifiers & Qt.ShiftModifier && root.mode === "clipboard") {
                                const it = root.results[root.current];
                                if (it) {
                                    Quickshell.execDetached(["sh", "-c", `cliphist list | grep -P '^${it.id}\\t' | cliphist delete`]);
                                    root.clips = root.clips.filter(c => c.id !== it.id);
                                }
                            } else {
                                return;
                            }
                            e.accepted = true;
                        }
                    }

                    Repeater {
                        model: [
                            { m: "apps", label: "Apps" },
                            { m: "clipboard", label: "Clipboard" }
                        ]
                        Item {
                            required property var modelData
                            readonly property bool on: root.mode === modelData.m
                            implicitWidth: tab.implicitWidth + 20
                            implicitHeight: 28

                            Underline {
                                anchors.fill: parent
                                visible: parent.on
                            }
                            Label {
                                id: tab
                                anchors.centerIn: parent
                                text: parent.modelData.label
                                font.pixelSize: 13
                                color: parent.on ? Theme.fg : Theme.muted
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setMode(parent.modelData.m)
                            }
                        }
                    }
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                visible: root.gridMode
                implicitHeight: root.cellH * Math.min(root.gridRows, Math.ceil(count / root.cols))
                cellWidth: root.cellW
                cellHeight: root.cellH
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.current
                model: ScriptModel {
                    values: root.gridMode ? root.results : []
                }

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool current: index === root.current

                    width: root.cellW
                    height: root.cellH

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 14
                        color: Theme.surface
                        opacity: cell.current ? 1 : cellMa.containsMouse ? 0.6 : 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        width: cell.current ? 22 : 0
                        height: 3
                        radius: 1.5
                        color: Theme.accent
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        AppIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: cell.modelData.icon ?? ""
                            name: cell.modelData.name
                            size: 38
                            scale: cell.current ? 1.1 : 1
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: root.cellW - 16
                            text: cell.modelData.name
                            font.pixelSize: 11
                            font.bold: cell.current
                            color: cell.current ? Theme.fg : Theme.dim
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: cellMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(cell.modelData, false)
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                visible: !root.gridMode
                implicitHeight: root.rowH * Math.max(1, Math.min(root.listRows, count))
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.current
                highlightMoveDuration: 140
                model: ScriptModel {
                    values: root.gridMode ? [] : root.results
                }

                highlight: Rectangle {
                    radius: 12
                    color: Theme.surface
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 20
                        radius: 1.5
                        color: Theme.accent
                    }
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool current: index === root.current
                    readonly property string thumb: modelData.image ? Quickshell.cachePath(`clip/${modelData.id}.png`) : ""
                    property bool thumbReady: false

                    width: list.width
                    height: root.rowH

                    Component.onCompleted: if (thumb) decoder.running = true

                    Process {
                        id: decoder
                        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")"; [ -s "$1" ] || cliphist decode "$2" > "$1"', "_", row.thumb, row.modelData.id ?? ""]
                        onExited: row.thumbReady = true
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 14
                        spacing: 14

                        Item {
                            implicitWidth: 30
                            implicitHeight: 30

                            AppIcon {
                                anchors.fill: parent
                                visible: row.modelData.kind === "app"
                                icon: row.modelData.icon ?? ""
                                name: row.modelData.name
                                size: 30
                            }
                            ClippingRectangle {
                                anchors.fill: parent
                                visible: row.thumbReady
                                radius: 8
                                color: Theme.surface2
                                Image {
                                    anchors.fill: parent
                                    source: row.thumbReady ? "file://" + row.thumb : ""
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize: Qt.size(64, 64)
                                    asynchronous: true
                                }
                            }
                            Icon {
                                anchors.centerIn: parent
                                visible: row.modelData.kind !== "app" && !row.thumbReady
                                text: row.modelData.glyph ?? ""
                                color: row.current ? Theme.accent : Theme.dim
                                font.pixelSize: 20
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            color: row.current ? Theme.fg : Theme.dim
                            font.pixelSize: row.modelData.kind === "calc" ? 20 : 14
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                        Label {
                            Layout.maximumWidth: list.width * 0.45
                            visible: text !== ""
                            text: row.modelData.sub ?? ""
                            color: Theme.muted
                            font.bold: false
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: root.current = row.index
                        onClicked: root.activate(row.modelData, false)
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: root.mode === "clipboard" ? "Histórico vazio" : "Nada encontrado"
                    color: Theme.muted
                    font.bold: false
                }
            }

            Label {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: -4
                text: root.mode === "clipboard" ? "↵ copiar    ⇧⌦ apagar    ⇥ apps    esc fechar" : root.gridMode ? "←↑↓→ navegar    ↵ abrir    ⇥ clipboard    esc fechar" : "↑↓ navegar    ↵ abrir    ⇥ clipboard    esc fechar"
                color: Theme.muted
                font.pixelSize: 11
                font.bold: false
            }
        }
    }
}

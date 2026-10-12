import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

PanelWindow {
    id: root

    readonly property int border: 6
    readonly property int segments: 10
    readonly property int segLen: 5

    property real ax: 0
    property real ay: 0
    property real x1: width / 2
    property real y1: height / 2
    property real x2: width / 2
    property real y2: height / 2
    property var ropes: []

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-region"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    function corners() {
        return [
            [0, 0, x1, y1],
            [width, 0, x2, y1],
            [0, height, x1, y2],
            [width, height, x2, y2]
        ];
    }

    function step() {
        if (width <= 0)
            return;
        const c = corners();
        if (ropes.length === 0)
            ropes = c.map(([ax, ay]) => Array.from({ length: segments + 1 }, (_, i) => ({ x: ax + i, y: ay + i, vx: 0, vy: 0 })));
        for (let r = 0; r < 4; r++) {
            const pts = ropes[r];
            const [ancX, ancY, pullX, pullY] = c[r];
            pts[0].x = ancX;
            pts[0].y = ancY;
            for (let i = segments; i > 0; i--) {
                const p = pts[i], prev = pts[i - 1];
                const pdx = prev.x - p.x, pdy = prev.y - p.y;
                const pd = Math.sqrt(pdx * pdx + pdy * pdy);
                const pe = pd - segLen;
                let vx = (pdx / pd) * pe;
                let vy = (pdy / pd) * pe + 9.8;
                if (isNaN(vx)) vx = 0;
                if (isNaN(vy)) vy = 0;
                if (i < segments - 3) {
                    const n = pts[i + 1];
                    const ndx = n.x - p.x, ndy = n.y - p.y;
                    const nd = Math.sqrt(ndx * ndx + ndy * ndy);
                    const ne = nd - segLen;
                    if (nd > 0) {
                        vx += (ndx / nd) * ne;
                        vy += (ndy / nd) * ne;
                    }
                } else {
                    p.x = pullX;
                    p.y = pullY;
                }
                p.vx = p.vx * 0.5 + vx * 0.45;
                p.vy = p.vy * 0.5 + vy * 0.45;
                p.x += p.vx;
                p.y += p.vy;
            }
        }
        canvas.requestPaint();
    }

    function finish() {
        const w = Math.round(x2 - x1), h = Math.round(y2 - y1);
        if (w < 4 || h < 4)
            Ui.selecting = false;
        else
            Ui.captureRegion(Math.round(screen.x + x1), Math.round(screen.y + y1), w, h);
    }

    Timer {
        interval: 1000 / 60
        running: true
        repeat: true
        onTriggered: root.step()
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            const b = root.border, R = b * 4;
            const x1 = root.x1, y1 = root.y1, dx = root.x2 - root.x1, dy = root.y2 - root.y1;
            ctx.reset();

            ctx.globalAlpha = 0.8;
            ctx.fillStyle = Theme.bgSolid;
            ctx.fillRect(0, 0, width, height);
            ctx.globalAlpha = 1;

            ctx.fillStyle = Theme.accent;
            ctx.fillRect(x1 - b, y1 - b, dx + b * 2, dy + b * 2);
            for (const [cx, cy] of [[x1, y1], [root.x2, y1], [x1, root.y2], [root.x2, root.y2]]) {
                ctx.beginPath();
                ctx.arc(cx, cy, R, 0, 2 * Math.PI);
                ctx.fill();
            }
            ctx.clearRect(x1, y1, dx, dy);

            ctx.lineWidth = 6;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.strokeStyle = Theme.accent;
            for (const pts of root.ropes) {
                ctx.beginPath();
                ctx.moveTo(pts[0].x, pts[0].y);
                for (let i = 0; i < pts.length - 1; i++) {
                    const p0 = pts[i - 1] ?? pts[i], p1 = pts[i], p2 = pts[i + 1], p3 = pts[i + 2] ?? p2;
                    ctx.bezierCurveTo(p1.x + (p2.x - p0.x) / 6, p1.y + (p2.y - p0.y) / 6,
                                      p2.x - (p3.x - p1.x) / 6, p2.y - (p3.y - p1.y) / 6, p2.x, p2.y);
                }
                ctx.stroke();

                ctx.fillStyle = "white";
                for (let i = 0; i < pts.length; i++) {
                    ctx.beginPath();
                    ctx.arc(pts[i].x, pts[i].y, i === 0 ? 3 : 1, 0, 2 * Math.PI);
                    ctx.fill();
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.CrossCursor

        onPressed: m => {
            if (m.button === Qt.RightButton) {
                Ui.selecting = false;
                return;
            }
            root.ax = root.x1 = root.x2 = m.x;
            root.ay = root.y1 = root.y2 = m.y;
        }
        onPositionChanged: m => {
            root.x1 = Math.min(root.ax, m.x);
            root.y1 = Math.min(root.ay, m.y);
            root.x2 = Math.max(root.ax, m.x);
            root.y2 = Math.max(root.ay, m.y);
        }
        onReleased: m => {
            if (m.button === Qt.LeftButton)
                root.finish();
        }
    }

    Item {
        focus: true
        Keys.onEscapePressed: Ui.selecting = false
    }
}

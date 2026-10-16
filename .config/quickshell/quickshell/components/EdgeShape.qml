import QtQuick
import qs

Canvas {
    id: root

    property string edge: "left"
    property real fillet: 16
    property real radius: 18
    property color fill: Theme.bg
    property color stroke: Qt.alpha(Theme.accent, 0.18)
    property rect hole: Qt.rect(0, 0, 0, 0)
    property real holeRadius: 10

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onHoleChanged: requestPaint()

    function shape(ctx) {
        const f = fillet, r = radius, w = width, h = height;
        ctx.beginPath();
        if (edge === "left") {
            ctx.moveTo(0, 0);
            ctx.arc(f, 0, f, Math.PI, Math.PI / 2, true);
            ctx.lineTo(w - r, f);
            ctx.arcTo(w, f, w, f + r, r);
            ctx.lineTo(w, h - f - r);
            ctx.arcTo(w, h - f, w - r, h - f, r);
            ctx.lineTo(f, h - f);
            ctx.arc(f, h, f, -Math.PI / 2, -Math.PI, true);
        } else if (edge === "bottom") {
            ctx.moveTo(0, h);
            ctx.arc(0, h - f, f, Math.PI / 2, 0, true);
            ctx.lineTo(f, r);
            ctx.arcTo(f, 0, f + r, 0, r);
            ctx.lineTo(w - f - r, 0);
            ctx.arcTo(w - f, 0, w - f, r, r);
            ctx.lineTo(w - f, h - f);
            ctx.arc(w, h - f, f, Math.PI, Math.PI / 2, true);
        } else {
            ctx.moveTo(w, 0);
            ctx.arc(w - f, 0, f, 0, Math.PI / 2, false);
            ctx.lineTo(r, f);
            ctx.arcTo(0, f, 0, f + r, r);
            ctx.lineTo(0, h - f - r);
            ctx.arcTo(0, h - f, r, h - f, r);
            ctx.lineTo(w - f, h - f);
            ctx.arc(w - f, h, f, -Math.PI / 2, 0, false);
        }
        ctx.closePath();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        shape(ctx);
        ctx.fillStyle = fill;
        ctx.fill();
        ctx.strokeStyle = stroke;
        ctx.lineWidth = 1;
        ctx.stroke();
        if (hole.width > 0) {
            ctx.globalCompositeOperation = "destination-out";
            ctx.beginPath();
            ctx.roundedRect(hole.x, hole.y, hole.width, hole.height, holeRadius, holeRadius);
            ctx.fillStyle = "black";
            ctx.fill();
        }
    }
}
